import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ndu_project/screens/project_close_out_screen.dart';
import 'package:ndu_project/screens/transition_to_prod_team_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';

class DeliverProjectClosureScreen extends StatefulWidget {
  const DeliverProjectClosureScreen({super.key});

  static void open(BuildContext context) {
    PhaseTransitionHelper.pushPhaseAware(
      context: context,
      builder: (_) => const DeliverProjectClosureScreen(),
      destinationCheckpoint: 'deliver_project_closure',
    );
  }

  @override
  State<DeliverProjectClosureScreen> createState() => _DeliverProjectClosureScreenState();
}

class _DeliverProjectClosureScreenState extends State<DeliverProjectClosureScreen> {
  final List<LaunchEntry> _summary = [];
  final List<LaunchEntry> _scopeOutcomes = [];
  final List<LaunchEntry> _risks = [];
  final List<LaunchEntry> _checklist = [];
  bool _loadedEntries = false;
  bool _aiGenerated = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 18 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Deliver Project'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(context),
                        const SizedBox(height: 20),
                        LaunchEditableSection(
                          title: 'Closure summary & metrics',
                          description: 'Start from a clean slate. Add the delivery metrics or highlights you want to track.',
                          entries: _summary,
                          onAdd: () => _addEntry(_summary, titleLabel: 'Metric or highlight', includeStatus: true),
                          onRemove: (index) => _removeEntry(_summary, index),
                        ),
                        LaunchEditableSection(
                          title: 'Scope closure & acceptance',
                          description: 'Record acceptance notes, outcomes, or pending items.',
                          entries: _scopeOutcomes,
                          onAdd: () => _addEntry(_scopeOutcomes, titleLabel: 'Outcome', includeStatus: true),
                          onRemove: (index) => _removeEntry(_scopeOutcomes, index),
                        ),
                        LaunchEditableSection(
                          title: 'Risks, gaps, and follow-ups',
                          description: 'Document anything that must be monitored post-delivery.',
                          entries: _risks,
                          onAdd: () => _addEntry(_risks, titleLabel: 'Risk or gap', includeStatus: true),
                          onRemove: (index) => _removeEntry(_risks, index),
                        ),
                        LaunchEditableSection(
                          title: 'Final checklist',
                          description: 'Add the tasks required to confirm the project is fully delivered.',
                          entries: _checklist,
                          onAdd: () => _addEntry(_checklist, titleLabel: 'Checklist item', includeStatus: true),
                          onRemove: (index) => _removeEntry(_checklist, index),
                        ),
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel: 'Back: Project Close Out',
                          nextLabel: 'Next: Transition To Production Team',
                          onBack: () => ProjectCloseOutScreen.open(
                            context,
                            summarized: false,
                            activeItemLabel: 'Project Close Out',
                          ),
                          onNext: () => TransitionToProdTeamScreen.open(context),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deliver Project · Closure Summary',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'All launch-phase data is now blank by default. Use the add buttons to populate each section from the pop-ups.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Future<void> _addEntry(
    List<LaunchEntry> targetList, {
    String titleLabel = 'Title',
    bool includeStatus = true,
  }) async {
    final entry = await showLaunchEntryDialog(
      context,
      titleLabel: titleLabel,
      detailsLabel: 'Details',
      includeStatus: includeStatus,
    );
    if (entry != null && mounted) {
      setState(() => targetList.add(entry));
      await _persistEntries();
    }
  }

  void _removeEntry(List<LaunchEntry> targetList, int index) {
    setState(() => targetList.removeAt(index));
    _persistEntries();
  }

  Future<void> _loadEntries() async {
    if (_loadedEntries) return;
    final provider = ProjectDataHelper.getProvider(context);
    final projectId = provider.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('launch_phase')
          .doc('deliver_project_closure')
          .get();
      if (!doc.exists) {
        _loadedEntries = true;
        return;
      }
      final data = doc.data() ?? {};
      final summary = (data['summary'] as List?)
              ?.whereType<Map>()
              .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      final scope = (data['scopeOutcomes'] as List?)
              ?.whereType<Map>()
              .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      final risks = (data['risks'] as List?)
              ?.whereType<Map>()
              .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      final checklist = (data['checklist'] as List?)
              ?.whereType<Map>()
              .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      if (!mounted) return;
      setState(() {
        _summary
          ..clear()
          ..addAll(summary);
        _scopeOutcomes
          ..clear()
          ..addAll(scope);
        _risks
          ..clear()
          ..addAll(risks);
        _checklist
          ..clear()
          ..addAll(checklist);
      });
      _loadedEntries = true;
      if (_summary.isEmpty && _scopeOutcomes.isEmpty && _risks.isEmpty && _checklist.isEmpty) {
        await _populateFromAi();
      }
    } catch (error) {
      debugPrint('Failed to load deliver project entries: $error');
    }
  }

  Future<void> _populateFromAi() async {
    if (_aiGenerated || _isGenerating) return;
    final projectData = ProjectDataHelper.getData(context);
    final contextText = ProjectDataHelper.buildFepContext(projectData, sectionLabel: 'Deliver Project');
    if (contextText.trim().isEmpty) return;

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> generated = {};
    try {
      generated = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: contextText,
        sections: const {
          'closure_summary': 'Closure summary & metrics',
          'scope_acceptance': 'Scope closure & acceptance',
          'risks_followups': 'Risks, gaps, and follow-ups',
          'final_checklist': 'Final checklist',
        },
        itemsPerSection: 2,
      );
    } catch (error) {
      debugPrint('Deliver project AI call failed: $error');
    }

    if (!mounted) return;
    if (_summary.isNotEmpty || _scopeOutcomes.isNotEmpty || _risks.isNotEmpty || _checklist.isNotEmpty) {
      setState(() => _isGenerating = false);
      _aiGenerated = true;
      return;
    }

    setState(() {
      _summary
        ..clear()
        ..addAll(_mapEntries(generated['closure_summary']));
      _scopeOutcomes
        ..clear()
        ..addAll(_mapEntries(generated['scope_acceptance']));
      _risks
        ..clear()
        ..addAll(_mapEntries(generated['risks_followups']));
      _checklist
        ..clear()
        ..addAll(_mapEntries(generated['final_checklist']));
      _isGenerating = false;
    });
    _aiGenerated = true;
    await _persistEntries();
  }

  List<LaunchEntry> _mapEntries(List<Map<String, dynamic>>? raw) {
    if (raw == null) return [];
    return raw
        .map((item) => LaunchEntry(
              title: (item['title'] ?? '').toString().trim(),
              details: (item['details'] ?? '').toString().trim(),
              status: (item['status'] ?? '').toString().trim().isEmpty ? null : item['status'].toString().trim(),
            ))
        .where((entry) => entry.title.isNotEmpty)
        .toList();
  }

  Future<void> _persistEntries() async {
    final provider = ProjectDataHelper.getProvider(context);
    final projectId = provider.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;

    final payload = {
      'summary': _summary.map((e) => e.toJson()).toList(),
      'scopeOutcomes': _scopeOutcomes.map((e) => e.toJson()).toList(),
      'risks': _risks.map((e) => e.toJson()).toList(),
      'checklist': _checklist.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('launch_phase')
        .doc('deliver_project_closure')
        .set(payload, SetOptions(merge: true));
  }
}
