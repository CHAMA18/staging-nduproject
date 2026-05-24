import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/screens/risk_tracking_workspace_screen.dart';
import 'package:ndu_project/screens/update_ops_maintenance_plans_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/utils/execution_phase_ai_seed.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';

import 'package:ndu_project/widgets/voice_text_field.dart';
import 'package:ndu_project/widgets/launch_data_table.dart';
class LaunchChecklistScreen extends StatefulWidget {
  const LaunchChecklistScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LaunchChecklistScreen()),
    );
  }

  @override
  State<LaunchChecklistScreen> createState() => _LaunchChecklistScreenState();
}

class _LaunchChecklistScreenState extends State<LaunchChecklistScreen> {
  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;
  bool _autoGenerationTriggered = false;
  bool _isAutoGenerating = false;

  List<_ChecklistItemData> _checklistItems = [];
  List<_ApprovalData> _approvals = [];
  List<_MilestoneData> _milestones = [];
  List<_TimelineStage> _timelineStages = [];

  String _coordinatorName = '';
  String _coordinatorRole = '';
  String _coordinatorEmail = '';
  String _coordinatorPhone = '';

  @override
  void initState() {
    super.initState();
    _checklistItems = _defaultChecklistItems();
    _approvals = _defaultApprovals();
    _milestones = _defaultMilestones();
    _timelineStages = _defaultTimelineStages();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    if (_suspendSave) return;
    _saveDebouncer.run(_saveToFirestore);
  }

  Future<void> _loadFromFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('launch_checklist')
          .get();
      final data = doc.data() ?? {};

      final checklist = _ChecklistItemData.fromList(data['checklistItems']);
      final approvals = _ApprovalData.fromList(data['approvals']);
      final milestones = _MilestoneData.fromList(data['milestones']);
      final stages = _TimelineStage.fromList(data['timelineStages']);

      final hasContent = checklist.isNotEmpty ||
          approvals.isNotEmpty ||
          milestones.isNotEmpty ||
          stages.isNotEmpty;

      _suspendSave = true;
      if (!mounted) return;
      setState(() {
        _checklistItems = checklist.isEmpty ? _defaultChecklistItems() : checklist;
        _approvals = approvals.isEmpty ? _defaultApprovals() : approvals;
        _milestones = milestones.isEmpty ? _defaultMilestones() : milestones;
        _timelineStages = stages.isEmpty ? _defaultTimelineStages() : stages;

        final coordinator = Map<String, dynamic>.from(data['coordinator'] as Map? ?? {});
        _coordinatorName = coordinator['name']?.toString() ?? '';
        _coordinatorRole = coordinator['role']?.toString() ?? '';
        _coordinatorEmail = coordinator['email']?.toString() ?? '';
        _coordinatorPhone = coordinator['phone']?.toString() ?? '';
      });
      _suspendSave = false;

