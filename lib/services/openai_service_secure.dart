import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ndu_project/openai/openai_config.dart';
import 'package:ndu_project/models/project_data_model.dart';

// Remove markdown bold markers commonly produced by the model (e.g. *text* or **text**)
String _stripAsterisks(String s) => s.replaceAll('*', '');

/// Filters out cloud/software-only references, keeping only physical infrastructure
bool _isPhysicalInfrastructure(String item) {
  final lower = item.toLowerCase();
  // Exclude cloud services and software-only terms
  final excludePatterns = [
    'cloud', 'aws', 'azure', 'gcp', 'google cloud', 'amazon web services',
    'saas', 'paas', 'iaas', 'docker', 'kubernetes', 'container',
    'virtual machine', 'vm', 'vmware', 'hypervisor',
    'api', 'framework', 'library', 'sdk', 'software',
    'database' // Exclude unless it's clearly a physical server
  ];

  // Check if item contains any exclude patterns
  for (final pattern in excludePatterns) {
    if (lower.contains(pattern)) {
      // Allow exceptions for physical hardware mentions
      if (lower.contains('physical') ||
          lower.contains('hardware') ||
          lower.contains('server') ||
          lower.contains('rack') ||
          lower.contains('data center') ||
          lower.contains('datacenter')) {
        continue; // Allow if it's clearly physical
      }
      return false; // Exclude cloud/software references
    }
  }

  // Include physical infrastructure keywords
  final includePatterns = [
    'server',
    'cabling',
    'cable',
    'hardware',
    'router',
    'switch',
    'network',
    'storage',
    'rack',
    'data center',
    'datacenter',
    'cooling',
    'power',
    'ups',
    'physical',
    'equipment'
  ];

  // Check if item contains any include patterns
  for (final pattern in includePatterns) {
    if (lower.contains(pattern)) {
      return true;
    }
  }

  // Default: include if it doesn't match exclude patterns
  return true;
}

class AiSolutionItem {
  final String title;
  final String description;

  AiSolutionItem({required this.title, required this.description});

  factory AiSolutionItem.fromMap(Map<String, dynamic> map) => AiSolutionItem(
        title: _stripAsterisks((map['title'] ?? '').toString().trim()),
        description:
            _stripAsterisks((map['description'] ?? '').toString().trim()),
      );
}

class AiCostItem {
  final String item;
  final String description;
  final double estimatedCost;
  final double roiPercent; // percent value, e.g., 15.0 means 15%
  final Map<int, double> npvByYear;
  final double npv; // default to selected baseline (5-year when available)

  AiCostItem({
    required this.item,
    required this.description,
    required this.estimatedCost,
    required this.roiPercent,
    required Map<int, double> npvByYear,
  })  : npvByYear = Map.unmodifiable({...npvByYear}),
        npv =
            npvByYear[5] ?? (npvByYear.isNotEmpty ? npvByYear.values.first : 0);

  double npvForYear(int years) => npvByYear[years] ?? npv;

  factory AiCostItem.fromMap(Map<String, dynamic> map) {
    final Map<int, double> parsedNpvs = {};

    double toD(v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      final s = v.toString().replaceAll(',', '').replaceAll('%', '').trim();
      return double.tryParse(s) ?? 0;
    }

    void addNpv(int year, dynamic value) {
      final parsed = toD(value);
      if (parsedNpvs.containsKey(year) || parsed == 0) return;
      parsedNpvs[year] = parsed;
    }

    final npvField = map['npv'];
    if (npvField is Map) {
      for (final entry in npvField.entries) {
        final key = entry.key.toString().replaceAll(RegExp(r'[^0-9]'), '');
        final year = int.tryParse(key);
        if (year != null) addNpv(year, entry.value);
      }
    } else {
      addNpv(5, npvField);
    }

    final npvByYearsField = map['npv_by_years'];
    if (npvByYearsField is Map) {
      for (final entry in npvByYearsField.entries) {
        final key = entry.key.toString().replaceAll(RegExp(r'[^0-9]'), '');
        final year = int.tryParse(key);
        if (year != null) addNpv(year, entry.value);
      }
    }

    if (parsedNpvs.isEmpty) addNpv(5, 0);

    return AiCostItem(
      item: (map['item'] ?? map['project_item'] ?? '').toString().trim(),
      description: (map['description'] ?? '').toString().trim(),
      estimatedCost: toD(map['estimated_cost']),
      roiPercent: toD(map['roi_percent']),
      npvByYear: parsedNpvs,
    );
  }
}

class AiProjectValueInsights {
  final double estimatedProjectValue;
  final Map<String, String> benefits;

  AiProjectValueInsights(
      {required this.estimatedProjectValue, required this.benefits});

  factory AiProjectValueInsights.fromMap(Map<String, dynamic> map) {
    double toD(v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      final s = v.toString().replaceAll(',', '').replaceAll('%', '').trim();
      return double.tryParse(s) ?? 0;
    }

    final estimated = toD(map['estimated_value'] ?? map['project_value']);
    final benefitsRaw = map['benefits'];
    final parsedBenefits = <String, String>{};
    if (benefitsRaw is Map) {
      for (final entry in benefitsRaw.entries) {
        parsedBenefits[entry.key.toString()] =
            _stripAsterisks(entry.value.toString());
      }
    } else if (benefitsRaw is List) {
      for (final item in benefitsRaw) {
        if (item is Map && item.containsKey('category')) {
          parsedBenefits[item['category'].toString()] = _stripAsterisks(
              (item['details'] ?? item['value'] ?? '').toString());
        }
      }
    }
    return AiProjectValueInsights(
        estimatedProjectValue: estimated, benefits: parsedBenefits);
  }
}

class AiProjectGoalRecommendation {
  final String name;
  final String description;
  final String? framework;

  AiProjectGoalRecommendation({
    required this.name,
    required this.description,
    this.framework,
  });

  factory AiProjectGoalRecommendation.fromMap(Map<String, dynamic> map) {
    final rawName = map['name'] ?? map['goal_name'] ?? map['title'] ?? '';
    final rawDesc = map['description'] ?? map['details'] ?? map['text'] ?? '';
    final rawFramework =
        map['framework'] ?? map['methodology'] ?? map['approach'] ?? '';
    final name = _stripAsterisks(rawName.toString().trim());
    final description = _stripAsterisks(rawDesc.toString().trim());
    final framework = _stripAsterisks(rawFramework?.toString().trim() ?? '');
    return AiProjectGoalRecommendation(
      name: name,
      description: description,
      framework: (framework.isEmpty) ? null : framework,
    );
  }

  factory AiProjectGoalRecommendation.fallback({
    required String name,
    required String description,
    String? framework,
  }) {
    return AiProjectGoalRecommendation(
      name: name,
      description: description,
      framework: framework,
    );
  }
}

class AiProjectFrameworkAndGoals {
  final String framework;
  final List<AiProjectGoalRecommendation> goals;

  AiProjectFrameworkAndGoals({
    required this.framework,
    required this.goals,
  });

  factory AiProjectFrameworkAndGoals.fromMap(Map<String, dynamic> map) {
    final rawFramework =
        map['framework'] ?? map['overallFramework'] ?? map['methodology'] ?? '';
    final framework = _stripAsterisks(rawFramework.toString().trim());
    final rawGoals = map['goals'];
    final parsedGoals = <AiProjectGoalRecommendation>[];
    if (rawGoals is List) {
      for (final entry in rawGoals) {
        if (entry is Map<String, dynamic>) {
          parsedGoals.add(AiProjectGoalRecommendation.fromMap(entry));
        } else if (entry is String) {
          parsedGoals.add(AiProjectGoalRecommendation(
            name: '',
            description: _stripAsterisks(entry.trim()),
            framework: framework.isEmpty ? null : framework,
          ));
        }
      }
    } else if (rawGoals is Map<String, dynamic>) {
      parsedGoals.add(AiProjectGoalRecommendation.fromMap(rawGoals));
    }

    return AiProjectFrameworkAndGoals(
      framework: framework,
      goals: parsedGoals,
    );
  }

  factory AiProjectFrameworkAndGoals.fallback(String context) {
    final projectName = _extractProjectName(context);
    final assetName = projectName.isEmpty ? 'project' : projectName;
    final descriptions = [
      'Define a governance model and stakeholder alignment for $assetName to keep priorities clear and enable timely decisions.',
      'Deliver measurable outcomes around customer experience, regulation, or operational efficiency while reinforcing transparency for $assetName.',
      'Create delivery cadences (planning, review, launch) that keep teams accountable and surface risks early during $assetName implementation.',
    ];
    const frameworkOptions = ['Agile', 'Waterfall', 'Hybrid'];
    final goals = List.generate(3, (index) {
      return AiProjectGoalRecommendation.fallback(
        name: 'Goal ${index + 1}',
        description: descriptions[index % descriptions.length],
        framework: frameworkOptions[index % frameworkOptions.length],
      );
    });
    return AiProjectFrameworkAndGoals(framework: 'Hybrid', goals: goals);
  }
}

String _extractProjectName(String context) {
  final lines = context.split('\n');
  for (final line in lines) {
    final lower = line.toLowerCase();
    if (lower.startsWith('project name:')) {
      final value = line.substring(line.indexOf(':') + 1).trim();
      if (value.isNotEmpty) return value;
    }
  }
  return '';
}

class BenefitLineItemInput {
  final String category;
  final String title;
  final double unitValue;
  final double units;
  final String notes;

  BenefitLineItemInput({
    required this.category,
    required this.title,
    required this.unitValue,
    required this.units,
    this.notes = '',
  });

  double get total => unitValue * units;

  Map<String, dynamic> toJson() => {
        'category': category,
        'title': title,
        'unit_value': unitValue,
        'units': units,
        'total': total,
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      };
}

class AiBenefitSavingsSuggestion {
  final String lever;
  final String recommendation;
  final double projectedSavings;
  final String timeframe;
  final String confidence;
  final String rationale;

  AiBenefitSavingsSuggestion({
    required this.lever,
    required this.recommendation,
    required this.projectedSavings,
    required this.timeframe,
    required this.confidence,
    required this.rationale,
  });

  factory AiBenefitSavingsSuggestion.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      final sanitized = value.toString().replaceAll(RegExp(r'[^0-9\.-]'), '');
      return double.tryParse(sanitized) ?? 0;
    }

    String parseString(dynamic value) => value?.toString().trim() ?? '';

    return AiBenefitSavingsSuggestion(
      lever: _stripAsterisks(
          parseString(map['lever'] ?? map['title'] ?? map['scenario'])),
      recommendation: _stripAsterisks(parseString(
          map['recommendation'] ?? map['action'] ?? map['strategy'])),
      projectedSavings: parseDouble(
          map['projected_savings'] ?? map['savings'] ?? map['projected_value']),
      timeframe: _stripAsterisks(
          parseString(map['timeframe'] ?? map['horizon'] ?? map['period'])),
      confidence: _stripAsterisks(parseString(
          map['confidence'] ?? map['certainty'] ?? map['confidence_level'])),
      rationale: _stripAsterisks(
          parseString(map['rationale'] ?? map['notes'] ?? map['summary'])),
    );
  }
}

