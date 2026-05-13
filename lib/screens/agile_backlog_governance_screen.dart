import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/agile_wireframe_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';

const Color _kBackground = Color(0xFFF9FAFC);
const Color _kMuted = Color(0xFF6B7280);
const Color _kHeadline = Color(0xFF111827);
const Color _kAccent = Color(0xFFD97706);

class AgileBacklogGovernanceScreen extends StatefulWidget {
  const AgileBacklogGovernanceScreen({super.key});

  @override
  State<AgileBacklogGovernanceScreen> createState() =>
      _AgileBacklogGovernanceScreenState();
}

class _AgileBacklogGovernanceScreenState
    extends State<AgileBacklogGovernanceScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGenerating = false;
  Timer? _autoSaveDebounce;

  static const List<_FieldConfig> _fields = [
    _FieldConfig(
      key: 'definition_of_ready',
      label: 'Definition of Ready',
      hint:
          'Criteria a backlog item must meet before it can be pulled into a sprint. e.g. acceptance criteria defined, estimated, dependencies identified.',
    ),
    _FieldConfig(
      key: 'definition_of_done',
      label: 'Definition of Done',
      hint:
          'Quality gate criteria that must be met for work to be considered complete. e.g. code reviewed, tested, documented, deployed to staging.',
    ),
    _FieldConfig(
      key: 'prioritization_framework',
      label: 'Prioritization Framework',
      hint:
          'How backlog items are prioritized. e.g. MoSCoW (Must/Should/Could/Won\'t), WSJF, RICE, or custom approach.',
    ),
    _FieldConfig(
      key: 'refinement_cadence',
      label: 'Refinement Cadence',
      hint:
          'How often backlog refinement occurs. e.g. Weekly 1-hour session mid-sprint, or continuous async refinement.',
    ),
    _FieldConfig(
      key: 'estimation_framework',
      label: 'Estimation Framework',
      hint:
          'How effort is estimated. e.g. Story points (Fibonacci 1,2,3,5,8,13), T-shirt sizes (S/M/L/XL), or Ideal hours.',
    ),
    _FieldConfig(
      key: 'ownership',
      label: 'Backlog Ownership',
      hint:
          'Who owns the backlog. e.g. Product Owner owns prioritization, Tech Lead owns technical refinement, Team owns estimation.',
    ),
    _FieldConfig(
      key: 'grooming_rules',
      label: 'Grooming Rules & Policies',
      hint:
          'Rules for backlog hygiene. e.g. Max age of items, WIP limits, splitting rules, stale item policy.',
      fullWidth: true,
    ),
  ];

  String? get _projectId {
    try {
      return ProjectDataInherited.maybeOf(context)?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      _controllers[f.key] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final pid = _projectId;
    if (pid == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await AgileWireframeService.loadBacklogGovernance(pid);
      if (!mounted) return;
      final hasContent = data.values.any(
          (v) => v is String && v.trim().isNotEmpty);
      if (!hasContent) {
        final dm = await AgileWireframeService.loadDeliveryModel(pid);
        final backlogText = dm['backlog'] as String? ?? '';
        if (backlogText.isNotEmpty) {
          for (final f in _fields) {
            final val = data[f.key];
            if (val == null || (val is String && val.isEmpty)) {
              _controllers[f.key]?.text = backlogText;
            }
          }
        }
      } else {
        for (final f in _fields) {
          _controllers[f.key]?.text = data[f.key] as String? ?? '';
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _scheduleAutoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 500), () => _performSave());
  }

  Future<void> _performSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final pid = _projectId;
      if (pid == null) return;
      final data = <String, String>{};
      for (final f in _fields) {
        data[f.key] = _controllers[f.key]?.text ?? '';
      }
      await AgileWireframeService.saveBacklogGovernance(projectId: pid, data: data);
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)),
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _generateWithAI() async {
    final pid = _projectId;
    if (pid == null) return;
    setState(() => _isGenerating = true);
    try {
      final projectData = ProjectDataHelper.getData(context);
      final contextText = ProjectDataHelper.buildProjectContextScan(projectData, sectionLabel: 'Backlog Governance');
      final openai = OpenAiServiceSecure();
      final result = await openai.generateCompletion(
        'Based on this project context, suggest backlog governance rules.\n\n'
        'Context:\n$contextText\n\n'
        'For each area provide 2-3 sentences:\n'
        '- definition_of_ready\n'
        '- definition_of_done\n'
        '- prioritization_framework\n'
        '- refinement_cadence\n'
        '- estimation_framework\n'
        '- ownership\n'
        '- grooming_rules\n\n'
        'Return as a JSON object with the keys above.',
        maxTokens: 1200,
        temperature: 0.5,
      );
      final parsed = _parseAIResult(result);
      for (final entry in parsed.entries) {
        if (_controllers.containsKey(entry.key)) {
          _controllers[entry.key]?.text = entry.value;
        }
      }
      _performSave();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI generation failed: ${e.toString()}')),
        );
      }
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  Map<String, String> _parseAIResult(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end == -1) return {};
      final jsonStr = text.substring(start, end + 1);
      final Map<String, dynamic> parsed = Map<String, dynamic>.from(
          JsonDecoder().convert(jsonStr) as Map);
      return parsed.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double hp = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Agile Wireframe - Backlog Governance'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: hp, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlanningPhaseHeader(
                          title: 'Backlog Governance',
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                              context, 'agile_backlog_governance'),
                          onForward: () => PlanningPhaseNavigation.goToNext(
                              context, 'agile_backlog_governance'),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Define the rules, criteria, and processes for managing the product backlog.',
                                style: TextStyle(fontSize: 15, color: _kMuted),
                              ),
                            ),
                            if (!_isLoading) ...[
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _isGenerating ? null : _generateWithAI,
                                icon: _isGenerating
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.auto_awesome, size: 18),
                                label: Text(_isGenerating ? 'Generating...' : 'AI Generate'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _kAccent,
                                  side: const BorderSide(color: _kAccent),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          if (_isSaving)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                  const SizedBox(width: 8),
                                  Text('Saving...', style: TextStyle(fontSize: 12, color: _kMuted)),
                                ],
                              ),
                            ),
                          ..._fields.map((f) => _buildField(f)),
                        ],
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel: PlanningPhaseNavigation.backLabel('agile_backlog_governance'),
                          nextLabel: PlanningPhaseNavigation.nextLabel('agile_backlog_governance'),
                          onBack: () => PlanningPhaseNavigation.goToPrevious(context, 'agile_backlog_governance'),
                          onNext: () => PlanningPhaseNavigation.goToNext(context, 'agile_backlog_governance'),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: 24,
                    bottom: 24,
                    child: KazAiChatBubble(positioned: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(_FieldConfig f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f.label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kHeadline)),
          const SizedBox(height: 8),
          TextField(
            controller: _controllers[f.key],
            decoration: InputDecoration(
              hintText: f.hint,
              border: const OutlineInputBorder(),
            ),
            minLines: f.fullWidth ? 3 : 2,
            maxLines: f.fullWidth ? 6 : 4,
            onChanged: (_) => _scheduleAutoSave(),
          ),
        ],
      ),
    );
  }
}