      if (!hasContent) {
        await _autoGenerateIfNeeded();
      }
    } catch (error) {
      debugPrint('Launch checklist load error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _autoGenerateIfNeeded() async {
    if (!mounted || _autoGenerationTriggered || _isAutoGenerating) return;
    _autoGenerationTriggered = true;
    _isAutoGenerating = true;
    try {
      final generated = await ExecutionPhaseAiSeed.generateEntries(
        context: context,
        section: 'Launch Checklist',
        sections: const {
          'checklist_items': 'Launch checklist action items with owners and due',
          'approvals': 'Approvals and sign-offs required',
          'milestones': 'Key launch milestones with due dates',
          'timeline_stages': 'Timeline stages toward go-live',
        },
        itemsPerSection: 3,
      );

      final checklist = generated['checklist_items'] ?? const [];
      final approvals = generated['approvals'] ?? const [];
      final milestones = generated['milestones'] ?? const [];
      final stages = generated['timeline_stages'] ?? const [];

      if (checklist.isNotEmpty) {
        _checklistItems = _mapChecklistItems(checklist);
      }
      if (approvals.isNotEmpty) {
        _approvals = _mapApprovals(approvals);
      }
      if (milestones.isNotEmpty) {
        _milestones = _mapMilestones(milestones);
      }
      if (stages.isNotEmpty) {
        _timelineStages = _mapTimelineStages(stages);
      }

      if (mounted) {
        setState(() {});
        await _saveToFirestore();
      }
    } catch (e) {
      debugPrint('Error auto-generating launch checklist data: $e');
    } finally {
      _isAutoGenerating = false;
    }
  }

  List<_ChecklistItemData> _mapChecklistItems(List<LaunchEntry> entries) {
    return entries.map((entry) => _ChecklistItemData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: entry.title,
      detail: entry.details,
      owner: _extractField(entry.details, 'Owner'),
      due: _extractField(entry.details, 'Due'),
      status: entry.status ?? 'Pending',
    )).toList();
  }

  List<_ApprovalData> _mapApprovals(List<LaunchEntry> entries) {
    return entries.map((entry) => _ApprovalData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: entry.title,
      detail: entry.details,
      status: entry.status ?? 'Pending',
      approver: _extractField(entry.details, 'Approver'),
    )).toList();
  }

  List<_MilestoneData> _mapMilestones(List<LaunchEntry> entries) {
    return entries.map((entry) => _MilestoneData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: entry.title,
      detail: entry.details,
      due: _extractField(entry.details, 'Due'),
      status: entry.status ?? 'Upcoming',
    )).toList();
  }

  List<_TimelineStage> _mapTimelineStages(List<LaunchEntry> entries) {
    return entries.map((entry) => _TimelineStage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: entry.title,
      detail: entry.details,
      date: _extractField(entry.details, 'Date'),
      status: entry.status ?? 'Upcoming',
    )).toList();
  }

  String _extractField(String text, String key) {
    final match = RegExp('$key\\s*[:=-]\\s*([^|;\\n]+)', caseSensitive: false).firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  Future<void> _saveToFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('launch_checklist')
          .set({
        'checklistItems': _checklistItems.map((e) => e.toMap()).toList(),
        'approvals': _approvals.map((e) => e.toMap()).toList(),
        'milestones': _milestones.map((e) => e.toMap()).toList(),
        'timelineStages': _timelineStages.map((e) => e.toMap()).toList(),
        'coordinator': {
          'name': _coordinatorName,
          'role': _coordinatorRole,
          'email': _coordinatorEmail,
          'phone': _coordinatorPhone,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Launch checklist save error: $error');
    }
  }

  // Defaults
  List<_ChecklistItemData> _defaultChecklistItems() => [
    _ChecklistItemData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'Cutover rehearsals signed off',
      detail: 'Dry run #2 captured follow-up items',
      owner: 'Operations lead',
      due: 'Aug 12',
      status: 'Complete',
    ),
    _ChecklistItemData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'Rollback playbook distributed',
      detail: 'Share final rollback guide with war room',
      owner: 'Program manager',
      due: 'Aug 09',
      status: 'At risk',
    ),
    _ChecklistItemData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'Hypercare squad roster confirmed',
      detail: 'Roster, shifts, and bridge details communicated',
      owner: 'Launch director',
      due: 'Aug 15',
      status: 'On track',
    ),
    _ChecklistItemData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'Customer comms final approval',
      detail: 'Exec sign-off on launch narratives',
      owner: 'Comms lead',
      due: 'Aug 14',
      status: 'In review',
    ),
  ];

  List<_ApprovalData> _defaultApprovals() => [
    _ApprovalData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: 'Cutover rehearsal sign-off',
      detail: 'Delivery, platform, and ops leads approved',
      status: 'Complete',
      approver: 'Ops Director',
    ),
    _ApprovalData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: 'Business readiness validation',
      detail: 'Support staffing matrix ready',
      status: 'Complete',
      approver: 'Business Owner',
    ),
    _ApprovalData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: 'Comms go-live bundle',
      detail: 'Legal + comms reviewing final messaging',
      status: 'In review',
      approver: 'Legal Counsel',
    ),
  ];

  List<_MilestoneData> _defaultMilestones() => [
    _MilestoneData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'Cutover rehearsal playback',
      detail: 'Ops + Engineering walk-through',
      due: 'Aug 09',
      status: 'Complete',
    ),
    _MilestoneData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'Go / no-go rehearsal',
      detail: 'Dry run with scenario walk-through',
      due: 'Aug 11',
      status: 'Upcoming',
    ),
    _MilestoneData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'Launch day',
      detail: 'Go-live execution',
      due: 'Aug 18',
      status: 'Upcoming',
    ),
  ];

  List<_TimelineStage> _defaultTimelineStages() => [
    _TimelineStage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: 'Final readiness review',
      detail: 'All cutover artefacts verified',
      date: 'Aug 10',
      status: 'Complete',
    ),
    _TimelineStage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: 'Go / no-go rehearsal',
      detail: 'Dry run with escalation practices',
      date: 'Aug 11',
      status: 'In progress',
    ),
    _TimelineStage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      label: 'Launch day execution',
      detail: 'Go-live cutover',
      date: 'Aug 18',
      status: 'Upcoming',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final double hPad = isMobile ? 20 : 40;
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            if (isMobile)
              _buildMobileLayout(hPad, projectId)
            else
              _buildDesktopLayout(hPad, projectId),
            MobileSidebarHamburger(
                      sidebar: const InitiationLikeSidebar(
                        activeItemLabel: 'Launch Checklist',
                      ),
                    ),
                    const KazAiChatBubble(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(double hPad, String? projectId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DraggableSidebar(
          openWidth: AppBreakpoints.sidebarWidth(context),
          child: const InitiationLikeSidebar(
              activeItemLabel: 'Launch Checklist'),
        ),
        Expanded(child: _buildScrollContent(hPad, projectId)),
      ],
    );
  }

  Widget _buildMobileLayout(double hPad, String? projectId) {
    return _buildScrollContent(hPad, projectId);
  }

  Widget _buildScrollContent(double hPad, String? projectId) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PlanningPhaseHeader(
            title: 'Launch Checklist',
            showImportButton: false,
            showContentButton: false,
            showNavigationButtons: false,
          ),
          const SizedBox(height: 32),
          _buildSectionIntro(),
          const SizedBox(height: 28),
          if (_isLoading) ...[
            const Center(
                child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
          ] else ...[
            _buildChecklistSection(),
            const SizedBox(height: 28),
            _buildApprovalsSection(),
            const SizedBox(height: 28),
            _buildMilestonesSection(),
            const SizedBox(height: 28),
            _buildTimelineSection(),
          ],
          const SizedBox(height: 36),
          _buildBottomActionBar(),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  Widget _buildSectionIntro() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.checklist_rounded,
              size: 22, color: Color(0xFF4338CA)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Launch Readiness Checklist',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Track cutover tasks, approvals, and milestones before go-live.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: LaunchPhaseNavigation(
        backLabel: 'Back: Update Ops & Maintenance Plans',
        nextLabel: 'Next: Risk Tracking',
        onBack: () => UpdateOpsMaintenancePlansScreen.open(context),
        onNext: () => RiskTrackingWorkspaceScreen.open(context),
      ),
    );
  }

  Widget _buildChecklistSection() {
    return LaunchDataTable(
      title: 'Launch Checklist',
      subtitle: 'Critical action items with owners and due dates',
      columns: const ['Task', 'Detail', 'Owner', 'Due', 'Status'],
      rowCount: _checklistItems.length,
      onAdd: _addChecklistItem,
      addLabel: 'Add checklist item',
      emptyMessage: 'No checklist items yet. Add critical action items before go-live.',
      cellBuilder: (context, i) {
        final item = _checklistItems[i];
        return LaunchDataRow(
          onDelete: () => _deleteChecklistItem(item.id),
          showDivider: i < _checklistItems.length - 1,
          cells: [
            LaunchEditableCell(
              value: item.title,
              hint: 'Task',
              bold: true,
              expand: true,
              onChanged: (v) {
                _checklistItems[i] = _ChecklistItemData(
                  id: item.id, title: v, detail: item.detail,
                  owner: item.owner, due: item.due, status: item.status,
                );
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.detail,
              hint: 'Detail',
              expand: true,
              onChanged: (v) {
                _checklistItems[i] = _ChecklistItemData(
                  id: item.id, title: item.title, detail: v,
                  owner: item.owner, due: item.due, status: item.status,
                );
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.owner,
              hint: 'Owner',
              expand: true,
              onChanged: (v) {
                _checklistItems[i] = _ChecklistItemData(
                  id: item.id, title: item.title, detail: item.detail,
                  owner: v, due: item.due, status: item.status,
                );
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.due,
              hint: 'Due',
              width: 100,
              onChanged: (v) {
                _checklistItems[i] = _ChecklistItemData(
                  id: item.id, title: item.title, detail: item.detail,
                  owner: item.owner, due: v, status: item.status,
                );
                _scheduleSave();
              },
            ),
            LaunchStatusDropdown(
              value: item.status,
              items: const ['Complete', 'On track', 'At risk', 'In review', 'Pending'],
              onChanged: (v) {
                if (v == null) return;
                _checklistItems[i] = _ChecklistItemData(
                  id: item.id, title: item.title, detail: item.detail,
                  owner: item.owner, due: item.due, status: v,
                );
                _scheduleSave();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildApprovalsSection() {
    return LaunchDataTable(
      title: 'Approvals & Sign-offs',
      subtitle: 'Required approvals before go-live',
      columns: const ['Approval', 'Detail', 'Approver', 'Status'],
      rowCount: _approvals.length,
      onAdd: _addApproval,
      addLabel: 'Add approval',
      emptyMessage: 'No approvals yet. Track required sign-offs before launch.',
      cellBuilder: (context, i) {
        final item = _approvals[i];
        return LaunchDataRow(
          onDelete: () => _deleteApproval(item.id),
          showDivider: i < _approvals.length - 1,
          cells: [
            LaunchEditableCell(
              value: item.label,
              hint: 'Approval',
              bold: true,
              expand: true,
              onChanged: (v) {
                _approvals[i] = _ApprovalData(
                  id: item.id, label: v, detail: item.detail,
                  status: item.status, approver: item.approver,
                );
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.detail,
              hint: 'Detail',
              expand: true,
              onChanged: (v) {
                _approvals[i] = _ApprovalData(
                  id: item.id, label: item.label, detail: v,
                  status: item.status, approver: item.approver,
                );
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.approver,
              hint: 'Approver',
              expand: true,
              onChanged: (v) {
                _approvals[i] = _ApprovalData(
                  id: item.id, label: item.label, detail: item.detail,
                  status: item.status, approver: v,
                );
                _scheduleSave();
              },
            ),
            LaunchStatusDropdown(
              value: item.status,
              items: const ['Complete', 'In review', 'Pending'],
              onChanged: (v) {
                if (v == null) return;
                _approvals[i] = _ApprovalData(
                  id: item.id, label: item.label, detail: item.detail,
                  status: v, approver: item.approver,
                );
                _scheduleSave();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMilestonesSection() {
    return LaunchDataTable(
      title: 'Launch Milestones',
      subtitle: 'Key milestones leading to go-live',
      columns: const ['Milestone', 'Detail', 'Due', 'Status'],
      rowCount: _milestones.length,
      onAdd: _addMilestone,
      addLabel: 'Add milestone',
      emptyMessage: 'No milestones yet. Add key milestones leading to go-live.',
      cellBuilder: (context, i) {
        final item = _milestones[i];
        return LaunchDataRow(
          onDelete: () => _deleteMilestone(item.id),
          showDivider: i < _milestones.length - 1,
          cells: [
            LaunchEditableCell(
              value: item.title,
              hint: 'Milestone',
              bold: true,
              expand: true,
              onChanged: (v) {
                _milestones[i] = _MilestoneData(
                  id: item.id, title: v, detail: item.detail,
                  due: item.due, status: item.status,
                );
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.detail,
              hint: 'Detail',
              expand: true,
              onChanged: (v) {
                _milestones[i] = _MilestoneData(
                  id: item.id, title: item.title, detail: v,
                  due: item.due, status: item.status,
                );
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: item.due,
              hint: 'Due',
              width: 100,
              onChanged: (v) {
                _milestones[i] = _MilestoneData(
                  id: item.id, title: item.title, detail: item.detail,
                  due: v, status: item.status,
                );
                _scheduleSave();
              },
            ),
            LaunchStatusDropdown(
              value: item.status,
              items: const ['Complete', 'Upcoming', 'In progress', 'Delayed'],
              onChanged: (v) {
                if (v == null) return;
                _milestones[i] = _MilestoneData(
                  id: item.id, title: item.title, detail: item.detail,
                  due: item.due, status: v,
                );
                _scheduleSave();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimelineSection() {
    return LaunchDataTable(
      title: 'Launch Timeline',
      subtitle: 'Timeline stages toward go-live',
      columns: const ['Stage', 'Detail', 'Date', 'Status'],
      rowCount: _timelineStages.length,
      onAdd: _addTimelineStage,
      addLabel: 'Add stage',
      emptyMessage: 'No timeline stages yet. Add stages leading to go-live.',
      cellBuilder: (context, i) {
        final stage = _timelineStages[i];
        return LaunchDataRow(
          onDelete: () => _deleteTimelineStage(stage.id),
          showDivider: i < _timelineStages.length - 1,
          cells: [
            LaunchEditableCell(
              value: stage.label,
              hint: 'Stage',
              bold: true,
              expand: true,
              onChanged: (v) {
                _timelineStages[i] = _TimelineStage(
                  id: stage.id, label: v, detail: stage.detail,
                  date: stage.date, status: stage.status,
                );
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: stage.detail,
              hint: 'Detail',
              expand: true,
              onChanged: (v) {
                _timelineStages[i] = _TimelineStage(
                  id: stage.id, label: stage.label, detail: v,
                  date: stage.date, status: stage.status,
                );
                _scheduleSave();
              },
            ),
            LaunchEditableCell(
              value: stage.date,
              hint: 'Date',
              width: 100,
              onChanged: (v) {
                _timelineStages[i] = _TimelineStage(
                  id: stage.id, label: stage.label, detail: stage.detail,
                  date: v, status: stage.status,
                );
                _scheduleSave();
              },
            ),
            LaunchStatusDropdown(
              value: stage.status,
              items: const ['Complete', 'In progress', 'Upcoming', 'Delayed'],
              onChanged: (v) {
                if (v == null) return;
                _timelineStages[i] = _TimelineStage(
                  id: stage.id, label: stage.label, detail: stage.detail,
                  date: stage.date, status: v,
                );
                _scheduleSave();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('complete') || normalized.contains('done')) return const Color(0xFF10B981);
    if (normalized.contains('risk') || normalized.contains('block')) return const Color(0xFFEF4444);
    if (normalized.contains('review') || normalized.contains('pending')) return const Color(0xFFF59E0B);
    if (normalized.contains('progress')) return const Color(0xFF6366F1);
    return const Color(0xFF6B7280);
  }

  // Edit Dialogs
  Future<void> _editChecklistItem(_ChecklistItemData item) async {
    final titleController = TextEditingController(text: item.title);
    final detailController = TextEditingController(text: item.detail);
    final ownerController = TextEditingController(text: item.owner);
    final dueController = TextEditingController(text: item.due);
    String status = item.status;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.checklist_rounded,
                          color: Color(0xFF6366F1), size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit checklist item',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text('Update checklist item details.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                VoiceTextFormField(
                  controller: titleController,
                  decoration: _dialogDecoration('Title'),
                ),
                const SizedBox(height: 12),
                VoiceTextFormField(
                  controller: detailController,
                  decoration: _dialogDecoration('Details'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: VoiceTextFormField(
                      controller: ownerController,
                      decoration: _dialogDecoration('Owner'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: VoiceTextFormField(
                      controller: dueController,
                      decoration: _dialogDecoration('Due date'),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: ['Complete', 'On track', 'At risk', 'In review', 'Pending']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  decoration: _dialogDecoration('Status'),
                  onChanged: (v) => status = v ?? status,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() => _checklistItems[_checklistItems.indexWhere((i) => i.id == item.id)] =
                            item.copyWith(
                              title: titleController.text.trim(),
                              detail: detailController.text.trim(),
                              owner: ownerController.text.trim(),
                              due: dueController.text.trim(),
                              status: status,
                            ));
                        _scheduleSave();
                        Navigator.of(dialogContext).pop();
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editApproval(_ApprovalData item) async {
    final labelController = TextEditingController(text: item.label);
    final detailController = TextEditingController(text: item.detail);
    final approverController = TextEditingController(text: item.approver);
    String status = item.status;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setDialog) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.approval_rounded,
                            color: Color(0xFF10B981), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit approval',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Update approval details.',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  VoiceTextFormField(
                    controller: labelController,
                    decoration: _dialogDecoration('Approval name'),
                  ),
                  const SizedBox(height: 12),
                  VoiceTextFormField(
                    controller: detailController,
                    decoration: _dialogDecoration('Details'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  VoiceTextFormField(
                    controller: approverController,
                    decoration: _dialogDecoration('Approver'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    items: ['Complete', 'In review', 'Pending']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    decoration: _dialogDecoration('Status'),
                    onChanged: (v) => setDialog(() => status = v ?? status),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() => _approvals[_approvals.indexWhere((i) => i.id == item.id)] =
                              item.copyWith(
                                label: labelController.text.trim(),
                                detail: detailController.text.trim(),
                                approver: approverController.text.trim(),
                                status: status,
                              ));
                          _scheduleSave();
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editMilestone(_MilestoneData item) async {
    final titleController = TextEditingController(text: item.title);
    final detailController = TextEditingController(text: item.detail);
    final dueController = TextEditingController(text: item.due);
    String status = item.status;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setDialog) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.flag_rounded,
                            color: Color(0xFFF59E0B), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit milestone',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Update milestone details.',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  VoiceTextFormField(
                    controller: titleController,
                    decoration: _dialogDecoration('Milestone title'),
                  ),
                  const SizedBox(height: 12),
                  VoiceTextFormField(
                    controller: detailController,
                    decoration: _dialogDecoration('Details'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  VoiceTextFormField(
                    controller: dueController,
                    decoration: _dialogDecoration('Due date'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    items: ['Complete', 'Upcoming', 'In progress', 'At risk']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    decoration: _dialogDecoration('Status'),
                    onChanged: (v) => setDialog(() => status = v ?? status),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() => _milestones[_milestones.indexWhere((i) => i.id == item.id)] =
                              item.copyWith(
                                title: titleController.text.trim(),
                                detail: detailController.text.trim(),
                                due: dueController.text.trim(),
                                status: status,
                              ));
                          _scheduleSave();
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editTimelineStage(_TimelineStage item) async {
    final labelController = TextEditingController(text: item.label);
    final detailController = TextEditingController(text: item.detail);
    final dateController = TextEditingController(text: item.date);
    String status = item.status;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setDialog) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.timeline_rounded,
                            color: Color(0xFF0EA5E9), size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Edit timeline stage',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Update stage details.',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  VoiceTextFormField(
                    controller: labelController,
                    decoration: _dialogDecoration('Stage label'),
                  ),
                  const SizedBox(height: 12),
                  VoiceTextFormField(
                    controller: detailController,
                    decoration: _dialogDecoration('Details'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  VoiceTextFormField(
                    controller: dateController,
                    decoration: _dialogDecoration('Date'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    items: ['Complete', 'In progress', 'Upcoming']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    decoration: _dialogDecoration('Status'),
                    onChanged: (v) => setDialog(() => status = v ?? status),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          setState(() => _timelineStages[_timelineStages.indexWhere((i) => i.id == item.id)] =
                              item.copyWith(
                                label: labelController.text.trim(),
                                detail: detailController.text.trim(),
                                date: dateController.text.trim(),
                                status: status,
                              ));
                          _scheduleSave();
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Save'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dialogDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
    );
  }

  // Add methods
  void _addChecklistItem() {
    setState(() {
      _checklistItems.add(_ChecklistItemData(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'New checklist item',
        detail: 'Add details...',
        owner: 'Owner TBD',
        due: 'TBD',
        status: 'Pending',
      ));
    });
    _scheduleSave();
  }

  void _deleteChecklistItem(String id) {
    setState(() => _checklistItems.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addApproval() {
    setState(() {
      _approvals.add(_ApprovalData(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: 'New approval',
        detail: 'Add details...',
        status: 'Pending',
        approver: 'Approver TBD',
      ));
    });
    _scheduleSave();
  }

  void _deleteApproval(String id) {
    setState(() => _approvals.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addMilestone() {
    setState(() {
      _milestones.add(_MilestoneData(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'New milestone',
        detail: 'Add details...',
        due: 'TBD',
        status: 'Upcoming',
      ));
    });
    _scheduleSave();
  }

  void _deleteMilestone(String id) {
    setState(() => _milestones.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addTimelineStage() {
    setState(() {
      _timelineStages.add(_TimelineStage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        label: 'New stage',
        detail: 'Add details...',
        date: 'TBD',
        status: 'Upcoming',
      ));
    });
    _scheduleSave();
  }

  void _deleteTimelineStage(String id) {
    setState(() => _timelineStages.removeWhere((item) => item.id == id));
    _scheduleSave();
  }
}

// Shared Widgets

class _Debouncer {
  _Debouncer({Duration? delay}) : delay = delay ?? const Duration(milliseconds: 600);
  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

// Data Models
class _ChecklistItemData {
  const _ChecklistItemData({
    required this.id,
    required this.title,
    required this.detail,
    required this.owner,
    required this.due,
    required this.status,
  });

  final String id;
  final String title;
  final String detail;
  final String owner;
  final String due;
  final String status;

  _ChecklistItemData copyWith({
    String? title,
    String? detail,
    String? owner,
    String? due,
    String? status,
  }) {
    return _ChecklistItemData(
      id: id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      owner: owner ?? this.owner,
      due: due ?? this.due,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'detail': detail,
        'owner': owner,
        'due': due,
        'status': status,
      };

  static List<_ChecklistItemData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ChecklistItemData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        due: map['due']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Pending',
      );
    }).toList();
  }
}

class _ApprovalData {
  const _ApprovalData({
    required this.id,
    required this.label,
    required this.detail,
    required this.status,
    required this.approver,
  });

  final String id;
  final String label;
  final String detail;
  final String status;
  final String approver;

  _ApprovalData copyWith({
    String? label,
    String? detail,
    String? status,
    String? approver,
  }) {
    return _ApprovalData(
      id: id,
      label: label ?? this.label,
      detail: detail ?? this.detail,
      status: status ?? this.status,
      approver: approver ?? this.approver,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'detail': detail,
        'status': status,
        'approver': approver,
      };

  static List<_ApprovalData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ApprovalData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Pending',
        approver: map['approver']?.toString() ?? '',
      );
    }).toList();
  }
}

class _MilestoneData {
  const _MilestoneData({
    required this.id,
    required this.title,
    required this.detail,
    required this.due,
    required this.status,
  });

  final String id;
  final String title;
  final String detail;
  final String due;
  final String status;

  _MilestoneData copyWith({
    String? title,
    String? detail,
    String? due,
    String? status,
  }) {
    return _MilestoneData(
      id: id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      due: due ?? this.due,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'detail': detail,
        'due': due,
        'status': status,
      };

  static List<_MilestoneData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _MilestoneData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
        due: map['due']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Upcoming',
      );
    }).toList();
  }
}

class _TimelineStage {
  const _TimelineStage({
    required this.id,
    required this.label,
    required this.detail,
    required this.date,
    required this.status,
  });

  final String id;
  final String label;
  final String detail;
  final String date;
  final String status;

  _TimelineStage copyWith({
    String? label,
    String? detail,
    String? date,
    String? status,
  }) {
    return _TimelineStage(
      id: id,
      label: label ?? this.label,
      detail: detail ?? this.detail,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'detail': detail,
        'date': date,
        'status': status,
      };

  static List<_TimelineStage> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _TimelineStage(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
        date: map['date']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Upcoming',
      );
    }).toList();
  }
}
