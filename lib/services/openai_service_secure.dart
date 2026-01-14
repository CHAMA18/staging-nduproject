import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ndu_project/openai/openai_config.dart';
import 'package:ndu_project/models/project_data_model.dart';

// Remove markdown bold markers commonly produced by the model (e.g. *text* or **text**)
String _stripAsterisks(String s) => s.replaceAll('*', '');

class AiSolutionItem {
  final String title;
  final String description;

  AiSolutionItem({required this.title, required this.description});

  factory AiSolutionItem.fromMap(Map<String, dynamic> map) => AiSolutionItem(
  title: _stripAsterisks((map['title'] ?? '').toString().trim()),
  description: _stripAsterisks((map['description'] ?? '').toString().trim()),
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
    parsedBenefits[entry.key.toString()] = _stripAsterisks(entry.value.toString());
      }
    } else if (benefitsRaw is List) {
      for (final item in benefitsRaw) {
        if (item is Map && item.containsKey('category')) {
      parsedBenefits[item['category'].toString()] =
        _stripAsterisks((item['details'] ?? item['value'] ?? '').toString());
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
    lever: _stripAsterisks(parseString(map['lever'] ?? map['title'] ?? map['scenario'])),
    recommendation: _stripAsterisks(parseString(
      map['recommendation'] ?? map['action'] ?? map['strategy'])),
    projectedSavings: parseDouble(
      map['projected_savings'] ?? map['savings'] ?? map['projected_value']),
    timeframe:
      _stripAsterisks(parseString(map['timeframe'] ?? map['horizon'] ?? map['period'])),
    confidence: _stripAsterisks(parseString(
      map['confidence'] ?? map['certainty'] ?? map['confidence_level'])),
    rationale:
      _stripAsterisks(parseString(map['rationale'] ?? map['notes'] ?? map['summary'])),
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
        return parsed.values.map((v) => _stripAsterisks(v.toString())).join('\n').trim();
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
        throw Exception('OpenAI error ${response.statusCode}: ${response.body}');
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
        return value.map((e) => _stripAsterisks(e.toString().trim())).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    List<DesignDeliverablePipelineItem> parsePipeline(dynamic value) {
      if (value is List) {
        return value.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return DesignDeliverablePipelineItem(
            label: _stripAsterisks((map['label'] ?? '').toString().trim()),
            status: _stripAsterisks((map['status'] ?? '').toString().trim()),
          );
        }).where((item) => item.label.isNotEmpty).toList();
      }
      return const [];
    }

    List<DesignDeliverableRegisterItem> parseRegister(dynamic value) {
      if (value is List) {
        return value.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return DesignDeliverableRegisterItem(
            name: _stripAsterisks((map['name'] ?? '').toString().trim()),
            owner: _stripAsterisks((map['owner'] ?? '').toString().trim()),
            status: _stripAsterisks((map['status'] ?? '').toString().trim()),
            due: _stripAsterisks((map['due'] ?? '').toString().trim()),
            risk: _stripAsterisks((map['risk'] ?? '').toString().trim()),
          );
        }).where((item) => item.name.isNotEmpty).toList();
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
      metrics: const DesignDeliverablesMetrics(active: 6, inReview: 3, approved: 2, atRisk: 1),
      pipeline: const [
        DesignDeliverablePipelineItem(label: 'Discovery & Research', status: 'In Review'),
        DesignDeliverablePipelineItem(label: 'Wireframes', status: 'In Progress'),
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
        DesignDeliverableRegisterItem(name: 'Wireframe Pack', owner: 'UX Team', status: 'In Review', due: 'TBD', risk: 'Medium'),
        DesignDeliverableRegisterItem(name: 'UI Kit', owner: 'Design Ops', status: 'In Progress', due: 'TBD', risk: 'Low'),
        DesignDeliverableRegisterItem(name: 'Prototype', owner: 'Product', status: 'Pending', due: 'TBD', risk: 'High'),
        DesignDeliverableRegisterItem(name: 'Journey Maps', owner: 'Research', status: 'In Progress', due: 'TBD', risk: 'Medium'),
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
    if (trimmed.isEmpty) throw Exception('No context provided');
    if (!OpenAiConfig.isConfigured) throw const OpenAiNotConfiguredException();

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
      final list = (parsed['opportunities'] as List? ?? []);
      final result = <Map<String, String>>[];
      for (final item in list) {
        if (item is! Map) continue;
        final map = item as Map<String, dynamic>;
  final opp = _stripAsterisks((map['opportunity'] ?? map['title'] ?? '').toString().trim());
        if (opp.isEmpty) continue;
        result.add({
          'opportunity': opp,
          'discipline': (map['discipline'] ?? '').toString().trim(),
          'stakeholder':
              (map['stakeholder'] ?? map['owner'] ?? '').toString().trim(),
          'potentialCost1':
              (map['potential_cost_savings'] ?? map['cost_savings'] ?? '')
                  .toString()
                  .trim(),
          'potentialCost2': (map['potential_cost_schedule_savings'] ??
                  map['schedule_savings'] ??
                  '')
              .toString()
              .trim(),
        });
      }
      if (result.isNotEmpty) return result.take(12).toList();
      throw Exception('OpenAI returned no opportunities');
    } catch (e) {
      rethrow;
    }
  }

  String _opportunitiesPrompt(String context) {
    final c = _escape(context);
    return '''
From the project context below, list concrete project opportunities that would benefit the initiative (efficiency, cost, schedule, risk reduction, quality, compliance, etc.).

Return ONLY valid JSON with this exact structure:
{
  "opportunities": [
    {
      "opportunity": "Concise opportunity statement",
      "discipline": "Owning discipline (e.g., IT, Finance, Operations)",
      "stakeholder": "Primary stakeholder / owner",
      "potential_cost_savings": "Numeric or short label (e.g., 25,000)",
      "potential_cost_schedule_savings": "Numeric/short label (e.g., 2 weeks)"
    }
  ]
}

Guidelines:
- Be specific and actionable (no placeholders).
- Use concise text; do not add extra fields.
- 5–12 items is ideal.

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
              'You are a risk analyst. For each provided solution, list three crisp, non-overlapping delivery risks. Return strict JSON only.'
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
            'requirement': _stripAsterisks((item['requirement'] ?? '').toString().trim()),
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
              'You are a solutions architect. For each solution, list 3-6 core technologies, frameworks, services, or tools needed to implement it. Be concrete and vendor-agnostic where reasonable. Return strict JSON only.'
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
              'You are a cost analyst. For each solution, produce a concise cost breakdown: 8–20 project items with description, estimated cost ('
                  '$currency), expected ROI% and NPV values for 3, 5, and 10-year horizons (same currency). Use realistic but round numbers. Keep descriptions under 18 words. Return strict JSON only.'
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
 For each solution below, provide a cost breakdown with up to 20 items (aim for 12–20 when possible). For each item include: item (name), description, estimated_cost (number in $currency), roi_percent (number), npv_by_years (object with keys "3_years", "5_years", "10_years" and numeric values in $currency). Keep descriptions concise.

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
              'You are a cloud and infrastructure architect. For each solution, list the major infrastructure considerations required to operate it reliably and securely (e.g., environments, networking, security, observability, scaling, data, resiliency). Keep items concise. Return strict JSON only.'
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
    for (final s in solutions) {
      map[s.title] = [
        'Environments (dev/test/stage/prod) with promotion strategy',
        'Networking (VPC/VNet, subnets, ingress/egress, load balancers)',
        'Identity & access management (SSO, RBAC, least privilege)',
        'Secrets management (KMS/KeyVault, rotation, audit)',
        'Data storage & backups (RPO/RTO, encryption at rest/in transit)',
        'Observability (logs, metrics, tracing, alerting, dashboards)',
        'Scalability & performance (autoscaling, caching, capacity planning)',
        'Resilience & DR (multi-AZ/region, failover, chaos testing)'
      ];
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
For each solution below, list the major infrastructure considerations required to support it in production. Think in terms of environments, networking, security, observability, scaling, data, and resilience. 

IMPORTANT: Write clear, complete sentences. Each item should be a full, understandable statement (e.g., "Production environment with automated deployment pipelines" not just "Environments"). Keep each item between 8-20 words and make it actionable and specific.

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
  Future<Map<String, List<String>>> generateStakeholdersForSolutions(
      List<AiSolutionItem> solutions,
      {String contextNotes = ''}) async {
    if (solutions.isEmpty) return {};
    if (!OpenAiConfig.isConfigured) return _fallbackStakeholders(solutions);

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
              'You are a stakeholder analyst. For each solution, list the notable stakeholders that must be involved or consulted. Emphasize external, regulatory, government, and any critical third parties. Keep items concise. Return strict JSON only.'
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

      final List list = (parsed['stakeholders'] as List? ?? []);
      final Map<String, List<String>> result = {};
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final title = (map['solution'] ?? '').toString();
        final items = (map['items'] as List? ?? [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .take(6)
            .toList();
        if (title.isNotEmpty && items.isNotEmpty) result[title] = items;
      }
      return _mergeWithFallbackStakeholders(solutions, result);
    } catch (e) {
      print('generateStakeholdersForSolutions failed: $e');
      return _fallbackStakeholders(solutions);
    }
  }

  Map<String, List<String>> _mergeWithFallbackStakeholders(
      List<AiSolutionItem> solutions, Map<String, List<String>> generated) {
    final fallback = _fallbackStakeholders(solutions);
    final merged = <String, List<String>>{};
    for (final s in solutions) {
      final g = generated[s.title];
      merged[s.title] = (g != null && g.isNotEmpty)
          ? g.take(6).toList()
          : (fallback[s.title] ?? []);
    }
    return merged;
  }

  Map<String, List<String>> _fallbackStakeholders(
      List<AiSolutionItem> solutions) {
    final map = <String, List<String>>{};
    for (final s in solutions) {
      map[s.title] = [
        'Regulatory authority (industry-specific)',
        'Data protection authority / privacy office',
        'Government procurement or finance oversight',
        'External vendors / systems integrators',
        'Compliance & internal audit',
        'End-user representatives / advocacy groups',
      ];
    }
    return map;
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
For each solution below, identify the core stakeholders that must be engaged. Prioritize external, regulatory, government, and any other critical stakeholders of note. Keep each item under 12 words.

Return ONLY valid JSON with this exact structure:
{
  "stakeholders": [
    {"solution": "Solution Name", "items": ["Stakeholder 1", "Stakeholder 2", "Stakeholder 3"]}
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

Given these potential solutions, provide three distinct, solution-specific delivery risks for each. Keep each risk under 22 words, actionable and specific to that particular solution.

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
For each solution below, list 3-6 core technologies/services/frameworks that would be SPECIFICALLY required to implement that particular solution. 

IMPORTANT: Each solution must have DIFFERENT and UNIQUE technology recommendations tailored to its specific title, description, and requirements. Do NOT repeat the same generic technologies across all solutions. Consider:
- The nature of the solution (cloud-native vs on-premise, mobile vs web, etc.)
- Industry-specific requirements implied by the solution
- Scale and complexity differences between solutions
- Different architectural patterns suitable for each solution

Return ONLY valid JSON with this exact structure:
{
  "technologies": [
    {"solution": "Solution Name", "items": ["Tech 1", "Tech 2", "Tech 3"]}
  ]
}

${list.isNotEmpty ? 'Solutions: [$list]' : 'Project Context: $notes'}

Context notes (optional): $notes
''';
  }

  // FEP RISKS GENERATION - Generate risks with all fields (Title, Category, Probability, Impact)
  Future<List<Map<String, String>>> generateFepRisks(String context) async {
    if (context.trim().isEmpty) return [];
    if (!OpenAiConfig.isConfigured) throw const OpenAiNotConfiguredException();

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
              'You are a risk analyst. Generate project risks with Title, Category, Probability (Low/Medium/High), and Impact (Low/Medium/High). Return strict JSON only.'
        },
        {
          'role': 'user',
          'content': '''Generate 5-8 project risks based on this context:

$context

Return JSON in this format:
{
  "risks": [
    {
      "title": "Risk title",
      "category": "Technical/Financial/Operational/Schedule/Resource",
      "probability": "Low/Medium/High",
      "impact": "Low/Medium/High"
    }
  ]
}'''
        },
      ],
    });

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'OpenAI error ${response.statusCode}: ${response.body}');
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
            };
          })
          .where((r) => r['title']!.isNotEmpty)
          .toList();
      return risks;
    } catch (e) {
      rethrow;
    }
  }

  String _escape(String v) => v.replaceAll('"', '\\"').replaceAll('\n', ' ');
}