class _FieldConfig {
  final String key;
  final String label;
  final String hint;
  final bool fullWidth;
  const _FieldConfig({
    required this.key,
    required this.label,
    required this.hint,
    this.fullWidth = false,
  });
}

class JsonDecoder {
  dynamic convert(String source) {
    return _parseValue(source, 0).value;
  }

  _Result _parseValue(String s, int i) {
    i = _skipWhitespace(s, i);
    if (i >= s.length) throw FormatException('Unexpected end');
    final c = s[i];
    if (c == '[') return _parseArray(s, i);
    if (c == '{') return _parseObject(s, i);
    if (c == '"') return _parseString(s, i);
    if (c == 't' || c == 'f') return _parseBool(s, i);
    if (c == 'n') return _parseNull(s, i);
    return _parseNumber(s, i);
  }

  _Result _parseArray(String s, int i) {
    i++;
    final list = <dynamic>[];
    i = _skipWhitespace(s, i);
    if (i < s.length && s[i] == ']') return _Result(list, i + 1);
    while (true) {
      final r = _parseValue(s, i);
      list.add(r.value);
      i = _skipWhitespace(s, r.end);
      if (i >= s.length) throw FormatException('Unexpected end of array');
      if (s[i] == ']') return _Result(list, i + 1);
      if (s[i] != ',') throw FormatException('Expected , or ]');
      i++;
    }
  }

