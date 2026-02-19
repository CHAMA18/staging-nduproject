import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ndu_project/screens/commerce_viability_screen.dart';
import 'package:ndu_project/screens/gap_analysis_scope_reconcillation_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

class ActualVsPlannedGapAnalysisScreen extends StatefulWidget {
  const ActualVsPlannedGapAnalysisScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ActualVsPlannedGapAnalysisScreen()),
    );
  }

  @override
  State<ActualVsPlannedGapAnalysisScreen> createState() =>
      _ActualVsPlannedGapAnalysisScreenState();
}

class _ActualVsPlannedGapAnalysisScreenState
    extends State<ActualVsPlannedGapAnalysisScreen> {
  final List<LaunchEntry> _scheduleGaps = [];
  final List<LaunchEntry> _costGaps = [];
  final List<LaunchEntry> _scopeGaps = [];
  final List<LaunchEntry> _benefitsAndCauses = [];
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
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: 'Project Financial Review',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(positioned: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, vertical: isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(context, isMobile),
            const SizedBox(height: 20),
            LaunchEditableSection(
              title: 'Schedule gap analysis',
              description:
                  'Document the biggest timeline variances and what drove them.',
              entries: _scheduleGaps,
              onAdd: () => _addEntry(_scheduleGaps,
                  includeStatus: true, titleLabel: 'Milestone'),
              onRemove: (index) => _removeEntry(_scheduleGaps, index),
            ),
            LaunchEditableSection(
              title: 'Cost & budget gaps',
              description:
                  'Capture where spend diverged from plan and the drivers.',
              entries: _costGaps,
              onAdd: () => _addEntry(_costGaps,
                  includeStatus: true, titleLabel: 'Cost item'),
              onRemove: (index) => _removeEntry(_costGaps, index),
            ),
            LaunchEditableSection(
              title: 'Scope & quality gaps',
              description:
                  'Note any descoped items, quality issues, or additions.',
              entries: _scopeGaps,
              onAdd: () => _addEntry(_scopeGaps,
                  includeStatus: true, titleLabel: 'Scope item'),
              onRemove: (index) => _removeEntry(_scopeGaps, index),
            ),
            LaunchEditableSection(
              title: 'Benefits & root causes',
              description:
                  'Summarize realized benefits and the root causes behind gaps.',
              entries: _benefitsAndCauses,
              onAdd: () => _addEntry(_benefitsAndCauses,
                  includeStatus: true, titleLabel: 'Benefit or cause'),
              onRemove: (index) => _removeEntry(_benefitsAndCauses, index),
            ),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Warranties & Operations Support',
              nextLabel: 'Next: Scope Reconciliation',
              onBack: () => CommerceViabilityScreen.open(context),
              onNext: () => GapAnalysisScopeReconcillationScreen.open(context),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTUAL VS PLANNED GAP ANALYSIS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Compare what was promised vs. what was delivered',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start with a blank slate; add schedule, budget, scope, and benefits data through the pop-ups below.',
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
          .doc('actual_vs_planned_gap_analysis')
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final schedule = (data['scheduleGaps'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final cost = (data['costGaps'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final scope = (data['scopeGaps'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final benefits = (data['benefitsCauses'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        if (!mounted) return;
        setState(() {
          _scheduleGaps
            ..clear()
            ..addAll(schedule);
          _costGaps
            ..clear()
            ..addAll(cost);
          _scopeGaps
            ..clear()
            ..addAll(scope);
          _benefitsAndCauses
            ..clear()
            ..addAll(benefits);
        });
      }
      _loadedEntries = true;
      if (_scheduleGaps.isEmpty &&
          _costGaps.isEmpty &&
          _scopeGaps.isEmpty &&
          _benefitsAndCauses.isEmpty) {
        await _populateFromAi();
      }
    } catch (error) {
      debugPrint('Failed to load actual vs planned entries: $error');
    }
  }

  Future<void> _populateFromAi() async {
    if (_aiGenerated || _isGenerating) return;
    final projectData = ProjectDataHelper.getData(context);
    final contextText = ProjectDataHelper.buildFepContext(projectData,
        sectionLabel: 'Actual vs Planned Gap Analysis');
    if (contextText.trim().isEmpty) return;

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> generated = {};
    try {
      generated = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: contextText,
        sections: const {
          'schedule_gaps': 'Schedule gap analysis',
          'cost_gaps': 'Cost & budget gaps',
          'scope_gaps': 'Scope & quality gaps',
          'benefits_causes': 'Benefits & root causes',
        },
        itemsPerSection: 2,
      );
    } catch (error) {
      debugPrint('Actual vs planned AI call failed: $error');
    }

    if (!mounted) return;
    if (_scheduleGaps.isNotEmpty ||
        _costGaps.isNotEmpty ||
        _scopeGaps.isNotEmpty ||
        _benefitsAndCauses.isNotEmpty) {
      setState(() => _isGenerating = false);
      _aiGenerated = true;
      return;
    }

    setState(() {
      _scheduleGaps
        ..clear()
        ..addAll(_mapEntries(generated['schedule_gaps']));
      _costGaps
        ..clear()
        ..addAll(_mapEntries(generated['cost_gaps']));
      _scopeGaps
        ..clear()
        ..addAll(_mapEntries(generated['scope_gaps']));
      _benefitsAndCauses
        ..clear()
        ..addAll(_mapEntries(generated['benefits_causes']));
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
              status: (item['status'] ?? '').toString().trim().isEmpty
                  ? null
                  : item['status'].toString().trim(),
            ))
        .where((entry) => entry.title.isNotEmpty)
        .toList();
  }

  Future<void> _persistEntries() async {
    final provider = ProjectDataHelper.getProvider(context);
    final projectId = provider.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;

    final payload = {
      'scheduleGaps': _scheduleGaps.map((e) => e.toJson()).toList(),
      'costGaps': _costGaps.map((e) => e.toJson()).toList(),
      'scopeGaps': _scopeGaps.map((e) => e.toJson()).toList(),
      'benefitsCauses': _benefitsAndCauses.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('launch_phase')
        .doc('actual_vs_planned_gap_analysis')
        .set(payload, SetOptions(merge: true));
  }
}
