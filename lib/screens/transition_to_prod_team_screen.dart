import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ndu_project/screens/contract_close_out_screen.dart';
import 'package:ndu_project/screens/deliver_project_closure_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

class TransitionToProdTeamScreen extends StatefulWidget {
  const TransitionToProdTeamScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransitionToProdTeamScreen()),
    );
  }

  @override
  State<TransitionToProdTeamScreen> createState() => _TransitionToProdTeamScreenState();
}

class _TransitionToProdTeamScreenState extends State<TransitionToProdTeamScreen> {
  final List<LaunchEntry> _transitionSteps = [];
  final List<LaunchEntry> _handoverArtifacts = [];
  final List<LaunchEntry> _signOffs = [];
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Transition To Production Team'),
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
                          title: 'Guided transition steps',
                          description: 'Add the steps you plan to follow to hand over to production.',
                          entries: _transitionSteps,
                          onAdd: () => _addEntry(_transitionSteps, titleLabel: 'Step', includeStatus: true),
                          onRemove: (index) => _removeEntry(_transitionSteps, index),
                        ),
                        LaunchEditableSection(
                          title: 'Handover artifacts & tools',
                          description: 'List runbooks, dashboards, or other artifacts needed by Ops/Client.',
                          entries: _handoverArtifacts,
                          onAdd: () => _addEntry(_handoverArtifacts, titleLabel: 'Artifact'),
                          onRemove: (index) => _removeEntry(_handoverArtifacts, index),
                          showStatusChip: false,
                        ),
                        LaunchEditableSection(
                          title: 'Ops & client sign-offs',
                          description: 'Capture who needs to approve the handover and their status.',
                          entries: _signOffs,
                          onAdd: () => _addEntry(_signOffs, titleLabel: 'Approver', includeStatus: true),
                          onRemove: (index) => _removeEntry(_signOffs, index),
                        ),
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel: 'Back: Deliver Project',
                          nextLabel: 'Next: Contract Close Out',
                          onBack: () => DeliverProjectClosureScreen.open(context),
                          onNext: () => ContractCloseOutScreen.open(context),
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
          'Transition to Prod Team · Guided flow',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Launch-phase data is now empty by default. Use the pop-ups to add the steps, artifacts, and approvals you need.',
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
          .doc('transition_to_prod_team')
          .get();
      if (!doc.exists) {
        _loadedEntries = true;
        return;
      }
      final data = doc.data() ?? {};
      final steps = (data['transitionSteps'] as List?)
              ?.whereType<Map>()
              .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      final artifacts = (data['handoverArtifacts'] as List?)
              ?.whereType<Map>()
              .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      final signoffs = (data['signOffs'] as List?)
              ?.whereType<Map>()
              .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      if (!mounted) return;
      setState(() {
        _transitionSteps
          ..clear()
          ..addAll(steps);
        _handoverArtifacts
          ..clear()
          ..addAll(artifacts);
        _signOffs
          ..clear()
          ..addAll(signoffs);
      });
      _loadedEntries = true;
      if (_transitionSteps.isEmpty && _handoverArtifacts.isEmpty && _signOffs.isEmpty) {
        await _populateFromAi();
      }
    } catch (error) {
      debugPrint('Failed to load transition entries: $error');
    }
  }

  Future<void> _populateFromAi() async {
    if (_aiGenerated || _isGenerating) return;
    final projectData = ProjectDataHelper.getData(context);
    final contextText = ProjectDataHelper.buildFepContext(projectData, sectionLabel: 'Transition to Prod Team');
    if (contextText.trim().isEmpty) return;

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> generated = {};
    try {
      generated = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: contextText,
        sections: const {
          'transition_steps': 'Guided transition steps',
          'handover_artifacts': 'Handover artifacts & tools',
          'signoffs': 'Ops & client sign-offs',
        },
        itemsPerSection: 2,
      );
    } catch (error) {
      debugPrint('Transition to prod AI call failed: $error');
    }

    if (!mounted) return;
    if (_transitionSteps.isNotEmpty || _handoverArtifacts.isNotEmpty || _signOffs.isNotEmpty) {
      setState(() => _isGenerating = false);
      _aiGenerated = true;
      return;
    }

    setState(() {
      _transitionSteps
        ..clear()
        ..addAll(_mapEntries(generated['transition_steps']));
      _handoverArtifacts
        ..clear()
        ..addAll(_mapEntries(generated['handover_artifacts']));
      _signOffs
        ..clear()
        ..addAll(_mapEntries(generated['signoffs']));
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
      'transitionSteps': _transitionSteps.map((e) => e.toJson()).toList(),
      'handoverArtifacts': _handoverArtifacts.map((e) => e.toJson()).toList(),
      'signOffs': _signOffs.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('launch_phase')
        .doc('transition_to_prod_team')
        .set(payload, SetOptions(merge: true));
  }
}
