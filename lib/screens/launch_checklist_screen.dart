import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ndu_project/screens/risk_tracking_workspace_screen.dart';
import 'package:ndu_project/screens/update_ops_maintenance_plans_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/execution_phase_ai_seed.dart';

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
          _buildPremiumHeader(context, projectId),
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

  Widget _buildPremiumHeader(BuildContext context, String? projectId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => UpdateOpsMaintenancePlansScreen.open(context)),
              const SizedBox(width: 12),
              _CircleIconButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onTap: () => RiskTrackingWorkspaceScreen.open(context)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Launch Checklist',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const _CurrentUserProfileChip(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.rocket_launch_outlined,
                      size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  'Execution Phase · Launch Readiness',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
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
    return _buildSectionCard(
      icon: Icons.checklist_rounded,
      iconColor: const Color(0xFF6366F1),
      iconBg: const Color(0xFFEEF2FF),
      title: 'Launch Checklist',
      subtitle: 'Critical action items with owners and due dates',
      child: Column(
        children: [
          if (_checklistItems.isEmpty)
            _buildEmptyState('No checklist items yet', Icons.checklist_outlined)
          else
            ..._checklistItems.map((item) => _buildChecklistItem(item)),
          const SizedBox(height: 12),
          _buildAddButton('Add checklist item', _addChecklistItem),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(_ChecklistItemData item) {
    final statusColor = _getStatusColor(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x04000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.status.toLowerCase().contains('complete') ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      item.owner,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      item.due,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildEditButton(() => _editChecklistItem(item)),
          const SizedBox(width: 8),
          _buildDeleteButton(() => _deleteChecklistItem(item.id)),
        ],
      ),
    );
  }

  Widget _buildApprovalsSection() {
    return _buildSectionCard(
      icon: Icons.approval_rounded,
      iconColor: const Color(0xFF10B981),
      iconBg: const Color(0xFFECFDF5),
      title: 'Approvals & Sign-offs',
      subtitle: 'Required approvals before go-live',
      child: Column(
        children: [
          if (_approvals.isEmpty)
            _buildEmptyState('No approvals yet', Icons.approval_outlined)
          else
            ..._approvals.map((item) => _buildApprovalItem(item)),
          const SizedBox(height: 12),
          _buildAddButton('Add approval', _addApproval),
        ],
      ),
    );
  }

  Widget _buildApprovalItem(_ApprovalData item) {
    final statusColor = _getStatusColor(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x04000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.status.toLowerCase().contains('complete') ? Icons.check_circle : Icons.pending,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildEditButton(() => _editApproval(item)),
          const SizedBox(width: 8),
          _buildDeleteButton(() => _deleteApproval(item.id)),
        ],
      ),
    );
  }

  Widget _buildMilestonesSection() {
    return _buildSectionCard(
      icon: Icons.flag_rounded,
      iconColor: const Color(0xFFF59E0B),
      iconBg: const Color(0xFFFEF3C7),
      title: 'Launch Milestones',
      subtitle: 'Key milestones leading to go-live',
      child: Column(
        children: [
          if (_milestones.isEmpty)
            _buildEmptyState('No milestones yet', Icons.flag_outlined)
          else
            ..._milestones.map((item) => _buildMilestoneItem(item)),
          const SizedBox(height: 12),
          _buildAddButton('Add milestone', _addMilestone),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(_MilestoneData item) {
    final statusColor = _getStatusColor(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x04000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  item.due,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildEditButton(() => _editMilestone(item)),
          const SizedBox(width: 8),
          _buildDeleteButton(() => _deleteMilestone(item.id)),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return _buildSectionCard(
      icon: Icons.timeline_rounded,
      iconColor: const Color(0xFF0EA5E9),
      iconBg: const Color(0xFFE0F2FE),
      title: 'Launch Timeline',
      subtitle: 'Timeline stages toward go-live',
      child: Column(
        children: [
          if (_timelineStages.isEmpty)
            _buildEmptyState('No timeline stages yet', Icons.timeline_outlined)
          else
            ..._timelineStages.asMap().entries.map((entry) {
              final index = entry.key;
              final stage = entry.value;
              return _buildTimelineStage(stage, index, _timelineStages.length);
            }),
          const SizedBox(height: 12),
          _buildAddButton('Add stage', _addTimelineStage),
        ],
      ),
    );
  }

  Widget _buildTimelineStage(_TimelineStage stage, int index, int total) {
    final isLast = index == total - 1;
    final statusColor = _getStatusColor(stage.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: const Color(0xFFE5E7EB),
                  margin: const EdgeInsets.only(top: 8),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage.detail,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(
                          stage.date,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildEditButton(() => _editTimelineStage(stage)),
                  const SizedBox(width: 8),
                  _buildDeleteButton(() => _deleteTimelineStage(stage.id)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF9CA3AF), size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onPressed) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  Widget _buildEditButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6366F1)),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFDC2626)),
        ),
      ),
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
                TextFormField(
                  controller: titleController,
                  decoration: _dialogDecoration('Title'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: detailController,
                  decoration: _dialogDecoration('Details'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextFormField(
                      controller: ownerController,
                      decoration: _dialogDecoration('Owner'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
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
                  TextFormField(
                    controller: labelController,
                    decoration: _dialogDecoration('Approval name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: detailController,
                    decoration: _dialogDecoration('Details'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
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
                  TextFormField(
                    controller: titleController,
                    decoration: _dialogDecoration('Milestone title'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: detailController,
                    decoration: _dialogDecoration('Details'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
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
                  TextFormField(
                    controller: labelController,
                    decoration: _dialogDecoration('Stage label'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: detailController,
                    decoration: _dialogDecoration('Details'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
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
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _CurrentUserProfileChip extends StatelessWidget {
  const _CurrentUserProfileChip();

  String _initials(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r"\s+"));
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final photoUrl = user?.photoURL;
    final email = user?.email ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        _initials(displayName),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563)),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                  ),
                  Text(
                    role,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

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
