import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ndu_project/screens/gap_analysis_scope_reconcillation_screen.dart';
import 'package:ndu_project/screens/project_close_out_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

class DemobilizeTeamScreen extends StatefulWidget {
  const DemobilizeTeamScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DemobilizeTeamScreen()),
    );
  }

  @override
  State<DemobilizeTeamScreen> createState() => _DemobilizeTeamScreenState();
}

class _DemobilizeTeamScreenState extends State<DemobilizeTeamScreen> {
  final List<LaunchEntry> _teamRampDown = [];
  final List<LaunchEntry> _knowledgeTransfer = [];
  final List<LaunchEntry> _vendorOffboarding = [];
  final List<LaunchEntry> _communications = [];
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
      activeItemLabel: 'Demobilize Team',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(context, isMobile),
            const SizedBox(height: 20),
            LaunchEditableSection(
              title: 'Team ramp-down plan',
              description: 'Add actions and decisions for releasing core team members.',
              entries: _teamRampDown,
              onAdd: () => _addEntry(_teamRampDown, titleLabel: 'Ramp-down item'),
              onRemove: (index) => _removeEntry(_teamRampDown, index),
            ),
            LaunchEditableSection(
              title: 'Knowledge transfer & handover',
              description: 'Capture the sessions, artifacts, and owners for knowledge capture.',
              entries: _knowledgeTransfer,
              onAdd: () => _addEntry(_knowledgeTransfer, titleLabel: 'Knowledge item'),
              onRemove: (index) => _removeEntry(_knowledgeTransfer, index),
            ),
            LaunchEditableSection(
              title: 'Vendor & access offboarding',
              description: 'Track vendor exits, tool access clean-up, and remaining obligations.',
              entries: _vendorOffboarding,
              onAdd: () => _addEntry(_vendorOffboarding, titleLabel: 'Offboarding item', includeStatus: true),
              onRemove: (index) => _removeEntry(_vendorOffboarding, index),
            ),
            LaunchEditableSection(
              title: 'Communications & people care',
              description: 'Log communications, FAQs, and support for impacted people.',
              entries: _communications,
              onAdd: () => _addEntry(_communications, titleLabel: 'Communication item'),
              onRemove: (index) => _removeEntry(_communications, index),
              showStatusChip: false,
            ),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Project Financial Review - Scope Reconcillation',
              nextLabel: 'Next: Project Close Out',
              onBack: () => GapAnalysisScopeReconcillationScreen.open(context),
              onNext: () => ProjectCloseOutScreen.open(context),
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
          'DEMOBILIZE TEAM',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Wind down the project team responsibly',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Everything below starts blank—use the pop-ups to capture the actions, owners, and safeguards you need.',
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
          .doc('demobilize_team')
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final ramp = (data['teamRampDown'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final knowledge = (data['knowledgeTransfer'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final vendor = (data['vendorOffboarding'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final comms = (data['communications'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        if (!mounted) return;
        setState(() {
          _teamRampDown
            ..clear()
            ..addAll(ramp);
          _knowledgeTransfer
            ..clear()
            ..addAll(knowledge);
          _vendorOffboarding
            ..clear()
            ..addAll(vendor);
          _communications
            ..clear()
            ..addAll(comms);
        });
      }
      _loadedEntries = true;
      if (_teamRampDown.isEmpty && _knowledgeTransfer.isEmpty && _vendorOffboarding.isEmpty && _communications.isEmpty) {
        await _populateFromAi();
      }
    } catch (error) {
      debugPrint('Failed to load demobilize team entries: $error');
    }
  }

  Future<void> _populateFromAi() async {
    if (_aiGenerated || _isGenerating) return;
    final projectData = ProjectDataHelper.getData(context);
    final contextText = ProjectDataHelper.buildFepContext(projectData, sectionLabel: 'Demobilize Team');
    if (contextText.trim().isEmpty) return;

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> generated = {};
    try {
      generated = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: contextText,
        sections: const {
          'team_ramp_down': 'Team ramp-down plan',
          'knowledge_transfer': 'Knowledge transfer & handover',
          'vendor_offboarding': 'Vendor & access offboarding',
          'communications': 'Communications & people care',
        },
        itemsPerSection: 2,
      );
    } catch (error) {
      debugPrint('Demobilize team AI call failed: $error');
    }

    if (!mounted) return;
    if (_teamRampDown.isNotEmpty || _knowledgeTransfer.isNotEmpty || _vendorOffboarding.isNotEmpty || _communications.isNotEmpty) {
      setState(() => _isGenerating = false);
      _aiGenerated = true;
      return;
    }

    setState(() {
      _teamRampDown
        ..clear()
        ..addAll(_mapEntries(generated['team_ramp_down']));
      _knowledgeTransfer
        ..clear()
        ..addAll(_mapEntries(generated['knowledge_transfer']));
      _vendorOffboarding
        ..clear()
        ..addAll(_mapEntries(generated['vendor_offboarding']));
      _communications
        ..clear()
        ..addAll(_mapEntries(generated['communications']));
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
      'teamRampDown': _teamRampDown.map((e) => e.toJson()).toList(),
      'knowledgeTransfer': _knowledgeTransfer.map((e) => e.toJson()).toList(),
      'vendorOffboarding': _vendorOffboarding.map((e) => e.toJson()).toList(),
      'communications': _communications.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('launch_phase')
        .doc('demobilize_team')
        .set(payload, SetOptions(merge: true));
  }
}