class OpenAiServiceSecure {
  final http.Client _client;
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 2);

  OpenAiServiceSecure({http.Client? client})
      : _client = client ?? http.Client();

  // Generate a concise section text for Front End Planning pages based on full project context.
  // Returns a rich paragraph suitable for a multi-line TextField. If API is not configured,
  // falls back to a short heuristic summary from the provided context.
  Future<String> generateFepSectionText({
    required String section,
    required String context,
    int maxTokens = 900,
    double temperature = 0.5,
  }) async {
    final trimmedContext = context.trim();
    if (trimmedContext.isEmpty) return '';
    if (!OpenAiConfig.isConfigured) {
      throw const OpenAiNotConfiguredException();
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };

    final prompt = _fepSectionPrompt(section: section, context: trimmedContext);
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a senior delivery planner. For the requested section, draft a crisp, actionable write-up. Always return only a JSON object.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 14));
      if (response.statusCode == 401) throw Exception('Invalid API key');
      if (response.statusCode == 429) throw Exception('API quota exceeded');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final text =
          (parsed['text'] ?? parsed['section'] ?? parsed['content'] ?? '')
              .toString()
              .trim();
      final cleanText = _stripAsterisks(text);
      if (cleanText.isNotEmpty) return cleanText;
      // If missing expected key, try to flatten other fields to text
      if (parsed.isNotEmpty) {
        return parsed.values
            .map((v) => _stripAsterisks(v.toString()))
            .join('\n')
            .trim();
      }
      return '';
    } catch (e) {
      // Surface the error to callers so the UI can show a clear failure state
      rethrow;
    }
  }

  Future<DesignDeliverablesData> generateDesignDeliverables({
    required String context,
    int maxTokens = 1200,
    double temperature = 0.4,
  }) async {
    final trimmedContext = context.trim();
    if (trimmedContext.isEmpty) {
      return const DesignDeliverablesData();
    }
    if (!OpenAiConfig.isConfigured) {
      return _designDeliverablesFallback(trimmedContext);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };

    final prompt = '''
You are drafting the Design Deliverables workspace for a project. Using the context below, return ONLY a JSON object with the exact keys:
metrics: {active, in_review, approved, at_risk}
pipeline: [{label, status}]
approvals: [string]
register: [{name, owner, status, due, risk}]
dependencies: [string]
handoff: [string]

Rules:
- Provide 4-6 items for pipeline, approvals, register, dependencies, and handoff.
- Use realistic owners, dates, and statuses (Approved, In Review, In Progress, Pending).
- Use risks: Low, Medium, High.
- Keep each string under 90 characters.

Context:
$trimmedContext
''';

    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a design delivery coordinator. Return only a JSON object that matches the requested schema.'
        },
        {'role': 'user', 'content': prompt}
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 16));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      return _parseDesignDeliverables(parsed);
    } catch (_) {
      return _designDeliverablesFallback(trimmedContext);
    }
  }

  DesignDeliverablesData _parseDesignDeliverables(Map<String, dynamic> json) {
    List<String> toStringList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => _stripAsterisks(e.toString().trim()))
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    }

    List<DesignDeliverablePipelineItem> parsePipeline(dynamic value) {
      if (value is List) {
        return value
            .map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return DesignDeliverablePipelineItem(
                label: _stripAsterisks((map['label'] ?? '').toString().trim()),
                status:
                    _stripAsterisks((map['status'] ?? '').toString().trim()),
              );
            })
            .where((item) => item.label.isNotEmpty)
            .toList();
      }
      return const [];
    }

    List<DesignDeliverableRegisterItem> parseRegister(dynamic value) {
      if (value is List) {
        return value
            .map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return DesignDeliverableRegisterItem(
                name: _stripAsterisks((map['name'] ?? '').toString().trim()),
                owner: _stripAsterisks((map['owner'] ?? '').toString().trim()),
                status:
                    _stripAsterisks((map['status'] ?? '').toString().trim()),
                due: _stripAsterisks((map['due'] ?? '').toString().trim()),
                risk: _stripAsterisks((map['risk'] ?? '').toString().trim()),
              );
            })
            .where((item) => item.name.isNotEmpty)
            .toList();
      }
      return const [];
    }

    final metricsMap = json['metrics'] is Map
        ? Map<String, dynamic>.from(json['metrics'] as Map)
        : <String, dynamic>{};
    final metrics = DesignDeliverablesMetrics.fromJson(metricsMap);

    return DesignDeliverablesData(
      metrics: metrics,
      pipeline: parsePipeline(json['pipeline']),
      approvals: toStringList(json['approvals']),
      register: parseRegister(json['register']),
      dependencies: toStringList(json['dependencies']),
      handoffChecklist: toStringList(json['handoff']),
    );
  }

  DesignDeliverablesData _designDeliverablesFallback(String context) {
    final project = _extractProjectName(context);
    final name = project.isNotEmpty ? project : 'Project';
    return DesignDeliverablesData(
      metrics: const DesignDeliverablesMetrics(
          active: 6, inReview: 3, approved: 2, atRisk: 1),
      pipeline: const [
        DesignDeliverablePipelineItem(
            label: 'Discovery & Research', status: 'In Review'),
        DesignDeliverablePipelineItem(
            label: 'Wireframes', status: 'In Progress'),
        DesignDeliverablePipelineItem(label: 'UI Design', status: 'Pending'),
        DesignDeliverablePipelineItem(label: 'Prototype', status: 'Pending'),
      ],
      approvals: [
        'Product sign-off aligned for $name',
        'Engineering review scheduled',
        'Accessibility review pending',
        'Brand compliance check queued',
      ],
      register: const [
        DesignDeliverableRegisterItem(
            name: 'Wireframe Pack',
            owner: 'UX Team',
            status: 'In Review',
            due: 'TBD',
            risk: 'Medium'),
        DesignDeliverableRegisterItem(
            name: 'UI Kit',
            owner: 'Design Ops',
            status: 'In Progress',
            due: 'TBD',
            risk: 'Low'),
        DesignDeliverableRegisterItem(
            name: 'Prototype',
            owner: 'Product',
            status: 'Pending',
            due: 'TBD',
            risk: 'High'),
        DesignDeliverableRegisterItem(
            name: 'Journey Maps',
            owner: 'Research',
            status: 'In Progress',
            due: 'TBD',
            risk: 'Medium'),
      ],
      dependencies: const [
        'Finalize IA and navigation taxonomy',
        'Confirm content strategy inputs',
        'Align analytics tracking requirements',
      ],
      handoffChecklist: const [
        'Component specs documented',
        'Accessibility annotations included',
        'Figma files shared with dev team',
        'Interaction guidelines attached',
      ],
    );
  }

  Future<AiProjectFrameworkAndGoals> suggestProjectFrameworkGoals({
    required String context,
    int maxTokens = 450,
    double temperature = 0.4,
  }) async {
    final trimmedContext = context.trim();
    if (trimmedContext.isEmpty) {
      throw Exception('No project context provided');
    }
    if (!OpenAiConfig.isConfigured) {
      throw const OpenAiNotConfiguredException();
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a senior project strategist helping to set the right delivery framework and goals. Always reply with JSON only and obey the required schema.'
        },
        {
          'role': 'user',
          'content': _projectFrameworkPrompt(trimmedContext),
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>? ?? [];
      if (choices.isNotEmpty) {
        final firstMessage =
            choices.first['message'] as Map<String, dynamic>? ?? {};
        final content = (firstMessage['content'] as String?)?.trim() ?? '';
        final parsed = _decodeJsonSafely(content);
        if (parsed != null) {
          final result = AiProjectFrameworkAndGoals.fromMap(parsed);
          if (result.goals.length >= 3 && result.framework.isNotEmpty) {
            return result;
          }
          if (result.goals.isNotEmpty) {
            return result;
          }
        }
      }
    } catch (e) {
      // Let callers handle the failure and show an explicit error state
      rethrow;
    }
    throw Exception('OpenAI did not return framework goals');
  }

  // OPPORTUNITIES
  // Generates a structured list of project opportunities based on full project context.
  // Returns up to 12 rows suitable for the Opportunities table.
  Future<List<Map<String, String>>> generateOpportunitiesFromContext(
      String context) async {
    final trimmed = context.trim();
    if (trimmed.isEmpty) {
      debugPrint('No context provided for opportunities generation');
      return _fallbackOpportunities();
    }
    if (!OpenAiConfig.isConfigured) {
      debugPrint('OpenAI not configured, using fallback opportunities');
      return _fallbackOpportunities();
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };

    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.55,
      'max_tokens': 1200,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a program manager. From prior project inputs, draft tangible project opportunities. Always return a JSON object only.'
        },
        {
          'role': 'user',
          'content': _opportunitiesPrompt(trimmed),
        }
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30)); // Increased timeout
      if (response.statusCode == 401) {
        debugPrint('Invalid API key for opportunities generation');
        return _fallbackOpportunities();
      }
      if (response.statusCode == 429) {
        debugPrint('API quota exceeded for opportunities generation');
        return _fallbackOpportunities();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('OpenAI error ${response.statusCode} for opportunities');
        return _fallbackOpportunities();
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final list = (parsed['opportunities'] as List? ?? []);
      final result = <Map<String, String>>[];
      for (final item in list) {
        if (item is! Map) continue;
        final map = item as Map<String, dynamic>;
        final opp = _stripAsterisks(
            (map['opportunity'] ?? map['title'] ?? '').toString().trim());
        if (opp.isEmpty) continue;

        // Extract all fields with multiple fallback options
        final discipline = (map['discipline'] ?? '').toString().trim();
        final stakeholder = (map['stakeholder'] ??
                map['owner'] ??
                map['stakeholder_name'] ??
                '')
            .toString()
            .trim();
        final costSavings = (map['potential_cost_savings'] ??
                map['cost_savings'] ??
                map['potentialCost1'] ??
                '')
            .toString()
            .trim();
        final scheduleSavings = (map['potential_cost_schedule_savings'] ??
                map['schedule_savings'] ??
                map['potentialCost2'] ??
                '')
            .toString()
            .trim();

        // If critical fields are missing, use fallback data for this item
        if (discipline.isEmpty ||
            stakeholder.isEmpty ||
            costSavings.isEmpty ||
            scheduleSavings.isEmpty) {
          // Use a fallback opportunity with all fields filled
          final fallbackIndex = result.length % _fallbackOpportunities().length;
          final fallback = _fallbackOpportunities()[fallbackIndex];
          result.add({
            'opportunity': opp.isNotEmpty ? opp : fallback['opportunity']!,
            'discipline':
                discipline.isNotEmpty ? discipline : fallback['discipline']!,
            'stakeholder':
                stakeholder.isNotEmpty ? stakeholder : fallback['stakeholder']!,
            'potentialCost1': costSavings.isNotEmpty
                ? costSavings
                : fallback['potentialCost1']!,
            'potentialCost2': scheduleSavings.isNotEmpty
                ? scheduleSavings
                : fallback['potentialCost2']!,
          });
        } else {
          result.add({
            'opportunity': opp,
            'discipline': discipline,
            'stakeholder': stakeholder,
            'potentialCost1': costSavings,
            'potentialCost2': scheduleSavings,
          });
        }
      }
      if (result.isNotEmpty) return result.take(12).toList();
      // Return fallback if no opportunities generated
      return _fallbackOpportunities();
    } catch (e) {
      debugPrint('generateOpportunitiesFromContext failed: $e');
      // Return fallback on any error (timeout, network, parsing, etc.)
      return _fallbackOpportunities();
    }
  }

  List<Map<String, String>> _fallbackOpportunities() {
    return [
      {
        'opportunity': 'Automate manual data entry processes',
        'discipline': 'IT',
        'stakeholder': 'IT Operations Manager',
        'potentialCost1': '50,000',
        'potentialCost2': '4 weeks',
      },
      {
        'opportunity': 'Consolidate vendor contracts for better pricing',
        'discipline': 'Procurement',
        'stakeholder': 'Procurement Director',
        'potentialCost1': '75,000',
        'potentialCost2': '6 weeks',
      },
      {
        'opportunity': 'Implement early risk detection mechanisms',
        'discipline': 'Project Management',
        'stakeholder': 'Program Manager',
        'potentialCost1': '30,000',
        'potentialCost2': '2 weeks',
      },
      {
        'opportunity': 'Streamline approval workflows',
        'discipline': 'Operations',
        'stakeholder': 'Operations Lead',
        'potentialCost1': '40,000',
        'potentialCost2': '3 weeks',
      },
      {
        'opportunity': 'Leverage existing infrastructure investments',
        'discipline': 'IT',
        'stakeholder': 'IT Infrastructure Manager',
        'potentialCost1': '100,000',
        'potentialCost2': '8 weeks',
      },
      {
        'opportunity': 'Cross-train team members for better coverage',
        'discipline': 'Human Resources',
        'stakeholder': 'HR Director',
        'potentialCost1': '25,000',
        'potentialCost2': '2 weeks',
      },
    ];
  }

  String _opportunitiesPrompt(String context) {
    final c = _escape(context);
    return '''
From the project context below, list concrete project opportunities that would benefit the initiative (efficiency, cost, schedule, risk reduction, quality, compliance, etc.).

CRITICAL: You MUST include ALL fields for each opportunity. Do not leave any field empty.

Return ONLY valid JSON with this exact structure:
{
  "opportunities": [
    {
      "opportunity": "Concise opportunity statement (REQUIRED)",
      "discipline": "Owning discipline (e.g., IT, Finance, Operations, Project Management, Risk Management, Consulting) (REQUIRED)",
      "stakeholder": "Primary stakeholder / owner name and title (e.g., 'IT Operations Manager', 'Procurement Director', 'Program Manager') (REQUIRED)",
      "potential_cost_savings": "Estimated cost savings amount (e.g., '50,000', '75,000', '100,000') (REQUIRED)",
      "potential_cost_schedule_savings": "Estimated schedule savings (e.g., '4 weeks', '6 weeks', '2 months') (REQUIRED)"
    }
  ]
}

Guidelines:
- Be specific and actionable (no placeholders).
- ALWAYS provide a stakeholder name and title for each opportunity.
- ALWAYS provide realistic cost savings estimates (use dollar amounts like '50,000' or '75,000').
- ALWAYS provide realistic schedule savings (use time periods like '2 weeks', '1 month', '6 weeks').
- Use concise text; do not add extra fields.
- Generate 5–12 items.

Project context:
"""
$c
"""
''';
  }

  String _fepSectionPrompt({required String section, required String context}) {
    final s = _escape(section);
    final c = _escape(context);
    return '''
Draft the Front End Planning section: "$s" from the project context below.

Return ONLY valid JSON with this exact structure:
{
  "text": "final write-up as plain text, with concise paragraphs and bullet points only when helpful"
}

Guidelines:
- Use the project's goals, risks, and milestones as constraints and inputs.
- Keep it 120–250 words when possible; be specific and actionable.
- Avoid placeholders, boilerplate, and generic fluff.
- Where helpful, use short lists (hyphen bullets) but keep structure minimal.

Project context:
"""
$c
"""
''';
  }

  /// Generates a comprehensive business case from project notes and context
  Future<String> generateBusinessCase({
    required String projectName,
    String notes = '',
    String solutionTitle = '',
    String solutionDescription = '',
    int maxTokens = 1200,
    double temperature = 0.6,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      throw const OpenAiNotConfiguredException();
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };

    final prompt = _businessCasePrompt(
      projectName: projectName,
      notes: notes,
      solutionTitle: solutionTitle,
      solutionDescription: solutionDescription,
    );

    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a senior business analyst. Generate a comprehensive, professional business case that justifies the project investment. Always return only a JSON object with a "business_case" field containing the full text.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 401) throw Exception('Invalid API key');
      if (response.statusCode == 429) throw Exception('API quota exceeded');
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final businessCase =
          (parsed['business_case'] ?? parsed['text'] ?? parsed['content'] ?? '')
              .toString()
              .trim();
      final cleanText = _stripAsterisks(businessCase);
      if (cleanText.isNotEmpty) return cleanText;
      // Fallback: try to extract from any text field
      if (parsed.isNotEmpty) {
        return parsed.values
            .map((v) => _stripAsterisks(v.toString()))
            .join('\n')
            .trim();
      }
      return '';
    } catch (e) {
      rethrow;
    }
  }

  String _businessCasePrompt({
    required String projectName,
    String notes = '',
    String solutionTitle = '',
    String solutionDescription = '',
  }) {
    final pn = _escape(projectName);
    final n = _escape(notes);
    final st = _escape(solutionTitle);
    final sd = _escape(solutionDescription);

    return '''
Generate a comprehensive business case for the project: "$pn"

Return ONLY valid JSON with this exact structure:
{
  "business_case": "A detailed business case (minimum 150 words) covering: 1) Executive Summary, 2) Problem Statement, 3) Proposed Solution, 4) Expected Benefits, 5) Investment Requirements, 6) Risk Assessment, 7) Success Metrics. Use clear paragraphs and professional business language."
}

Guidelines:
- Minimum 150 words, ideally 200-400 words
- Include specific, measurable benefits
- Address risks and mitigation strategies
- Use professional business terminology
- Be specific to the project context provided
- Avoid generic templates or placeholders

Project Information:
- Project Name: $pn
${notes.isNotEmpty ? '- Notes: $n' : ''}
${solutionTitle.isNotEmpty ? '- Solution: $st' : ''}
${solutionDescription.isNotEmpty ? '- Solution Description: $sd' : ''}

Generate a compelling business case that would justify this project to executive stakeholders.
''';
  }

  // Quick single-item estimate for inline AI suggestions in cost fields
  // Returns a numeric estimated cost in the provided currency (defaults to USD).
  Future<double> estimateCostForItem({
    required String itemName,
    String description = '',
    String assumptions = '',
    String currency = 'USD',
    String contextNotes = '',
  }) async {
    final String trimmed = itemName.trim();
    if (trimmed.isEmpty) return 0;

    if (!OpenAiConfig.isConfigured) throw const OpenAiNotConfiguredException();

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };

    final prompt = _singleItemEstimatePrompt(
      itemName: trimmed,
      description: description,
      assumptions: assumptions,
      currency: currency,
      contextNotes: contextNotes,
    );

    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.35,
      'max_tokens': 300,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a senior cost analyst. Always return a JSON object only.'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) {
        throw Exception('Invalid API key');
      }
      if (response.statusCode == 429) {
        throw Exception('API quota exceeded');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }

      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final dynamic value =
          parsed['estimated_cost'] ?? parsed['cost'] ?? parsed['value'];
      return _toDouble(value);
    } catch (e) {
      rethrow;
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(s) ?? 0;
  }

