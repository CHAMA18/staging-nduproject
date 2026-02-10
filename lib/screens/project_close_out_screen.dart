import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ndu_project/screens/deliver_project_closure_screen.dart';
import 'package:ndu_project/screens/demobilize_team_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

class ProjectCloseOutScreen extends StatefulWidget {
  const ProjectCloseOutScreen({
    super.key,
    this.summarized = false,
    this.activeItemLabel = 'Project Close Out',
  });

  final bool summarized;
  final String activeItemLabel;

  static void open(
    BuildContext context, {
    bool summarized = false,
    String activeItemLabel = 'Project Close Out',
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectCloseOutScreen(
          summarized: summarized,
          activeItemLabel: activeItemLabel,
        ),
      ),
    );
  }

  @override
  State<ProjectCloseOutScreen> createState() => _ProjectCloseOutScreenState();
}

class _ProjectCloseOutScreenState extends State<ProjectCloseOutScreen> {
  final List<LaunchEntry> _closeOutChecklist = [];
  final List<LaunchEntry> _approvals = [];
  final List<LaunchEntry> _archive = [];
  late _CloseOutView _selectedView;
  bool _loadedEntries = false;
  bool _aiGenerated = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _selectedView = widget.summarized ? _CloseOutView.summarized : _CloseOutView.longForm;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: widget.activeItemLabel,
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(context, isMobile),
            const SizedBox(height: 20),
            if (_selectedView == _CloseOutView.longForm) ...[
              LaunchEditableSection(
                title: 'Close-out checklist',
                description: 'Add the tasks you need to finish before the project is closed.',
                entries: _closeOutChecklist,
                onAdd: () => _addEntry(_closeOutChecklist, titleLabel: 'Checklist item', includeStatus: true),
                onRemove: (index) => _removeEntry(_closeOutChecklist, index),
              ),
              LaunchEditableSection(
                title: 'Approvals & sign-off',
                description: 'Capture approvers, their roles, and confirmation status.',
                entries: _approvals,
                onAdd: () => _addEntry(_approvals, titleLabel: 'Approver', includeStatus: true),
                onRemove: (index) => _removeEntry(_approvals, index),
              ),
              LaunchEditableSection(
                title: 'Archive & access',
                description: 'List the repositories, documents, and access changes required.',
                entries: _archive,
                onAdd: () => _addEntry(_archive, titleLabel: 'Archive item'),
                onRemove: (index) => _removeEntry(_archive, index),
                showStatusChip: false,
              ),
            ] else ...[
              _CloseOutSummary(
                checklistCount: _closeOutChecklist.length,
                approvalCount: _approvals.length,
                archiveCount: _archive.length,
                approvals: _approvals,
                checklist: _closeOutChecklist,
                archive: _archive,
              ),
            ],
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: _selectedView == _CloseOutView.longForm ? 'Back: Demobilize Team' : 'Back: Close-out long form',
              nextLabel: _selectedView == _CloseOutView.longForm ? 'Next: Summarized Form' : 'Next: Deliver Project',
              onBack: _selectedView == _CloseOutView.longForm
                  ? () => DemobilizeTeamScreen.open(context)
                  : () => ProjectCloseOutScreen.open(
                        context,
                        summarized: false,
                        activeItemLabel: 'Project Close Out',
                      ),
              onNext: _selectedView == _CloseOutView.longForm
                  ? () => ProjectCloseOutScreen.open(
                        context,
                        summarized: true,
                        activeItemLabel: 'Project Close Out - Summarized Form',
                      )
                  : () => DeliverProjectClosureScreen.open(context),
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
          'PROJECT CLOSE OUT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Formally close the project and lock in the outcomes',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'No default content is pre-filled. Use the pop-ups in each section to capture the close-out data you need.',
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
          .doc('project_close_out')
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final checklist = (data['closeOutChecklist'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final approvals = (data['approvals'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final archive = (data['archive'] as List?)
                ?.whereType<Map>()
                .map((e) => LaunchEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        if (!mounted) return;
        setState(() {
          _closeOutChecklist
            ..clear()
            ..addAll(checklist);
          _approvals
            ..clear()
            ..addAll(approvals);
          _archive
            ..clear()
            ..addAll(archive);
        });
      }
      _loadedEntries = true;
      if (_closeOutChecklist.isEmpty && _approvals.isEmpty && _archive.isEmpty) {
        await _populateFromAi();
      }
    } catch (error) {
      debugPrint('Failed to load project close-out entries: $error');
    }
  }

  Future<void> _populateFromAi() async {
    if (_aiGenerated || _isGenerating) return;
    final projectData = ProjectDataHelper.getData(context);
    final contextText = ProjectDataHelper.buildFepContext(projectData, sectionLabel: 'Project Close Out');
    if (contextText.trim().isEmpty) return;

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> generated = {};
    try {
      generated = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: contextText,
        sections: const {
          'close_out_checklist': 'Close-out checklist',
          'approvals_signoff': 'Approvals & sign-off',
          'archive_access': 'Archive & access',
        },
        itemsPerSection: 2,
      );
    } catch (error) {
      debugPrint('Project close-out AI call failed: $error');
    }

    if (!mounted) return;
    if (_closeOutChecklist.isNotEmpty || _approvals.isNotEmpty || _archive.isNotEmpty) {
      setState(() => _isGenerating = false);
      _aiGenerated = true;
      return;
    }

    setState(() {
      _closeOutChecklist
        ..clear()
        ..addAll(_mapEntries(generated['close_out_checklist']));
      _approvals
        ..clear()
        ..addAll(_mapEntries(generated['approvals_signoff']));
      _archive
        ..clear()
        ..addAll(_mapEntries(generated['archive_access']));
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
      'closeOutChecklist': _closeOutChecklist.map((e) => e.toJson()).toList(),
      'approvals': _approvals.map((e) => e.toJson()).toList(),
      'archive': _archive.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('launch_phase')
        .doc('project_close_out')
        .set(payload, SetOptions(merge: true));
  }
}

enum _CloseOutView { longForm, summarized }

// ignore: unused_element
class _CloseOutNavItem extends StatelessWidget {
  const _CloseOutNavItem({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseOutSummary extends StatelessWidget {
  const _CloseOutSummary({
    required this.checklistCount,
    required this.approvalCount,
    required this.archiveCount,
    required this.approvals,
    required this.checklist,
    required this.archive,
  });

  final int checklistCount;
  final int approvalCount;
  final int archiveCount;
  final List<LaunchEntry> approvals;
  final List<LaunchEntry> checklist;
  final List<LaunchEntry> archive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryMetrics(
          checklistCount: checklistCount,
          approvalCount: approvalCount,
          archiveCount: archiveCount,
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          title: 'Close-out Highlights',
          subtitle: 'Top tasks and blockers for close-out readiness.',
          items: _buildSummaryItems(checklist, fallback: 'No checklist items captured yet.'),
        ),
        _SummaryCard(
          title: 'Approvals Snapshot',
          subtitle: 'Latest sign-off entries and statuses.',
          items: _buildSummaryItems(approvals, fallback: 'No approvers captured yet.'),
        ),
        _SummaryCard(
          title: 'Archive & Access',
          subtitle: 'Systems and documents queued for archive.',
          items: _buildSummaryItems(archive, fallback: 'No archive items captured yet.'),
        ),
      ],
    );
  }

  List<String> _buildSummaryItems(List<LaunchEntry> entries, {required String fallback}) {
    if (entries.isEmpty) {
      return [fallback];
    }
    return entries.take(3).map((e) {
      final details = e.details.trim();
      if (details.isEmpty) return e.title;
      return '${e.title} — $details';
    }).toList();
  }
}

class _SummaryMetrics extends StatelessWidget {
  const _SummaryMetrics({
    required this.checklistCount,
    required this.approvalCount,
    required this.archiveCount,
  });

  final int checklistCount;
  final int approvalCount;
  final int archiveCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryMetricCard(
          label: 'Checklist Items',
          value: '$checklistCount',
          color: const Color(0xFF2563EB),
        ),
        _SummaryMetricCard(
          label: 'Approvals',
          value: '$approvalCount',
          color: const Color(0xFF10B981),
        ),
        _SummaryMetricCard(
          label: 'Archive Items',
          value: '$archiveCount',
          color: const Color(0xFFF59E0B),
        ),
      ],
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.subtitle, required this.items});

  final String title;
  final String subtitle;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
