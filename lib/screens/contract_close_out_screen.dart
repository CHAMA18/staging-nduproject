import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ndu_project/screens/transition_to_prod_team_screen.dart';
import 'package:ndu_project/screens/vendor_account_close_out_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

class ContractCloseOutScreen extends StatefulWidget {
  const ContractCloseOutScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContractCloseOutScreen()),
    );
  }

  @override
  State<ContractCloseOutScreen> createState() => _ContractCloseOutScreenState();
}

class _ContractCloseOutScreenState extends State<ContractCloseOutScreen> {
  final List<LaunchEntry> _summary = [];
  final List<LaunchEntry> _steps = [];
  final List<LaunchEntry> _contracts = [];
  final List<LaunchEntry> _signoffs = [];
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Contract Close Out'),
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
                          title: 'Close-out summary',
                          description: 'Add the headline status and metrics you want to track—no defaults are pre-filled.',
                          entries: _summary,
                          onAdd: () => _addEntry(_summary, titleLabel: 'Summary item', includeStatus: true),
                          onRemove: (index) => _removeEntry(_summary, index),
                        ),
                        LaunchEditableSection(
                          title: 'Guided close-out steps',
                          description: 'Capture the steps you will follow to close contracts.',
                          entries: _steps,
                          onAdd: () => _addEntry(_steps, titleLabel: 'Step', includeStatus: true),
                          onRemove: (index) => _removeEntry(_steps, index),
                        ),
                        LaunchEditableSection(
                          title: 'Contracts needing attention',
                          description: 'List contracts or vendors with notes and status.',
                          entries: _contracts,
                          onAdd: () => _addEntry(_contracts, titleLabel: 'Contract or vendor', includeStatus: true),
                          onRemove: (index) => _removeEntry(_contracts, index),
                        ),
                        LaunchEditableSection(
                          title: 'Financial & compliance sign-off',
                          description: 'Track who needs to sign and the state of finance/compliance items.',
                          entries: _signoffs,
                          onAdd: () => _addEntry(_signoffs, titleLabel: 'Approver', includeStatus: true),
                          onRemove: (index) => _removeEntry(_signoffs, index),
                        ),
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel: 'Back: Transition To Production Team',
                          nextLabel: 'Next: Vendor Account Close Out',
                          onBack: () => TransitionToProdTeamScreen.open(context),
                          onNext: () => VendorAccountCloseOutScreen.open(context),
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
          'Contract Close Out · Guided flow',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Launch-phase pages are now empty by default. Use the add buttons to populate each section through pop-ups.',
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
          .doc('contract_close_out')
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
      final steps = (data['steps'] as List?)
              ?.whereType<Map>()
              .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      final contracts = (data['contracts'] as List?)
              ?.whereType<Map>()
              .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      final signoffs = (data['signoffs'] as List?)
              ?.whereType<Map>()
              .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [];
      if (!mounted) return;
      setState(() {
        _summary
          ..clear()
          ..addAll(summary);
        _steps
          ..clear()
          ..addAll(steps);
        _contracts
          ..clear()
          ..addAll(contracts);
        _signoffs
          ..clear()
          ..addAll(signoffs);
      });
      _loadedEntries = true;
      if (_summary.isEmpty && _steps.isEmpty && _contracts.isEmpty && _signoffs.isEmpty) {
        await _populateFromAi();
      }
    } catch (error) {
      debugPrint('Failed to load contract close-out entries: $error');
    }
  }

  Future<void> _populateFromAi() async {
    if (_aiGenerated || _isGenerating) return;
    final projectData = ProjectDataHelper.getData(context);
    final contextText = ProjectDataHelper.buildFepContext(projectData, sectionLabel: 'Contract Close Out');
    if (contextText.trim().isEmpty) return;

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> generated = {};
    try {
      generated = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: contextText,
        sections: const {
          'closeout_summary': 'Close-out summary',
          'closeout_steps': 'Guided close-out steps',
          'contracts_attention': 'Contracts needing attention',
          'closeout_signoff': 'Financial & compliance sign-off',
        },
        itemsPerSection: 2,
      );
    } catch (error) {
      debugPrint('Contract close-out AI call failed: $error');
    }

    if (!mounted) return;
    if (_summary.isNotEmpty || _steps.isNotEmpty || _contracts.isNotEmpty || _signoffs.isNotEmpty) {
      setState(() => _isGenerating = false);
      _aiGenerated = true;
      return;
    }

    setState(() {
      _summary
        ..clear()
        ..addAll(_mapEntries(generated['closeout_summary']));
      _steps
        ..clear()
        ..addAll(_mapEntries(generated['closeout_steps']));
      _contracts
        ..clear()
        ..addAll(_mapEntries(generated['contracts_attention']));
      _signoffs
        ..clear()
        ..addAll(_mapEntries(generated['closeout_signoff']));
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
      'steps': _steps.map((e) => e.toJson()).toList(),
      'contracts': _contracts.map((e) => e.toJson()).toList(),
      'signoffs': _signoffs.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('launch_phase')
        .doc('contract_close_out')
        .set(payload, SetOptions(merge: true));
  }
}