// Removed small deterministic fallback helpers — API failures must surface to the UI.

  String _singleItemEstimatePrompt({
    required String itemName,
    required String description,
    required String assumptions,
    required String currency,
    required String contextNotes,
  }) {
    final safeName = _escape(itemName);
    final safeDesc = _escape(description);
    final safeAssumptions = _escape(assumptions);
    final notes = contextNotes.trim().isEmpty ? 'None' : _escape(contextNotes);
    return '''
Estimate a realistic one-off cost for a single project line item in $currency.

Return ONLY valid JSON like this example:
{
  "estimated_cost": 12345
}

Item: "$safeName"
Description: "$safeDesc"
Assumptions: "$safeAssumptions"
Additional context: "$notes"
''';
  }

  // SOLUTIONS
  Future<List<AiSolutionItem>> generateSolutionsFromBusinessCase(
      String businessCase) async {
    if (businessCase.trim().isEmpty) throw Exception('Business case is empty');
    if (!OpenAiConfig.isConfigured) throw const OpenAiNotConfiguredException();

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final solutions = await _attemptSolutionsApiCall(businessCase);
        if (solutions.isNotEmpty) return solutions;
      } catch (e) {
        if (attempt < maxRetries - 1) await Future.delayed(retryDelay);
        if (attempt == maxRetries - 1) rethrow;
      }
    }
    throw Exception('OpenAI returned no solutions');
  }

  Future<List<AiSolutionItem>> _attemptSolutionsApiCall(
      String businessCase) async {
    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.7,
      'max_tokens': 1000,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a project initiation assistant. You write concise, business-friendly solution options. Always return strict JSON that matches the required schema.'
        },
        {'role': 'user', 'content': _solutionsPrompt(businessCase)},
      ],
    });

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 429) {
      throw Exception('API quota exceeded. Please check your OpenAI billing.');
    }
    if (response.statusCode == 401) {
      throw Exception('Invalid API key. Please check your OpenAI API key.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'OpenAI API error ${response.statusCode}: ${response.body}');
    }

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final content =
        (data['choices'] as List).first['message']['content'] as String;
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final items = (parsed['solutions'] as List? ?? [])
        .map((e) => AiSolutionItem.fromMap(e as Map<String, dynamic>))
        .where((e) => e.title.isNotEmpty && e.description.isNotEmpty)
        .toList();
    return _normalizeSolutions(items);
  }

  // RISKS
  Future<Map<String, List<String>>> generateRisksForSolutions(
      List<AiSolutionItem> solutions,
      {String contextNotes = ''}) async {
    if (solutions.isEmpty) return {};
    if (!OpenAiConfig.isConfigured) throw const OpenAiNotConfiguredException();

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.6,
      'max_tokens': 1200,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a risk analyst. For each provided solution, list three crisp, non-overlapping delivery risks. Be detailed and specific: do not use "etc.", "and similar", or vague groupings. State each risk explicitly in full. Return strict JSON only.'
        },
        {'role': 'user', 'content': _risksPrompt(solutions, contextNotes)},
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      final List list = (parsed['risks'] as List? ?? []);
      final Map<String, List<String>> result = {};
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final title = _stripAsterisks((map['solution'] ?? '').toString());
        final items = (map['items'] as List? ?? [])
            .map((e) => _stripAsterisks(e.toString()))
            .where((e) => e.trim().isNotEmpty)
            .take(3)
            .toList();
        if (title.isNotEmpty && items.isNotEmpty) result[title] = items;
      }
      return _mergeWithFallbackRisks(solutions, result);
    } catch (e) {
      rethrow;
    }
  }

  Map<String, List<String>> _mergeWithFallbackRisks(
      List<AiSolutionItem> solutions, Map<String, List<String>> generated) {
    final fallback = _fallbackRisks(solutions);
    final merged = <String, List<String>>{};
    for (final s in solutions) {
      final g = generated[s.title];
      merged[s.title] = (g != null && g.isNotEmpty)
          ? g.take(3).toList()
          : (fallback[s.title] ?? []);
    }
    return merged;
  }

  Map<String, List<String>> _fallbackRisks(List<AiSolutionItem> solutions) {
    // Provide solution-specific fallback risks to avoid identical risks across solutions
    final genericRiskPools = [
      [
        'Phased approach may extend overall timeline beyond stakeholder expectations.',
        'Handoff between phases creates potential for knowledge loss and rework.',
        'Early phases may require scope adjustments impacting later deliverables.'
      ],
      [
        'Hybrid integration complexity increases testing and validation effort.',
        'Legacy system dependencies may limit new technology capabilities.',
        'Technical debt from bridging old and new systems requires ongoing maintenance.'
      ],
      [
        'Vendor lock-in reduces flexibility for future changes and negotiations.',
        'External team coordination overhead impacts delivery velocity.',
        'Quality control challenges when work is distributed across organizations.'
      ],
      [
        'Aggressive timeline may compromise solution quality and testing coverage.',
        'Resource ramp-up time delays initial productivity and momentum.',
        'Stakeholder expectations misalignment leads to scope disputes.'
      ],
      [
        'Technology maturity risks if relying on emerging tools or frameworks.',
        'Skills gap in team requires training investment before productive work.',
        'Infrastructure provisioning delays block development progress.'
      ],
    ];

    final map = <String, List<String>>{};
    for (int i = 0; i < solutions.length; i++) {
      final s = solutions[i];
      // Assign different risk pools to different solutions
      map[s.title] = genericRiskPools[i % genericRiskPools.length];
    }
    return map;
  }

  // REQUIREMENTS GENERATION
  Future<List<Map<String, String>>> generateRequirementsFromBusinessCase(
      String businessCase) async {
    if (businessCase.trim().isEmpty) throw Exception('Business case is empty');
    if (!OpenAiConfig.isConfigured) throw const OpenAiNotConfiguredException();

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final requirements = await _attemptRequirementsApiCall(businessCase);
        if (requirements.isNotEmpty) return requirements;
      } catch (e) {
        if (attempt < maxRetries - 1) await Future.delayed(retryDelay);
        if (attempt == maxRetries - 1) rethrow;
      }
    }
    throw Exception('OpenAI returned no requirements');
  }

  Future<List<Map<String, String>>> _attemptRequirementsApiCall(
      String businessCase) async {
    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.7,
      'max_tokens': 2000,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a business analyst expert. Generate project requirements from business cases. Each requirement should be clear, specific, and categorized by type. Always return strict JSON that matches the required schema.'
        },
        {'role': 'user', 'content': _requirementsPrompt(businessCase)},
      ],
    });

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 429) {
      throw Exception('API quota exceeded. Please check your OpenAI billing.');
    }
    if (response.statusCode == 401) {
      throw Exception('Invalid API key. Please check your OpenAI API key.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'OpenAI API error ${response.statusCode}: ${response.body}');
    }

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final content =
        (data['choices'] as List).first['message']['content'] as String;
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final items = (parsed['requirements'] as List? ?? [])
        .map((e) {
          final item = e as Map<String, dynamic>;
          return {
            'requirement':
                _stripAsterisks((item['requirement'] ?? '').toString().trim()),
            'requirementType': _stripAsterisks((item['requirementType'] ??
                    item['requirement_type'] ??
                    'Functional')
                .toString()
                .trim()),
          };
        })
        .where((e) => e['requirement']!.isNotEmpty)
        .toList();

    // Limit to 20 requirements as specified
    return items.take(20).toList();
  }

  // Fallback requirements removed. OpenAI failures should surface to the UI.

  // TECHNOLOGIES
  Future<Map<String, List<String>>> generateTechnologiesForSolutions(
      List<AiSolutionItem> solutions,
      {String contextNotes = ''}) async {
    if (solutions.isEmpty) return {};
    if (!OpenAiConfig.isConfigured) throw const OpenAiNotConfiguredException();

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.5,
      'max_tokens': 1200,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an infrastructure architect. For each solution, list ONLY physical infrastructure items needed (servers, cabling, hardware, routers, switches, physical storage, network equipment). EXCLUDE cloud services, software, frameworks, or virtual-only solutions. Focus on tangible, physical hardware and infrastructure components. Be detailed and specific: do not use "etc.", "and similar", or vague groupings. State each item explicitly. Return strict JSON only.'
        },
        {
          'role': 'user',
          'content': _technologiesPrompt(solutions, contextNotes)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      final List list = (parsed['technologies'] as List? ?? []);
      final Map<String, List<String>> result = {};
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final title = _stripAsterisks((map['solution'] ?? '').toString());
        final items = (map['items'] as List? ?? [])
            .map((e) => _stripAsterisks(e.toString()))
            .where((e) => e.trim().isNotEmpty)
            // Filter out cloud/software-only references
            .where((e) => _isPhysicalInfrastructure(e))
            .take(6)
            .toList();
        if (title.isNotEmpty && items.isNotEmpty) result[title] = items;
      }
      return _mergeWithFallbackTech(solutions, result);
    } catch (e) {
      rethrow;
    }
  }

  // Backwards-compatibility alias for any older calls with a typo
  Future<Map<String, List<String>>> generateTechnolofiesForSolutions(
          List<AiSolutionItem> solutions,
          {String contextNotes = ''}) =>
      generateTechnologiesForSolutions(solutions, contextNotes: contextNotes);

  Map<String, List<String>> _mergeWithFallbackTech(
      List<AiSolutionItem> solutions, Map<String, List<String>> generated) {
    final merged = <String, List<String>>{};
    for (final s in solutions) {
      final g = generated[s.title];
      merged[s.title] =
          (g != null && g.isNotEmpty) ? g.take(6).toList() : <String>[];
    }
    return merged;
  }

  // COST BREAKDOWN
  Future<Map<String, List<AiCostItem>>> generateCostBreakdownForSolutions(
    List<AiSolutionItem> solutions, {
    String contextNotes = '',
    String currency = 'USD',
  }) async {
    if (solutions.isEmpty) return {};
    if (!OpenAiConfig.isConfigured) return _fallbackCostBreakdown(solutions);

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.5,
      'max_tokens': 1400,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a cost analyst. For each solution, produce a detailed cost breakdown: 8–20 project items with description, estimated cost ('
                  '$currency), expected ROI% and NPV values for 3, 5, and 10-year horizons (same currency). Use realistic but round numbers. Be detailed and specific: do not use "etc.", "and similar", or vague groupings. State each cost item explicitly. Return strict JSON only.'
        },
        {
          'role': 'user',
          'content': _costBreakdownPrompt(solutions, contextNotes, currency)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 14));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      final List list = (parsed['cost_breakdown'] as List? ?? []);
      final Map<String, List<AiCostItem>> result = {};
      for (final entry in list) {
        final map = entry as Map<String, dynamic>;
        final title = _stripAsterisks((map['solution'] ?? '').toString());
        final itemsRaw = (map['items'] as List? ?? []);
        final items = itemsRaw
            .map((e) => AiCostItem.fromMap(e as Map<String, dynamic>))
            .where((e) => e.item.isNotEmpty)
            .toList();
        if (title.isNotEmpty && items.isNotEmpty) result[title] = items;
      }
      return _mergeWithFallbackCost(solutions, result);
    } catch (e) {
      print('generateCostBreakdownForSolutions failed: $e');
      return _fallbackCostBreakdown(solutions);
    }
  }

  Map<String, List<AiCostItem>> _mergeWithFallbackCost(
      List<AiSolutionItem> solutions, Map<String, List<AiCostItem>> generated) {
    final fallback = _fallbackCostBreakdown(solutions);
    final merged = <String, List<AiCostItem>>{};
    for (final s in solutions) {
      final g = generated[s.title];
      merged[s.title] = (g != null && g.isNotEmpty)
          ? g.take(5).toList()
          : (fallback[s.title] ?? []);
    }
    return merged;
  }

  Map<String, List<AiCostItem>> _fallbackCostBreakdown(
      List<AiSolutionItem> solutions) {
    final map = <String, List<AiCostItem>>{};
    for (final s in solutions) {
      map[s.title] = [
        AiCostItem(
          item: 'Discovery & Planning',
          description: 'Workshops, requirements, roadmap and governance setup',
          estimatedCost: 25000,
          roiPercent: 12,
          npvByYear: const {3: 6000, 5: 8000, 10: 14000},
        ),
        AiCostItem(
          item: 'MVP Build',
          description: 'Design, engineering, testing for initial release',
          estimatedCost: 120000,
          roiPercent: 22,
          npvByYear: const {3: 18000, 5: 24000, 10: 42000},
        ),
        AiCostItem(
          item: 'Integration & Data',
          description: 'APIs, data migration, and quality checks',
          estimatedCost: 45000,
          roiPercent: 15,
          npvByYear: const {3: 7000, 5: 9000, 10: 16000},
        ),
      ];
    }
    return map;
  }

  String _costBreakdownPrompt(
      List<AiSolutionItem> solutions, String notes, String currency) {
    final list = solutions
        .map((s) =>
            '{"title": "${_escape(s.title)}", "description": "${_escape(s.description)}"}')
        .join(',');
    return '''
 For each solution below, provide a cost breakdown with up to 20 items (aim for 12–20 when possible). For each item include: item (name), description, estimated_cost (number in $currency), roi_percent (number), npv_by_years (object with keys "3_years", "5_years", "10_years" and numeric values in $currency). Be detailed and specific: do not use "etc.", "and similar", or vague groupings. State each cost item explicitly.

Return ONLY valid JSON with this exact structure:
{
  "cost_breakdown": [
    {"solution": "Solution Name", "items": [
      {"item": "Project Item", "description": "...", "estimated_cost": 12345, "roi_percent": 18.5, "npv_by_years": {"3_years": 5600, "5_years": 7800, "10_years": 12800}}
    ]}
  ]
}

Solutions: [$list]

Context notes (optional): $notes
''';
  }

  Future<AiProjectValueInsights> generateProjectValueInsights(
    List<AiSolutionItem> solutions, {
    String contextNotes = '',
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return _fallbackProjectValueInsights(solutions);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.4,
      'max_tokens': 900,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a financial analyst helping to prepare a cost-benefit analysis. Provide a clear project value estimate and articulate specific business benefits across financial gains, efficiencies, regulatory compliance, process improvements, and brand impact. Return strict JSON only.'
        },
        {
          'role': 'user',
          'content': _projectValuePrompt(solutions, contextNotes)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final valueMap =
          (parsed['project_value'] ?? parsed) as Map<String, dynamic>;
      return AiProjectValueInsights.fromMap(valueMap);
    } catch (e) {
      print('generateProjectValueInsights failed: $e');
      return _fallbackProjectValueInsights(solutions);
    }
  }

  AiProjectValueInsights _fallbackProjectValueInsights(
      List<AiSolutionItem> solutions) {
    final firstSolution =
        solutions.isNotEmpty ? solutions.first.title : 'Proposed initiative';
    return AiProjectValueInsights(
      estimatedProjectValue: 185000,
      benefits: {
        'financial_gains':
            'Projected incremental revenue of 8-12% within the first year of launch.',
        'operational_efficiencies':
            'Automates manual reconciliation and reduces processing time by an estimated 35%.',
        'regulatory_compliance':
            'Strengthens audit trails and positions the initiative for upcoming regulatory milestones.',
        'process_improvements':
            'Streamlines cross-team workflows tied to $firstSolution delivery.',
        'brand_image':
            'Signals innovation leadership and improves partner confidence in programme execution.',
      },
    );
  }

  Future<List<BenefitLineItemInput>> generateBenefitLineItems({
    required List<AiSolutionItem> solutions,
    required double estimatedProjectValue,
    String contextNotes = '',
    String currency = 'USD',
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return _fallbackBenefitLineItems(estimatedProjectValue, currency);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.4,
      'max_tokens': 1200,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a financial analyst creating detailed benefit line items for cost-benefit analysis. Generate realistic numeric values (unit_value and units) that sum to approximately the estimated project value. Return ONLY a JSON object with a "benefit_line_items" array.'
        },
        {
          'role': 'user',
          'content': _benefitLineItemsPrompt(
              solutions, estimatedProjectValue, contextNotes, currency)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final itemsRaw = parsed['benefit_line_items'] ?? parsed['items'] ?? [];
      if (itemsRaw is! List) {
        return _fallbackBenefitLineItems(estimatedProjectValue, currency);
      }
      final items = <BenefitLineItemInput>[];
      for (final item in itemsRaw) {
        if (item is Map<String, dynamic>) {
          final category =
              (item['category'] ?? item['category_key'] ?? 'other').toString();
          final title = _stripAsterisks(
              (item['title'] ?? item['name'] ?? '').toString().trim());
          final unitValue =
              _parseDouble(item['unit_value'] ?? item['unitValue'] ?? 0);
          final units = _parseDouble(item['units'] ?? item['quantity'] ?? 0);
          final notes = _stripAsterisks(
              (item['notes'] ?? item['description'] ?? '').toString().trim());
          if (title.isNotEmpty && unitValue > 0 && units > 0) {
            items.add(BenefitLineItemInput(
              category: category,
              title: title,
              unitValue: unitValue,
              units: units,
              notes: notes,
            ));
          }
        }
      }
      return items.isNotEmpty
          ? items
          : _fallbackBenefitLineItems(estimatedProjectValue, currency);
    } catch (e) {
      print('generateBenefitLineItems failed: $e');
      return _fallbackBenefitLineItems(estimatedProjectValue, currency);
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final s = value.toString().replaceAll(',', '').replaceAll('%', '').trim();
    return double.tryParse(s) ?? 0;
  }

  String _benefitLineItemsPrompt(
    List<AiSolutionItem> solutions,
    double estimatedProjectValue,
    String contextNotes,
    String currency,
  ) {
    final list = solutions
        .map((s) =>
            '{"title": "${_escape(s.title)}", "description": "${_escape(s.description)}"}')
        .join(',');
    return '''
We are creating detailed benefit line items for a cost-benefit analysis. The estimated total project value is ${estimatedProjectValue.toStringAsFixed(0)} $currency.

Generate 4-8 benefit line items with realistic numeric values. Each item should have:
- category: one of revenue, cost_saving, ops_efficiency, productivity, regulatory_compliance, process_improvement, brand_image, stakeholder_commitment, or other
- title: a clear, specific benefit description (e.g., "Reduced manual processing time", "Increased customer retention")
- unit_value: numeric value per unit in $currency (e.g., 5000, 12000.50)
- units: quantity/number of units (e.g., 10, 25.5, 100)
- notes: optional brief explanation

The total of (unit_value × units) for all items should approximately equal ${estimatedProjectValue.toStringAsFixed(0)} $currency.

Return ONLY valid JSON with this exact structure:
{
  "benefit_line_items": [
    {
      "category": "revenue",
      "title": "Increased monthly subscription revenue",
      "unit_value": 5000,
      "units": 12,
      "notes": "Monthly recurring revenue increase"
    },
    {
      "category": "ops_efficiency",
      "title": "Reduced manual processing hours",
      "unit_value": 50,
      "units": 200,
      "notes": "Time savings per month"
    }
  ]
}

Solutions: [$list]

Context notes (optional): ${contextNotes.isEmpty ? 'None provided' : contextNotes}
''';
  }

  List<BenefitLineItemInput> _fallbackBenefitLineItems(
      double estimatedProjectValue, String currency) {
    // Distribute the estimated value across realistic benefit line items
    final items = <BenefitLineItemInput>[];
    final valuePerItem = estimatedProjectValue / 5; // 5 items

    items.add(BenefitLineItemInput(
      category: 'revenue',
      title: 'Increased monthly revenue',
      unitValue: valuePerItem * 0.4,
      units: 12,
      notes: 'Monthly recurring revenue increase over 12 months',
    ));

    items.add(BenefitLineItemInput(
      category: 'ops_efficiency',
      title: 'Reduced operational costs',
      unitValue: valuePerItem * 0.3,
      units: 10,
      notes: 'Cost savings from automation',
    ));

    items.add(BenefitLineItemInput(
      category: 'productivity',
      title: 'Time savings per employee',
      unitValue: valuePerItem * 0.15,
      units: 50,
      notes: 'Hours saved per employee per month',
    ));

    items.add(BenefitLineItemInput(
      category: 'cost_saving',
      title: 'Avoided compliance penalties',
      unitValue: valuePerItem * 0.1,
      units: 1,
      notes: 'One-time penalty avoidance',
    ));

    items.add(BenefitLineItemInput(
      category: 'process_improvement',
      title: 'Streamlined workflow efficiency',
      unitValue: valuePerItem * 0.05,
      units: 20,
      notes: 'Process improvement gains',
    ));

    return items;
  }

  String _projectValuePrompt(List<AiSolutionItem> solutions, String notes) {
    final list = solutions
        .map((s) =>
            '{"title": "${_escape(s.title)}", "description": "${_escape(s.description)}"}')
        .join(',');
    return '''
We are preparing a project cost-benefit analysis. Provide a JSON object with the estimated overall project value (numeric) and detailed notes for five benefit categories: financial_gains, operational_efficiencies, regulatory_compliance, process_improvements, brand_image. Keep each benefit under 20 words and actionable. If you need context, use the optional notes.

Return ONLY valid JSON with this exact structure:
{
  "project_value": {
    "estimated_value": 123456,
    "benefits": {
      "financial_gains": "...",
      "operational_efficiencies": "...",
      "regulatory_compliance": "...",
      "process_improvements": "...",
      "brand_image": "..."
    }
  }
}

Solutions: [$list]

Context notes (optional): $notes
''';
  }

  Future<List<AiBenefitSavingsSuggestion>> generateBenefitSavingsSuggestions(
    List<BenefitLineItemInput> items, {
    String currency = 'USD',
    double? savingsTargetPercent,
    String contextNotes = '',
  }) async {
    if (items.isEmpty) return [];
    if (!OpenAiConfig.isConfigured) {
      return _fallbackSavingsSuggestions(items, currency: currency);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.4,
      'max_tokens': 1200,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a finance analyst who identifies savings levers based on structured benefit line items. Always output a JSON object with a "savings_scenarios" array. Each scenario requires: lever, recommendation, projected_savings (number), timeframe, confidence, rationale.'
        },
        {
          'role': 'user',
          'content': _benefitSavingsPrompt(
              items, currency, savingsTargetPercent, contextNotes),
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 14));
      if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your OpenAI API key.');
      }
      if (response.statusCode == 429) {
        throw Exception(
            'API quota exceeded. Please check your OpenAI billing.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }

      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final scenarios = (parsed['savings_scenarios'] as List? ?? [])
          .map((e) => AiBenefitSavingsSuggestion.fromMap(
              (e ?? {}) as Map<String, dynamic>))
          .where((e) => e.lever.isNotEmpty)
          .toList();
      if (scenarios.isEmpty) {
        return _fallbackSavingsSuggestions(items, currency: currency);
      }
      return scenarios;
    } catch (e) {
      print('generateBenefitSavingsSuggestions failed: $e');
      return _fallbackSavingsSuggestions(items, currency: currency);
    }
  }

  String _benefitSavingsPrompt(
    List<BenefitLineItemInput> items,
    String currency,
    double? savingsTargetPercent,
    String contextNotes,
  ) {
    final target = savingsTargetPercent != null && savingsTargetPercent > 0
        ? 'Aim for at least ${savingsTargetPercent.toStringAsFixed(1)}% savings against total monetised benefits.'
        : 'If no explicit savings target is provided, surface high-impact opportunities.';
    final payload = jsonEncode(items.map((e) => e.toJson()).toList());
    final notes = contextNotes.trim().isEmpty
        ? 'No additional context supplied.'
        : contextNotes.trim();
    return '''
These are the financial benefit line items currently modelled (currency: $currency):
$payload

$target
Respond with 2-4 concise savings scenarios that resemble spreadsheet-style levers (unit cost, volume, timing). Use numeric projected_savings values in $currency.
Extra notes for context: $notes

Remember: Return ONLY a JSON object with key "savings_scenarios".
''';
  }

  List<AiBenefitSavingsSuggestion> _fallbackSavingsSuggestions(
    List<BenefitLineItemInput> items, {
    required String currency,
  }) {
    if (items.isEmpty) return [];
    final sorted = List<BenefitLineItemInput>.from(items)
      ..sort((a, b) => b.total.compareTo(a.total));
    final total = sorted.fold<double>(0, (sum, item) => sum + item.total);

    double cappedSavings(double value) => value.isFinite ? value : 0;

    final suggestions = <AiBenefitSavingsSuggestion>[];
    final top = sorted.first;
    suggestions.add(AiBenefitSavingsSuggestion(
      lever: 'Negotiate ${top.title}',
      recommendation:
          'Target a 10% reduction on unit value through vendor negotiations and alternative sourcing.',
      projectedSavings: cappedSavings(top.total * 0.1),
      timeframe: 'Next quarter',
      confidence: 'Medium',
      rationale:
          'Largest monetised benefit in ${top.category}; small rate improvements yield immediate savings.',
    ));

    if (sorted.length > 1) {
      final runnerUp = sorted[1];
      suggestions.add(AiBenefitSavingsSuggestion(
        lever: 'Volume discipline for ${runnerUp.title}',
        recommendation:
            'Reduce consumption by 5% via tighter controls and usage analytics.',
        projectedSavings: cappedSavings(runnerUp.total * 0.05),
        timeframe: '6 months',
        confidence: 'Medium',
        rationale:
            'Second-largest line item where volume adjustments protect realised benefits.',
      ));
    }

    suggestions.add(AiBenefitSavingsSuggestion(
      lever: 'Benefit realisation governance',
      recommendation:
          'Embed monthly finance checkpoints to prevent benefit leakage across all categories.',
      projectedSavings: cappedSavings(total * 0.05),
      timeframe: '12 months',
      confidence: 'Medium',
      rationale:
          'Routine oversight across the full benefit base (~$currency ${total.toStringAsFixed(0)}) typically safeguards at least 5% of value.',
    ));

    return suggestions;
  }

  // Removed fallback technology suggestions; API must provide technologies or return an error.

  // INFRASTRUCTURE
  Future<Map<String, List<String>>> generateInfrastructureForSolutions(
      List<AiSolutionItem> solutions,
      {String contextNotes = ''}) async {
    if (solutions.isEmpty) return {};
    if (!OpenAiConfig.isConfigured) return _fallbackInfrastructure(solutions);

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.5,
      'max_tokens': 1200,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a cloud and infrastructure architect. For each solution, list the major infrastructure considerations required to operate it reliably and securely (e.g., environments, networking, security, observability, scaling, data, resiliency). Be detailed and specific: do not use "etc.", "and similar", or vague groupings. State each item explicitly. Return strict JSON only.'
        },
        {
          'role': 'user',
          'content': _infrastructurePrompt(solutions, contextNotes)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      final List list = (parsed['infrastructure'] as List? ?? []);
      final Map<String, List<String>> result = {};
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final title = (map['solution'] ?? '').toString();
        final items = (map['items'] as List? ?? [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .take(8)
            .toList();
        if (title.isNotEmpty && items.isNotEmpty) result[title] = items;
      }
      return _mergeWithFallbackInfra(solutions, result);
    } catch (e) {
      print('generateInfrastructureForSolutions failed: $e');
      return _fallbackInfrastructure(solutions);
    }
  }

  Map<String, List<String>> _mergeWithFallbackInfra(
      List<AiSolutionItem> solutions, Map<String, List<String>> generated) {
    final fallback = _fallbackInfrastructure(solutions);
    final merged = <String, List<String>>{};
    for (final s in solutions) {
      final g = generated[s.title];
      merged[s.title] = (g != null && g.isNotEmpty)
          ? g.take(8).toList()
          : (fallback[s.title] ?? []);
    }
    return merged;
  }

  Map<String, List<String>> _fallbackInfrastructure(
      List<AiSolutionItem> solutions) {
    final map = <String, List<String>>{};
    // Provide distinct-but-reasonable infrastructure lists per solution (avoid identical outputs).
    const pools = <List<String>>[
      [
        'Production environments (dev/test/stage/prod) with CI/CD promotion',
        'Networking: segmented subnets, ingress/egress controls, load balancing',
        'Identity & access: SSO + RBAC with least privilege reviews',
        'Secrets management with rotation and audit trails',
        'Encrypted data storage with backup policy (RPO/RTO defined)',
        'Observability: logs, metrics, traces, alerting and dashboards',
        'Scalability: autoscaling rules and capacity planning baselines',
        'Resilience: multi-zone deployment and documented failover runbooks',
      ],
      [
        'Dedicated environments with automated deployments and rollback strategy',
        'API gateway / reverse proxy with WAF and rate limiting',
        'Private networking with secure connectivity to on-prem / partners',
        'Centralized identity provider and privileged access workflows',
        'Data integration layer with secure queues/topics and retry policies',
        'Monitoring for SLOs: uptime, latency, error budgets, alert routing',
        'Performance testing infrastructure and caching strategy',
        'Disaster recovery plan with periodic restore testing',
      ],
      [
        'Hardened baseline images and configuration management standards',
        'Network segmentation for sensitive components and data flows',
        'Endpoint and service-to-service encryption (mTLS where needed)',
        'Key management (KMS/KeyVault) and certificate lifecycle process',
        'Audit logging and retention aligned to compliance requirements',
        'Data lifecycle controls: retention, archival, deletion workflows',
        'High availability with redundancy for critical services',
        'Operational runbooks and incident response escalation paths',
      ],
      [
        'Compute sizing for expected throughput and peak load scenarios',
        'Storage performance tiering (IOPS/latency) for core datasets',
        'Batch/ETL scheduling infrastructure (jobs, orchestration, retries)',
        'Role-based access boundaries and admin separation of duties',
        'Secure remote access for operations with session recording',
        'Cost governance: tagging, budgets, alerts, and usage reporting',
        'Service health dashboards and automated anomaly detection',
        'Resilience testing cadence (chaos / failover exercises)',
      ],
      [
        'Edge delivery where needed (CDN) and static asset optimization',
        'DNS strategy and TLS termination with certificate automation',
        'Load testing harness and production-like staging environment',
        'Data replication strategy for geo / multi-site requirements',
        'Backup encryption, immutable backups, and restore SLAs',
        'Centralized logging with searchable retention policies',
        'Security scanning pipeline (SAST/DAST/dependency) integrated into CI',
        'Governance: change control approvals and deployment audit trail',
      ],
    ];

    for (int i = 0; i < solutions.length; i++) {
      final s = solutions[i];
      map[s.title] = pools[i % pools.length];
    }
    return map;
  }

  String _infrastructurePrompt(List<AiSolutionItem> solutions, String notes) {
    // Handle empty solutions by using project context from notes
    String list = '';
    if (solutions.isNotEmpty) {
      list = solutions
          .map((s) =>
              '{"title": "${_escape(s.title)}", "description": "${_escape(s.description)}"}')
          .join(',');
    } else if (notes.isNotEmpty) {
      // If no solutions but we have project context, create a placeholder
      list = '{"title": "Project", "description": "${_escape(notes)}"}';
    }

    return '''
For each solution below, list ONLY physical infrastructure considerations required to support it - things that can be physically touched or installed.

CRITICAL REQUIREMENTS:
- ONLY include physical infrastructure: servers, cabling, hardware, routers, switches, physical storage devices, network equipment, data center components, cooling systems, power units, UPS systems, physical racks
- EXCLUDE: cloud services (AWS, Azure, GCP), software frameworks, virtual-only solutions, SaaS platforms, APIs, databases (unless referring to physical database servers), containers, or any intangible components
- Focus exclusively on tangible hardware and physical infrastructure components that can be physically installed
- Each solution must have DIFFERENT and UNIQUE physical infrastructure recommendations tailored to its specific requirements

IMPORTANT: Write clear, complete sentences. Each item should be a full, understandable statement (e.g., "Physical rack-mounted servers with redundant power supplies" not just "Servers"). Keep each item between 8-20 words and make it actionable and specific.
IMPORTANT: Tailor items to EACH solution's title/description. Do NOT reuse the exact same list across different solutions.
IMPORTANT: Be detailed and specific. Do not use "etc.", "and similar", or vague groupings. State each item explicitly.

Return ONLY valid JSON with this exact structure:
{
  "infrastructure": [
    {"solution": "Solution Name", "items": ["Complete infrastructure consideration 1", "Complete infrastructure consideration 2", "Complete infrastructure consideration 3"]}
  ]
}

${list.isNotEmpty ? 'Solutions: [$list]' : 'Project Context: $notes'}

Context notes (optional): $notes
''';
  }

  // STAKEHOLDERS
  // Returns a map with 'internal' and 'external' keys, each containing Map<String, List<String>>
  Future<Map<String, Map<String, List<String>>>> generateStakeholdersForSolutions(
      List<AiSolutionItem> solutions,
      {String contextNotes = ''}) async {
    if (solutions.isEmpty) return {'internal': {}, 'external': {}};
    if (!OpenAiConfig.isConfigured) return _fallbackStakeholders(solutions);

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.5,
      'max_tokens': 2000,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a stakeholder analyst. For each solution, separately list INTERNAL stakeholders (employees, departments, teams within the organization) and EXTERNAL stakeholders (regulatory bodies, vendors, government agencies, external partners). Be detailed and specific: do not use "etc.", "and similar", or vague groupings. State each stakeholder explicitly. Return strict JSON only.'
        },
        {
          'role': 'user',
          'content': _stakeholdersPrompt(solutions, contextNotes)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      final Map<String, List<String>> internalResult = {};
      final Map<String, List<String>> externalResult = {};
      
      final List stakeholderList = (parsed['stakeholders'] as List? ?? []);
      for (final item in stakeholderList) {
        final map = item as Map<String, dynamic>;
        final title = (map['solution'] ?? '').toString();
        final internalItems = (map['internal'] as List? ?? [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .take(6)
            .toList();
        final externalItems = (map['external'] as List? ?? [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .take(6)
            .toList();
        if (title.isNotEmpty) {
          if (internalItems.isNotEmpty) internalResult[title] = internalItems;
          if (externalItems.isNotEmpty) externalResult[title] = externalItems;
        }
      }
      return _mergeWithFallbackStakeholders(solutions, internalResult, externalResult);
    } catch (e) {
      print('generateStakeholdersForSolutions failed: $e');
      return _fallbackStakeholders(solutions);
    }
  }

  Map<String, Map<String, List<String>>> _mergeWithFallbackStakeholders(
      List<AiSolutionItem> solutions, 
      Map<String, List<String>> generatedInternal,
      Map<String, List<String>> generatedExternal) {
    final fallback = _fallbackStakeholders(solutions);
    final mergedInternal = <String, List<String>>{};
    final mergedExternal = <String, List<String>>{};
    
    for (final s in solutions) {
      final gInternal = generatedInternal[s.title];
      final gExternal = generatedExternal[s.title];
      mergedInternal[s.title] = (gInternal != null && gInternal.isNotEmpty)
          ? gInternal.take(6).toList()
          : (fallback['internal']![s.title] ?? []);
      mergedExternal[s.title] = (gExternal != null && gExternal.isNotEmpty)
          ? gExternal.take(6).toList()
          : (fallback['external']![s.title] ?? []);
    }
    return {'internal': mergedInternal, 'external': mergedExternal};
  }

  Map<String, Map<String, List<String>>> _fallbackStakeholders(
      List<AiSolutionItem> solutions) {
    // Create distinct pools of stakeholders for variety
    const internalPools = <List<String>>[
      [
        'Project Manager / Program Director',
        'IT Operations Team',
        'Finance & Budget Office',
        'Legal & Compliance Department',
        'Internal Audit',
        'Business Unit Leads',
      ],
      [
        'Executive Sponsor',
        'Operations Manager',
        'Procurement Team',
        'Security & Risk Management',
        'Quality Assurance',
        'Change Management Office',
      ],
      [
        'Technology Lead',
        'Product Owner',
        'Vendor Management',
        'Data Governance Team',
        'Training & Development',
        'Stakeholder Relations',
      ],
      [
        'Chief Technology Officer',
        'Business Analysts',
        'Contract Management',
        'Information Security',
        'Testing & Validation',
        'Communications Team',
      ],
      [
        'Program Office',
        'Technical Architects',
        'Budget & Finance',
        'Legal Counsel',
        'Internal Controls',
        'User Experience Team',
      ],
    ];
    
    const externalPools = <List<String>>[
      [
        'Regulatory authority (industry-specific)',
        'Data protection authority / privacy office',
        'Government procurement or finance oversight',
        'External vendors / systems integrators',
        'End-user representatives / advocacy groups',
        'Industry standards organizations',
      ],
      [
        'Compliance & regulatory bodies',
        'Third-party auditors',
        'External consultants',
        'Vendor partners',
        'Community stakeholders',
        'Trade associations',
      ],
      [
        'Government agencies',
        'Regulatory compliance officers',
        'External service providers',
        'Customer advisory boards',
        'Public interest groups',
        'Industry watchdogs',
      ],
      [
        'Oversight committees',
        'External legal advisors',
        'Managed service providers',
        'User groups',
        'Environmental regulators',
        'Consumer protection agencies',
      ],
      [
        'International regulatory bodies',
        'Certification organizations',
        'Outsourced IT services',
        'Public stakeholders',
        'Media & communications',
        'Independent evaluators',
      ],
    ];
    
    final internalMap = <String, List<String>>{};
    final externalMap = <String, List<String>>{};
    
    for (int i = 0; i < solutions.length; i++) {
      final s = solutions[i];
      internalMap[s.title] = internalPools[i % internalPools.length];
      externalMap[s.title] = externalPools[i % externalPools.length];
    }
    
    return {'internal': internalMap, 'external': externalMap};
  }

  String _stakeholdersPrompt(List<AiSolutionItem> solutions, String notes) {
    // Handle empty solutions by using project context from notes
    String list = '';
    if (solutions.isNotEmpty) {
      list = solutions
          .map((s) =>
              '{"title": "${_escape(s.title)}", "description": "${_escape(s.description)}"}')
          .join(',');
    } else if (notes.isNotEmpty) {
      // If no solutions but we have project context, create a placeholder
      list = '{"title": "Project", "description": "${_escape(notes)}"}';
    }

    return '''
For each solution below, separately identify INTERNAL stakeholders (employees, departments, teams within your organization) and EXTERNAL stakeholders (regulatory bodies, vendors, government agencies, external partners, community groups). 

IMPORTANT: Tailor stakeholders to EACH solution's specific title and description. Do NOT reuse the exact same list across different solutions. Keep each item under 12 words.
IMPORTANT: Be detailed and specific. Do not use "etc.", "and similar", or vague groupings. State each stakeholder explicitly.

Return ONLY valid JSON with this exact structure:
{
  "stakeholders": [
    {
      "solution": "Solution Name",
      "internal": ["Internal Stakeholder 1", "Internal Stakeholder 2"],
      "external": ["External Stakeholder 1", "External Stakeholder 2"]
    }
  ]
}

${list.isNotEmpty ? 'Solutions: [$list]' : 'Project Context: $notes'}

Context notes (optional): $notes
''';
  }

  // Helpers
  List<AiSolutionItem> _normalizeSolutions(List<AiSolutionItem> items) {
    final List<AiSolutionItem> normalized = [];
    // Take up to 5 items from API response
    for (var i = 0; i < items.length && normalized.length < 5; i++) {
      normalized.add(items[i]);
    }
    // Ensure we always return exactly 5 solutions for consistency
    while (normalized.length < 5) {
      normalized.add(AiSolutionItem(
        title: 'Solution Option ${normalized.length + 1}',
        description:
            'A comprehensive approach to address the project requirements, considering feasibility, resources, and expected outcomes.',
      ));
    }
    return normalized;
  }

  String _solutionsPrompt(String businessCase) => '''
Generate exactly 5 concrete solution options for this business case. Each solution should be practical, achievable, and directly address the project needs.

Return ONLY valid JSON in this exact structure:
{
  "solutions": [
    {"title": "Solution Name", "description": "Brief description of approach, benefits, and key considerations"}
  ]
}

Project Context:
$businessCase
''';

  String _requirementsPrompt(String businessCase) => '''
Based on this project context, generate 10-20 specific project requirements that must be met for the project to be considered successful.

Each requirement should be:
- Clear and specific
- Measurable or verifiable
- Properly categorized by type (Functional, Non-Functional, Technical, Business, or Regulatory)

Return ONLY valid JSON in this exact structure:
{
  "requirements": [
    {
      "requirement": "Specific requirement statement",
      "requirementType": "Functional|Non-Functional|Technical|Business|Regulatory"
    }
  ]
}

Business Case:
$businessCase
''';

  String _risksPrompt(List<AiSolutionItem> solutions, String notes) {
    final list = solutions
        .map((s) =>
            '{"title": "${_escape(s.title)}", "description": "${_escape(s.description)}"}')
        .join(',');
    return '''
IMPORTANT: Generate UNIQUE and DIFFERENT risks for EACH solution. Each solution has its own specific characteristics, so the risks should be tailored to that particular solution's approach, technology, and implementation strategy.

Do NOT repeat the same generic risks across solutions. Consider:
- The specific implementation approach of each solution
- Technical challenges unique to that solution
- Resource and skill requirements specific to that approach
- Integration challenges particular to that solution's architecture
- Timeline and budget risks specific to that solution's scope

Given these potential solutions, provide three distinct, solution-specific delivery risks for each. Keep each risk under 22 words, actionable and specific to that particular solution. Be detailed and specific: do not use "etc.", "and similar", or vague groupings. State each risk explicitly.

Return ONLY valid JSON with this exact structure:
{
  "risks": [
    {"solution": "Solution Name", "items": ["Unique Risk 1 specific to this solution", "Unique Risk 2 specific to this solution", "Unique Risk 3 specific to this solution"]}
  ]
}

Solutions: [$list]

Context notes (optional): $notes
''';
  }

  /// Generate risk suggestions for a single risk field using KAZ AI
  Future<List<String>> generateSingleRiskSuggestions({
    required String solutionTitle,
    required int riskNumber,
    required List<String> existingRisks,
    required String contextNotes,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return _fallbackSingleRiskSuggestions(solutionTitle, riskNumber);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };

    final existingRisksText = existingRisks.isEmpty
        ? 'None yet'
        : existingRisks.map((r) => '- $r').join('\n');

    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.7,
      'max_tokens': 600,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a risk analyst helping identify project delivery risks. Generate unique, specific risks that are different from any already identified. Return strict JSON only.'
        },
        {
          'role': 'user',
          'content': '''
Generate 3 unique risk suggestions for Risk #$riskNumber of the solution: "$solutionTitle"

Already identified risks for this solution (DO NOT repeat these):
$existingRisksText

Context notes: ${contextNotes.isEmpty ? 'None provided' : contextNotes}

Return ONLY valid JSON with this exact structure:
{
  "suggestions": ["Risk suggestion 1", "Risk suggestion 2", "Risk suggestion 3"]
}

Make each suggestion:
- Specific to this solution's approach
- Different from the existing risks
- Actionable and under 25 words
- Focus on delivery, technical, resource, or timeline risks
'''
        }
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('OpenAI error ${response.statusCode}');
      }

      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      final suggestions = (parsed['suggestions'] as List? ?? [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();

      return suggestions.isEmpty
          ? _fallbackSingleRiskSuggestions(solutionTitle, riskNumber)
          : suggestions;
    } catch (e) {
      print('generateSingleRiskSuggestions failed: $e');
      return _fallbackSingleRiskSuggestions(solutionTitle, riskNumber);
    }
  }

  List<String> _fallbackSingleRiskSuggestions(
      String solutionTitle, int riskNumber) {
    final allFallbacks = [
      'Resource availability may impact timeline due to competing project priorities.',
      'Technical integration complexity could lead to unexpected delays and cost overruns.',
      'Stakeholder alignment challenges may slow decision-making and approval processes.',
      'Vendor dependency creates risk if external deliverables are delayed or below quality.',
      'Scope creep from evolving requirements could impact budget and schedule.',
      'Knowledge transfer gaps may affect team productivity during implementation.',
      'Data migration complexity could introduce quality issues and extend timelines.',
      'Change management resistance may slow user adoption and reduce expected benefits.',
      'Infrastructure scaling requirements may exceed initial capacity planning estimates.',
    ];

    // Return different fallbacks based on risk number to avoid duplicates
    final startIdx = (riskNumber - 1) * 3;
    return [
      allFallbacks[startIdx % allFallbacks.length],
      allFallbacks[(startIdx + 1) % allFallbacks.length],
      allFallbacks[(startIdx + 2) % allFallbacks.length],
    ];
  }

  String _projectFrameworkPrompt(String context) {
    final escaped = _escape(context);
    return '''
Determine the best overall project framework (Waterfall, Agile, or Hybrid) and generate three distinct project goals aligned with that framework. Each goal should include a brief description (max 40 words) and may optionally specify the preferred framework if Hybrid is chosen.

Return ONLY valid JSON in this exact structure:
{
  "framework": "Waterfall|Agile|Hybrid",
  "goals": [
    {
      "name": "Goal 1",
      "description": "Concise description",
      "framework": "Optional: Waterfall|Agile|Hybrid"
    }
  ]
}

Project Context:
"""
$escaped
"""
''';
  }

  Future<String> generateSsherPlanSummary({
    required String context,
    int maxTokens = 450,
    double temperature = 0.45,
  }) async {
    final trimmedContext = context.trim();
    if (trimmedContext.isEmpty) return '';
    if (!OpenAiConfig.isConfigured) {
      return _fallbackSsherSummary(trimmedContext);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };

    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an SSHER strategist. Craft a concise summary (120-180 words) that highlights the safety, security, health, environment, and regulatory priorities tied to the provided context. Always return ONLY valid JSON matching the requested schema.'
        },
        {
          'role': 'user',
          'content': _ssherSummaryPrompt(trimmedContext),
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>? ?? [];
      if (choices.isNotEmpty) {
        final firstMessage =
            choices.first['message'] as Map<String, dynamic>? ?? {};
        final content = (firstMessage['content'] as String?)?.trim() ?? '';
        final parsed = _decodeJsonSafely(content);
        final summary = parsed != null
            ? (parsed['summary'] ?? parsed['text'] ?? '').toString().trim()
            : '';
        if (summary.isNotEmpty) return summary;
      }
    } catch (e) {
      print('generateSsherPlanSummary failed: $e');
    }

    return _fallbackSsherSummary(trimmedContext);
  }

  Future<List<SsherEntry>> generateSsherEntries({
    required String context,
    int itemsPerCategory = 2,
    int maxTokens = 900,
    double temperature = 0.5,
  }) async {
    final trimmedContext = context.trim();
    if (trimmedContext.isEmpty) return [];
    if (!OpenAiConfig.isConfigured) {
      return _fallbackSsherEntries(trimmedContext, itemsPerCategory);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };

    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an SSHER strategist. Generate concise, realistic table entries for safety, security, health, environment, and regulatory risks. Always return ONLY valid JSON matching the requested schema.'
        },
        {
          'role': 'user',
          'content': _ssherEntriesPrompt(trimmedContext, itemsPerCategory),
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>? ?? [];
      if (choices.isNotEmpty) {
        final firstMessage =
            choices.first['message'] as Map<String, dynamic>? ?? {};
        final content = (firstMessage['content'] as String?)?.trim() ?? '';
        final parsed = _decodeJsonSafely(content);
        if (parsed != null) {
          final entries = _parseSsherEntries(parsed, itemsPerCategory);
          if (entries.isNotEmpty) return entries;
        }
      }
    } catch (e) {
      print('generateSsherEntries failed: $e');
    }

    return _fallbackSsherEntries(trimmedContext, itemsPerCategory);
  }

  Future<Map<String, List<Map<String, dynamic>>>> generateLaunchPhaseEntries({
    required String context,
    required Map<String, String> sections,
    int itemsPerSection = 2,
    int maxTokens = 900,
    double temperature = 0.5,
  }) async {
    final trimmedContext = context.trim();
    if (trimmedContext.isEmpty) return {};
    if (!OpenAiConfig.isConfigured) {
      return _fallbackLaunchEntries(trimmedContext, sections, itemsPerSection);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}',
    };

    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a launch-phase analyst. Generate concise, realistic table entries for each section key provided. Always return ONLY valid JSON matching the requested schema.'
        },
        {
          'role': 'user',
          'content': _launchPhaseEntriesPrompt(
              trimmedContext, sections, itemsPerSection),
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>? ?? [];
      if (choices.isNotEmpty) {
        final firstMessage =
            choices.first['message'] as Map<String, dynamic>? ?? {};
        final content = (firstMessage['content'] as String?)?.trim() ?? '';
        final parsed = _decodeJsonSafely(content);
        if (parsed != null) {
          final entries =
              _parseLaunchPhaseEntries(parsed, sections, itemsPerSection);
          if (entries.isNotEmpty) return entries;
        }
      }
    } catch (e) {
      print('generateLaunchPhaseEntries failed: $e');
    }

    return _fallbackLaunchEntries(trimmedContext, sections, itemsPerSection);
  }

  String _ssherSummaryPrompt(String context) {
    final escaped = _escape(context);
    return '''
 Using the project inputs below, write a single coherent SSHER summary (120-180 words) that highlights safety, security, health, environment, and regulatory priorities while tying the language directly to the context.

 Return ONLY valid JSON with this exact structure:
 {
   "summary": "Concise SSHER plan summary text goes here."
 }

 Project context:
 """
 $escaped
 """
 ''';
  }

  String _fallbackSsherSummary(String context) {
    final lines = context
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .take(5)
        .join(' ');
    return lines.isEmpty
        ? 'SSHER plan is in progress.'
        : 'SSHER plan summary: $lines';
  }

  String _ssherEntriesPrompt(String context, int itemsPerCategory) {
    final escaped = _escape(context);
    return '''
Using the project inputs below, generate $itemsPerCategory entries for each category (safety, security, health, environment, regulatory).
Each entry must be realistic and grounded in the project context.

Return ONLY valid JSON with this exact structure:
{
  "entries": [
    {
      "category": "safety|security|health|environment|regulatory",
      "department": "Department name",
      "teamMember": "Role or owner",
      "concern": "Short, specific concern",
      "riskLevel": "Low|Medium|High",
      "mitigation": "Short, specific mitigation action"
    }
  ]
}

Project context:
"""
$escaped
"""
''';
  }

  String _launchPhaseEntriesPrompt(
      String context, Map<String, String> sections, int itemsPerSection) {
    final escaped = _escape(context);
    final sectionJson = sections.entries
        .map((entry) => '"${entry.key}": "${_escape(entry.value)}"')
        .join(',\n  ');
    return '''
Using the project inputs below, generate $itemsPerSection entries for each section key in the sections map.
Each entry must include a concise title, optional details, and optional status.

Return ONLY valid JSON with this exact structure:
{
  "sections": {
    "section_key": [
      {
        "title": "Short item title",
        "details": "Supporting details",
        "status": "Optional status"
      }
    ]
  }
}

Sections:
{
  $sectionJson
}

Project context:
"""
$escaped
"""
''';
  }

  List<SsherEntry> _parseSsherEntries(
      Map<String, dynamic> parsed, int itemsPerCategory) {
    final entriesRaw = parsed['entries'] ??
        parsed['items'] ??
        parsed['rows'] ??
        parsed['data'];
    final counts = <String, int>{};
    final entries = <SsherEntry>[];

    void addEntry(String categoryKey, Map<String, dynamic> item) {
      final category = _normalizeSsherCategory(categoryKey);
      if (category.isEmpty) return;
      final count = counts[category] ?? 0;
      if (count >= itemsPerCategory) return;
      final department = (item['department'] ?? '').toString().trim();
      final teamMember =
          (item['teamMember'] ?? item['owner'] ?? item['lead'] ?? '')
              .toString()
              .trim();
      final concern = (item['concern'] ?? item['issue'] ?? item['risk'] ?? '')
          .toString()
          .trim();
      final riskLevel = _normalizeRiskLevel(
          (item['riskLevel'] ?? item['risk_level'] ?? '').toString().trim());
      final mitigation =
          (item['mitigation'] ?? item['response'] ?? item['action'] ?? '')
              .toString()
              .trim();
      if (department.isEmpty || concern.isEmpty) return;
      entries.add(SsherEntry(
        category: category,
        department: department,
        teamMember: teamMember.isEmpty ? 'Owner' : teamMember,
        concern: concern,
        riskLevel: riskLevel,
        mitigation:
            mitigation.isEmpty ? 'Mitigation plan in progress.' : mitigation,
      ));
      counts[category] = count + 1;
    }

    if (entriesRaw is List) {
      for (final item in entriesRaw) {
        if (item is Map<String, dynamic>) {
          final category = (item['category'] ?? '').toString();
          addEntry(category, item);
        }
      }
    } else if (entriesRaw is Map) {
      for (final entry in entriesRaw.entries) {
        final category = entry.key.toString();
        final value = entry.value;
        if (value is List) {
          for (final item in value) {
            if (item is Map<String, dynamic>) {
              addEntry(category, item);
            }
          }
        }
      }
    }

    return entries;
  }

  Map<String, List<Map<String, dynamic>>> _parseLaunchPhaseEntries(
    Map<String, dynamic> parsed,
    Map<String, String> sections,
    int itemsPerSection,
  ) {
    final sectionsRaw = parsed['sections'] ?? parsed['data'] ?? parsed['items'];
    if (sectionsRaw is! Map) return {};

    final result = <String, List<Map<String, dynamic>>>{};
    for (final entry in sections.entries) {
      result[entry.key] = [];
    }

    for (final entry in sectionsRaw.entries) {
      final key = entry.key.toString();
      if (!result.containsKey(key)) continue;
      final value = entry.value;
      if (value is List) {
        for (final item in value) {
          if (result[key]!.length >= itemsPerSection) break;
          if (item is Map) {
            final mapped = Map<String, dynamic>.from(item);
            final title =
                (mapped['title'] ?? mapped['item'] ?? '').toString().trim();
            if (title.isEmpty) continue;
            result[key]!.add({
              'title': title,
              'details': (mapped['details'] ?? mapped['description'] ?? '')
                  .toString()
                  .trim(),
              'status': (mapped['status'] ?? '').toString().trim(),
            });
          }
        }
      }
    }

    result.removeWhere((key, value) => value.isEmpty);
    return result;
  }

  Map<String, List<Map<String, dynamic>>> _fallbackLaunchEntries(
    String context,
    Map<String, String> sections,
    int itemsPerSection,
  ) {
    final projectName = _extractProjectName(context);
    final assetName = projectName.isEmpty ? 'the project' : projectName;
    final result = <String, List<Map<String, dynamic>>>{};

    for (final entry in sections.entries) {
      final key = entry.key;
      final items = _fallbackLaunchEntriesForSection(key, assetName)
          .take(itemsPerSection)
          .toList();
      if (items.isNotEmpty) {
        result[key] = items;
      }
    }

    return result;
  }

  List<Map<String, dynamic>> _fallbackLaunchEntriesForSection(
      String key, String assetName) {
    switch (key) {
      case 'viability_checks':
        return [
          {
            'title': 'Revalidate value drivers for $assetName',
            'details':
                'Confirm the core business case assumptions still hold against current demand.',
            'status': 'In review',
          },
          {
            'title': 'Validate revenue model alignment',
            'details':
                'Check pricing and adoption signals against target segments.',
            'status': 'On track',
          },
        ];
      case 'financial_signals':
        return [
          {
            'title': 'Unit economics trend',
            'details':
                'Track margin per transaction and cost-to-serve against baseline.',
            'status': 'Monitor',
          },
          {
            'title': 'Demand velocity',
            'details': 'Compare weekly usage against forecasted ramp.',
            'status': 'At risk',
          },
        ];
      case 'decisions':
        return [
          {
            'title': 'Go / Grow decision checkpoint',
            'details': 'Proceed with scaled rollout once metrics stabilize.',
            'status': 'Go',
          },
          {
            'title': 'Risk mitigation action',
            'details': 'Pause expansion if cost-to-serve exceeds threshold.',
            'status': 'Guardrail',
          },
        ];
      case 'account_health':
        return [
          {
            'title': 'Launch readiness',
            'details': 'Delivery completed with minor open items.',
            'status': 'Healthy',
          },
          {
            'title': 'Stakeholder alignment',
            'details': 'Weekly cadence in place with sponsors and operations.',
            'status': 'Stable',
          },
        ];
      case 'highlights':
        return [
          {
            'title': 'Key milestone delivered',
            'details': 'Core platform capability delivered on schedule.',
            'status': '',
          },
          {
            'title': 'Strong cross-team collaboration',
            'details': 'Product and engineering aligned on release criteria.',
            'status': '',
          },
        ];
      case 'delivery_risks':
        return [
          {
            'title': 'Support coverage risk',
            'details': 'Ops coverage still staffing for night shifts.',
            'status': 'At risk',
          },
          {
            'title': 'Vendor dependency',
            'details': 'Third-party SLA review pending.',
            'status': 'In review',
          },
        ];
      case 'next_90_days':
        return [
          {
            'title': 'Post-launch optimization',
            'details': 'Stabilize latency and monitor user feedback.',
            'status': 'Planned',
          },
          {
            'title': 'Expand reporting',
            'details': 'Deliver weekly performance dashboards to sponsors.',
            'status': 'Planned',
          },
        ];
      case 'vendor_snapshot':
        return [
          {
            'title': 'Active vendor close-out items',
            'details': 'Finalize remaining invoices and service confirmations.',
            'status': 'In progress',
          },
          {
            'title': 'Access revocation status',
            'details': 'Remove unused vendor credentials by close-out date.',
            'status': 'Scheduled',
          },
        ];
      case 'guided_steps':
        return [
          {
            'title': 'Confirm deliverables received',
            'details': 'Validate all contract deliverables are archived.',
            'status': 'In review',
          },
          {
            'title': 'Close vendor accounts',
            'details': 'Execute termination checklist with procurement.',
            'status': 'Planned',
          },
        ];
      case 'vendors_attention':
        return [
          {
            'title': 'Payment reconciliation',
            'details': 'Resolve outstanding invoice with key vendor.',
            'status': 'At risk',
          },
          {
            'title': 'Compliance documentation',
            'details': 'Collect final compliance certificates.',
            'status': 'Pending',
          },
        ];
      case 'access_signoff':
        return [
          {
            'title': 'Ops sign-off',
            'details': 'Confirm access removal and handover completion.',
            'status': 'Pending',
          },
          {
            'title': 'Security approval',
            'details': 'Verify all vendor access audit logs are archived.',
            'status': 'In review',
          },
        ];
      case 'schedule_gaps':
        return [
          {
            'title': 'Milestone slip on core integration',
            'details':
                'Integration testing pushed by 1 sprint due to dependency delays.',
            'status': 'Investigate',
          },
          {
            'title': 'UAT readiness variance',
            'details': 'User acceptance testing started later than planned.',
            'status': 'In progress',
          },
        ];
      case 'cost_gaps':
        return [
          {
            'title': 'Cloud spend over baseline',
            'details': 'Compute usage exceeded forecast during load testing.',
            'status': 'At risk',
          },
          {
            'title': 'Vendor cost variance',
            'details': 'Support contract extension added unplanned cost.',
            'status': 'Review',
          },
        ];
      case 'scope_gaps':
        return [
          {
            'title': 'Deferred analytics dashboard',
            'details': 'Advanced reporting moved to post-launch release.',
            'status': 'Deferred',
          },
          {
            'title': 'Quality remediation',
            'details': 'Additional QA cycles added for critical workflows.',
            'status': 'In progress',
          },
        ];
      case 'benefits_causes':
        return [
          {
            'title': 'Efficiency gains behind forecast',
            'details': 'Operational throughput improved but below target.',
            'status': 'Monitor',
          },
          {
            'title': 'Root cause: integration rework',
            'details': 'Rework required due to upstream API changes.',
            'status': 'Identified',
          },
        ];
      case 'team_ramp_down':
        return [
          {
            'title': 'Release core engineers',
            'details': 'Transition ownership to ops team after stabilization.',
            'status': 'Planned',
          },
          {
            'title': 'Reassign QA support',
            'details': 'Move QA resources to next program after close-out.',
            'status': 'Scheduled',
          },
        ];
      case 'knowledge_transfer':
        return [
          {
            'title': 'Ops runbook walkthrough',
            'details': 'Finalize handover session with support leads.',
            'status': 'Planned',
          },
          {
            'title': 'Architecture deep-dive',
            'details': 'Record system overview for future maintenance.',
            'status': 'Scheduled',
          },
        ];
      case 'vendor_offboarding':
        return [
          {
            'title': 'Revoke vendor access',
            'details': 'Remove all third-party credentials post-contract.',
            'status': 'Pending',
          },
          {
            'title': 'Close vendor obligations',
            'details': 'Confirm deliverables and archive documentation.',
            'status': 'In progress',
          },
        ];
      case 'communications':
        return [
          {
            'title': 'Stakeholder update',
            'details': 'Communicate close-out timeline to business owners.',
            'status': '',
          },
          {
            'title': 'Support FAQ refresh',
            'details': 'Publish knowledge base updates for impacted users.',
            'status': '',
          },
        ];
      case 'impact_assessment':
        return [
          {
            'title': 'Schedule',
            'details':
                'Critical path recovery improved after scope reprioritization.',
            'status': 'Medium | Improving',
          },
          {
            'title': 'Cost',
            'details': 'Budget variance stabilized after vendor renegotiation.',
            'status': 'Low | Stable',
          },
          {
            'title': 'Quality',
            'details': 'Regression suite still pending final validation.',
            'status': 'Medium | Needs attention',
          },
        ];
      case 'reconciliation_workflow':
        return [
          {
            'title': 'Discovery',
            'details': 'Gap interviews and system scans captured.',
            'status': 'Complete',
          },
          {
            'title': 'Mitigation backlog',
            'details': 'Actions scheduled with delivery squads.',
            'status': 'In progress',
          },
          {
            'title': 'Validation & sign-off',
            'details': 'Stakeholder review targeted this week.',
            'status': 'Upcoming',
          },
        ];
      case 'lessons_learned':
        return [
          {
            'title': 'Align ops readiness early to avoid late scope drift.',
            'details': '',
            'status': '',
          },
          {
            'title': 'Validate vendor dependencies against launch timelines.',
            'details': '',
            'status': '',
          },
          {
            'title': 'Track adoption metrics weekly for early signals.',
            'details': '',
            'status': '',
          },
        ];
      case 'close_out_checklist':
        return [
          {
            'title': 'Finalize close-out documentation',
            'details': 'Compile acceptance notes, metrics, and closure report.',
            'status': 'In progress',
          },
          {
            'title': 'Confirm stakeholder sign-off',
            'details': 'Collect final approvals from sponsors and operations.',
            'status': 'Pending',
          },
        ];
      case 'approvals_signoff':
        return [
          {
            'title': 'Executive sponsor approval',
            'details': 'Sign-off on project outcomes and benefits.',
            'status': 'Pending',
          },
          {
            'title': 'Operations acceptance',
            'details': 'Ops lead confirms handover readiness.',
            'status': 'In review',
          },
        ];
      case 'archive_access':
        return [
          {
            'title': 'Archive project artifacts',
            'details': 'Store final deliverables and contracts in repository.',
            'status': '',
          },
          {
            'title': 'Revoke elevated access',
            'details': 'Remove temporary permissions and vendor credentials.',
            'status': '',
          },
        ];
      case 'transition_steps':
        return [
          {
            'title': 'Finalize production readiness checklist',
            'details': 'Confirm monitoring, alerting, and rollback plans.',
            'status': 'In review',
          },
          {
            'title': 'Run handover walkthrough',
            'details': 'Ops team reviews runbooks and escalation paths.',
            'status': 'Scheduled',
          },
        ];
      case 'handover_artifacts':
        return [
          {
            'title': 'Operational runbook',
            'details': 'Document SOPs, on-call playbooks, and recovery steps.',
            'status': '',
          },
          {
            'title': 'Service dashboard',
            'details': 'Share KPIs and health monitoring links.',
            'status': '',
          },
        ];
      case 'signoffs':
        return [
          {
            'title': 'Ops lead approval',
            'details': 'Ops confirms readiness for production handover.',
            'status': 'Pending',
          },
          {
            'title': 'Security sign-off',
            'details': 'Security review completed for production release.',
            'status': 'In review',
          },
        ];
      case 'closeout_summary':
        return [
          {
            'title': 'Close-out summary metric',
            'details': 'Track key close-out KPIs and status.',
            'status': 'On track',
          },
          {
            'title': 'Final deliverables status',
            'details': 'All required outputs verified and archived.',
            'status': 'Complete',
          },
        ];
      case 'closeout_steps':
        return [
          {
            'title': 'Complete contract checklist',
            'details': 'Verify obligations and handover evidence.',
            'status': 'In progress',
          },
          {
            'title': 'Confirm invoice reconciliation',
            'details': 'Finance validates final billing with vendors.',
            'status': 'Pending',
          },
        ];
      case 'contracts_attention':
        return [
          {
            'title': 'Outstanding vendor deliverable',
            'details': 'Awaiting final documentation from vendor.',
            'status': 'At risk',
          },
          {
            'title': 'SLA reconciliation',
            'details': 'Confirm SLA credits before closure.',
            'status': 'In review',
          },
        ];
      case 'closeout_signoff':
        return [
          {
            'title': 'Finance approval',
            'details': 'Finance validates final spend and closes ledger.',
            'status': 'Pending',
          },
          {
            'title': 'Compliance approval',
            'details': 'Compliance confirms regulatory close-out steps.',
            'status': 'Planned',
          },
        ];
      case 'closure_summary':
        return [
          {
            'title': 'Delivery status',
            'details': 'All launch deliverables completed.',
            'status': 'Complete',
          },
          {
            'title': 'Post-launch metrics',
            'details': 'Stability and adoption tracked for 2 weeks.',
            'status': 'Monitoring',
          },
        ];
      case 'scope_acceptance':
        return [
          {
            'title': 'Scope acceptance',
            'details': 'Stakeholders accept final scope outcomes.',
            'status': 'Approved',
          },
          {
            'title': 'Open scope items',
            'details': 'Minor backlog moved to next release.',
            'status': 'Deferred',
          },
        ];
      case 'risks_followups':
        return [
          {
            'title': 'Operational follow-up',
            'details': 'Monitor incidents during hypercare window.',
            'status': 'Planned',
          },
          {
            'title': 'Support readiness',
            'details': 'Ensure 24/7 coverage for first month.',
            'status': 'In progress',
          },
        ];
      case 'final_checklist':
        return [
          {
            'title': 'Archive project artifacts',
            'details': 'Ensure all documentation is stored.',
            'status': 'Pending',
          },
          {
            'title': 'Finalize stakeholder report',
            'details': 'Send closure summary to sponsors.',
            'status': 'Planned',
          },
        ];
      case 'contract_quotes':
        return [
          {
            'title': 'Build-ready engineering vendor',
            'details':
                'Structural engineering and inspection coverage for $assetName.',
            'status': '\$120,000 - \$150,000',
          },
          {
            'title': 'Systems integration partner',
            'details': 'Integration of platform services and delivery tooling.',
            'status': '\$60,000 - \$80,000',
          },
        ];
      case 'contract_overview':
        return [
          {
            'title': 'Published Date',
            'details': 'Aug 12, 2025',
            'status': '',
          },
          {
            'title': 'Submission Deadline',
            'details': 'Sep 5, 2025 (5:00 PM)',
            'status': 'Deadline',
          },
        ];
      case 'contract_description':
        return [
          {
            'title': 'Project Overview',
            'details':
                'Define vendor responsibilities, delivery timelines, and acceptance criteria tied to $assetName.',
            'status': '',
          },
        ];
      case 'scope_items':
        return [
          {
            'title': 'Define contracting scope and deliverables.',
            'details': '',
            'status': '',
          },
          {
            'title': 'Confirm service levels and escalation paths.',
            'details': '',
            'status': '',
          },
        ];
      case 'contract_documents':
        return [
          {
            'title': 'Scope of Work',
            'details': 'PDF, 2.4 MB',
            'status': 'PDF',
          },
          {
            'title': 'Technical Specifications',
            'details': 'DOCX, 1.1 MB',
            'status': 'DOCX',
          },
        ];
      case 'bidder_information':
        return [
          {
            'title': 'Eligibility',
            'details':
                'Vendors must meet compliance and certification requirements.',
            'status': '',
          },
          {
            'title': 'Evaluation Criteria',
            'details':
                'Weighted scoring across technical fit, delivery plan, and cost.',
            'status': '',
          },
        ];
      case 'contact_details':
        return [
          {
            'title': 'Procurement Lead',
            'details': 'Procurement Officer',
            'status': 'procurement@company.com',
          },
        ];
      case 'prebid_meeting':
        return [
          {
            'title': 'Sep 1, 2025',
            'details': '10:00 AM',
            'status': 'Virtual meeting link to follow.',
          },
        ];
      case 'contract_timeline':
        return [
          {
            'title': 'Award approvals',
            'details': 'Finalize vendor approvals and contract signatures.',
            'status': 'In progress',
          },
          {
            'title': 'Delivery readiness',
            'details': 'Ensure contract deliverables are on track.',
            'status': 'Planned',
          },
        ];
      case 'contract_status_summary':
        return [
          {
            'title': 'Average Bid Value',
            'details': '\$1,250,000',
            'status': '',
          },
          {
            'title': 'Total Contractors',
            'details': '4',
            'status': '',
          },
          {
            'title': 'Milestone Progress',
            'details': '2/4 Complete',
            'status': '',
          },
          {
            'title': 'Status',
            'details': 'Bid Evaluation',
            'status': '',
          },
        ];
      case 'contract_recent_activity':
        return [
          {
            'title': 'Vendor shortlist updated',
            'details': 'Aug 21, 2025',
            'status': '',
          },
          {
            'title': 'Bid clarifications requested',
            'details': 'Aug 18, 2025',
            'status': '',
          },
        ];
      case 'contract_milestones':
        return [
          {
            'title': 'Contract awards complete',
            'details': 'Sep 15, 2025',
            'status': 'Complete',
          },
          {
            'title': 'Equipment delivery',
            'details': 'Oct 10, 2025',
            'status': 'In progress',
          },
        ];
      case 'contract_execution_steps':
        return [
          {
            'title': 'Request for Quote (RFQ)',
            'details': 'Distribute RFQ and collect vendor responses.',
            'status': 'Not scheduled',
          },
          {
            'title': 'Review Quotes',
            'details': 'Evaluate proposals and document scoring.',
            'status': 'Pending',
          },
        ];
      case 'contractors_directory':
        return [
          {
            'title': 'BuildTech Engineering',
            'details': 'General Contractor | New York, NY | \$1,250,000',
            'status': 'Under Review',
          },
          {
            'title': 'MetroStructural Solutions',
            'details': 'Structural Engineering | Chicago, IL | \$1,180,000',
            'status': 'Bid Submitted',
          },
        ];
      case 'summary_rows':
        return [
          {
            'title': 'Core services contract',
            'details':
                'Primary vendor | Bidding / Lump Sum | \$750,000 | 120 days',
            'status': 'In progress',
          },
          {
            'title': 'Operations support',
            'details':
                'Support partner | Reimbursable / Monthly | \$180,000 | 90 days',
            'status': 'Planned',
          },
        ];
      case 'budget_impact':
        return [
          {
            'title': 'Original Budget',
            'details': '\$2,000,000',
            'status': '',
          },
          {
            'title': 'Current Estimate',
            'details': '\$1,250,000',
            'status': '',
          },
          {
            'title': 'Variance',
            'details': '\$750,000 (under)',
            'status': '',
          },
        ];
      case 'schedule_impact':
        return [
          {
            'title': 'Project Start',
            'details': 'Sep 1, 2025',
            'status': '',
          },
          {
            'title': 'Contracting Finish',
            'details': 'Dec 15, 2025',
            'status': '',
          },
          {
            'title': 'Total Duration',
            'details': '105 days',
            'status': '',
          },
        ];
      case 'warranty_support':
        return [
          {
            'title': 'Core services contract',
            'details': '12 months | Standard support | support@vendor.com',
            'status': 'View',
          },
        ];
      case 'summary_highlights':
        return [
          {
            'title': 'Contract Summary',
            'details':
                '3 Contracts Planned\n1 Contract In-Progress\n0 Contracts Completed',
            'status': '',
          },
          {
            'title': 'Budget Impact',
            'details':
                '\$1.25M Total Contract Value\nBudget tracking ongoing\nVariance pending',
            'status': '',
          },
        ];
      default:
        return [
          {
            'title': 'Launch action item',
            'details': 'Add details for $assetName.',
            'status': 'Planned',
          },
        ];
    }
  }

  List<SsherEntry> _fallbackSsherEntries(String context, int itemsPerCategory) {
    final projectName = _extractProjectName(context);
    final assetName = projectName.isEmpty ? 'the project' : projectName;
    final templates = <String, List<Map<String, String>>>{
      'safety': [
        {
          'department': 'Operations',
          'teamMember': 'Safety Lead',
          'concern':
              'Inconsistent PPE usage during ${assetName.toLowerCase()} rollout activities.',
          'riskLevel': 'High',
          'mitigation':
              'Enforce PPE checklists and daily toolbox talks across shifts.',
        },
        {
          'department': 'Facilities',
          'teamMember': 'Site Supervisor',
          'concern':
              'Limited emergency egress signage in newly activated zones.',
          'riskLevel': 'Medium',
          'mitigation':
              'Install signage and conduct evacuation drills before go-live.',
        },
      ],
      'security': [
        {
          'department': 'IT Security',
          'teamMember': 'Security Analyst',
          'concern':
              'Incomplete access reviews for vendors supporting ${assetName.toLowerCase()}.',
          'riskLevel': 'High',
          'mitigation':
              'Complete quarterly access audits and enforce least-privilege roles.',
        },
        {
          'department': 'Facilities',
          'teamMember': 'Security Manager',
          'concern': 'Badge access not synchronized with contractor schedules.',
          'riskLevel': 'Medium',
          'mitigation':
              'Align badge provisioning with approved rosters and auto-expire access.',
        },
      ],
      'health': [
        {
          'department': 'HR',
          'teamMember': 'Wellness Coordinator',
          'concern':
              'Shift fatigue risk during the ${assetName.toLowerCase()} launch window.',
          'riskLevel': 'Medium',
          'mitigation': 'Introduce rotation plans and mandatory rest breaks.',
        },
        {
          'department': 'Operations',
          'teamMember': 'Ops Manager',
          'concern': 'Ergonomic strain reported at staging workstations.',
          'riskLevel': 'Low',
          'mitigation':
              'Provide adjustable workstations and ergonomics training.',
        },
      ],
      'environment': [
        {
          'department': 'Sustainability',
          'teamMember': 'Environmental Lead',
          'concern':
              'Waste segregation compliance gaps during ${assetName.toLowerCase()} prep.',
          'riskLevel': 'Medium',
          'mitigation':
              'Deploy labeled bins and weekly compliance inspections.',
        },
        {
          'department': 'Operations',
          'teamMember': 'Facilities Lead',
          'concern': 'Energy spikes expected from temporary equipment usage.',
          'riskLevel': 'Low',
          'mitigation':
              'Schedule equipment use off-peak and track energy KPIs.',
        },
      ],
      'regulatory': [
        {
          'department': 'Compliance',
          'teamMember': 'Compliance Officer',
          'concern':
              'Incomplete documentation for regulatory reporting milestones.',
          'riskLevel': 'High',
          'mitigation':
              'Complete audit trail and align reporting calendar with regulators.',
        },
        {
          'department': 'Legal',
          'teamMember': 'Regulatory Counsel',
          'concern':
              'Pending review of new policy changes impacting ${assetName.toLowerCase()}.',
          'riskLevel': 'Medium',
          'mitigation':
              'Validate policy updates and secure sign-off before launch.',
        },
      ],
    };

    final entries = <SsherEntry>[];
    for (final entry in templates.entries) {
      final category = entry.key;
      for (final item in entry.value.take(itemsPerCategory)) {
        entries.add(SsherEntry(
          category: category,
          department: item['department'] ?? '',
          teamMember: item['teamMember'] ?? 'Owner',
          concern: item['concern'] ?? '',
          riskLevel: _normalizeRiskLevel(item['riskLevel'] ?? ''),
          mitigation: item['mitigation'] ?? '',
        ));
      }
    }
    return entries;
  }

  String _normalizeSsherCategory(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('safety')) return 'safety';
    if (normalized.contains('security')) return 'security';
    if (normalized.contains('health')) return 'health';
    if (normalized.contains('environment')) return 'environment';
    if (normalized.contains('regulatory')) return 'regulatory';
    return '';
  }

  String _normalizeRiskLevel(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.startsWith('high')) return 'High';
    if (normalized.startsWith('low')) return 'Low';
    return 'Medium';
  }

  Map<String, dynamic>? _decodeJsonSafely(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;
    try {
      return jsonDecode(trimmed) as Map<String, dynamic>;
    } catch (_) {
      final start = trimmed.indexOf('{');
      final end = trimmed.lastIndexOf('}');
      if (start >= 0 && end > start) {
        try {
          return jsonDecode(trimmed.substring(start, end + 1))
              as Map<String, dynamic>;
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  String _technologiesPrompt(List<AiSolutionItem> solutions, String notes) {
    // Handle empty solutions by using project context from notes
    String list = '';
    if (solutions.isNotEmpty) {
      list = solutions
          .map((s) =>
              '{"title": "${_escape(s.title)}", "description": "${_escape(s.description)}"}')
          .join(',');
    } else if (notes.isNotEmpty) {
      // If no solutions but we have project context, create a placeholder
      list = '{"title": "Project", "description": "${_escape(notes)}"}';
    }

    return '''
For each solution below, list 3-6 physical infrastructure considerations that would be SPECIFICALLY required. 

CRITICAL REQUIREMENTS:
- ONLY include physical infrastructure: servers, cabling, hardware, routers, switches, physical storage devices, network equipment, data center components
- EXCLUDE: cloud services (AWS, Azure, GCP), software frameworks, virtual-only solutions, SaaS platforms, APIs, databases (unless referring to physical database servers)
- Focus on tangible hardware and physical network components
- Each solution must have DIFFERENT and UNIQUE infrastructure recommendations tailored to its specific requirements

Examples of VALID items: "Physical servers (rack-mounted)", "Network cabling (Cat6)", "Hardware routers", "Physical storage arrays", "Network switches", "Data center cooling systems"
Examples of INVALID items: "Cloud hosting", "AWS EC2", "Docker containers", "Kubernetes", "Software-defined networking", "Virtual machines"
Be detailed and specific: do not use "etc.", "and similar", or vague groupings. State each item explicitly.

Return ONLY valid JSON with this exact structure:
{
  "technologies": [
    {"solution": "Solution Name", "items": ["Physical Infrastructure Item 1", "Physical Infrastructure Item 2", "Physical Infrastructure Item 3"]}
  ]
}

${list.isNotEmpty ? 'Solutions: [$list]' : 'Project Context: $notes'}

Context notes (optional): $notes
''';
  }

  // FEP RISKS GENERATION - Generate risks with all fields (Title, Category, Probability, Impact, Mitigation)
  Future<List<Map<String, String>>> generateFepRisks(String context,
      {int? minCount}) async {
    if (context.trim().isEmpty) return [];
    if (!OpenAiConfig.isConfigured) throw const OpenAiNotConfiguredException();

    final targetCount = minCount != null && minCount > 0
        ? minCount.clamp(5, 20) // Generate between 5 and 20 risks
        : 8; // Default to 8 risks

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.6,
      'max_tokens': 2000,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a risk analyst. Generate project risks with Title, Category, Probability (Low/Medium/High), Impact (Low/Medium/High), and a short Mitigation Strategy. Return strict JSON only.'
        },
        {
          'role': 'user',
          'content':
              '''Generate $targetCount project risks based on this context:

$context

Return JSON in this format:
{
  "risks": [
    {
      "title": "Risk title",
      "category": "Technical/Financial/Operational/Schedule/Resource",
      "probability": "Low/Medium/High",
      "impact": "Low/Medium/High",
      "mitigationStrategy": "Short mitigation plan"
    }
  ]
}'''
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30)); // Increased timeout
      if (response.statusCode < 200 || response.statusCode >= 300) {
        // Return fallback instead of throwing
        return _fallbackFepRisks(targetCount);
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final risks = (parsed['risks'] as List? ?? [])
          .map((e) {
            final item = e as Map<String, dynamic>;
            return {
              'title': (item['title'] ?? '').toString().trim(),
              'category': (item['category'] ?? 'Technical').toString().trim(),
              'probability':
                  (item['probability'] ?? 'Medium').toString().trim(),
              'impact': (item['impact'] ?? 'Medium').toString().trim(),
              'mitigationStrategy':
                  (item['mitigationStrategy'] ?? '').toString().trim(),
            };
          })
          .where((r) => r['title']!.isNotEmpty)
          .toList();

      // If we got fewer risks than requested, use fallback to fill the gap
      if (risks.length < targetCount) {
        final fallback = _fallbackFepRisks(targetCount - risks.length);
        risks.addAll(fallback);
      }

      return risks.take(targetCount).toList();
    } catch (e) {
      // Return fallback on any error (timeout, network, parsing, etc.)
      debugPrint('generateFepRisks failed: $e');
      return _fallbackFepRisks(targetCount);
    }
  }

  List<Map<String, String>> _fallbackFepRisks(int count) {
    final fallbackRisks = [
      {
        'title': 'Scope creep leading to timeline delays',
        'category': 'Schedule',
        'probability': 'Medium',
        'impact': 'High',
        'mitigationStrategy':
            'Define scope boundaries early, require change control, and track scope impacts weekly.',
      },
      {
        'title': 'Resource availability constraints',
        'category': 'Resource',
        'probability': 'Medium',
        'impact': 'Medium',
        'mitigationStrategy':
            'Confirm resourcing plan, assign backups, and maintain a rolling 2–4 week staffing forecast.',
      },
      {
        'title': 'Technical integration challenges',
        'category': 'Technical',
        'probability': 'High',
        'impact': 'High',
        'mitigationStrategy':
            'Run early integration spikes, define interface contracts, and schedule staged integration testing.',
      },
      {
        'title': 'Budget overruns due to unforeseen costs',
        'category': 'Financial',
        'probability': 'Medium',
        'impact': 'Medium',
        'mitigationStrategy':
            'Add contingency, validate vendor quotes, and monitor burn rate against milestones.',
      },
      {
        'title': 'Stakeholder alignment and approval delays',
        'category': 'Operational',
        'probability': 'Medium',
        'impact': 'Medium',
        'mitigationStrategy':
            'Set a decision cadence, clarify owners, and pre-align with stakeholders before approvals.',
      },
      {
        'title': 'Data security and compliance requirements',
        'category': 'Technical',
        'probability': 'Low',
        'impact': 'High',
        'mitigationStrategy':
            'Perform security review early, implement least-privilege access, and validate compliance controls.',
      },
      {
        'title': 'Vendor delivery delays',
        'category': 'Schedule',
        'probability': 'Medium',
        'impact': 'Medium',
        'mitigationStrategy':
            'Confirm lead times, include schedule buffers, and establish escalation paths with vendors.',
      },
      {
        'title': 'Change management resistance',
        'category': 'Operational',
        'probability': 'Low',
        'impact': 'Medium',
        'mitigationStrategy':
            'Create a change plan, deliver training, and communicate benefits with stakeholder champions.',
      },
    ];

    // Return requested count, cycling through fallback risks if needed
    final result = <Map<String, String>>[];
    for (int i = 0; i < count; i++) {
      result.add(
          Map<String, String>.from(fallbackRisks[i % fallbackRisks.length]));
    }
    return result;
  }

  // PROCUREMENT - Generate multiple vendors
  Future<List<Map<String, dynamic>>> generateProcurementVendors({
    required String projectName,
    required String solutionTitle,
    String contextNotes = '',
    int count = 5,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return _fallbackProcurementVendors(count);
    }

    final categories = [
      'IT Equipment',
      'Construction Services',
      'Furniture',
      'Security',
      'Logistics',
      'Services',
      'Materials'
    ];
    final vendors = <Map<String, dynamic>>[];

    // Generate vendors for different categories
    final categoriesToGenerate = categories.take(count).toList();

    for (final category in categoriesToGenerate) {
      try {
        final vendor = await generateVendorSuggestion(
          projectName: projectName,
          solutionTitle: solutionTitle,
          category: category,
          contextNotes: contextNotes,
        );
        vendors.add(vendor);
      } catch (e) {
        debugPrint('Failed to generate vendor for $category: $e');
        // Add fallback vendor for this category
        vendors.add(_fallbackVendor(category));
      }
    }

    return vendors;
  }

  List<Map<String, dynamic>> _fallbackProcurementVendors(int count) {
    final categories = [
      'IT Equipment',
      'Construction Services',
      'Furniture',
      'Security',
      'Logistics'
    ];
    return categories
        .take(count)
        .map((category) => _fallbackVendor(category))
        .toList();
  }

  // PROCUREMENT - Generate RFQ workflows
  Future<List<Map<String, dynamic>>> generateProcurementRfqs({
    required String projectName,
    required String solutionTitle,
    String contextNotes = '',
    int count = 3,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return _fallbackProcurementRfqs(count);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.6,
      'max_tokens': 1500,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a procurement specialist. Generate RFQ (Request for Quotation) workflows with title, category, owner, dueDate, invited vendors count, responses count, budget, status, and priority. Return strict JSON only.'
        },
        {
          'role': 'user',
          'content': _rfqGenerationPrompt(
              projectName, solutionTitle, contextNotes, count)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackProcurementRfqs(count);
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final rfqs = (parsed['rfqs'] as List? ?? [])
          .map((e) {
            final item = e as Map<String, dynamic>;
            return {
              'title': _stripAsterisks((item['title'] ?? '').toString().trim()),
              'category': _stripAsterisks(
                  (item['category'] ?? 'IT Equipment').toString().trim()),
              'owner': _stripAsterisks(
                  (item['owner'] ?? 'Procurement Manager').toString().trim()),
              'dueDate': _stripAsterisks(
                  (item['dueDate'] ?? item['due_date'] ?? '')
                      .toString()
                      .trim()),
              'invited': (item['invited'] as num?)?.toInt() ?? 5,
              'responses': (item['responses'] as num?)?.toInt() ?? 3,
              'budget': (item['budget'] as num?)?.toInt() ?? 50000,
              'status': _normalizeRfqStatus(
                  (item['status'] ?? 'draft').toString().trim()),
              'priority': _normalizePriority(
                  (item['priority'] ?? 'medium').toString().trim()),
            };
          })
          .where((r) => r['title']!.toString().isNotEmpty)
          .toList();
      return rfqs.length >= count
          ? rfqs.take(count).toList()
          : [...rfqs, ..._fallbackProcurementRfqs(count - rfqs.length)];
    } catch (e) {
      debugPrint('generateProcurementRfqs failed: $e');
      return _fallbackProcurementRfqs(count);
    }
  }

  String _normalizeRfqStatus(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('draft')) return 'draft';
    if (lower.contains('review')) return 'review';
    if (lower.contains('market')) return 'inMarket';
    if (lower.contains('evaluation') || lower.contains('evaluating'))
      return 'evaluation';
    if (lower.contains('award')) return 'awarded';
    return 'draft';
  }

  String _rfqGenerationPrompt(String projectName, String solutionTitle,
      String contextNotes, int count) {
    final notes = contextNotes.trim().isEmpty
        ? 'No additional context provided.'
        : contextNotes.trim();
    return '''
Generate $count RFQ (Request for Quotation) workflows for this procurement scenario:

Project: $projectName
Solution: $solutionTitle

Context: $notes

Return JSON in this format:
{
  "rfqs": [
    {
      "title": "RFQ title (e.g., Network Infrastructure Equipment)",
      "category": "IT Equipment/Construction Services/Furniture/Security/Logistics/Services/Materials",
      "owner": "Owner name (e.g., Procurement Manager)",
      "dueDate": "YYYY-MM-DD format",
      "invited": 5,
      "responses": 3,
      "budget": 50000,
      "status": "draft/review/inMarket/evaluation/awarded",
      "priority": "critical/high/medium/low"
    }
  ]
}

Return ONLY valid JSON.
''';
  }

  List<Map<String, dynamic>> _fallbackProcurementRfqs(int count) {
    final now = DateTime.now();
    return List.generate(count, (index) {
      final dueDate = now.add(Duration(days: 30 + (index * 15)));
      return {
        'title': [
          'Network Infrastructure Equipment',
          'Office Furniture Set',
          'Security System Installation',
          'Construction Materials',
          'Professional Services'
        ][index % 5],
        'category': [
          'IT Equipment',
          'Furniture',
          'Security',
          'Materials',
          'Services'
        ][index % 5],
        'owner': 'Procurement Manager',
        'dueDate':
            '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
        'invited': 5 + index,
        'responses': 3 + index,
        'budget': 50000 + (index * 25000),
        'status': [
          'draft',
          'review',
          'inMarket',
          'evaluation',
          'awarded'
        ][index % 5],
        'priority': ['high', 'medium', 'critical', 'medium', 'low'][index % 5],
      };
    });
  }

  // PROCUREMENT - Generate Purchase Orders
  Future<List<Map<String, dynamic>>> generateProcurementPurchaseOrders({
    required String projectName,
    required String solutionTitle,
    String contextNotes = '',
    int count = 4,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return _fallbackProcurementPurchaseOrders(count);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.6,
      'max_tokens': 1500,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a procurement specialist. Generate purchase orders with id, vendor, category, owner, orderedDate, expectedDate, amount, progress, and status. Return strict JSON only.'
        },
        {
          'role': 'user',
          'content': _purchaseOrderGenerationPrompt(
              projectName, solutionTitle, contextNotes, count)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackProcurementPurchaseOrders(count);
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final pos = (parsed['purchaseOrders'] as List? ??
              parsed['purchase_orders'] as List? ??
              [])
          .map((e) {
            final item = e as Map<String, dynamic>;
            return {
              'id': _stripAsterisks((item['id'] ??
                      item['po_id'] ??
                      'PO-${DateTime.now().millisecondsSinceEpoch}')
                  .toString()
                  .trim()),
              'vendor': _stripAsterisks(
                  (item['vendor'] ?? item['vendor_name'] ?? '')
                      .toString()
                      .trim()),
              'category': _stripAsterisks(
                  (item['category'] ?? 'IT Equipment').toString().trim()),
              'owner': _stripAsterisks(
                  (item['owner'] ?? 'Procurement Manager').toString().trim()),
              'orderedDate': _stripAsterisks(
                  (item['orderedDate'] ?? item['ordered_date'] ?? '')
                      .toString()
                      .trim()),
              'expectedDate': _stripAsterisks(
                  (item['expectedDate'] ?? item['expected_date'] ?? '')
                      .toString()
                      .trim()),
              'amount': (item['amount'] as num?)?.toInt() ?? 50000,
              'progress': ((item['progress'] as num?)?.toDouble() ?? 0.5)
                  .clamp(0.0, 1.0),
              'status': _normalizePoStatus(
                  (item['status'] ?? 'issued').toString().trim()),
            };
          })
          .where((r) => r['vendor']!.toString().isNotEmpty)
          .toList();
      return pos.length >= count
          ? pos.take(count).toList()
          : [...pos, ..._fallbackProcurementPurchaseOrders(count - pos.length)];
    } catch (e) {
      debugPrint('generateProcurementPurchaseOrders failed: $e');
      return _fallbackProcurementPurchaseOrders(count);
    }
  }

  String _normalizePoStatus(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('approval') || lower.contains('pending'))
      return 'awaitingApproval';
    if (lower.contains('issue')) return 'issued';
    if (lower.contains('transit') || lower.contains('shipping'))
      return 'inTransit';
    if (lower.contains('receive') || lower.contains('delivered'))
      return 'received';
    return 'issued';
  }

  String _purchaseOrderGenerationPrompt(String projectName,
      String solutionTitle, String contextNotes, int count) {
    final notes = contextNotes.trim().isEmpty
        ? 'No additional context provided.'
        : contextNotes.trim();
    return '''
Generate $count purchase orders for this procurement scenario:

Project: $projectName
Solution: $solutionTitle

Context: $notes

Return JSON in this format:
{
  "purchaseOrders": [
    {
      "id": "PO-001",
      "vendor": "Vendor company name",
      "category": "IT Equipment/Construction Services/Furniture/Security/Logistics/Services/Materials",
      "owner": "Owner name",
      "orderedDate": "YYYY-MM-DD",
      "expectedDate": "YYYY-MM-DD",
      "amount": 50000,
      "progress": 0.5,
      "status": "awaitingApproval/issued/inTransit/received"
    }
  ]
}

Return ONLY valid JSON.
''';
  }

  List<Map<String, dynamic>> _fallbackProcurementPurchaseOrders(int count) {
    final now = DateTime.now();
    return List.generate(count, (index) {
      final orderedDate = now.subtract(Duration(days: 10 + (index * 5)));
      final expectedDate = now.add(Duration(days: 20 + (index * 10)));
      return {
        'id': 'PO-${(1000 + index).toString().padLeft(4, '0')}',
        'vendor': [
          'TechCorp Solutions',
          'BuildRight Contractors',
          'Office Essentials Co',
          'SecureGuard Services'
        ][index % 4],
        'category': [
          'IT Equipment',
          'Construction Services',
          'Furniture',
          'Security'
        ][index % 4],
        'owner': 'Procurement Manager',
        'orderedDate':
            '${orderedDate.year}-${orderedDate.month.toString().padLeft(2, '0')}-${orderedDate.day.toString().padLeft(2, '0')}',
        'expectedDate':
            '${expectedDate.year}-${expectedDate.month.toString().padLeft(2, '0')}-${expectedDate.day.toString().padLeft(2, '0')}',
        'amount': 50000 + (index * 25000),
        'progress': [0.3, 0.6, 0.8, 1.0][index % 4],
        'status': [
          'awaitingApproval',
          'issued',
          'inTransit',
          'received'
        ][index % 4],
      };
    });
  }

  // PROCUREMENT - Generate Trackable Items
  Future<List<Map<String, dynamic>>> generateProcurementTrackableItems({
    required String projectName,
    required String solutionTitle,
    String contextNotes = '',
    int count = 3,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return _fallbackProcurementTrackableItems(count);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.6,
      'max_tokens': 1500,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a logistics coordinator. Generate trackable procurement items with name, description, orderStatus, currentStatus, lastUpdate, and events timeline. Return strict JSON only.'
        },
        {
          'role': 'user',
          'content': _trackableItemGenerationPrompt(
              projectName, solutionTitle, contextNotes, count)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackProcurementTrackableItems(count);
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final items =
          (parsed['trackableItems'] as List? ?? parsed['items'] as List? ?? [])
              .map<Map<String, dynamic>>((e) {
                final item = e as Map<String, dynamic>;
                final events = (item['events'] as List? ?? [])
                    .map<Map<String, dynamic>>((ev) {
                      final event = ev as Map<String, dynamic>;
                      return <String, dynamic>{
                        'title': _stripAsterisks(
                            (event['title'] ?? event['description'] ?? '')
                                .toString()
                                .trim()),
                        'date': _stripAsterisks(
                            (event['date'] ?? event['timestamp'] ?? '')
                                .toString()
                                .trim()),
                        'status': _normalizeTrackableStatus(
                            (event['status'] ?? 'inTransit').toString().trim()),
                      };
                    })
                    .where((ev) => ev['title']!.toString().isNotEmpty)
                    .toList();

                return <String, dynamic>{
                  'name': _stripAsterisks(
                      (item['name'] ?? item['title'] ?? '').toString().trim()),
                  'description': _stripAsterisks(
                      (item['description'] ?? '').toString().trim()),
                  'orderStatus': _stripAsterisks(
                      (item['orderStatus'] ?? item['order_status'] ?? 'Ordered')
                          .toString()
                          .trim()),
                  'currentStatus': _normalizeTrackableStatus(
                      (item['currentStatus'] ??
                              item['current_status'] ??
                              'inTransit')
                          .toString()
                          .trim()),
                  'lastUpdate': _stripAsterisks(
                      (item['lastUpdate'] ?? item['last_update'] ?? '')
                          .toString()
                          .trim()),
                  'events': events,
                };
              })
              .where((r) => r['name']!.toString().isNotEmpty)
              .toList();
      return items.length >= count
          ? items.take(count).toList()
          : [
              ...items,
              ..._fallbackProcurementTrackableItems(count - items.length)
            ];
    } catch (e) {
      debugPrint('generateProcurementTrackableItems failed: $e');
      return _fallbackProcurementTrackableItems(count);
    }
  }

  String _normalizeTrackableStatus(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('transit') || lower.contains('shipping'))
      return 'inTransit';
    if (lower.contains('deliver') || lower.contains('received'))
      return 'delivered';
    return 'notTracked';
  }

  String _trackableItemGenerationPrompt(String projectName,
      String solutionTitle, String contextNotes, int count) {
    final notes = contextNotes.trim().isEmpty
        ? 'No additional context provided.'
        : contextNotes.trim();
    return '''
Generate $count trackable procurement items for this project:

Project: $projectName
Solution: $solutionTitle

Context: $notes

Return JSON in this format:
{
  "trackableItems": [
    {
      "name": "Item name (e.g., Network Switches)",
      "description": "Brief description",
      "orderStatus": "Ordered/Processing/Shipped",
      "currentStatus": "inTransit/notTracked/delivered",
      "lastUpdate": "YYYY-MM-DD HH:MM",
      "events": [
        {
          "title": "Event description",
          "date": "YYYY-MM-DD",
          "status": "inTransit/notTracked/delivered"
        }
      ]
    }
  ]
}

Return ONLY valid JSON.
''';
  }

  List<Map<String, dynamic>> _fallbackProcurementTrackableItems(int count) {
    final now = DateTime.now();
    return List.generate(count, (index) {
      final lastUpdate = now.subtract(Duration(days: index));
      return {
        'name': [
          'Network Infrastructure Equipment',
          'Office Furniture Set',
          'Security Cameras'
        ][index % 3],
        'description': 'Procurement item for project delivery',
        'orderStatus': 'Ordered',
        'currentStatus': ['inTransit', 'inTransit', 'delivered'][index % 3],
        'lastUpdate':
            '${lastUpdate.year}-${lastUpdate.month.toString().padLeft(2, '0')}-${lastUpdate.day.toString().padLeft(2, '0')} ${lastUpdate.hour.toString().padLeft(2, '0')}:${lastUpdate.minute.toString().padLeft(2, '0')}',
        'events': [
          {
            'title': 'Order placed',
            'date':
                '${now.subtract(Duration(days: 5 + index)).year}-${(now.subtract(Duration(days: 5 + index)).month).toString().padLeft(2, '0')}-${(now.subtract(Duration(days: 5 + index)).day).toString().padLeft(2, '0')}',
            'status': 'notTracked'
          },
          {
            'title': 'Shipped from warehouse',
            'date':
                '${now.subtract(Duration(days: 3 + index)).year}-${(now.subtract(Duration(days: 3 + index)).month).toString().padLeft(2, '0')}-${(now.subtract(Duration(days: 3 + index)).day).toString().padLeft(2, '0')}',
            'status': 'inTransit'
          },
          if (index == 2)
            {
              'title': 'Delivered',
              'date':
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
              'status': 'delivered'
            },
        ],
      };
    });
  }

  // PROCUREMENT - Generate Reports Data
  List<Map<String, dynamic>> generateProcurementReportsData() {
    // Reports are typically calculated from existing data, but we can provide default KPIs
    return [
      {
        'kpis': [
          {
            'label': 'Total Spend',
            'value': '\$450,000',
            'delta': '+12.5%',
            'positive': false
          },
          {
            'label': 'Active POs',
            'value': '8',
            'delta': '+2',
            'positive': true
          },
          {
            'label': 'Avg Lead Time',
            'value': '18 days',
            'delta': '-3 days',
            'positive': true
          },
          {
            'label': 'On-Time Delivery',
            'value': '87%',
            'delta': '+5%',
            'positive': true
          },
        ],
        'spendBreakdown': [
          {
            'label': 'IT Equipment',
            'amount': 180000,
            'percent': 40.0,
            'color': 0xFF2563EB
          },
          {
            'label': 'Construction',
            'amount': 135000,
            'percent': 30.0,
            'color': 0xFFF97316
          },
          {
            'label': 'Services',
            'amount': 90000,
            'percent': 20.0,
            'color': 0xFF10B981
          },
          {
            'label': 'Other',
            'amount': 45000,
            'percent': 10.0,
            'color': 0xFF64748B
          },
        ],
        'leadTimeMetrics': [
          {'label': 'IT Equipment', 'onTimeRate': 0.85},
          {'label': 'Construction', 'onTimeRate': 0.90},
          {'label': 'Services', 'onTimeRate': 0.92},
        ],
        'savingsOpportunities': [
          {
            'title': 'Consolidate vendor contracts',
            'value': '\$25,000',
            'owner': 'Procurement Manager'
          },
          {
            'title': 'Negotiate volume discounts',
            'value': '\$15,000',
            'owner': 'Category Manager'
          },
        ],
        'complianceMetrics': [
          {'label': 'Contract Compliance', 'value': 0.95},
          {'label': 'Documentation Complete', 'value': 0.88},
        ],
      },
    ];
  }

  String _escape(String v) => v.replaceAll('"', '\\"').replaceAll('\n', ' ');

  // PROCUREMENT - VENDORS
  Future<Map<String, dynamic>> generateVendorSuggestion({
    required String projectName,
    required String solutionTitle,
    required String category,
    String contextNotes = '',
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return _fallbackVendor(category);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.6,
      'max_tokens': 800,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a procurement specialist. Generate realistic vendor suggestions based on project context. Return a JSON object with: name (vendor company name), category (matching the requested category), rating (1-5 integer), approved (boolean), preferred (boolean).'
        },
        {
          'role': 'user',
          'content':
              _vendorPrompt(projectName, solutionTitle, category, contextNotes)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      return {
        'name': _stripAsterisks((parsed['name'] ?? '').toString().trim()),
        'category':
            _stripAsterisks((parsed['category'] ?? category).toString().trim()),
        'rating': (parsed['rating'] is num)
            ? (parsed['rating'] as num).toInt().clamp(1, 5)
            : 4,
        'approved': parsed['approved'] == true,
        'preferred': parsed['preferred'] == false, // Default to false
      };
    } catch (e) {
      debugPrint('generateVendorSuggestion failed: $e');
      return _fallbackVendor(category);
    }
  }

  Map<String, dynamic> _fallbackVendor(String category) {
    final names = {
      'IT Equipment': [
        'TechCorp Solutions',
        'Digital Systems Inc',
        'IT Partners Group'
      ],
      'Construction Services': [
        'BuildRight Contractors',
        'Premier Construction Co',
        'Apex Builders'
      ],
      'Furniture': [
        'Office Essentials Co',
        'Workspace Solutions',
        'Furniture Direct'
      ],
      'Security': [
        'SecureGuard Services',
        'Safety First Systems',
        'Protection Plus'
      ],
      'Logistics': [
        'FastTrack Logistics',
        'Global Shipping Co',
        'Express Delivery'
      ],
      'Services': [
        'Professional Services Group',
        'Expert Consultants',
        'Service Partners'
      ],
      'Materials': [
        'Material Supply Co',
        'Industrial Materials Inc',
        'Supply Chain Solutions'
      ],
    };
    final nameList = names[category] ?? ['Vendor Partner'];
    return {
      'name': nameList[0],
      'category': category,
      'rating': 4,
      'approved': true,
      'preferred': false,
    };
  }

  String _vendorPrompt(String projectName, String solutionTitle,
      String category, String contextNotes) {
    final notes = contextNotes.trim().isEmpty
        ? 'No additional context provided.'
        : contextNotes.trim();
    return '''
Generate a vendor suggestion for this procurement scenario:

Project: $projectName
Solution: $solutionTitle
Category: $category

Context: $notes

Provide a realistic vendor company name that specializes in $category. The vendor should be appropriate for a project involving "$solutionTitle".

Return a JSON object with:
- name: Company name (e.g., "Atlas Tech Supply" or "Premier Construction Co")
- category: "$category"
- rating: Integer 1-5 (typical range 3-5)
- approved: Boolean (typically true)
- preferred: Boolean (typically false unless explicitly noted)

Return ONLY valid JSON.
''';
  }

  // PROCUREMENT - ITEMS
  Future<Map<String, dynamic>> generateProcurementItemSuggestion({
    required String projectName,
    required String solutionTitle,
    required String category,
    String contextNotes = '',
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return _fallbackProcurementItem(category);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.6,
      'max_tokens': 1000,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a procurement specialist. Generate realistic procurement item suggestions. Return JSON with: name (item name), description (brief description), category (matching requested), budget (estimated cost as integer), priority (one of: critical, high, medium, low), estimatedDeliveryDays (days from now as integer, typically 30-180).'
        },
        {
          'role': 'user',
          'content': _procurementItemPrompt(
              projectName, solutionTitle, category, contextNotes)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content =
          (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      final budget =
          (parsed['budget'] is num) ? (parsed['budget'] as num).toInt() : 50000;
      final deliveryDays = (parsed['estimatedDeliveryDays'] is num)
          ? (parsed['estimatedDeliveryDays'] as num).toInt().clamp(7, 365)
          : 90;

      return {
        'name': _stripAsterisks((parsed['name'] ?? '').toString().trim()),
        'description':
            _stripAsterisks((parsed['description'] ?? '').toString().trim()),
        'category':
            _stripAsterisks((parsed['category'] ?? category).toString().trim()),
        'budget': budget,
        'priority': _normalizePriority(
            (parsed['priority'] ?? 'medium').toString().trim()),
        'estimatedDeliveryDays': deliveryDays,
      };
    } catch (e) {
      debugPrint('generateProcurementItemSuggestion failed: $e');
      return _fallbackProcurementItem(category);
    }
  }

  Map<String, dynamic> _fallbackProcurementItem(String category) {
    final items = {
      'IT Equipment': {
        'name': 'Network Infrastructure Equipment',
        'description': 'Core networking hardware and switches',
        'budget': 85000
      },
      'Construction Services': {
        'name': 'Site Preparation Services',
        'description': 'Groundwork and site setup',
        'budget': 120000
      },
      'Furniture': {
        'name': 'Office Furniture Set',
        'description': 'Desks, chairs, and workspace furniture',
        'budget': 45000
      },
      'Security': {
        'name': 'Security System Installation',
        'description': 'Access control and monitoring systems',
        'budget': 65000
      },
      'Logistics': {
        'name': 'Shipping and Delivery Services',
        'description': 'Transportation and logistics coordination',
        'budget': 35000
      },
      'Services': {
        'name': 'Professional Services',
        'description': 'Consulting and implementation services',
        'budget': 95000
      },
      'Materials': {
        'name': 'Construction Materials',
        'description': 'Building materials and supplies',
        'budget': 75000
      },
    };
    final item = items[category] ??
        {
          'name': 'Procurement Item',
          'description': 'Item description',
          'budget': 50000
        };
    return {
      'name': item['name']!,
      'description': item['description']!,
      'category': category,
      'budget': item['budget']!,
      'priority': 'medium',
      'estimatedDeliveryDays': 90,
    };
  }

  String _normalizePriority(String priority) {
    final lower = priority.toLowerCase();
    if (lower.contains('critical')) return 'critical';
    if (lower.contains('high')) return 'high';
    if (lower.contains('low')) return 'low';
    return 'medium';
  }

  String _procurementItemPrompt(String projectName, String solutionTitle,
      String category, String contextNotes) {
    final notes = contextNotes.trim().isEmpty
        ? 'No additional context provided.'
        : contextNotes.trim();
    return '''
Generate a procurement item suggestion for this project:

Project: $projectName
Solution: $solutionTitle
Category: $category

Context: $notes

Provide a realistic procurement item that would be needed for a project involving "$solutionTitle" in the "$category" category.

Return a JSON object with:
- name: Item name (e.g., "Network core switches" or "Office furniture set")
- description: Brief description (1-2 sentences)
- category: "$category"
- budget: Estimated cost as integer (typical range: 20000-200000)
- priority: One of: critical, high, medium, low (typically "medium" or "high")
- estimatedDeliveryDays: Days from now (typical range: 30-180)

Return ONLY valid JSON.
''';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // WBS GENERATION
  // ─────────────────────────────────────────────────────────────────────────────
  
  /// Generates a hierarchical Work Breakdown Structure (WBS) based on project details
  Future<List<WorkItem>> generateWbsStructure({
    required String projectName,
    required String projectObjective,
    required String dimension,
    String contextNotes = '',
  }) async {
    if (!OpenAiConfig.isConfigured) return [];

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': 0.5,
      'max_tokens': 1500,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a project management expert. Generate a hierarchical Work Breakdown Structure (WBS) in strict JSON format. Each item should have a title, description, and optionally children and dependencies.'
        },
        {
          'role': 'user',
          'content': _wbsPrompt(
            projectName: projectName,
            projectObjective: projectObjective,
            dimension: dimension,
            contextNotes: contextNotes,
          )
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 22));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('OpenAI error ${response.statusCode}: ${response.body}');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content = (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final List rawWbs = parsed['wbs'] as List? ?? [];
      
      final items = rawWbs.map((e) => WorkItem.fromJson(e as Map<String, dynamic>)).toList();
      _wireUpWbsTree(items);
      return items;
    } catch (e) {
      debugPrint('Error generating WBS: $e');
      return [];
    }
  }

  void _wireUpWbsTree(List<WorkItem> items, {String parentId = ''}) {
    for (var item in items) {
      item.parentId = parentId;
      if (item.children.isNotEmpty) {
        _wireUpWbsTree(item.children, parentId: item.id);
      }
    }
  }

  String _wbsPrompt({
    required String projectName,
    required String projectObjective,
    required String dimension,
    required String contextNotes,
  }) {
    return '''
Generate a Work Breakdown Structure (WBS) for:
Project: $projectName
Objective: $projectObjective
Segmentation Dimension: $dimension

Requirements:
1. Break the project down into a hierarchical tree structure (2-3 levels deep).
2. Level 1 should be the major phases or segments based on "$dimension".
3. Level 2 and below should be specific deliverables or tasks.
4. Each item MUST have a "title" and "description".
5. Use "children" for sub-items.
6. Use "dependencies" as a list of titles of sibling items that must be completed first.

Return strict JSON only in this format:
{
  "wbs": [
    {
      "title": "Phase 1: Civil Works",
      "description": "Foundation and structural elements",
      "children": [
        {
          "title": "Excavation",
          "description": "Earthmoving and site preparation"
        },
        {
          "title": "Concrete Pouring",
          "description": "Foundation base construction",
          "dependencies": ["Excavation"]
        }
      ]
    }
  ]
}

Additional Context: $contextNotes
''';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // COST ESTIMATE SUGGESTIONS
  // ─────────────────────────────────────────────────────────────────────────────
  
  /// Generates cost estimate item suggestions based on project context
  Future<List<CostEstimateItem>> generateCostEstimateSuggestions({
    required String context,
    int maxTokens = 1200,
    double temperature = 0.6,
  }) async {
    if (!OpenAiConfig.isConfigured) {
      return _fallbackCostEstimateItems(context);
    }

    final uri = OpenAiConfig.chatUri();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${OpenAiConfig.apiKeyValue}'
    };
    final body = jsonEncode({
      'model': OpenAiConfig.model,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': 'You are a project cost estimation expert. Generate realistic cost estimate line items based on project context. Return strict JSON only.'
        },
        {
          'role': 'user',
          'content': _costEstimatePrompt(context)
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 25));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackCostEstimateItems(context);
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final content = (data['choices'] as List).first['message']['content'] as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final List rawItems = parsed['costItems'] as List? ?? parsed['items'] as List? ?? [];
      
      return rawItems.map((e) => CostEstimateItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error generating cost estimates: $e');
      return _fallbackCostEstimateItems(context);
    }
  }

  String _costEstimatePrompt(String context) {
    return '''
Generate 5-8 cost estimate line items for the following project:

$context

Return JSON in this format:
{
  "costItems": [
    {
      "itemName": "Cost item name",
      "description": "Brief description",
      "category": "Labor/Materials/Equipment/Services/Contingency",
      "unitType": "hours/units/lump sum",
      "quantity": 10,
      "unitCost": 150.0,
      "totalCost": 1500.0,
      "notes": "Optional notes"
    }
  ]
}

Return ONLY valid JSON.
''';
  }

  List<CostEstimateItem> _fallbackCostEstimateItems(String context) {
    return [
      CostEstimateItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Project Management',
        notes: 'Project coordination and oversight',
        amount: 20000.0,
        costType: 'labor',
      ),
      CostEstimateItem(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        title: 'Equipment and Materials',
        notes: 'Primary equipment and material costs',
        amount: 50000.0,
        costType: 'direct',
      ),
      CostEstimateItem(
        id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
        title: 'Professional Services',
        notes: 'Consulting and technical expertise',
        amount: 16000.0,
        costType: 'direct',
      ),
      CostEstimateItem(
        id: (DateTime.now().millisecondsSinceEpoch + 3).toString(),
        title: 'Contingency Reserve',
        notes: 'Risk buffer (10% of total)',
        amount: 8600.0,
        costType: 'indirect',
      ),
    ];
  }
}
