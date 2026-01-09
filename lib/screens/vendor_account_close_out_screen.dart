import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ndu_project/screens/contract_close_out_screen.dart';
import 'package:ndu_project/screens/summarize_account_risks_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

class VendorAccountCloseOutScreen extends StatefulWidget {
  const VendorAccountCloseOutScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VendorAccountCloseOutScreen()),
    );
  }

  @override
  State<VendorAccountCloseOutScreen> createState() => _VendorAccountCloseOutScreenState();
}

class _VendorAccountCloseOutScreenState extends State<VendorAccountCloseOutScreen> {
  final List<LaunchEntry> _snapshot = [];
  final List<LaunchEntry> _steps = [];
  final List<LaunchEntry> _vendors = [];
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Vendor Account Close Out'),
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
                          title: 'Vendor close-out snapshot',
                          description: 'Add counts, notes, or status items that matter to your vendor close-out.',
                          entries: _snapshot,
                          onAdd: () => _addEntry(_snapshot, titleLabel: 'Snapshot item', includeStatus: true),
                          onRemove: (index) => _removeEntry(_snapshot, index),
                        ),
                        LaunchEditableSection(
                          title: 'Guided steps',
                          description: 'Capture the sequence you will run to close vendor accounts.',
                          entries: _steps,
                          onAdd: () => _addEntry(_steps, titleLabel: 'Step', includeStatus: true),
                          onRemove: (index) => _removeEntry(_steps, index),
                        ),
                        LaunchEditableSection(
                          title: 'Vendors requiring attention',
                          description: 'List vendors with outstanding actions or risks.',
                          entries: _vendors,
                          onAdd: () => _addEntry(_vendors, titleLabel: 'Vendor', includeStatus: true),
                          onRemove: (index) => _removeEntry(_vendors, index),
                        ),
                        LaunchEditableSection(
                          title: 'Access & sign-off',
                          description: 'Track access removals, ownership, and required approvals.',
                          entries: _signOffs,
                          onAdd: () => _addEntry(_signOffs, titleLabel: 'Approver or action', includeStatus: true),
                          onRemove: (index) => _removeEntry(_signOffs, index),
                        ),
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel: 'Back: Contract Close Out',
                          nextLabel: 'Next: Project Summary',
                          onBack: () => ContractCloseOutScreen.open(context),
                          onNext: () => SummarizeAccountRisksScreen.open(context),
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
          'Vendor Account Close Out · Guided flow',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'The sections below now start empty. Use the pop-ups to add vendors, steps, and approvals as you work.',
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
          .doc('vendor_account_close_out')
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final snapshot = (data['snapshot'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final steps = (data['steps'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final vendors = (data['vendors'] as List?)
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
          _snapshot
            ..clear()
            ..addAll(snapshot);
          _steps
            ..clear()
            ..addAll(steps);
          _vendors
            ..clear()
            ..addAll(vendors);
          _signOffs
            ..clear()
            ..addAll(signoffs);
        });
      }
      _loadedEntries = true;
      if (_snapshot.isEmpty && _steps.isEmpty && _vendors.isEmpty && _signOffs.isEmpty) {
        await _populateFromAi();
      }
    } catch (error) {
      debugPrint('Failed to load vendor close-out entries: $error');
    }
  }

  Future<void> _populateFromAi() async {
    if (_aiGenerated || _isGenerating) return;
    final projectData = ProjectDataHelper.getData(context);
    final contextText = ProjectDataHelper.buildFepContext(projectData, sectionLabel: 'Vendor Account Close Out');
    if (contextText.trim().isEmpty) return;

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> generated = {};
    try {
      generated = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: contextText,
        sections: const {
          'vendor_snapshot': 'Vendor close-out snapshot',
          'guided_steps': 'Guided steps',
          'vendors_attention': 'Vendors requiring attention',
          'access_signoff': 'Access & sign-off',
        },
        itemsPerSection: 2,
      );
    } catch (error) {
      debugPrint('Vendor close-out AI call failed: $error');
    }

    if (!mounted) return;
    if (_snapshot.isNotEmpty || _steps.isNotEmpty || _vendors.isNotEmpty || _signOffs.isNotEmpty) {
      setState(() => _isGenerating = false);
      _aiGenerated = true;
      return;
    }

    setState(() {
      _snapshot
        ..clear()
        ..addAll(_mapEntries(generated['vendor_snapshot']));
      _steps
        ..clear()
        ..addAll(_mapEntries(generated['guided_steps']));
      _vendors
        ..clear()
        ..addAll(_mapEntries(generated['vendors_attention']));
      _signOffs
        ..clear()
        ..addAll(_mapEntries(generated['access_signoff']));
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
      'snapshot': _snapshot.map((e) => e.toJson()).toList(),
      'steps': _steps.map((e) => e.toJson()).toList(),
      'vendors': _vendors.map((e) => e.toJson()).toList(),
      'signOffs': _signOffs.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('launch_phase')
        .doc('vendor_account_close_out')
        .set(payload, SetOptions(merge: true));
  }
}