  _Result _parseObject(String s, int i) {
    i++;
    final map = <String, dynamic>{};
    i = _skipWhitespace(s, i);
    if (i < s.length && s[i] == '}') return _Result(map, i + 1);
    while (true) {
      final keyR = _parseString(s, i);
      i = _skipWhitespace(s, keyR.end);
      if (i >= s.length || s[i] != ':') throw FormatException('Expected :');
      i++;
      final valR = _parseValue(s, i);
      map[keyR.value as String] = valR.value;
      i = _skipWhitespace(s, valR.end);
      if (i >= s.length) throw FormatException('Unexpected end of object');
      if (s[i] == '}') return _Result(map, i + 1);
      if (s[i] != ',') throw FormatException('Expected , or }');
      i++;
    }
  }

  _Result _parseString(String s, int i) {
    i++;
    final buf = StringBuffer();
    while (i < s.length) {
      final c = s[i];
      if (c == '"') return _Result(buf.toString(), i + 1);
      if (c == '\\') {
        i++;
        if (i < s.length) {
          final esc = s[i];
          if (esc == '"') buf.write('"');
          else if (esc == '\\') buf.write('\\');
          else if (esc == '/') buf.write('/');
          else if (esc == 'n') buf.write('\n');
          else if (esc == 'r') buf.write('\r');
          else if (esc == 't') buf.write('\t');
          else buf.write(esc);
        }
        i++;
      } else {
        buf.write(c);
        i++;
      }
    }
    throw FormatException('Unterminated string');
  }

  _Result _parseNumber(String s, int i) {
    final start = i;
    if (s[i] == '-') i++;
    while (i < s.length && _isDigit(s[i])) i++;
    if (i < s.length && s[i] == '.') {
      i++;
      while (i < s.length && _isDigit(s[i])) i++;
    }
    if (i < s.length && (s[i] == 'e' || s[i] == 'E')) {
      i++;
      if (i < s.length && (s[i] == '+' || s[i] == '-')) i++;
      while (i < s.length && _isDigit(s[i])) i++;
    }
    final numStr = s.substring(start, i);
    if (numStr.contains('.') || numStr.contains('e') || numStr.contains('E')) {
      return _Result(double.parse(numStr), i);
    }
    return _Result(int.parse(numStr), i);
  }

  _Result _parseBool(String s, int i) {
    if (s.startsWith('true', i)) return _Result(true, i + 4);
    if (s.startsWith('false', i)) return _Result(false, i + 5);
    throw FormatException('Expected boolean');
  }

  _Result _parseNull(String s, int i) {
    if (s.startsWith('null', i)) return _Result(null, i + 4);
    throw FormatException('Expected null');
  }

  bool _isDigit(String s, [int? i]) {
    final c = i != null ? s.codeUnitAt(i) : s.codeUnitAt(0);
    return c >= 48 && c <= 57;
  }

  int _skipWhitespace(String s, int i) {
    while (i < s.length && s.codeUnitAt(i) <= 32) i++;
    return i;
  }
}

class _Result {
  final dynamic value;
  final int end;
  _Result(this.value, this.end);
}
