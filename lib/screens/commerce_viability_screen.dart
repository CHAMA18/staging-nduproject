import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ndu_project/screens/actual_vs_planned_gap_analysis_screen.dart';
import 'package:ndu_project/screens/summarize_account_risks_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

class CommerceViabilityScreen extends StatefulWidget {
  const CommerceViabilityScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommerceViabilityScreen()),
    );
  }

  @override
  State<CommerceViabilityScreen> createState() =>
      _CommerceViabilityScreenState();
}

class _CommerceViabilityScreenState extends State<CommerceViabilityScreen> {
  final List<LaunchEntry> _viabilityChecks = [];
  final List<LaunchEntry> _financialSignals = [];
  final List<LaunchEntry> _decisions = [];
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
      activeItemLabel: 'Warranties & Operations Support',
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
              title: 'Viability checkpoints',
              description:
                  'Add the checks you want to run to confirm the business case still holds.',
              entries: _viabilityChecks,
              onAdd: () =>
                  _addEntry(_viabilityChecks, titleLabel: 'Checkpoint'),
              onRemove: (index) => _removeEntry(_viabilityChecks, index),
            ),
            LaunchEditableSection(
              title: 'Financial signals & unit economics',
              description:
                  'Capture demand, margins, and cost-to-serve data as you collect it.',
              entries: _financialSignals,
              onAdd: () => _addEntry(_financialSignals,
                  titleLabel: 'Signal', includeStatus: true),
              onRemove: (index) => _removeEntry(_financialSignals, index),
            ),
            LaunchEditableSection(
              title: 'Decisions & recommendations',
              description:
                  'Record the go / grow / pause call with supporting context.',
              entries: _decisions,
              onAdd: () => _addEntry(_decisions,
                  titleLabel: 'Decision', includeStatus: true),
              onRemove: (index) => _removeEntry(_decisions, index),
            ),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Project Summary',
              nextLabel: 'Next: Project Financial Review',
              onBack: () => SummarizeAccountRisksScreen.open(context),
              onNext: () => ActualVsPlannedGapAnalysisScreen.open(context),
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
          'COMMERCE VIABILITY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check if this solution is commercially sustainable',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'The sections below start empty—use the pop-ups to add the numbers, risks, and decisions you want to track.',
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
          .doc('commerce_viability')
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final viability = (data['viabilityChecks'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final signals = (data['financialSignals'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final decisions = (data['decisions'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        if (!mounted) return;
        setState(() {
          _viabilityChecks
            ..clear()
            ..addAll(viability);
          _financialSignals
            ..clear()
            ..addAll(signals);
          _decisions
            ..clear()
            ..addAll(decisions);
        });
      }
      _loadedEntries = true;
      if (_viabilityChecks.isEmpty &&
          _financialSignals.isEmpty &&
          _decisions.isEmpty) {
        await _populateFromAi();
      }
    } catch (error) {
      debugPrint('Failed to load commerce viability entries: $error');
    }
  }

  Future<void> _populateFromAi() async {
    if (_aiGenerated || _isGenerating) return;
    final projectData = ProjectDataHelper.getData(context);
    final contextText = ProjectDataHelper.buildFepContext(projectData,
        sectionLabel: 'Commerce Viability');
    if (contextText.trim().isEmpty) return;

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> generated = {};
    try {
      generated = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: contextText,
        sections: const {
          'viability_checks': 'Viability checkpoints',
          'financial_signals': 'Financial signals & unit economics',
          'decisions': 'Decisions & recommendations',
        },
        itemsPerSection: 2,
      );
    } catch (error) {
      debugPrint('Commerce viability AI call failed: $error');
    }

    if (!mounted) return;
    if (_viabilityChecks.isNotEmpty ||
        _financialSignals.isNotEmpty ||
        _decisions.isNotEmpty) {
      setState(() => _isGenerating = false);
      _aiGenerated = true;
      return;
    }

    setState(() {
      _viabilityChecks
        ..clear()
        ..addAll(_mapEntries(generated['viability_checks']));
      _financialSignals
        ..clear()
        ..addAll(_mapEntries(generated['financial_signals']));
      _decisions
        ..clear()
        ..addAll(_mapEntries(generated['decisions']));
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
      'viabilityChecks': _viabilityChecks.map((e) => e.toJson()).toList(),
      'financialSignals': _financialSignals.map((e) => e.toJson()).toList(),
      'decisions': _decisions.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('launch_phase')
        .doc('commerce_viability')
        .set(payload, SetOptions(merge: true));
  }
}
