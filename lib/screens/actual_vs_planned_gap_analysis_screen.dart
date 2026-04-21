import 'package:flutter/material.dart';

import 'package:ndu_project/models/launch_phase_models.dart';
import 'package:ndu_project/screens/commerce_viability_screen.dart';
import 'package:ndu_project/screens/project_close_out_screen.dart';
import 'package:ndu_project/services/launch_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/execution_phase_ui.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_data_table.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

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
  List<LaunchGapItem> _scopeGaps = [];
  List<LaunchMilestoneVariance> _milestoneVariances = [];
  List<LaunchBudgetVariance> _budgetVariances = [];
  List<LaunchRootCauseItem> _rootCauses = [];
  List<LaunchFollowUpItem> _followUpActions = [];

  bool _isLoading = true;
  bool _isGenerating = false;
  bool _hasLoaded = false;
  bool _suspendSave = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  String? get _projectId => ProjectDataHelper.getData(context).projectId;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 980;

    return ResponsiveScaffold(
      activeItemLabel: 'Actual vs Planned Gap Analysis',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(positioned: false),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 32,
          vertical: isMobile ? 16 : 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildMetricsRow(),
            const SizedBox(height: 20),
            _buildScopeGapsPanel(),
            const SizedBox(height: 16),
            _buildMilestoneVariancePanel(),
            const SizedBox(height: 16),
            _buildBudgetVariancePanel(),
            const SizedBox(height: 16),
            _buildRootCausesPanel(),
            const SizedBox(height: 16),
            _buildFollowUpPanel(),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Warranties & Operations Support',
              nextLabel: 'Next: Project Close Out',
              onBack: () => CommerceViabilityScreen.open(context),
              onNext: () => ProjectCloseOutScreen.open(context),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ExecutionPageHeader(
      badge: 'LAUNCH PHASE',
      title: 'Actual vs Planned Gap Analysis',
      description:
          'Compare planned deliverables, milestones, and budgets against actual outcomes. Identify root causes and corrective actions.',
      trailing: ExecutionActionBar(
        actions: [
          ExecutionActionItem(
            label: _isGenerating ? 'Generating...' : 'AI Assist',
            icon: Icons.auto_awesome_outlined,
            tone: ExecutionActionTone.ai,
            isLoading: _isGenerating,
            onPressed: _isGenerating ? null : _populateFromAi,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    final met = _scopeGaps.where((g) => g.gapStatus == 'Met').length;
    final partial = _scopeGaps.where((g) => g.gapStatus == 'Partial').length;
    final missed = _scopeGaps.where((g) => g.gapStatus == 'Missed').length;
    final openActions =
        _followUpActions.where((f) => f.status != 'Complete').length;

    return ExecutionMetricsGrid(
      metrics: [
        ExecutionMetricData(
            label: 'Met',
            value: '$met',
            icon: Icons.check_circle_outline,
            emphasisColor: const Color(0xFF10B981)),
        ExecutionMetricData(
            label: 'Partial',
            value: '$partial',
            icon: Icons.indeterminate_check_box_outlined,
            emphasisColor: const Color(0xFFF59E0B)),
        ExecutionMetricData(
            label: 'Missed',
            value: '$missed',
            icon: Icons.cancel_outlined,
            emphasisColor:
                missed > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
        ExecutionMetricData(
            label: 'Open Actions',
            value: '$openActions',
            icon: Icons.pending_outlined,
            emphasisColor: const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildScopeGapsPanel() {
    return LaunchDataTable(
      title: 'Scope Gap Analysis',
      subtitle: 'Compare planned deliverables vs actual outcomes.',
      columns: const ['Planned', 'Actual', 'Gap', 'Status'],
      rowCount: _scopeGaps.length,
      onAdd: () {
        setState(() => _scopeGaps.add(LaunchGapItem()));
        _save();
      },
      emptyMessage: 'Add items to compare planned vs actual.',
      cellBuilder: (context, i) {
        final g = _scopeGaps[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirm =
                await launchConfirmDelete(context, itemName: 'scope gap');
            if (!confirm || !mounted) return;
            setState(() => _scopeGaps.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: g.planned,
              hint: 'Planned',
              bold: true,
              expand: true,
              onChanged: (s) {
                _scopeGaps[i] = g.copyWith(planned: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: g.actual,
              hint: 'Actual',
              expand: true,
              onChanged: (s) {
                _scopeGaps[i] = g.copyWith(actual: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: g.gapDescription,
              hint: 'Gap',
              expand: true,
              onChanged: (s) {
                _scopeGaps[i] = g.copyWith(gapDescription: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: g.gapStatus,
              items: LaunchGapItem.gapStatuses,
              onChanged: (s) {
                if (s == null) return;
                _scopeGaps[i] = g.copyWith(gapStatus: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMilestoneVariancePanel() {
    return LaunchDataTable(
      title: 'Milestone Variance',
      subtitle: 'Compare planned vs actual milestone dates.',
      columns: const ['Milestone', 'Planned', 'Actual', 'Variance', 'Status'],
      rowCount: _milestoneVariances.length,
      onAdd: () {
        setState(() => _milestoneVariances.add(LaunchMilestoneVariance()));
        _save();
      },
      emptyMessage: 'Track planned vs actual milestone dates.',
      cellBuilder: (context, i) {
        final m = _milestoneVariances[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirm = await launchConfirmDelete(context,
                itemName: 'milestone variance');
            if (!confirm || !mounted) return;
            setState(() => _milestoneVariances.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: m.milestone,
              hint: 'Milestone',
              bold: true,
              expand: true,
              onChanged: (s) {
                _milestoneVariances[i] = m.copyWith(milestone: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: m.plannedDate,
              hint: 'Planned',
              expand: true,
              onChanged: (s) {
                _milestoneVariances[i] = m.copyWith(plannedDate: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: m.actualDate,
              hint: 'Actual',
              expand: true,
              onChanged: (s) {
                _milestoneVariances[i] = m.copyWith(actualDate: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: m.varianceDays,
              hint: 'Days',
              width: 70,
              onChanged: (s) {
                _milestoneVariances[i] = m.copyWith(varianceDays: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: m.status,
              items: const ['On Track', 'Delayed', 'Missed', 'Early'],
              onChanged: (s) {
                if (s == null) return;
                _milestoneVariances[i] = m.copyWith(status: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetVariancePanel() {
    return LaunchDataTable(
      title: 'Budget Variance',
      subtitle: 'Compare planned vs actual costs by category.',
      columns: const ['Category', 'Planned', 'Actual', 'Variance', '%'],
      rowCount: _budgetVariances.length,
      onAdd: () {
        setState(() => _budgetVariances.add(LaunchBudgetVariance()));
        _save();
      },
      emptyMessage: 'Track planned vs actual budget by category.',
      cellBuilder: (context, i) {
        final b = _budgetVariances[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirm =
                await launchConfirmDelete(context, itemName: 'budget variance');
            if (!confirm || !mounted) return;
            setState(() => _budgetVariances.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: b.category,
              hint: 'Category',
              bold: true,
              expand: true,
              onChanged: (s) {
                _budgetVariances[i] = b.copyWith(category: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: b.plannedAmount,
              hint: 'Planned',
              width: 100,
              onChanged: (s) {
                _budgetVariances[i] = b.copyWith(plannedAmount: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: b.actualAmount,
              hint: 'Actual',
              width: 100,
              onChanged: (s) {
                _budgetVariances[i] = b.copyWith(actualAmount: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: b.variance,
              hint: 'Variance',
              width: 90,
              onChanged: (s) {
                _budgetVariances[i] = b.copyWith(variance: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: b.variancePercent,
              hint: '%',
              width: 60,
              onChanged: (s) {
                _budgetVariances[i] = b.copyWith(variancePercent: s);
                _save();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRootCausesPanel() {
    return LaunchDataTable(
      title: 'Root Cause Analysis',
      subtitle:
          'For major gaps: identify root cause, impact, and corrective action.',
      columns: const ['Gap', 'Root Cause', 'Impact', 'Action', 'Status'],
      rowCount: _rootCauses.length,
      onAdd: () {
        setState(() => _rootCauses.add(LaunchRootCauseItem()));
        _save();
      },
      emptyMessage: 'Analyze why major gaps occurred.',
      cellBuilder: (context, i) {
        final r = _rootCauses[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirm =
                await launchConfirmDelete(context, itemName: 'root cause');
            if (!confirm || !mounted) return;
            setState(() => _rootCauses.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: r.gap,
              hint: 'Gap',
              bold: true,
              expand: true,
              onChanged: (s) {
                _rootCauses[i] = r.copyWith(gap: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: r.rootCause,
              hint: 'Cause',
              expand: true,
              onChanged: (s) {
                _rootCauses[i] = r.copyWith(rootCause: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: r.impact,
              hint: 'Impact',
              expand: true,
              onChanged: (s) {
                _rootCauses[i] = r.copyWith(impact: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: r.correctiveAction,
              hint: 'Action',
              expand: true,
              onChanged: (s) {
                _rootCauses[i] = r.copyWith(correctiveAction: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: r.status,
              items: const ['Open', 'In Progress', 'Resolved'],
              onChanged: (s) {
                if (s == null) return;
                _rootCauses[i] = r.copyWith(status: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFollowUpPanel() {
    return LaunchDataTable(
      title: 'Follow-Up Actions',
      subtitle: 'Items requiring post-project attention.',
      columns: const ['Action', 'Details', 'Owner', 'Status'],
      rowCount: _followUpActions.length,
      onAdd: () {
        setState(() => _followUpActions.add(LaunchFollowUpItem()));
        _save();
      },
      emptyMessage: 'List items requiring attention after project closure.',
      cellBuilder: (context, i) {
        final f = _followUpActions[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirm = await launchConfirmDelete(context,
                itemName: 'follow-up action');
            if (!confirm || !mounted) return;
            setState(() => _followUpActions.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: f.title,
              hint: 'Action',
              bold: true,
              expand: true,
              onChanged: (s) {
                _followUpActions[i] = f.copyWith(title: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: f.details,
              hint: 'Details',
              expand: true,
              onChanged: (s) {
                _followUpActions[i] = f.copyWith(details: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: f.owner,
              hint: 'Owner',
              width: 100,
              onChanged: (s) {
                _followUpActions[i] = f.copyWith(owner: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: f.status,
              items: const ['Open', 'In Progress', 'Complete'],
              onChanged: (s) {
                if (s == null) return;
                _followUpActions[i] = f.copyWith(status: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  void _save() {
    if (_suspendSave || !_hasLoaded) return;
    Future.microtask(() {
      if (mounted) _persistData();
    });
  }

  Future<void> _loadData() async {
    if (_hasLoaded || _projectId == null) return;
    _suspendSave = true;
    try {
      final r =
          await LaunchPhaseService.loadGapAnalysis(projectId: _projectId!);
      if (!mounted) return;
      setState(() {
        _scopeGaps = r.scopeGaps;
        _milestoneVariances = r.milestoneVariances;
        _budgetVariances = r.budgetVariances;
        _rootCauses = r.rootCauses;
        _followUpActions = r.followUpActions;
        _isLoading = false;
        _hasLoaded = true;
      });
      if (_scopeGaps.isEmpty &&
          _milestoneVariances.isEmpty &&
          _budgetVariances.isEmpty &&
          _rootCauses.isEmpty &&
          _followUpActions.isEmpty) {
        await _populateFromAi();
      }
    } catch (e) {
      debugPrint('Gap analysis load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
    _suspendSave = false;
  }

  Future<void> _persistData() async {
    if (_projectId == null) return;
    try {
      await LaunchPhaseService.saveGapAnalysis(
          projectId: _projectId!,
          scopeGaps: _scopeGaps,
          milestoneVariances: _milestoneVariances,
          budgetVariances: _budgetVariances,
          rootCauses: _rootCauses,
          followUpActions: _followUpActions);
    } catch (e) {
      debugPrint('Gap analysis save error: $e');
    }
  }

  Future<void> _populateFromAi() async {
    if (_isGenerating) return;
    final data = ProjectDataHelper.getData(context);
    var ctx = ProjectDataHelper.buildExecutivePlanContext(data,
        sectionLabel: 'Actual vs Planned Gap Analysis');
    if (ctx.trim().isEmpty) {
      ctx = ProjectDataHelper.buildProjectContextScan(data,
          sectionLabel: 'Actual vs Planned Gap Analysis');
    }
    if (ctx.trim().isEmpty) return;
    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> gen = {};
    try {
      gen = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: ctx,
        sections: const {
          'scope_gaps': 'Scope gaps: planned vs actual with gap status',
          'milestone_variances':
              'Milestone variances: planned date vs actual date with variance in days',
          'budget_variances':
              'Budget variances: planned amount vs actual with variance',
          'root_causes': 'Root causes for major gaps with corrective actions',
          'follow_up_actions':
              'Follow-up actions requiring post-project attention',
        },
        itemsPerSection: 3,
      );
    } catch (e) {
      debugPrint('Gap AI error: $e');
    }
    if (!mounted) return;
    final hasData = _scopeGaps.isNotEmpty ||
        _milestoneVariances.isNotEmpty ||
        _budgetVariances.isNotEmpty ||
        _rootCauses.isNotEmpty;
    if (hasData) {
      setState(() => _isGenerating = false);
      return;
    }
    setState(() {
      _scopeGaps = (gen['scope_gaps'] ?? [])
          .map((m) => LaunchGapItem(
              planned: _s(m['title']),
              actual: _s(m['details']),
              gapStatus: _ns(m['status'], 'Met')))
          .where((i) => i.planned.isNotEmpty)
          .toList();
      _milestoneVariances = (gen['milestone_variances'] ?? [])
          .map((m) => LaunchMilestoneVariance(
              milestone: _s(m['title']), status: _ns(m['status'], 'On Track')))
          .where((i) => i.milestone.isNotEmpty)
          .toList();
      _budgetVariances = (gen['budget_variances'] ?? [])
          .map((m) => LaunchBudgetVariance(
              category: _s(m['title']), plannedAmount: _s(m['details'])))
          .where((i) => i.category.isNotEmpty)
          .toList();
      _rootCauses = (gen['root_causes'] ?? [])
          .map((m) => LaunchRootCauseItem(
              gap: _s(m['title']),
              rootCause: _s(m['details']),
              status: _ns(m['status'], 'Open')))
          .where((i) => i.gap.isNotEmpty)
          .toList();
      _followUpActions = (gen['follow_up_actions'] ?? [])
          .map((m) => LaunchFollowUpItem(
              title: _s(m['title']),
              details: _s(m['details']),
              status: _ns(m['status'], 'Open')))
          .where((i) => i.title.isNotEmpty)
          .toList();
      _isGenerating = false;
    });
    await _persistData();
  }

  String _s(dynamic v) => (v ?? '').toString().trim();
  String _ns(dynamic v, String fb) => _s(v).isEmpty ? fb : _s(v);
}
