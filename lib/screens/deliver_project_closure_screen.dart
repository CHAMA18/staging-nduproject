import 'package:flutter/material.dart';

import 'package:ndu_project/models/launch_phase_models.dart';
import 'package:ndu_project/screens/transition_to_prod_team_screen.dart';
import 'package:ndu_project/services/launch_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/launch_phase_ai_seed.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/execution_phase_ui.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_data_table.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

class DeliverProjectClosureScreen extends StatefulWidget {
  const DeliverProjectClosureScreen({super.key});

  static void open(BuildContext context) {
    PhaseTransitionHelper.pushPhaseAware(
      context: context,
      builder: (_) => const DeliverProjectClosureScreen(),
      destinationCheckpoint: 'deliver_project_closure',
    );
  }

  @override
  State<DeliverProjectClosureScreen> createState() =>
      _DeliverProjectClosureScreenState();
}

class _DeliverProjectClosureScreenState
    extends State<DeliverProjectClosureScreen> {
  List<LaunchScopeItem> _scopeItems = [];
  List<LaunchMilestone> _milestones = [];
  List<LaunchFollowUpItem> _outstandingItems = [];
  List<LaunchFollowUpItem> _riskFollowUps = [];
  LaunchClosureNotes _closureNotes = LaunchClosureNotes();

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
      activeItemLabel: 'Deliver Project',
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
            const PlanningPhaseHeader(
              title: 'Deliver Project',
              showImportButton: false,
              showContentButton: false,
              showNavigationButtons: false,
            ),
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildMetricsRow(),
            const SizedBox(height: 20),
            _buildScopeAcceptancePanel(),
            const SizedBox(height: 16),
            _buildMilestonesPanel(),
            const SizedBox(height: 16),
            _buildOutstandingPanel(),
            const SizedBox(height: 16),
            _buildRiskFollowUpsPanel(),
            const SizedBox(height: 16),
            _buildClosureNotesPanel(),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Salvage and/or Disposal Plan',
              nextLabel: 'Next: Transition To Production Team',
              onBack: () => Navigator.of(context).maybePop(),
              onNext: () => TransitionToProdTeamScreen.open(context),
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
      title: 'Deliver Project · Closure Summary',
      description:
          'Confirm scope is delivered and accepted. Review milestones, outstanding items, and post-delivery risks before transitioning.',
      trailing: ExecutionActionBar(
        actions: [
          ExecutionActionItem(
            label: _isGenerating ? 'Generating…' : 'AI Assist',
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
    final accepted = _scopeItems.where((s) => s.status == 'Accepted').length;
    final total = _scopeItems.length;
    final milestonesDone =
        _milestones.where((m) => m.status == 'Complete').length;
    final milestonesTotal = _milestones.length;
    final openOutstanding =
        _outstandingItems.where((o) => o.status != 'Complete').length;

    return ExecutionMetricsGrid(
      metrics: [
        ExecutionMetricData(
          label: 'Scope Accepted',
          value: total == 0 ? '—' : '$accepted / $total',
          icon: Icons.check_circle_outline,
          emphasisColor: const Color(0xFF10B981),
          helper: total == 0
              ? 'No scope items yet'
              : '${((accepted / total) * 100).round()}%',
        ),
        ExecutionMetricData(
          label: 'Milestones Done',
          value: '$milestonesDone / $milestonesTotal',
          icon: Icons.flag_outlined,
          emphasisColor: const Color(0xFF2563EB),
        ),
        ExecutionMetricData(
          label: 'Open Items',
          value: '$openOutstanding',
          icon: Icons.pending_outlined,
          emphasisColor: openOutstanding > 0
              ? const Color(0xFFF59E0B)
              : const Color(0xFF10B981),
        ),
        ExecutionMetricData(
          label: 'Post-Delivery Risks',
          value: '${_riskFollowUps.length}',
          icon: Icons.warning_amber_outlined,
          emphasisColor: _riskFollowUps.any((r) => r.status == 'Open')
              ? const Color(0xFFEF4444)
              : const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildScopeAcceptancePanel() {
    return LaunchDataTable(
      title: 'Scope Acceptance',
      subtitle:
          'Track acceptance status for each deliverable. Items are editable inline.',
      columns: ['Deliverable', 'Criteria', 'Status', 'Date'],
      rowCount: _scopeItems.length,
      onAdd: () => _addScopeItem(),
      importLabel: 'Import Scope',
      onImport: _importScope,
      emptyMessage:
          'No scope items yet. Add deliverables to track their acceptance status.',
      cellBuilder: (ctx, i) => LaunchDataRow(
        onDelete: () => _confirmDeleteScope(i),
        showDivider: i < _scopeItems.length - 1,
        cells: [
          LaunchEditableCell(
            value: _scopeItems[i].deliverable,
            hint: 'Deliverable',
            expand: true,
            bold: true,
            onChanged: (v) {
              _scopeItems[i] = _scopeItems[i].copyWith(deliverable: v);
              _scheduleSave();
            },
          ),
          LaunchEditableCell(
            value: _scopeItems[i].acceptanceCriteria,
            hint: 'Criteria',
            expand: true,
            onChanged: (v) {
              _scopeItems[i] = _scopeItems[i].copyWith(acceptanceCriteria: v);
              _scheduleSave();
            },
          ),
          LaunchStatusDropdown(
            value: _scopeItems[i].status,
            items: ['Pending', 'Accepted', 'Partial', 'Rejected'],
            onChanged: (v) {
              if (v == null) return;
              _scopeItems[i] = _scopeItems[i].copyWith(status: v);
              _scheduleSave();
              setState(() {});
            },
          ),
          LaunchDateCell(
            value: _scopeItems[i].acceptanceDate,
            hint: 'Date',
            width: 100,
            onChanged: (v) {
              _scopeItems[i] = _scopeItems[i].copyWith(acceptanceDate: v);
              _scheduleSave();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesPanel() {
    return LaunchDataTable(
      title: 'Delivery Milestones',
      subtitle: 'Track planned vs actual completion for key milestones.',
      columns: ['Milestone', 'Planned', 'Actual', 'Status'],
      rowCount: _milestones.length,
      onAdd: () => _addMilestone(),
      emptyMessage:
          'No milestones yet. Add delivery milestones to track progress.',
      cellBuilder: (ctx, i) => LaunchDataRow(
        onDelete: () => _confirmDeleteMilestone(i),
        showDivider: i < _milestones.length - 1,
        cells: [
          LaunchEditableCell(
            value: _milestones[i].title,
            hint: 'Milestone',
            expand: true,
            bold: true,
            onChanged: (v) {
              _milestones[i] = _milestones[i].copyWith(title: v);
              _scheduleSave();
            },
          ),
          LaunchDateCell(
            value: _milestones[i].plannedDate,
            hint: 'Planned date',
            onChanged: (v) {
              _milestones[i] = _milestones[i].copyWith(plannedDate: v);
              _scheduleSave();
            },
          ),
          LaunchDateCell(
            value: _milestones[i].actualDate,
            hint: 'Actual date',
            onChanged: (v) {
              _milestones[i] = _milestones[i].copyWith(actualDate: v);
              _scheduleSave();
            },
          ),
          LaunchStatusDropdown(
            value: _milestones[i].status,
            items: ['Pending', 'In Progress', 'Complete', 'Delayed'],
            onChanged: (v) {
              if (v == null) return;
              _milestones[i] = _milestones[i].copyWith(status: v);
              _scheduleSave();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingPanel() {
    return LaunchDataTable(
      title: 'Outstanding Items',
      subtitle: 'Items still pending closure before or shortly after handover.',
      columns: ['Title', 'Details', 'Owner', 'Status'],
      rowCount: _outstandingItems.length,
      onAdd: () => _addFollowUp(_outstandingItems),
      emptyMessage:
          'No outstanding items. All clear, or add items that need resolution.',
      cellBuilder: (ctx, i) => LaunchDataRow(
        onDelete: () => _confirmDeleteFollowUp(i, _outstandingItems),
        showDivider: i < _outstandingItems.length - 1,
        cells: [
          LaunchEditableCell(
            value: _outstandingItems[i].title,
            hint: 'Title',
            expand: true,
            bold: true,
            onChanged: (v) {
              _outstandingItems[i] = _outstandingItems[i].copyWith(title: v);
              _scheduleSave();
            },
          ),
          LaunchEditableCell(
            value: _outstandingItems[i].details,
            hint: 'Details',
            expand: true,
            onChanged: (v) {
              _outstandingItems[i] = _outstandingItems[i].copyWith(details: v);
              _scheduleSave();
            },
          ),
          LaunchEditableCell(
            value: _outstandingItems[i].owner,
            hint: 'Owner',
            expand: true,
            onChanged: (v) {
              _outstandingItems[i] = _outstandingItems[i].copyWith(owner: v);
              _scheduleSave();
            },
          ),
          LaunchStatusDropdown(
            value: _outstandingItems[i].status,
            items: ['Open', 'In Progress', 'Complete', 'Deferred'],
            onChanged: (v) {
              if (v == null) return;
              _outstandingItems[i] = _outstandingItems[i].copyWith(status: v);
              _scheduleSave();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRiskFollowUpsPanel() {
    return LaunchDataTable(
      title: 'Post-Delivery Risks',
      subtitle: 'Risks and gaps to monitor after project delivery.',
      columns: ['Title', 'Details', 'Owner', 'Status'],
      rowCount: _riskFollowUps.length,
      onAdd: () => _addFollowUp(_riskFollowUps),
      emptyMessage:
          'No post-delivery risks. Document risks that need monitoring post-delivery.',
      cellBuilder: (ctx, i) => LaunchDataRow(
        onDelete: () => _confirmDeleteFollowUp(i, _riskFollowUps),
        showDivider: i < _riskFollowUps.length - 1,
        cells: [
          LaunchEditableCell(
            value: _riskFollowUps[i].title,
            hint: 'Title',
            expand: true,
            bold: true,
            onChanged: (v) {
              _riskFollowUps[i] = _riskFollowUps[i].copyWith(title: v);
              _scheduleSave();
            },
          ),
          LaunchEditableCell(
            value: _riskFollowUps[i].details,
            hint: 'Details',
            expand: true,
            onChanged: (v) {
              _riskFollowUps[i] = _riskFollowUps[i].copyWith(details: v);
              _scheduleSave();
            },
          ),
          LaunchEditableCell(
            value: _riskFollowUps[i].owner,
            hint: 'Owner',
            expand: true,
            onChanged: (v) {
              _riskFollowUps[i] = _riskFollowUps[i].copyWith(owner: v);
              _scheduleSave();
            },
          ),
          LaunchStatusDropdown(
            value: _riskFollowUps[i].status,
            items: ['Open', 'In Progress', 'Complete', 'Deferred'],
            onChanged: (v) {
              if (v == null) return;
              _riskFollowUps[i] = _riskFollowUps[i].copyWith(status: v);
              _scheduleSave();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClosureNotesPanel() {
    return ExecutionPanelShell(
      title: 'Closure Notes',
      subtitle: 'Any additional notes or context for the delivery record.',
      collapsible: true,
      initiallyExpanded: true,
      headerIcon: Icons.note_alt_outlined,
      headerIconColor: const Color(0xFF6366F1),
      child: TextFormField(
        initialValue: _closureNotes.notes,
        maxLines: 5,
        style: const TextStyle(fontSize: 13, height: 1.5),
        decoration: InputDecoration(
          hintText: 'Write delivery notes, observations, or context…',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFD700)),
          ),
        ),
        onChanged: (v) {
          _closureNotes = LaunchClosureNotes(notes: v);
          _scheduleSave();
        },
      ),
    );
  }

  void _addScopeItem() {
    setState(() {
      _scopeItems.add(LaunchScopeItem());
    });
    _scheduleSave();
  }

  void _addMilestone() {
    setState(() {
      _milestones.add(LaunchMilestone());
    });
    _scheduleSave();
  }

  void _addFollowUp(List<LaunchFollowUpItem> list) {
    setState(() {
      list.add(LaunchFollowUpItem());
    });
    _scheduleSave();
  }

  Future<void> _importScope() async {
    if (_projectId == null) return;
    final imported =
        await LaunchPhaseService.loadScopeTrackingItems(_projectId!);
    if (imported.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No scope items found to import.')),
        );
      }
      return;
    }
    setState(() {
      final existing = _scopeItems.map((s) => s.deliverable).toSet();
      for (final s in imported) {
        if (!existing.contains(s.deliverable)) _scopeItems.add(s);
      }
    });
    _scheduleSave();
  }

  Future<void> _confirmDeleteScope(int idx) async {
    final confirmed =
        await launchConfirmDelete(context, itemName: 'scope item');
    if (!confirmed || !mounted) return;
    setState(() => _scopeItems.removeAt(idx));
    _scheduleSave();
  }

  Future<void> _confirmDeleteMilestone(int idx) async {
    final confirmed = await launchConfirmDelete(context, itemName: 'milestone');
    if (!confirmed || !mounted) return;
    setState(() => _milestones.removeAt(idx));
    _scheduleSave();
  }

  Future<void> _confirmDeleteFollowUp(
      int idx, List<LaunchFollowUpItem> list) async {
    final confirmed =
        await launchConfirmDelete(context, itemName: 'follow-up item');
    if (!confirmed || !mounted) return;
    setState(() => list.removeAt(idx));
    _scheduleSave();
  }

  void _scheduleSave() {
    if (_suspendSave || !_hasLoaded) return;
    Future.microtask(() {
      if (mounted) _persistData();
    });
  }

  Future<void> _loadData() async {
    if (_hasLoaded || _projectId == null) return;
    _suspendSave = true;

    try {
      final result =
          await LaunchPhaseService.loadDeliverProject(projectId: _projectId!);

      if (!mounted) return;
      setState(() {
        _scopeItems = result.scopeItems;
        _milestones = result.milestones;
        _outstandingItems = result.outstandingItems;
        _riskFollowUps = result.riskFollowUps;
        _closureNotes = result.closureNotes;
        _isLoading = false;
        _hasLoaded = true;
      });

      final allEmpty = _scopeItems.isEmpty &&
          _milestones.isEmpty &&
          _outstandingItems.isEmpty &&
          _riskFollowUps.isEmpty;
      if (allEmpty) {
        await _autoPopulateFromPriorPhases();
      }

      final stillEmpty = _scopeItems.isEmpty &&
          _milestones.isEmpty &&
          _outstandingItems.isEmpty &&
          _riskFollowUps.isEmpty;
      if (stillEmpty) await _populateFromAi();
    } catch (e) {
      debugPrint('Deliver project load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }

    _suspendSave = false;
  }

  Future<void> _persistData() async {
    if (_projectId == null) return;
    try {
      await LaunchPhaseService.saveDeliverProject(
        projectId: _projectId!,
        scopeItems: _scopeItems,
        milestones: _milestones,
        outstandingItems: _outstandingItems,
        riskFollowUps: _riskFollowUps,
        closureNotes: _closureNotes,
      );
    } catch (e) {
      debugPrint('Deliver project save error: $e');
    }
  }

  Future<void> _autoPopulateFromPriorPhases() async {
    if (_projectId == null) return;
    try {
      final cp = await LaunchPhaseAiSeed.loadCrossPhaseData(_projectId!);
      if (!mounted) return;

      // Pre-fill scope items from cross-phase scope tracking
      if (_scopeItems.isEmpty && cp.scopeTracking.isNotEmpty) {
        final existing = _scopeItems.map((s) => s.deliverable).toSet();
        final newItems = cp.scopeTracking
            .where((s) => !existing.contains(s.deliverable))
            .toList();
        if (newItems.isNotEmpty) {
          setState(() => _scopeItems.addAll(newItems));
        }
      }

      // Pre-fill milestones from planning sprints
      if (_milestones.isEmpty && cp.planningSprints.isNotEmpty) {
        final newMilestones = cp.planningSprints
            .map((s) => LaunchMilestone(
                  title: 'Sprint ${s['sprintNumber'] ?? s['name'] ?? '?'}: ${s['goal'] ?? s['title'] ?? ''}',
                  status: _normalizeSprintStatus(s['status']),
                ))
            .where((m) => m.title.isNotEmpty)
            .toList();
        if (newMilestones.isNotEmpty) {
          setState(() => _milestones.addAll(newMilestones));
        }
      }

      // Pre-fill risk follow-ups from open risk items
      if (_riskFollowUps.isEmpty && cp.openRiskItems.isNotEmpty) {
        final existing = _riskFollowUps.map((r) => r.title).toSet();
        final newRisks = cp.openRiskItems
            .where((r) => !existing.contains(r['title']?.toString() ?? r['risk']?.toString() ?? ''))
            .map((r) => LaunchFollowUpItem(
                  title: r['title']?.toString() ?? r['risk']?.toString() ?? '',
                  details: r['description']?.toString() ?? r['details']?.toString() ?? '',
                  owner: r['owner']?.toString() ?? '',
                  status: r['status']?.toString() ?? 'Open',
                ))
            .where((r) => r.title.isNotEmpty)
            .toList();
        if (newRisks.isNotEmpty) {
          setState(() => _riskFollowUps.addAll(newRisks));
        }
      }

      final hasNewData = _scopeItems.isNotEmpty ||
          _milestones.isNotEmpty ||
          _riskFollowUps.isNotEmpty;
      if (hasNewData) await _persistData();
    } catch (e) {
      debugPrint('Deliver project auto-populate error: $e');
    }
  }

  String _normalizeSprintStatus(dynamic status) {
    final s = (status ?? '').toString().toLowerCase();
    if (s == 'completed' || s == 'done') return 'Complete';
    if (s == 'in progress' || s == 'active') return 'In Progress';
    return 'Pending';
  }

  Future<void> _populateFromAi() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    Map<String, List<Map<String, dynamic>>> generated = {};
    try {
      generated = await LaunchPhaseAiSeed.generateEntries(
        context: context,
        sectionLabel: 'Deliver Project Closure',
        sections: const {
          'scope_acceptance':
              'Scope acceptance items with "deliverable", "acceptance_criteria", "status"',
          'milestones':
              'Delivery milestones with "title", "planned_date", "actual_date", "status"',
          'outstanding': 'Outstanding items with "title", "details", "owner", "status"',
          'risk_followups': 'Post-delivery risks with "title", "details", "owner", "status"',
        },
        itemsPerSection: 3,
      );
    } catch (e) {
      debugPrint('Deliver project AI error: $e');
    }

    if (!mounted) return;

    final hasExistingData = _scopeItems.isNotEmpty ||
        _milestones.isNotEmpty ||
        _outstandingItems.isNotEmpty ||
        _riskFollowUps.isNotEmpty;
    if (hasExistingData) {
      setState(() => _isGenerating = false);
      return;
    }

    setState(() {
      _scopeItems = _mapToScopeItems(generated['scope_acceptance']);
      _milestones = _mapToMilestones(generated['milestones']);
      _outstandingItems = _mapToFollowUps(generated['outstanding']);
      _riskFollowUps = _mapToFollowUps(generated['risk_followups']);
      _isGenerating = false;
    });
    await _persistData();
  }

  List<LaunchScopeItem> _mapToScopeItems(List<Map<String, dynamic>>? raw) {
    if (raw == null) return [];
    return raw
        .map((m) => LaunchScopeItem(
              deliverable: (m['title'] ?? '').toString().trim(),
              acceptanceCriteria: (m['details'] ?? '').toString().trim(),
              status: _normalizeStatus(m['status'], 'Pending'),
            ))
        .where((i) => i.deliverable.isNotEmpty)
        .toList();
  }

  List<LaunchMilestone> _mapToMilestones(List<Map<String, dynamic>>? raw) {
    if (raw == null) return [];
    return raw
        .map((m) => LaunchMilestone(
              title: (m['title'] ?? '').toString().trim(),
              status: _normalizeStatus(m['status'], 'Pending'),
            ))
        .where((i) => i.title.isNotEmpty)
        .toList();
  }

  List<LaunchFollowUpItem> _mapToFollowUps(List<Map<String, dynamic>>? raw) {
    if (raw == null) return [];
    return raw
        .map((m) => LaunchFollowUpItem(
              title: (m['title'] ?? '').toString().trim(),
              details: (m['details'] ?? '').toString().trim(),
              status: _normalizeStatus(m['status'], 'Open'),
            ))
        .where((i) => i.title.isNotEmpty)
        .toList();
  }

  String _normalizeStatus(dynamic value, String fallback) {
    final s = (value ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }
}
