import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ndu_project/screens/risk_tracking_screen.dart';
import 'package:ndu_project/screens/update_ops_maintenance_plans_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/providers/project_data_provider.dart';

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
  final Set<String> _selectedFocusFilters = {'Readiness'};
  final Set<String> _selectedVisibilityFilters = {'Show dependencies'};

  static const List<String> _focusOptions = [
    'Readiness',
    'Execution',
    'Support',
    'Stakeholders',
    'Risk',
  ];

  static const List<String> _visibilityOptions = [
    'Show dependencies',
    'Highlight blockers',
    'Include completed',
  ];

  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;

  List<_InfoChipData> _contextChips = [];
  List<_StatusMetricData> _statusMetrics = [];
  List<_MilestoneData> _milestones = [];
  List<_ApprovalItem> _approvalItems = [];
  List<_ChecklistRowData> _checklistRows = [];
  List<_TimelineStage> _timelineStages = [];
  List<_InfoPillData> _timelineInfoPills = [];
  List<_HighlightItem> _highlightItems = [];
  List<_InsightCardData> _insightCards = [];
  List<_ReadinessTagData> _readinessTags = [];

  double _confidencePercent = 68;
  String _confidenceStatus = 'On track';
  String _confidenceNote = 'Trending stable · no net-new blockers escalated';

  double _readinessProgress = 0.72;
  String _readinessSummary = '5 of 7 critical path items cleared · Next review Tue 10:00 AM';

  double _timelineProgress = 0.62;
  String _timelineSummary = 'Current phase: Cutover rehearsals · Go / no-go rehearsal in 3 days';

  String _coordinatorName = '';
  String _coordinatorRole = '';
  String _coordinatorEmail = '';
  String _coordinatorPhone = '';

  @override
  void initState() {
    super.initState();
    _contextChips = _defaultContextChips();
    _statusMetrics = _defaultStatusMetrics();
    _milestones = _defaultMilestones();
    _approvalItems = _defaultApprovalItems();
    _checklistRows = _defaultChecklistRows();
    _timelineStages = _defaultTimelineStages();
    _timelineInfoPills = _defaultTimelineInfoPills();
    _highlightItems = _defaultHighlightItems();
    _insightCards = _defaultInsightCards();
    _readinessTags = _defaultReadinessTags();
    _coordinatorName = 'Morgan Reyes';
    _coordinatorRole = 'Program Launch Director';
    _coordinatorEmail = 'morgan.reyes@example.com';
    _coordinatorPhone = '+1 312 555 0196';
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

      _suspendSave = true;
      if (!mounted) return;
      setState(() {
        final chips = _InfoChipData.fromList(data['contextChips']);
        final metrics = _StatusMetricData.fromList(data['statusMetrics']);
        final milestones = _MilestoneData.fromList(data['milestones']);
        final approvals = _ApprovalItem.fromList(data['approvalItems']);
        final checklist = _ChecklistRowData.fromList(data['checklistRows']);
        final stages = _TimelineStage.fromList(data['timelineStages']);
        final pills = _InfoPillData.fromList(data['timelineInfoPills']);
        final highlights = _HighlightItem.fromList(data['highlightItems']);
        final insights = _InsightCardData.fromList(data['insightCards']);
        final tags = _ReadinessTagData.fromList(data['readinessTags']);

        _contextChips = chips.isEmpty ? _defaultContextChips() : chips;
        _statusMetrics = metrics.isEmpty ? _defaultStatusMetrics() : metrics;
        _milestones = milestones.isEmpty ? _defaultMilestones() : milestones;
        _approvalItems = approvals.isEmpty ? _defaultApprovalItems() : approvals;
        _checklistRows = checklist.isEmpty ? _defaultChecklistRows() : checklist;
        _timelineStages = stages.isEmpty ? _defaultTimelineStages() : stages;
        _timelineInfoPills = pills.isEmpty ? _defaultTimelineInfoPills() : pills;
        _highlightItems = highlights.isEmpty ? _defaultHighlightItems() : highlights;
        _insightCards = insights.isEmpty ? _defaultInsightCards() : insights;
        _readinessTags = tags.isEmpty ? _defaultReadinessTags() : tags;

        _confidencePercent = _toDouble(data['confidencePercent'], fallback: 68);
        _confidenceStatus = data['confidenceStatus']?.toString() ?? 'On track';
        _confidenceNote = data['confidenceNote']?.toString() ?? 'Trending stable · no net-new blockers escalated';
        _readinessProgress = _toDouble(data['readinessProgress'], fallback: 0.72).clamp(0.0, 1.0);
        _readinessSummary = data['readinessSummary']?.toString() ?? '5 of 7 critical path items cleared · Next review Tue 10:00 AM';
        _timelineProgress = _toDouble(data['timelineProgress'], fallback: 0.62).clamp(0.0, 1.0);
        _timelineSummary = data['timelineSummary']?.toString() ?? 'Current phase: Cutover rehearsals · Go / no-go rehearsal in 3 days';

        final coordinator = Map<String, dynamic>.from(data['coordinator'] as Map? ?? {});
        _coordinatorName = coordinator['name']?.toString() ?? 'Morgan Reyes';
        _coordinatorRole = coordinator['role']?.toString() ?? 'Program Launch Director';
        _coordinatorEmail = coordinator['email']?.toString() ?? 'morgan.reyes@example.com';
        _coordinatorPhone = coordinator['phone']?.toString() ?? '+1 312 555 0196';
      });
    } catch (error) {
      debugPrint('Launch checklist load error: $error');
    } finally {
      _suspendSave = false;
      if (mounted) setState(() => _isLoading = false);
    }
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
        'contextChips': _contextChips.map((e) => e.toMap()).toList(),
        'statusMetrics': _statusMetrics.map((e) => e.toMap()).toList(),
        'milestones': _milestones.map((e) => e.toMap()).toList(),
        'approvalItems': _approvalItems.map((e) => e.toMap()).toList(),
        'checklistRows': _checklistRows.map((e) => e.toMap()).toList(),
        'timelineStages': _timelineStages.map((e) => e.toMap()).toList(),
        'timelineInfoPills': _timelineInfoPills.map((e) => e.toMap()).toList(),
        'highlightItems': _highlightItems.map((e) => e.toMap()).toList(),
        'insightCards': _insightCards.map((e) => e.toMap()).toList(),
        'readinessTags': _readinessTags.map((e) => e.toMap()).toList(),
        'confidencePercent': _confidencePercent,
        'confidenceStatus': _confidenceStatus,
        'confidenceNote': _confidenceNote,
        'readinessProgress': _readinessProgress,
        'readinessSummary': _readinessSummary,
        'timelineProgress': _timelineProgress,
        'timelineSummary': _timelineSummary,
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

  double _toDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  List<_InfoChipData> _defaultContextChips() => [
        _InfoChipData(id: _newId(), iconKey: 'flag', label: 'Program', value: 'AI operations uplift · Launch phase'),
        _InfoChipData(id: _newId(), iconKey: 'layers', label: 'Workstream', value: 'Customer experience platform'),
        _InfoChipData(id: _newId(), iconKey: 'calendar', label: 'Go-live window', value: 'Target 18 Aug · T−9 days'),
        _InfoChipData(id: _newId(), iconKey: 'update', label: 'Last sync', value: 'Executive review · 2h ago'),
      ];

  List<_StatusMetricData> _defaultStatusMetrics() => [
        _StatusMetricData(
          id: _newId(),
          label: 'Current stage',
          value: 'Final launch readiness',
          annotation: 'All squads aligned · rehearsal booked',
          iconKey: 'stacked',
          accentColor: const Color(0xFF2563EB),
          background: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFD2E3FC),
        ),
        _StatusMetricData(
          id: _newId(),
          label: 'Next exec gate',
          value: 'Go / no-go rehearsal · Thu 10 Aug',
          annotation: 'Agenda confirmed · decks in review',
          iconKey: 'event',
          accentColor: const Color(0xFF0EA5E9),
          background: const Color(0xFFE0F2FE),
          borderColor: const Color(0xFFBAE6FD),
        ),
        _StatusMetricData(
          id: _newId(),
          label: 'Risk posture',
          value: '2 watch items · 0 critical blockers',
          annotation: 'Escalations held daily with Ops & Tech',
          iconKey: 'warning',
          accentColor: const Color(0xFFF97316),
          background: const Color(0xFFFFF7ED),
          borderColor: const Color(0xFFFBD5BB),
        ),
        _StatusMetricData(
          id: _newId(),
          label: 'Hypercare',
          value: '14-day coverage · roster confirmed',
          annotation: 'Control room opens 16 Aug · 06:30 AM',
          iconKey: 'support',
          accentColor: const Color(0xFF10B981),
          background: const Color(0xFFECFDF5),
          borderColor: const Color(0xFFCFFADE),
        ),
      ];

  List<_MilestoneData> _defaultMilestones() => [
        _MilestoneData(
          id: _newId(),
          title: 'Cutover rehearsal playback',
          detail: 'Ops + Engineering walk-through with war room dry run',
          dateLabel: 'Due Wed · 09 Aug',
          badgeLabel: 'Scheduled',
          badgeColor: const Color(0xFF2563EB),
          iconKey: 'present',
        ),
        _MilestoneData(
          id: _newId(),
          title: 'Rollback drill & automation test',
          detail: 'Validate failback steps · ensure observability hooks firing',
          dateLabel: 'Due Fri · 11 Aug',
          badgeLabel: 'Requires ops',
          badgeColor: const Color(0xFFF97316),
          iconKey: 'security',
        ),
        _MilestoneData(
          id: _newId(),
          title: 'Customer comms final approval',
          detail: 'Exec sign-off on launch narratives, social + support packs',
          dateLabel: 'Due Mon · 14 Aug',
          badgeLabel: 'In review',
          badgeColor: const Color(0xFF7C3AED),
          iconKey: 'campaign',
        ),
      ];

  List<_ApprovalItem> _defaultApprovalItems() => [
        _ApprovalItem(
          id: _newId(),
          label: 'Cutover rehearsal sign-off',
          detail: 'Delivery, platform, and ops leads approved latest runbook.',
          status: 'Complete',
          iconKey: 'check',
          iconColor: const Color(0xFF16A34A),
          iconBackground: const Color(0xFFDCFCE7),
        ),
        _ApprovalItem(
          id: _newId(),
          label: 'Business readiness validation',
          detail: 'Support staffing matrix ready · escalation tree validated.',
          status: 'On track',
          iconKey: 'briefcase',
          iconColor: const Color(0xFF2563EB),
          iconBackground: const Color(0xFFE0F2FE),
        ),
        _ApprovalItem(
          id: _newId(),
          label: 'Comms go-live bundle',
          detail: 'Legal + comms still reviewing final messaging artefacts.',
          status: 'In review',
          iconKey: 'voice',
          iconColor: const Color(0xFF6366F1),
          iconBackground: const Color(0xFFEEF2FF),
        ),
      ];

  List<_ChecklistRowData> _defaultChecklistRows() => [
        _ChecklistRowData(
          id: _newId(),
          title: 'Cutover rehearsals signed off',
          detail: 'Dry run #2 captured follow-up items and warm stand-by plan.',
          owner: 'Operations lead',
          due: 'Aug 12',
          status: 'On track',
        ),
        _ChecklistRowData(
          id: _newId(),
          title: 'Rollback playbook distribution',
          detail: 'Share final rollback guide with exec sponsors and war room.',
          owner: 'Program manager',
          due: 'Aug 09',
          status: 'At risk',
          flagLabel: 'Escalate with executive sponsor',
        ),
        _ChecklistRowData(
          id: _newId(),
          title: 'Hypercare squad roster confirmed',
          detail: 'Roster, shifts, and virtual bridge details communicated.',
          owner: 'Launch director',
          due: 'Aug 15',
          status: 'In review',
        ),
      ];

  List<_TimelineStage> _defaultTimelineStages() => [
        _TimelineStage(
          id: _newId(),
          label: 'Final readiness review',
          detail: 'All cutover and rollback artefacts verified with stakeholders.',
          date: 'Thu · 10 Aug',
          iconKey: 'factcheck',
          accent: const Color(0xFF2563EB),
        ),
        _TimelineStage(
          id: _newId(),
          label: 'Go / no-go rehearsal',
          detail: 'Dry run with scenario walk-through and escalation practices.',
          date: 'Fri · 11 Aug',
          iconKey: 'groups',
          accent: const Color(0xFF7C3AED),
        ),
      ];

  List<_InfoPillData> _defaultTimelineInfoPills() => [
        _InfoPillData(id: _newId(), iconKey: 'flag_circle', label: 'Go-live decision: 17 Aug, 09:00 AM'),
        _InfoPillData(id: _newId(), iconKey: 'groups', label: 'Hypercare squad rota confirmed'),
        _InfoPillData(id: _newId(), iconKey: 'safety', label: 'Rollback rehearsal scheduled for Fri'),
      ];

  List<_HighlightItem> _defaultHighlightItems() => [
        _HighlightItem(
          id: _newId(),
          title: 'Stakeholder communications',
          detail: 'Exec sponsor updates drafted · customer comms ready for approval.',
          status: 'In review',
          iconKey: 'campaign',
          accent: const Color(0xFF6366F1),
          ctaLabel: 'View comms bundle',
        ),
        _HighlightItem(
          id: _newId(),
          title: 'Support & triage coverage',
          detail: 'Tier-2 rota staffed · escalation drills scheduled with SRE.',
          status: 'On track',
          iconKey: 'support',
          accent: const Color(0xFF0EA5E9),
          ctaLabel: 'Open support playbook',
        ),
      ];

  List<_ReadinessTagData> _defaultReadinessTags() => [
        _ReadinessTagData(id: _newId(), label: 'Cutover rehearsal', status: 'Complete'),
        _ReadinessTagData(id: _newId(), label: 'Rollback playbook', status: 'In review'),
        _ReadinessTagData(id: _newId(), label: 'Support playbooks', status: 'At risk'),
        _ReadinessTagData(id: _newId(), label: 'Customer comms', status: 'On track'),
      ];

  List<_InsightCardData> _defaultInsightCards() => [
        _InsightCardData(
          id: _newId(),
          title: 'Checklist overview at a glance',
          subtitle: 'Item progress, ownership coverage, and upcoming due dates.',
          tag: 'Execution',
          tagColor: const Color(0xFF2563EB),
          entries: [
            _InsightEntryData(
              id: _newId(),
              label: '18 active checklist items',
              detail: '12 on track · 4 in review · 2 at risk',
              iconKey: 'checklist',
              iconColor: const Color(0xFF2563EB),
              status: 'On track',
            ),
            _InsightEntryData(
              id: _newId(),
              label: 'Ownership coverage',
              detail: 'All stream leads assigned · 3 tasks with deputy owners.',
              iconKey: 'badge',
              iconColor: const Color(0xFF0EA5E9),
            ),
          ],
          footerLabel: 'Open full checklist view',
        ),
      ];
  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: 'Launch Checklist',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            if (_isLoading) const SizedBox(height: 16),
            _buildPageHeader(context, isMobile),
            const SizedBox(height: 20),
            _buildContextChips(isMobile),
            const SizedBox(height: 24),
            _buildToolbar(context),
            const SizedBox(height: 24),
            _buildStatusOverview(context),
            const SizedBox(height: 24),
            _buildChecklistBoard(context),
            const SizedBox(height: 24),
            _buildTimelineAndHighlights(context),
            const SizedBox(height: 28),
            _buildInsightsGrid(context),
            const SizedBox(height: 48),
            LaunchPhaseNavigation(
              backLabel: 'Back: Update Ops & Maintenance Plans',
              nextLabel: 'Next: Risk Tracking',
              onBack: () => UpdateOpsMaintenancePlansScreen.open(context),
              onNext: () => RiskTrackingScreen.open(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Launch Checklist',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: isMobile ? 24 : 30,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Coordinate cutover tasks, spotlight go-live risks, and align your launch room around the same priorities.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5563),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildContextChips(bool isCompact) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ..._contextChips.map((chip) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconForKey(chip.iconKey), size: 18, color: const Color(0xFF6366F1)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: isCompact ? 140 : 180,
                      child: TextFormField(
                        key: ValueKey('chip-label-${chip.id}'),
                        initialValue: chip.label,
                        decoration: _inlineDecoration('Label'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                        onChanged: (value) => _updateContextChip(chip.copyWith(label: value)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      width: isCompact ? 140 : 180,
                      child: TextFormField(
                        key: ValueKey('chip-value-${chip.id}'),
                        initialValue: chip.value,
                        decoration: _inlineDecoration('Value'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                        onChanged: (value) => _updateContextChip(chip.copyWith(value: value)),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                  onPressed: () => _deleteContextChip(chip.id),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addContextChip,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add summary chip'),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              const Text(
                'Focus',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.article_outlined, size: 18),
                    label: const Text('Export runbook'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_active_outlined, size: 18),
                    label: const Text('Send launch update'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _focusOptions
                .map(
                  (option) => ChoiceChip(
                    label: Text(option),
                    selected: _selectedFocusFilters.contains(option),
                    onSelected: (_) => setState(() {
                      _selectedFocusFilters
                        ..clear()
                        ..add(option);
                    }),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    selectedColor: primary.withValues(alpha: 0.12),
                    backgroundColor: const Color(0xFFF3F4F6),
                    labelStyle: TextStyle(
                      fontWeight: _selectedFocusFilters.contains(option) ? FontWeight.w700 : FontWeight.w500,
                      color: _selectedFocusFilters.contains(option) ? primary : const Color(0xFF4B5563),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE5E7EB), height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _visibilityOptions
                .map(
                  (option) => FilterChip(
                    label: Text(option),
                    selected: _selectedVisibilityFilters.contains(option),
                    onSelected: (_) => setState(() {
                      if (_selectedVisibilityFilters.contains(option)) {
                        _selectedVisibilityFilters.remove(option);
                      } else {
                        _selectedVisibilityFilters.add(option);
                      }
                    }),
                    showCheckmark: false,
                    backgroundColor: const Color(0xFFF9FAFB),
                    selectedColor: const Color(0xFFEEF2FF),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _selectedVisibilityFilters.contains(option) ? const Color(0xFF3730A3) : const Color(0xFF4B5563),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompact = constraints.maxWidth < 920;
              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConfidenceGauge(),
                    const SizedBox(height: 22),
                    _buildStatusMetricPanel(context),
                    const SizedBox(height: 22),
                    _buildMilestonesPanel(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfidenceGauge(),
                  const SizedBox(width: 24),
                  Expanded(child: _buildStatusMetricPanel(context)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildMilestonesPanel()),
                ],
              );
            },
          ),
          const SizedBox(height: 26),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stack = constraints.maxWidth < 840;
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReadinessProgress(context),
                    const SizedBox(height: 24),
                    _buildApprovalAndCoordinatorPanel(context),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildReadinessProgress(context)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildApprovalAndCoordinatorPanel(context)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceGauge() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEDE9FE)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Confidence',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4C1D95),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (_confidencePercent / 100).clamp(0.0, 1.0),
                  strokeWidth: 12,
                  backgroundColor: const Color(0xFFE0E7FF),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_confidencePercent.round()}%',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF312E81)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _confidenceStatus,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4338CA)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _confidencePercent.round().toString(),
            decoration: _inlineDecoration('Confidence %'),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (value) {
              final parsed = double.tryParse(value) ?? _confidencePercent;
              setState(() => _confidencePercent = parsed.clamp(0, 100));
              _scheduleSave();
            },
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: _confidenceStatus,
            decoration: _inlineDecoration('Status label'),
            textAlign: TextAlign.center,
            onChanged: (value) {
              setState(() => _confidenceStatus = value);
              _scheduleSave();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _confidenceNote,
            decoration: _inlineDecoration('Status note'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
            onChanged: (value) {
              setState(() => _confidenceNote = value);
              _scheduleSave();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetricPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Launch status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
        ),
        const SizedBox(height: 12),
        ..._statusMetrics.map((metric) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: metric.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: metric.borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: metric.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForKey(metric.iconKey), size: 20, color: metric.accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          key: ValueKey('metric-label-${metric.id}'),
                          initialValue: metric.label,
                          decoration: _inlineDecoration('Metric label'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                          onChanged: (value) => _updateStatusMetric(metric.copyWith(label: value)),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          key: ValueKey('metric-value-${metric.id}'),
                          initialValue: metric.value,
                          decoration: _inlineDecoration('Metric value'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          onChanged: (value) => _updateStatusMetric(metric.copyWith(value: value)),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          key: ValueKey('metric-annotation-${metric.id}'),
                          initialValue: metric.annotation ?? '',
                          decoration: _inlineDecoration('Annotation'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                          onChanged: (value) => _updateStatusMetric(metric.copyWith(annotation: value)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                    onPressed: () => _deleteStatusMetric(metric.id),
                  ),
                ],
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addStatusMetric,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add status metric'),
        ),
      ],
    );
  }

  Widget _buildMilestonesPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Launch playbook',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 10),
          ..._milestones.map((milestone) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForKey(milestone.iconKey), color: const Color(0xFF0C4A6E), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          key: ValueKey('milestone-title-${milestone.id}'),
                          initialValue: milestone.title,
                          decoration: _inlineDecoration('Milestone'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          onChanged: (value) => _updateMilestone(milestone.copyWith(title: value)),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          key: ValueKey('milestone-detail-${milestone.id}'),
                          initialValue: milestone.detail,
                          decoration: _inlineDecoration('Detail'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                          onChanged: (value) => _updateMilestone(milestone.copyWith(detail: value)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: ValueKey('milestone-date-${milestone.id}'),
                          initialValue: milestone.dateLabel,
                          decoration: _inlineDecoration('Due date'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                          onChanged: (value) => _updateMilestone(milestone.copyWith(dateLabel: value)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: ValueKey('milestone-badge-${milestone.id}'),
                          initialValue: milestone.badgeLabel,
                          decoration: _inlineDecoration('Badge'),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: milestone.badgeColor),
                          onChanged: (value) => _updateMilestone(milestone.copyWith(badgeLabel: value)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                    onPressed: () => _deleteMilestone(milestone.id),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton.icon(
                onPressed: _addMilestone,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add milestone'),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.folder_copy_outlined),
                label: const Text('Open launch war room agenda'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessProgress(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Launch readiness tracker',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              SizedBox(width: 10),
              _StatusPill('On track'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: _readinessProgress.clamp(0.0, 1.0),
              minHeight: 14,
              backgroundColor: Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: _readinessSummary,
            decoration: _inlineDecoration('Summary'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
            onChanged: (value) {
              setState(() => _readinessSummary = value);
              _scheduleSave();
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: (_readinessProgress * 100).round().toString(),
            decoration: _inlineDecoration('Progress %'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final parsed = double.tryParse(value) ?? (_readinessProgress * 100);
              setState(() => _readinessProgress = (parsed / 100).clamp(0.0, 1.0));
              _scheduleSave();
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._readinessTags.map((tag) => _ReadinessTag(
                    label: tag.label,
                    status: tag.status,
                    onChangedLabel: (value) => _updateReadinessTag(tag.copyWith(label: value)),
                    onChangedStatus: (value) => _updateReadinessTag(tag.copyWith(status: value)),
                    onDelete: () => _deleteReadinessTag(tag.id),
                  )),
              TextButton.icon(
                onPressed: _addReadinessTag,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add readiness tag'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalAndCoordinatorPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Critical approvals & ownership',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          ..._approvalItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: item.iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForKey(item.iconKey), color: item.iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('approval-label-${item.id}'),
                                initialValue: item.label,
                                decoration: _inlineDecoration('Approval'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                                onChanged: (value) => _updateApprovalItem(item.copyWith(label: value)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusDropdown(
                              value: item.status,
                              onChanged: (value) => _updateApprovalItem(item.copyWith(status: value)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          key: ValueKey('approval-detail-${item.id}'),
                          initialValue: item.detail,
                          decoration: _inlineDecoration('Detail'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                          onChanged: (value) => _updateApprovalItem(item.copyWith(detail: value)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                    onPressed: () => _deleteApprovalItem(item.id),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: _addApprovalItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add approval'),
          ),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Launch coordinator',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: _coordinatorName,
                        decoration: _inlineDecoration('Name'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        onChanged: (value) {
                          setState(() => _coordinatorName = value);
                          _scheduleSave();
                        },
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        initialValue: _coordinatorRole,
                        decoration: _inlineDecoration('Role'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                        onChanged: (value) {
                          setState(() => _coordinatorRole = value);
                          _scheduleSave();
                        },
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _coordinatorEmail,
                              decoration: _inlineDecoration('Email'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                              onChanged: (value) {
                                setState(() => _coordinatorEmail = value);
                                _scheduleSave();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: _coordinatorPhone,
                              decoration: _inlineDecoration('Phone'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                              onChanged: (value) {
                                setState(() => _coordinatorPhone = value);
                                _scheduleSave();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Open in Teams'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistBoard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Checklist items',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Track execution readiness and align owners on every launch-critical activity.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                    label: const Text('Assign owners'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _addChecklistRow,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add checklist item'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Expanded(flex: 4, child: _TableHeader(label: 'Checklist item')),
                Expanded(flex: 2, child: _TableHeader(label: 'Owner')),
                Expanded(flex: 2, child: _TableHeader(label: 'Due by')),
                Expanded(flex: 2, child: _TableHeader(label: 'Status')),
                SizedBox(width: 32),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ..._checklistRows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final bool isOdd = index.isOdd;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: isOdd ? const Color(0xFFF9FAFB) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          key: ValueKey('checklist-title-${row.id}'),
                          initialValue: row.title,
                          decoration: _inlineDecoration('Checklist item'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          onChanged: (value) => _updateChecklistRow(row.copyWith(title: value)),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          key: ValueKey('checklist-detail-${row.id}'),
                          initialValue: row.detail,
                          decoration: _inlineDecoration('Detail'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                          onChanged: (value) => _updateChecklistRow(row.copyWith(detail: value)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: ValueKey('checklist-flag-${row.id}'),
                          initialValue: row.flagLabel ?? '',
                          decoration: _inlineDecoration('Flag/alert (optional)'),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)),
                          onChanged: (value) => _updateChecklistRow(row.copyWith(flagLabel: value)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: ValueKey('checklist-owner-${row.id}'),
                      initialValue: row.owner,
                      decoration: _inlineDecoration('Owner'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      onChanged: (value) => _updateChecklistRow(row.copyWith(owner: value)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: ValueKey('checklist-due-${row.id}'),
                      initialValue: row.due,
                      decoration: _inlineDecoration('Due'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                      onChanged: (value) => _updateChecklistRow(row.copyWith(due: value)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _StatusDropdown(
                      value: row.status,
                      onChanged: (value) => _updateChecklistRow(row.copyWith(status: value)),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _deleteChecklistRow(row.id),
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineAndHighlights(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTimelineCard(),
        const SizedBox(height: 24),
        _buildLaunchHighlightsCard(),
      ],
    );
  }

  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Launch timeline & guardrails',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              SizedBox(width: 10),
              _StatusPill('In review'),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _timelineProgress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _timelineSummary,
            decoration: _inlineDecoration('Timeline summary'),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
            onChanged: (value) {
              setState(() => _timelineSummary = value);
              _scheduleSave();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: (_timelineProgress * 100).round().toString(),
            decoration: _inlineDecoration('Timeline progress %'),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final parsed = double.tryParse(value) ?? (_timelineProgress * 100);
              setState(() => _timelineProgress = (parsed / 100).clamp(0.0, 1.0));
              _scheduleSave();
            },
          ),
          const SizedBox(height: 18),
          ..._timelineStages.map((stage) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: stage.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconForKey(stage.iconKey), color: stage.accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                key: ValueKey('timeline-label-${stage.id}'),
                                initialValue: stage.label,
                                decoration: _inlineDecoration('Stage'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                                onChanged: (value) => _updateTimelineStage(stage.copyWith(label: value)),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: TextFormField(
                                key: ValueKey('timeline-date-${stage.id}'),
                                initialValue: stage.date,
                                decoration: _inlineDecoration('Date'),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                                onChanged: (value) => _updateTimelineStage(stage.copyWith(date: value)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          key: ValueKey('timeline-detail-${stage.id}'),
                          initialValue: stage.detail,
                          decoration: _inlineDecoration('Detail'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                          onChanged: (value) => _updateTimelineStage(stage.copyWith(detail: value)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                    onPressed: () => _deleteTimelineStage(stage.id),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._timelineInfoPills.map((pill) {
                return _InfoPill(
                  icon: _iconForKey(pill.iconKey),
                  label: pill.label,
                  onChanged: (value) => _updateTimelineInfoPill(pill.copyWith(label: value)),
                  onDelete: () => _deleteTimelineInfoPill(pill.id),
                );
              }),
              TextButton.icon(
                onPressed: _addTimelineStage,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add timeline stage'),
              ),
              TextButton.icon(
                onPressed: _addTimelineInfoPill,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add guardrail'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLaunchHighlightsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guardrails & escalation paths',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Keep stakeholders ready across risk scenarios, comms, and analytics coverage.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 16),
          ..._highlightItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_iconForKey(item.iconKey), color: item.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey('highlight-title-${item.id}'),
                                  initialValue: item.title,
                                  decoration: _inlineDecoration('Highlight'),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                                  onChanged: (value) => _updateHighlightItem(item.copyWith(title: value)),
                                ),
                              ),
                              _StatusDropdown(
                                value: item.status,
                                onChanged: (value) => _updateHighlightItem(item.copyWith(status: value)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            key: ValueKey('highlight-detail-${item.id}'),
                            initialValue: item.detail,
                            decoration: _inlineDecoration('Detail'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                            onChanged: (value) => _updateHighlightItem(item.copyWith(detail: value)),
                          ),
                          if (item.ctaLabel != null) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              key: ValueKey('highlight-cta-${item.id}'),
                              initialValue: item.ctaLabel ?? '',
                              decoration: _inlineDecoration('CTA label'),
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                              onChanged: (value) => _updateHighlightItem(item.copyWith(ctaLabel: value)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                      onPressed: () => _deleteHighlightItem(item.id),
                    ),
                  ],
                ),
              ),
            );
          }),
          TextButton.icon(
            onPressed: _addHighlightItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add escalation item'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < _insightCards.length; i++) ...[
          _LaunchInsightCard(
            data: _insightCards[i],
            onUpdateCard: (card) => _updateInsightCard(card),
            onDeleteCard: () => _deleteInsightCard(_insightCards[i].id),
            onAddEntry: () => _addInsightEntry(_insightCards[i].id),
            onUpdateEntry: (entry) => _updateInsightEntry(_insightCards[i].id, entry),
            onDeleteEntry: (entryId) => _deleteInsightEntry(_insightCards[i].id, entryId),
          ),
          if (i != _insightCards.length - 1) const SizedBox(height: 20),
        ],
        TextButton.icon(
          onPressed: _addInsightCard,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add insight card'),
        ),
      ],
    );
  }

  void _addContextChip() {
    setState(() {
      _contextChips.add(_InfoChipData(id: _newId(), iconKey: 'flag', label: '', value: ''));
    });
    _scheduleSave();
  }

  void _updateContextChip(_InfoChipData chip) {
    final index = _contextChips.indexWhere((item) => item.id == chip.id);
    if (index == -1) return;
    setState(() => _contextChips[index] = chip);
    _scheduleSave();
  }

  void _deleteContextChip(String id) {
    setState(() => _contextChips.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addStatusMetric() {
    setState(() {
      _statusMetrics.add(_StatusMetricData(
        id: _newId(),
        label: '',
        value: '',
        annotation: '',
        iconKey: 'stacked',
        accentColor: const Color(0xFF2563EB),
        background: const Color(0xFFEFF6FF),
        borderColor: const Color(0xFFD2E3FC),
      ));
    });
    _scheduleSave();
  }

  void _updateStatusMetric(_StatusMetricData metric) {
    final index = _statusMetrics.indexWhere((item) => item.id == metric.id);
    if (index == -1) return;
    setState(() => _statusMetrics[index] = metric);
    _scheduleSave();
  }

  void _deleteStatusMetric(String id) {
    setState(() => _statusMetrics.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addMilestone() {
    setState(() {
      _milestones.add(_MilestoneData(
        id: _newId(),
        title: '',
        detail: '',
        dateLabel: '',
        badgeLabel: '',
        badgeColor: const Color(0xFF2563EB),
        iconKey: 'present',
      ));
    });
    _scheduleSave();
  }

  void _updateMilestone(_MilestoneData milestone) {
    final index = _milestones.indexWhere((item) => item.id == milestone.id);
    if (index == -1) return;
    setState(() => _milestones[index] = milestone);
    _scheduleSave();
  }

  void _deleteMilestone(String id) {
    setState(() => _milestones.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addApprovalItem() {
    setState(() {
      _approvalItems.add(_ApprovalItem(
        id: _newId(),
        label: '',
        detail: '',
        status: 'On track',
        iconKey: 'check',
        iconColor: const Color(0xFF16A34A),
        iconBackground: const Color(0xFFDCFCE7),
      ));
    });
    _scheduleSave();
  }

  void _updateApprovalItem(_ApprovalItem item) {
    final index = _approvalItems.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _approvalItems[index] = item);
    _scheduleSave();
  }

  void _deleteApprovalItem(String id) {
    setState(() => _approvalItems.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addChecklistRow() {
    setState(() {
      _checklistRows.add(_ChecklistRowData(
        id: _newId(),
        title: '',
        detail: '',
        owner: '',
        due: '',
        status: 'On track',
      ));
    });
    _scheduleSave();
  }

  void _updateChecklistRow(_ChecklistRowData row) {
    final index = _checklistRows.indexWhere((item) => item.id == row.id);
    if (index == -1) return;
    setState(() => _checklistRows[index] = row);
    _scheduleSave();
  }

  void _deleteChecklistRow(String id) {
    setState(() => _checklistRows.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addTimelineStage() {
    setState(() {
      _timelineStages.add(_TimelineStage(
        id: _newId(),
        label: '',
        detail: '',
        date: '',
        iconKey: 'factcheck',
        accent: const Color(0xFF2563EB),
      ));
    });
    _scheduleSave();
  }

  void _updateTimelineStage(_TimelineStage stage) {
    final index = _timelineStages.indexWhere((item) => item.id == stage.id);
    if (index == -1) return;
    setState(() => _timelineStages[index] = stage);
    _scheduleSave();
  }

  void _deleteTimelineStage(String id) {
    setState(() => _timelineStages.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addTimelineInfoPill() {
    setState(() {
      _timelineInfoPills.add(_InfoPillData(id: _newId(), iconKey: 'flag_circle', label: ''));
    });
    _scheduleSave();
  }

  void _updateTimelineInfoPill(_InfoPillData pill) {
    final index = _timelineInfoPills.indexWhere((item) => item.id == pill.id);
    if (index == -1) return;
    setState(() => _timelineInfoPills[index] = pill);
    _scheduleSave();
  }

  void _deleteTimelineInfoPill(String id) {
    setState(() => _timelineInfoPills.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addHighlightItem() {
    setState(() {
      _highlightItems.add(_HighlightItem(
        id: _newId(),
        title: '',
        detail: '',
        status: 'On track',
        iconKey: 'campaign',
        accent: const Color(0xFF6366F1),
        ctaLabel: '',
      ));
    });
    _scheduleSave();
  }

  void _updateHighlightItem(_HighlightItem item) {
    final index = _highlightItems.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _highlightItems[index] = item);
    _scheduleSave();
  }

  void _deleteHighlightItem(String id) {
    setState(() => _highlightItems.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addReadinessTag() {
    setState(() {
      _readinessTags.add(_ReadinessTagData(id: _newId(), label: '', status: 'On track'));
    });
    _scheduleSave();
  }

  void _updateReadinessTag(_ReadinessTagData tag) {
    final index = _readinessTags.indexWhere((item) => item.id == tag.id);
    if (index == -1) return;
    setState(() => _readinessTags[index] = tag);
    _scheduleSave();
  }

  void _deleteReadinessTag(String id) {
    setState(() => _readinessTags.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addInsightCard() {
    setState(() {
      _insightCards.add(_InsightCardData(
        id: _newId(),
        title: '',
        subtitle: '',
        tag: '',
        tagColor: const Color(0xFF2563EB),
        entries: [],
        footerLabel: '',
      ));
    });
    _scheduleSave();
  }

  void _updateInsightCard(_InsightCardData card) {
    final index = _insightCards.indexWhere((item) => item.id == card.id);
    if (index == -1) return;
    setState(() => _insightCards[index] = card);
    _scheduleSave();
  }

  void _deleteInsightCard(String id) {
    setState(() => _insightCards.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addInsightEntry(String cardId) {
    final index = _insightCards.indexWhere((item) => item.id == cardId);
    if (index == -1) return;
    final card = _insightCards[index];
    final updated = card.copyWith(entries: [
      ...card.entries,
      _InsightEntryData(
        id: _newId(),
        label: '',
        detail: '',
        iconKey: 'checklist',
        iconColor: const Color(0xFF2563EB),
        status: 'On track',
      ),
    ]);
    setState(() => _insightCards[index] = updated);
    _scheduleSave();
  }

  void _updateInsightEntry(String cardId, _InsightEntryData entry) {
    final cardIndex = _insightCards.indexWhere((item) => item.id == cardId);
    if (cardIndex == -1) return;
    final card = _insightCards[cardIndex];
    final entryIndex = card.entries.indexWhere((item) => item.id == entry.id);
    if (entryIndex == -1) return;
    final updatedEntries = [...card.entries];
    updatedEntries[entryIndex] = entry;
    setState(() => _insightCards[cardIndex] = card.copyWith(entries: updatedEntries));
    _scheduleSave();
  }

  void _deleteInsightEntry(String cardId, String entryId) {
    final cardIndex = _insightCards.indexWhere((item) => item.id == cardId);
    if (cardIndex == -1) return;
    final card = _insightCards[cardIndex];
    final updatedEntries = card.entries.where((item) => item.id != entryId).toList();
    setState(() => _insightCards[cardIndex] = card.copyWith(entries: updatedEntries));
    _scheduleSave();
  }
}

class _LaunchInsightCard extends StatelessWidget {
  const _LaunchInsightCard({
    required this.data,
    required this.onUpdateCard,
    required this.onDeleteCard,
    required this.onAddEntry,
    required this.onUpdateEntry,
    required this.onDeleteEntry,
  });

  final _InsightCardData data;
  final ValueChanged<_InsightCardData> onUpdateCard;
  final VoidCallback onDeleteCard;
  final VoidCallback onAddEntry;
  final ValueChanged<_InsightEntryData> onUpdateEntry;
  final ValueChanged<String> onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      initialValue: data.title,
                      decoration: _inlineDecoration('Card title'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      onChanged: (value) => onUpdateCard(data.copyWith(title: value)),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      initialValue: data.subtitle,
                      decoration: _inlineDecoration('Subtitle'),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                      onChanged: (value) => onUpdateCard(data.copyWith(subtitle: value)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: data.tagColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  width: 120,
                  child: TextFormField(
                    initialValue: data.tag,
                    decoration: _inlineDecoration('Tag'),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: data.tagColor),
                    onChanged: (value) => onUpdateCard(data.copyWith(tag: value)),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                onPressed: onDeleteCard,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: entry.iconColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconForKey(entry.iconKey), color: entry.iconColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: entry.label,
                                decoration: _inlineDecoration('Entry label'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                                onChanged: (value) => onUpdateEntry(entry.copyWith(label: value)),
                              ),
                            ),
                            _StatusDropdown(
                              value: entry.status ?? 'On track',
                              onChanged: (value) => onUpdateEntry(entry.copyWith(status: value)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          initialValue: entry.detail,
                          decoration: _inlineDecoration('Entry detail'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                          onChanged: (value) => onUpdateEntry(entry.copyWith(detail: value)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                    onPressed: () => onDeleteEntry(entry.id),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: onAddEntry,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add insight'),
          ),
          if (data.footerLabel != null) ...[
            const Divider(color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: data.footerLabel ?? '',
              decoration: _inlineDecoration('Footer link label'),
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
              onChanged: (value) => onUpdateCard(data.copyWith(footerLabel: value)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final visual = _statusVisuals[status] ?? _statusVisuals['On track']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: visual.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visual.icon, size: 16, color: visual.textColor),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: visual.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessTag extends StatelessWidget {
  const _ReadinessTag({
    required this.label,
    required this.status,
    this.onChangedLabel,
    this.onChangedStatus,
    this.onDelete,
  });

  final String label;
  final String status;
  final ValueChanged<String>? onChangedLabel;
  final ValueChanged<String>? onChangedStatus;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            child: TextFormField(
              initialValue: label,
              decoration: _inlineDecoration('Tag'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              onChanged: onChangedLabel,
            ),
          ),
          const SizedBox(width: 10),
          _StatusDropdown(
            value: status,
            onChanged: (value) => onChangedStatus?.call(value),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    this.onChanged,
    this.onDelete,
  });

  final IconData icon;
  final String label;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          SizedBox(
            width: 200,
            child: TextFormField(
              initialValue: label,
              decoration: _inlineDecoration('Guardrail'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              onChanged: onChanged,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChipData {
  const _InfoChipData({
    required this.id,
    required this.iconKey,
    required this.label,
    required this.value,
  });

  final String id;
  final String iconKey;
  final String label;
  final String value;

  _InfoChipData copyWith({String? iconKey, String? label, String? value}) {
    return _InfoChipData(
      id: id,
      iconKey: iconKey ?? this.iconKey,
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'iconKey': iconKey,
        'label': label,
        'value': value,
      };

  static List<_InfoChipData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _InfoChipData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        iconKey: map['iconKey']?.toString() ?? 'flag',
        label: map['label']?.toString() ?? '',
        value: map['value']?.toString() ?? '',
      );
    }).toList();
  }
}

class _StatusMetricData {
  const _StatusMetricData({
    required this.id,
    required this.label,
    required this.value,
    this.annotation,
    required this.iconKey,
    required this.accentColor,
    required this.background,
    required this.borderColor,
  });

  final String id;
  final String label;
  final String value;
  final String? annotation;
  final String iconKey;
  final Color accentColor;
  final Color background;
  final Color borderColor;

  _StatusMetricData copyWith({
    String? label,
    String? value,
    String? annotation,
    String? iconKey,
    Color? accentColor,
    Color? background,
    Color? borderColor,
  }) {
    return _StatusMetricData(
      id: id,
      label: label ?? this.label,
      value: value ?? this.value,
      annotation: annotation ?? this.annotation,
      iconKey: iconKey ?? this.iconKey,
      accentColor: accentColor ?? this.accentColor,
      background: background ?? this.background,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'value': value,
        'annotation': annotation,
        'iconKey': iconKey,
        'accentColor': accentColor.value,
        'background': background.value,
        'borderColor': borderColor.value,
      };

  static List<_StatusMetricData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _StatusMetricData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        value: map['value']?.toString() ?? '',
        annotation: map['annotation']?.toString(),
        iconKey: map['iconKey']?.toString() ?? 'stacked',
        accentColor: Color(map['accentColor'] is int ? map['accentColor'] as int : const Color(0xFF2563EB).value),
        background: Color(map['background'] is int ? map['background'] as int : const Color(0xFFEFF6FF).value),
        borderColor: Color(map['borderColor'] is int ? map['borderColor'] as int : const Color(0xFFD2E3FC).value),
      );
    }).toList();
  }
}

class _MilestoneData {
  const _MilestoneData({
    required this.id,
    required this.title,
    required this.detail,
    required this.dateLabel,
    required this.badgeLabel,
    required this.badgeColor,
    required this.iconKey,
  });

  final String id;
  final String title;
  final String detail;
  final String dateLabel;
  final String badgeLabel;
  final Color badgeColor;
  final String iconKey;

  _MilestoneData copyWith({
    String? title,
    String? detail,
    String? dateLabel,
    String? badgeLabel,
    Color? badgeColor,
    String? iconKey,
  }) {
    return _MilestoneData(
      id: id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      dateLabel: dateLabel ?? this.dateLabel,
      badgeLabel: badgeLabel ?? this.badgeLabel,
      badgeColor: badgeColor ?? this.badgeColor,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'detail': detail,
        'dateLabel': dateLabel,
        'badgeLabel': badgeLabel,
        'badgeColor': badgeColor.value,
        'iconKey': iconKey,
      };

  static List<_MilestoneData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _MilestoneData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
        dateLabel: map['dateLabel']?.toString() ?? '',
        badgeLabel: map['badgeLabel']?.toString() ?? '',
        badgeColor: Color(map['badgeColor'] is int ? map['badgeColor'] as int : const Color(0xFF2563EB).value),
        iconKey: map['iconKey']?.toString() ?? 'present',
      );
    }).toList();
  }
}

class _ApprovalItem {
  const _ApprovalItem({
    required this.id,
    required this.label,
    required this.detail,
    required this.status,
    required this.iconKey,
    required this.iconColor,
    required this.iconBackground,
  });

  final String id;
  final String label;
  final String detail;
  final String status;
  final String iconKey;
  final Color iconColor;
  final Color iconBackground;

  _ApprovalItem copyWith({
    String? label,
    String? detail,
    String? status,
    String? iconKey,
    Color? iconColor,
    Color? iconBackground,
  }) {
    return _ApprovalItem(
      id: id,
      label: label ?? this.label,
      detail: detail ?? this.detail,
      status: status ?? this.status,
      iconKey: iconKey ?? this.iconKey,
      iconColor: iconColor ?? this.iconColor,
      iconBackground: iconBackground ?? this.iconBackground,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'detail': detail,
        'status': status,
        'iconKey': iconKey,
        'iconColor': iconColor.value,
        'iconBackground': iconBackground.value,
      };

  static List<_ApprovalItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ApprovalItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
        status: map['status']?.toString() ?? 'On track',
        iconKey: map['iconKey']?.toString() ?? 'check',
        iconColor: Color(map['iconColor'] is int ? map['iconColor'] as int : const Color(0xFF16A34A).value),
        iconBackground: Color(map['iconBackground'] is int ? map['iconBackground'] as int : const Color(0xFFDCFCE7).value),
      );
    }).toList();
  }
}

class _ChecklistRowData {
  const _ChecklistRowData({
    required this.id,
    required this.title,
    required this.detail,
    required this.owner,
    required this.due,
    required this.status,
    this.flagLabel,
  });

  final String id;
  final String title;
  final String detail;
  final String owner;
  final String due;
  final String status;
  final String? flagLabel;

  _ChecklistRowData copyWith({
    String? title,
    String? detail,
    String? owner,
    String? due,
    String? status,
    String? flagLabel,
  }) {
    return _ChecklistRowData(
      id: id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      owner: owner ?? this.owner,
      due: due ?? this.due,
      status: status ?? this.status,
      flagLabel: flagLabel ?? this.flagLabel,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'detail': detail,
        'owner': owner,
        'due': due,
        'status': status,
        'flagLabel': flagLabel,
      };

  static List<_ChecklistRowData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ChecklistRowData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        due: map['due']?.toString() ?? '',
        status: map['status']?.toString() ?? 'On track',
        flagLabel: map['flagLabel']?.toString(),
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
    required this.iconKey,
    required this.accent,
  });

  final String id;
  final String label;
  final String detail;
  final String date;
  final String iconKey;
  final Color accent;

  _TimelineStage copyWith({
    String? label,
    String? detail,
    String? date,
    String? iconKey,
    Color? accent,
  }) {
    return _TimelineStage(
      id: id,
      label: label ?? this.label,
      detail: detail ?? this.detail,
      date: date ?? this.date,
      iconKey: iconKey ?? this.iconKey,
      accent: accent ?? this.accent,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'detail': detail,
        'date': date,
        'iconKey': iconKey,
        'accent': accent.value,
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
        iconKey: map['iconKey']?.toString() ?? 'factcheck',
        accent: Color(map['accent'] is int ? map['accent'] as int : const Color(0xFF2563EB).value),
      );
    }).toList();
  }
}

class _HighlightItem {
  const _HighlightItem({
    required this.id,
    required this.title,
    required this.detail,
    required this.status,
    required this.iconKey,
    required this.accent,
    this.ctaLabel,
  });

  final String id;
  final String title;
  final String detail;
  final String status;
  final String iconKey;
  final Color accent;
  final String? ctaLabel;

  _HighlightItem copyWith({
    String? title,
    String? detail,
    String? status,
    String? iconKey,
    Color? accent,
    String? ctaLabel,
  }) {
    return _HighlightItem(
      id: id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      status: status ?? this.status,
      iconKey: iconKey ?? this.iconKey,
      accent: accent ?? this.accent,
      ctaLabel: ctaLabel ?? this.ctaLabel,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'detail': detail,
        'status': status,
        'iconKey': iconKey,
        'accent': accent.value,
        'ctaLabel': ctaLabel,
      };

  static List<_HighlightItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _HighlightItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
        status: map['status']?.toString() ?? 'On track',
        iconKey: map['iconKey']?.toString() ?? 'campaign',
        accent: Color(map['accent'] is int ? map['accent'] as int : const Color(0xFF6366F1).value),
        ctaLabel: map['ctaLabel']?.toString(),
      );
    }).toList();
  }
}

class _InsightCardData {
  const _InsightCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.entries,
    this.footerLabel,
  });

  final String id;
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final List<_InsightEntryData> entries;
  final String? footerLabel;

  _InsightCardData copyWith({
    String? title,
    String? subtitle,
    String? tag,
    Color? tagColor,
    List<_InsightEntryData>? entries,
    String? footerLabel,
  }) {
    return _InsightCardData(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      tag: tag ?? this.tag,
      tagColor: tagColor ?? this.tagColor,
      entries: entries ?? this.entries,
      footerLabel: footerLabel ?? this.footerLabel,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'tag': tag,
        'tagColor': tagColor.value,
        'entries': entries.map((e) => e.toMap()).toList(),
        'footerLabel': footerLabel,
      };

  static List<_InsightCardData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _InsightCardData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
        tag: map['tag']?.toString() ?? '',
        tagColor: Color(map['tagColor'] is int ? map['tagColor'] as int : const Color(0xFF2563EB).value),
        entries: _InsightEntryData.fromList(map['entries']),
        footerLabel: map['footerLabel']?.toString(),
      );
    }).toList();
  }
}

class _InsightEntryData {
  const _InsightEntryData({
    required this.id,
    required this.label,
    required this.detail,
    required this.iconKey,
    required this.iconColor,
    this.status,
  });

  final String id;
  final String label;
  final String detail;
  final String iconKey;
  final Color iconColor;
  final String? status;

  _InsightEntryData copyWith({
    String? label,
    String? detail,
    String? iconKey,
    Color? iconColor,
    String? status,
  }) {
    return _InsightEntryData(
      id: id,
      label: label ?? this.label,
      detail: detail ?? this.detail,
      iconKey: iconKey ?? this.iconKey,
      iconColor: iconColor ?? this.iconColor,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'detail': detail,
        'iconKey': iconKey,
        'iconColor': iconColor.value,
        'status': status,
      };

  static List<_InsightEntryData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _InsightEntryData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
        iconKey: map['iconKey']?.toString() ?? 'checklist',
        iconColor: Color(map['iconColor'] is int ? map['iconColor'] as int : const Color(0xFF2563EB).value),
        status: map['status']?.toString(),
      );
    }).toList();
  }
}

class _InfoPillData {
  const _InfoPillData({
    required this.id,
    required this.iconKey,
    required this.label,
  });

  final String id;
  final String iconKey;
  final String label;

  _InfoPillData copyWith({String? iconKey, String? label}) {
    return _InfoPillData(
      id: id,
      iconKey: iconKey ?? this.iconKey,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'iconKey': iconKey,
        'label': label,
      };

  static List<_InfoPillData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _InfoPillData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        iconKey: map['iconKey']?.toString() ?? 'flag_circle',
        label: map['label']?.toString() ?? '',
      );
    }).toList();
  }
}

class _ReadinessTagData {
  const _ReadinessTagData({
    required this.id,
    required this.label,
    required this.status,
  });

  final String id;
  final String label;
  final String status;

  _ReadinessTagData copyWith({String? label, String? status}) {
    return _ReadinessTagData(
      id: id,
      label: label ?? this.label,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'status': status,
      };

  static List<_ReadinessTagData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ReadinessTagData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        status: map['status']?.toString() ?? 'On track',
      );
    }).toList();
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.background,
    required this.border,
    required this.textColor,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color textColor;
  final IconData icon;
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _statusOptions.contains(value) ? value : _statusOptions.first,
        items: _statusOptions
            .map((status) => DropdownMenuItem(value: status, child: _StatusPill(status)))
            .toList(),
        onChanged: (value) => onChanged(value ?? _statusOptions.first),
      ),
    );
  }
}

const List<String> _statusOptions = [
  'On track',
  'Complete',
  'In review',
  'At risk',
  'Decision pending',
  'Highlight blockers',
];

final Map<String, IconData> _iconRegistry = {
  'flag': Icons.flag_outlined,
  'layers': Icons.layers_outlined,
  'calendar': Icons.calendar_month_outlined,
  'update': Icons.update,
  'stacked': Icons.stacked_line_chart,
  'event': Icons.event_available_outlined,
  'warning': Icons.warning_amber_outlined,
  'support': Icons.support_agent_outlined,
  'present': Icons.present_to_all_outlined,
  'security': Icons.security_update_warning_outlined,
  'campaign': Icons.campaign_outlined,
  'check': Icons.check_circle_outline,
  'briefcase': Icons.business_center_outlined,
  'voice': Icons.record_voice_over_outlined,
  'factcheck': Icons.fact_check_outlined,
  'groups': Icons.groups_outlined,
  'verified': Icons.verified_user_outlined,
  'flag_circle': Icons.flag_circle_outlined,
  'safety': Icons.safety_check,
  'checklist': Icons.checklist_rtl,
  'badge': Icons.badge_outlined,
  'route': Icons.route_outlined,
  'insights': Icons.analytics_outlined,
};

IconData _iconForKey(String key) => _iconRegistry[key] ?? Icons.circle_outlined;

InputDecoration _inlineDecoration(String hint) {
  return const InputDecoration(
    isDense: true,
    border: InputBorder.none,
    hintText: '',
  ).copyWith(hintText: hint);
}

const Map<String, _StatusVisual> _statusVisuals = {
  'On track': _StatusVisual(
    background: Color(0xFFE0F2FE),
    border: Color(0xFFBAE6FD),
    textColor: Color(0xFF0369A1),
    icon: Icons.task_alt_rounded,
  ),
  'Complete': _StatusVisual(
    background: Color(0xFFDCFCE7),
    border: Color(0xFFBBF7D0),
    textColor: Color(0xFF15803D),
    icon: Icons.check_circle_rounded,
  ),
  'In review': _StatusVisual(
    background: Color(0xFFEEF2FF),
    border: Color(0xFFE0E7FF),
    textColor: Color(0xFF4338CA),
    icon: Icons.visibility_outlined,
  ),
  'At risk': _StatusVisual(
    background: Color(0xFFFEE2E2),
    border: Color(0xFFFECACA),
    textColor: Color(0xFFB91C1C),
    icon: Icons.error_outline,
  ),
  'Decision pending': _StatusVisual(
    background: Color(0xFFFDF4FF),
    border: Color(0xFFF5D0FE),
    textColor: Color(0xFF86198F),
    icon: Icons.hourglass_top_outlined,
  ),
  'Highlight blockers': _StatusVisual(
    background: Color(0xFFFFF7ED),
    border: Color(0xFFFBD5BB),
    textColor: Color(0xFFD97706),
    icon: Icons.report_problem_outlined,
  ),
};

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
