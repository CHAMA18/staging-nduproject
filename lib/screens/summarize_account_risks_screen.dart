import 'package:flutter/material.dart';

import 'package:ndu_project/models/launch_phase_models.dart';
import 'package:ndu_project/screens/commerce_viability_screen.dart';
import 'package:ndu_project/screens/vendor_account_close_out_screen.dart';
import 'package:ndu_project/services/launch_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/launch_phase_ai_seed.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/execution_phase_ui.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_data_table.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

class SummarizeAccountRisksScreen extends StatefulWidget {
  const SummarizeAccountRisksScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SummarizeAccountRisksScreen()),
    );
  }

  @override
  State<SummarizeAccountRisksScreen> createState() =>
      _SummarizeAccountRisksScreenState();
}

class _SummarizeAccountRisksScreenState
    extends State<SummarizeAccountRisksScreen> {
  List<LaunchFinancialMetric> _metrics = [];
  List<LaunchHighlightItem> _highlights = [];
  List<LaunchFollowUpItem> _topRisks = [];
  List<LaunchFollowUpItem> _next90Days = [];
  LaunchClosureNotes _summary = LaunchClosureNotes();

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
      activeItemLabel: 'Project Summary',
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
              title: 'Project Summary',
              showImportButton: false,
              showContentButton: false,
              showNavigationButtons: false,
            ),
            const SizedBox(height: 16),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildMetricsRow(),
            const SizedBox(height: 20),
            _buildExecutiveSummaryPanel(),
            const SizedBox(height: 16),
            _buildHighlightsPanel(),
            const SizedBox(height: 16),
            _buildTopRisksPanel(),
            const SizedBox(height: 16),
            _buildNext90DaysPanel(),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Vendor Account Close Out',
              nextLabel: 'Next: Warranties & Operations Support',
              onBack: () => VendorAccountCloseOutScreen.open(context),
              onNext: () => CommerceViabilityScreen.open(context),
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
      title: 'Project Summary',
      description:
          'Executive one-page health summary showing budget, scope, timeline, risks, and next steps.',
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
    return ExecutionMetricsGrid(
      metrics: _metrics.isEmpty
          ? [
              ExecutionMetricData(
                  label: 'Add metrics below',
                  value: '—',
                  icon: Icons.add_chart,
                  emphasisColor: const Color(0xFF9CA3AF)),
            ]
          : _metrics
              .take(4)
              .map((m) => ExecutionMetricData(
                    label: m.label,
                    value: m.value.isEmpty ? '—' : m.value,
                    icon: _iconForLabel(m.label),
                    emphasisColor: _colorForLabel(m.label),
                    helper: m.notes.isNotEmpty ? m.notes : null,
                  ))
              .toList(),
    );
  }

  IconData _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('budget') || l.contains('cost')) {
      return Icons.attach_money_outlined;
    }
    if (l.contains('scope')) {
      return Icons.check_circle_outline;
    }
    if (l.contains('timeline') || l.contains('schedule')) {
      return Icons.schedule_outlined;
    }
    if (l.contains('risk')) {
      return Icons.warning_amber_outlined;
    }
    if (l.contains('team')) return Icons.people_outline;
    return Icons.insights_outlined;
  }

  Color _colorForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('budget') || l.contains('cost')) {
      return const Color(0xFF10B981);
    }
    if (l.contains('scope')) {
      return const Color(0xFF2563EB);
    }
    if (l.contains('timeline') || l.contains('schedule')) {
      return const Color(0xFFF59E0B);
    }
    if (l.contains('risk')) {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFF8B5CF6);
  }

  Widget _buildExecutiveSummaryPanel() {
    return ExecutionPanelShell(
      title: 'Executive Summary',
      subtitle: 'Narrative overview of the project status at launch.',
      collapsible: true,
      initiallyExpanded: true,
      headerIcon: Icons.summarize_outlined,
      headerIconColor: const Color(0xFFEF4444),
      child: TextFormField(
        initialValue: _summary.notes,
        maxLines: 6,
        style: const TextStyle(fontSize: 13, height: 1.6),
        decoration: InputDecoration(
          hintText:
              'Summarize the overall project health, key achievements, and outstanding concerns…',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFFD700))),
        ),
        onChanged: (v) {
          _summary = LaunchClosureNotes(notes: v);
          _save();
        },
      ),
    );
  }

  Widget _buildHighlightsPanel() {
    return LaunchDataTable(
      title: 'Highlights & Wins',
      subtitle: 'Key achievements and what went well.',
      columns: const ['Highlight', 'Details'],
      rowCount: _highlights.length,
      onAdd: () {
        setState(() => _highlights.add(LaunchHighlightItem()));
        _save();
      },
      emptyMessage: 'Capture wins and achievements.',
      cellBuilder: (context, i) {
        final h = _highlights[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirm =
                await launchConfirmDelete(context, itemName: 'highlight');
            if (!confirm || !mounted) return;
            setState(() => _highlights.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: h.title,
              hint: 'Highlight',
              bold: true,
              expand: true,
              onChanged: (s) {
                _highlights[i] = h.copyWith(title: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: h.details,
              hint: 'Details',
              expand: true,
              onChanged: (s) {
                _highlights[i] = h.copyWith(details: s);
                _save();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopRisksPanel() {
    return LaunchDataTable(
      title: 'Top Risks',
      subtitle: 'Key risks that need attention or monitoring post-launch.',
      columns: const ['Risk', 'Details', 'Owner', 'Status'],
      rowCount: _topRisks.length,
      onAdd: () {
        setState(() => _topRisks.add(LaunchFollowUpItem()));
        _save();
      },
      emptyMessage: 'Document key delivery risks and mitigation plans.',
      cellBuilder: (context, i) {
        final r = _topRisks[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirm =
                await launchConfirmDelete(context, itemName: 'risk');
            if (!confirm || !mounted) return;
            setState(() => _topRisks.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: r.title,
              hint: 'Risk',
              bold: true,
              expand: true,
              onChanged: (s) {
                _topRisks[i] = r.copyWith(title: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: r.details,
              hint: 'Details',
              expand: true,
              onChanged: (s) {
                _topRisks[i] = r.copyWith(details: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: r.owner,
              hint: 'Owner',
              width: 100,
              onChanged: (s) {
                _topRisks[i] = r.copyWith(owner: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: r.status,
              items: const ['Open', 'Mitigated', 'Closed'],
              onChanged: (s) {
                if (s == null) return;
                _topRisks[i] = r.copyWith(status: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildNext90DaysPanel() {
    return LaunchDataTable(
      title: 'Next 90 Days Focus',
      subtitle:
          'Immediate priorities and follow-ups to keep the project on track post-launch.',
      columns: const ['Priority', 'Details', 'Owner', 'Status'],
      rowCount: _next90Days.length,
      onAdd: () {
        setState(() => _next90Days.add(LaunchFollowUpItem()));
        _save();
      },
      emptyMessage: 'List immediate priorities for the next 90 days.',
      cellBuilder: (context, i) {
        final f = _next90Days[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirm =
                await launchConfirmDelete(context, itemName: 'follow-up');
            if (!confirm || !mounted) return;
            setState(() => _next90Days.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: f.title,
              hint: 'Priority',
              bold: true,
              expand: true,
              onChanged: (s) {
                _next90Days[i] = f.copyWith(title: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: f.details,
              hint: 'Details',
              expand: true,
              onChanged: (s) {
                _next90Days[i] = f.copyWith(details: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: f.owner,
              hint: 'Owner',
              width: 100,
              onChanged: (s) {
                _next90Days[i] = f.copyWith(owner: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: f.status,
              items: const ['Planned', 'In Progress', 'Complete'],
              onChanged: (s) {
                if (s == null) return;
                _next90Days[i] = f.copyWith(status: s);
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
          await LaunchPhaseService.loadProjectSummary(projectId: _projectId!);
      if (!mounted) return;
      setState(() {
        _metrics = r.metrics;
        _highlights = r.highlights;
        _topRisks = r.topRisks;
        _next90Days = r.next90Days;
        _summary = r.summary;
        _isLoading = false;
        _hasLoaded = true;
      });
      if (_metrics.isEmpty &&
          _highlights.isEmpty &&
          _topRisks.isEmpty &&
          _next90Days.isEmpty) {
        await _autoPopulateFromPriorPhases();
      }
      if (_metrics.isEmpty &&
          _highlights.isEmpty &&
          _topRisks.isEmpty &&
          _next90Days.isEmpty) {
        await _populateFromAi();
      }
    } catch (e) {
      debugPrint('Summary load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
    _suspendSave = false;
  }

  Future<void> _persistData() async {
    if (_projectId == null) return;
    try {
      await LaunchPhaseService.saveProjectSummary(
          projectId: _projectId!,
          metrics: _metrics,
          highlights: _highlights,
          topRisks: _topRisks,
          next90Days: _next90Days,
          summary: _summary);
    } catch (e) {
      debugPrint('Summary save error: $e');
    }
  }

  Future<void> _autoPopulateFromPriorPhases() async {
    if (_projectId == null) return;
    try {
      final cp = await LaunchPhaseAiSeed.loadCrossPhaseData(_projectId!);
      if (!mounted) return;

      // Pre-fill metrics from CrossPhaseData helpers
      final metricExisting = _metrics.map((m) => m.label).toSet();
      final newMetrics = <LaunchFinancialMetric>[];

      if (cp.totalPlannedBudget > 0 && !metricExisting.contains('Total Budget')) {
        newMetrics.add(LaunchFinancialMetric(
          label: 'Total Budget',
          value: '\$${cp.totalPlannedBudget.toStringAsFixed(0)}',
          notes: 'Planned',
        ));
      }
      if (cp.totalActualBudget > 0 && !metricExisting.contains('Actual Spend')) {
        newMetrics.add(LaunchFinancialMetric(
          label: 'Actual Spend',
          value: '\$${cp.totalActualBudget.toStringAsFixed(0)}',
          notes: 'Actual',
        ));
      }
      if ((cp.totalPlannedBudget > 0 || cp.totalActualBudget > 0) &&
          !metricExisting.contains('Budget Variance')) {
        newMetrics.add(LaunchFinancialMetric(
          label: 'Budget Variance',
          value: '\$${cp.budgetVariance.toStringAsFixed(0)}',
          notes: cp.budgetVariance >= 0 ? 'Under budget' : 'Over budget',
        ));
      }
      if (cp.totalContractValue > 0 && !metricExisting.contains('Total Contract Value')) {
        newMetrics.add(LaunchFinancialMetric(
          label: 'Total Contract Value',
          value: '\$${cp.totalContractValue.toStringAsFixed(0)}',
        ));
      }
      if (!metricExisting.contains('Scope Completion')) {
        final total = cp.totalScopeCount;
        final done = cp.totalCompletedScope;
        if (total > 0) {
          newMetrics.add(LaunchFinancialMetric(
            label: 'Scope Completion',
            value: '$done / $total',
            notes: '${(done / total * 100).round()}%',
          ));
        }
      }
      if (cp.openRiskItems.isNotEmpty && !metricExisting.contains('Active Risks')) {
        newMetrics.add(LaunchFinancialMetric(
          label: 'Active Risks',
          value: '${cp.openRiskItems.length}',
          notes: 'Requires monitoring',
        ));
      }
      if (newMetrics.isNotEmpty) {
        setState(() => _metrics.addAll(newMetrics));
      }

      // Pre-fill highlights from completed deliverables and scope
      final highlightExisting = _highlights.map((h) => h.title).toSet();
      final newHighlights = <LaunchHighlightItem>[];
      for (final d in cp.deliverableRows) {
        final status = d['status']?.toString().toLowerCase() ?? '';
        if (status == 'completed' || status == 'done' || status == 'verified') {
          final title = d['title']?.toString() ?? '';
          if (title.isNotEmpty && !highlightExisting.contains(title)) {
            newHighlights.add(LaunchHighlightItem(
              title: title,
              details: 'Deliverable completed successfully',
              category: 'Win',
            ));
          }
        }
      }
      for (final s in cp.scopeTracking) {
        final status = s.status.toLowerCase();
        if (status == 'verified' || status == 'completed' || status == 'done') {
          if (s.deliverable.isNotEmpty && !highlightExisting.contains(s.deliverable)) {
            newHighlights.add(LaunchHighlightItem(
              title: s.deliverable,
              details: 'Scope item verified',
              category: 'Win',
            ));
          }
        }
      }
      if (newHighlights.isNotEmpty) {
        setState(() => _highlights.addAll(newHighlights));
      }

      // Pre-fill top risks from open risk items
      final riskExisting = _topRisks.map((r) => r.title).toSet();
      final newRisks = <LaunchFollowUpItem>[];
      for (final ri in cp.openRiskItems) {
        final title = ri['title']?.toString() ?? ri['risk']?.toString() ?? '';
        if (title.isNotEmpty && !riskExisting.contains(title)) {
          newRisks.add(LaunchFollowUpItem(
            title: title,
            details: ri['description']?.toString() ?? ri['details']?.toString() ?? '',
            owner: ri['owner']?.toString() ?? '',
            status: ri['status']?.toString() ?? 'Open',
          ));
        }
      }
      if (newRisks.isNotEmpty) {
        setState(() => _topRisks.addAll(newRisks));
      }

      // Pre-fill next 90 days from incomplete deliverables and mitigation plans
      final next90Existing = _next90Days.map((f) => f.title).toSet();
      final newNext90 = <LaunchFollowUpItem>[];
      for (final d in cp.deliverableRows) {
        final status = d['status']?.toString().toLowerCase() ?? '';
        if (status != 'completed' && status != 'done' && status != 'verified') {
          final title = d['title']?.toString() ?? '';
          if (title.isNotEmpty && !next90Existing.contains('Complete: $title')) {
            newNext90.add(LaunchFollowUpItem(
              title: 'Complete: $title',
              details: 'Deliverable pending completion',
              status: 'Planned',
            ));
          }
        }
      }
      for (final mp in cp.mitigationPlans) {
        final title = mp['title']?.toString() ?? mp['action']?.toString() ?? '';
        if (title.isNotEmpty && !next90Existing.contains(title)) {
          newNext90.add(LaunchFollowUpItem(
            title: title,
            details: mp['description']?.toString() ?? mp['details']?.toString() ?? '',
            owner: mp['owner']?.toString() ?? '',
            status: 'In Progress',
          ));
        }
      }
      if (newNext90.isNotEmpty) {
        setState(() => _next90Days.addAll(newNext90));
      }

      if (newMetrics.isNotEmpty || newHighlights.isNotEmpty || newRisks.isNotEmpty || newNext90.isNotEmpty) {
        await _persistData();
      }
    } catch (e) {
      debugPrint('Summary auto-populate error: $e');
    }
  }

  Future<void> _populateFromAi() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> gen = {};
    try {
      gen = await LaunchPhaseAiSeed.generateEntries(
        context: context,
        sectionLabel: 'Project Summary',
        sections: const {
          'metrics':
              'Executive metrics with "label", "value", "notes"',
          'highlights': 'Key achievements with "title", "details"',
          'risks': 'Top risks with "title", "details", "owner", "status"',
          'next_90_days': 'Immediate follow-up priorities with "title", "details", "owner", "status"',
        },
        itemsPerSection: 3,
      );
    } catch (e) {
      debugPrint('Summary AI error: $e');
    }
    if (!mounted) return;
    final hasData = _metrics.isNotEmpty ||
        _highlights.isNotEmpty ||
        _topRisks.isNotEmpty ||
        _next90Days.isNotEmpty;
    if (hasData) {
      setState(() => _isGenerating = false);
      return;
    }
    setState(() {
      _metrics = (gen['metrics'] ?? [])
          .map((m) => LaunchFinancialMetric(
              label: _s(m['title']),
              value: _s(m['details']),
              notes: _s(m['status'])))
          .where((i) => i.label.isNotEmpty)
          .toList();
      _highlights = (gen['highlights'] ?? [])
          .map((m) => LaunchHighlightItem(
              title: _s(m['title']), details: _s(m['details'])))
          .where((i) => i.title.isNotEmpty)
          .toList();
      _topRisks = (gen['risks'] ?? [])
          .map((m) => LaunchFollowUpItem(
              title: _s(m['title']),
              details: _s(m['details']),
              status: _ns(m['status'], 'Open')))
          .where((i) => i.title.isNotEmpty)
          .toList();
      _next90Days = (gen['next_90_days'] ?? [])
          .map((m) => LaunchFollowUpItem(
              title: _s(m['title']),
              details: _s(m['details']),
              status: _ns(m['status'], 'Planned')))
          .where((i) => i.title.isNotEmpty)
          .toList();
      _isGenerating = false;
    });
    await _persistData();
  }

  String _s(dynamic v) => (v ?? '').toString().trim();
  String _ns(dynamic v, String fb) => _s(v).isEmpty ? fb : _s(v);
}
