import 'package:flutter/material.dart';

import 'package:ndu_project/models/launch_phase_models.dart';
import 'package:ndu_project/screens/actual_vs_planned_gap_analysis_screen.dart';
import 'package:ndu_project/screens/summarize_account_risks_screen.dart';
import 'package:ndu_project/services/launch_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/execution_phase_ui.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_data_table.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class CommerceViabilityScreen extends StatefulWidget {
  const CommerceViabilityScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommerceViabilityScreen()),
    );
  }

  @override
  State<CommerceViabilityScreen> createState() =>
      _CommerceViabilityScreenState();
}

class _CommerceViabilityScreenState extends State<CommerceViabilityScreen> {
  List<LaunchWarrantyItem> _warranties = [];
  List<LaunchOpsCostItem> _opsCosts = [];
  List<LaunchFinancialMetric> _financialMetrics = [];
  List<LaunchFollowUpItem> _recommendations = [];
  LaunchClosureNotes _decision = LaunchClosureNotes();

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
      activeItemLabel: 'Warranties & Operations Support',
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
            _buildFinancialMetricsPanel(),
            const SizedBox(height: 16),
            _buildWarrantiesPanel(),
            const SizedBox(height: 16),
            _buildOpsCostsPanel(),
            const SizedBox(height: 16),
            _buildDecisionPanel(),
            const SizedBox(height: 16),
            _buildRecommendationsPanel(),
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Project Summary',
              nextLabel: 'Next: Actual vs Planned Gap Analysis',
              onBack: () => SummarizeAccountRisksScreen.open(context),
              onNext: () => ActualVsPlannedGapAnalysisScreen.open(context),
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
      title: 'Warranties & Operations Support',
      description:
          'Verify commercial sustainability, track warranties, project ongoing costs, and make the go/grow/pause decision.',
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
    final activeWarranties =
        _warranties.where((w) => w.status == 'Active').length;
    final monthlyTotal = _opsCosts.fold<double>(
        0,
        (sum, c) =>
            sum +
            (double.tryParse(c.monthlyCost.replaceAll(RegExp(r'[^\d.]'), '')) ??
                0));
    return ExecutionMetricsGrid(
      metrics: [
        ExecutionMetricData(
            label: 'Active Warranties',
            value: '$activeWarranties',
            icon: Icons.verified_user_outlined,
            emphasisColor: const Color(0xFF2563EB)),
        ExecutionMetricData(
            label: 'Monthly Ops Cost',
            value:
                monthlyTotal > 0 ? '\$${monthlyTotal.toStringAsFixed(0)}' : '—',
            icon: Icons.trending_up_outlined,
            emphasisColor: const Color(0xFF10B981)),
        ExecutionMetricData(
            label: 'Financial Metrics',
            value: '${_financialMetrics.length}',
            icon: Icons.analytics_outlined,
            emphasisColor: const Color(0xFF8B5CF6)),
        ExecutionMetricData(
            label: 'Recommendations',
            value: '${_recommendations.length}',
            icon: Icons.lightbulb_outline,
            emphasisColor: const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildFinancialMetricsPanel() {
    return LaunchDataTable(
      title: 'Financial Metrics',
      subtitle: 'ROI, payback period, total investment, and projected returns.',
      columns: const ['Metric', 'Value', 'Notes'],
      rowCount: _financialMetrics.length,
      onAdd: () {
        setState(() => _financialMetrics.add(LaunchFinancialMetric()));
        _save();
      },
      emptyMessage:
          'Track total investment, projected return, ROI, payback period.',
      cellBuilder: (context, i) {
        final m = _financialMetrics[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed = await launchConfirmDelete(context,
                itemName: 'financial metric');
            if (!confirmed || !mounted) return;
            setState(() => _financialMetrics.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: m.label,
              hint: 'Metric',
              bold: true,
              expand: true,
              onChanged: (s) {
                _financialMetrics[i] = m.copyWith(label: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: m.value,
              hint: 'Value',
              width: 120,
              onChanged: (s) {
                _financialMetrics[i] = m.copyWith(value: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: m.notes,
              hint: 'Notes',
              expand: true,
              onChanged: (s) {
                _financialMetrics[i] = m.copyWith(notes: s);
                _save();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildWarrantiesPanel() {
    return LaunchDataTable(
      title: 'Warranty Tracker',
      subtitle:
          'Track warranty coverage for deliverables, equipment, and services.',
      columns: const ['Item', 'Vendor', 'Type', 'Start', 'Expiry', 'Status'],
      rowCount: _warranties.length,
      onAdd: () {
        setState(() => _warranties.add(LaunchWarrantyItem()));
        _save();
      },
      emptyMessage: 'Add warranty items with vendor, type, and expiry.',
      cellBuilder: (context, i) {
        final w = _warranties[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed =
                await launchConfirmDelete(context, itemName: 'warranty');
            if (!confirmed || !mounted) return;
            setState(() => _warranties.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: w.item,
              hint: 'Item',
              bold: true,
              expand: true,
              onChanged: (s) {
                _warranties[i] = w.copyWith(item: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: w.vendor,
              hint: 'Vendor',
              width: 110,
              onChanged: (s) {
                _warranties[i] = w.copyWith(vendor: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: w.warrantyType,
              hint: 'Type',
              width: 100,
              onChanged: (s) {
                _warranties[i] = w.copyWith(warrantyType: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: w.startDate,
              hint: 'Start',
              width: 100,
              onChanged: (s) {
                _warranties[i] = w.copyWith(startDate: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: w.expiryDate,
              hint: 'Expiry',
              width: 100,
              onChanged: (s) {
                _warranties[i] = w.copyWith(expiryDate: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: w.status,
              items: const ['Active', 'Expiring Soon', 'Expired', 'Claimed'],
              width: 120,
              onChanged: (s) {
                if (s == null) return;
                _warranties[i] = w.copyWith(status: s);
                _save();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOpsCostsPanel() {
    return LaunchDataTable(
      title: 'Operations Cost Projection',
      subtitle: 'Monthly and annual ongoing costs post-launch.',
      columns: const ['Category', 'Monthly', 'Annual', 'Notes'],
      rowCount: _opsCosts.length,
      onAdd: () {
        setState(() => _opsCosts.add(LaunchOpsCostItem()));
        _save();
      },
      emptyMessage:
          'Project infrastructure, licenses, support, and maintenance costs.',
      cellBuilder: (context, i) {
        final c = _opsCosts[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed =
                await launchConfirmDelete(context, itemName: 'cost projection');
            if (!confirmed || !mounted) return;
            setState(() => _opsCosts.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: c.category,
              hint: 'Category',
              bold: true,
              expand: true,
              onChanged: (s) {
                _opsCosts[i] = c.copyWith(category: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: c.monthlyCost,
              hint: 'Monthly',
              width: 100,
              onChanged: (s) {
                _opsCosts[i] = c.copyWith(monthlyCost: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: c.annualCost,
              hint: 'Annual',
              width: 100,
              onChanged: (s) {
                _opsCosts[i] = c.copyWith(annualCost: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: c.notes,
              hint: 'Notes',
              expand: true,
              onChanged: (s) {
                _opsCosts[i] = c.copyWith(notes: s);
                _save();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDecisionPanel() {
    return ExecutionPanelShell(
      title: 'Commercial Decision',
      subtitle: 'Record the go / grow / pause recommendation with rationale.',
      child: TextFormField(
        initialValue: _decision.notes,
        maxLines: 4,
        style: const TextStyle(fontSize: 13, height: 1.6),
        decoration: InputDecoration(
          hintText:
              'Go / Grow / Pause — provide recommendation and supporting context…',
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
              borderSide: const BorderSide(color: Color(0xFF2563EB))),
        ),
        onChanged: (v) {
          _decision = LaunchClosureNotes(notes: v);
          _save();
        },
      ),
    );
  }

  Widget _buildRecommendationsPanel() {
    return LaunchDataTable(
      title: 'Recommendations',
      subtitle: 'Key actions for commercial sustainability.',
      columns: const ['Recommendation', 'Details', 'Status'],
      rowCount: _recommendations.length,
      onAdd: () {
        setState(() => _recommendations.add(LaunchFollowUpItem()));
        _save();
      },
      emptyMessage: 'Add actions to ensure commercial viability.',
      cellBuilder: (context, i) {
        final r = _recommendations[i];
        return LaunchDataRow(
          onDelete: () async {
            final confirmed =
                await launchConfirmDelete(context, itemName: 'recommendation');
            if (!confirmed || !mounted) return;
            setState(() => _recommendations.removeAt(i));
            _save();
          },
          cells: [
            LaunchEditableCell(
              value: r.title,
              hint: 'Title',
              bold: true,
              expand: true,
              onChanged: (s) {
                _recommendations[i] = r.copyWith(title: s);
                _save();
              },
            ),
            LaunchEditableCell(
              value: r.details,
              hint: 'Details',
              expand: true,
              onChanged: (s) {
                _recommendations[i] = r.copyWith(details: s);
                _save();
              },
            ),
            LaunchStatusDropdown(
              value: r.status,
              items: const ['Open', 'In Progress', 'Complete'],
              width: 120,
              onChanged: (s) {
                if (s == null) return;
                _recommendations[i] = r.copyWith(status: s);
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
      final r = await LaunchPhaseService.loadCommerceViability(
          projectId: _projectId!);
      if (!mounted) return;
      setState(() {
        _warranties = r.warranties;
        _opsCosts = r.opsCosts;
        _financialMetrics = r.financialMetrics;
        _recommendations = r.recommendations;
        _decision = r.decision;
        _isLoading = false;
        _hasLoaded = true;
      });
      if (_warranties.isEmpty &&
          _opsCosts.isEmpty &&
          _financialMetrics.isEmpty &&
          _recommendations.isEmpty) {
        await _populateFromAi();
      }
    } catch (e) {
      debugPrint('Commerce load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
    _suspendSave = false;
  }

  Future<void> _persistData() async {
    if (_projectId == null) return;
    try {
      await LaunchPhaseService.saveCommerceViability(
          projectId: _projectId!,
          warranties: _warranties,
          opsCosts: _opsCosts,
          financialMetrics: _financialMetrics,
          recommendations: _recommendations,
          decision: _decision);
    } catch (e) {
      debugPrint('Commerce save error: $e');
    }
  }

  Future<void> _populateFromAi() async {
    if (_isGenerating) return;
    final data = ProjectDataHelper.getData(context);
    var ctx = ProjectDataHelper.buildExecutivePlanContext(data,
        sectionLabel: 'Commerce Viability');
    if (ctx.trim().isEmpty) {
      ctx = ProjectDataHelper.buildProjectContextScan(data,
          sectionLabel: 'Commerce Viability');
    }
    if (ctx.trim().isEmpty) return;
    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> gen = {};
    try {
      gen = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: ctx,
        sections: const {
          'financial_metrics':
              'ROI metrics: total investment, projected annual return, payback period',
          'warranties':
              'Warranty items with vendor, type, start and expiry dates',
          'ops_costs':
              'Post-launch operational costs: infrastructure, licenses, support',
          'recommendations': 'Recommendations for commercial sustainability',
        },
        itemsPerSection: 3,
      );
    } catch (e) {
      debugPrint('Commerce AI error: $e');
    }
    if (!mounted) return;
    final hasData = _warranties.isNotEmpty ||
        _opsCosts.isNotEmpty ||
        _financialMetrics.isNotEmpty ||
        _recommendations.isNotEmpty;
    if (hasData) {
      setState(() => _isGenerating = false);
      return;
    }
    setState(() {
      _financialMetrics = (gen['financial_metrics'] ?? [])
          .map((m) => LaunchFinancialMetric(
              label: _s(m['title']), value: _s(m['details'])))
          .where((i) => i.label.isNotEmpty)
          .toList();
      _warranties = (gen['warranties'] ?? [])
          .map((m) => LaunchWarrantyItem(
              item: _s(m['title']),
              vendor: _s(m['details']),
              status: _ns(m['status'], 'Active')))
          .where((i) => i.item.isNotEmpty)
          .toList();
      _opsCosts = (gen['ops_costs'] ?? [])
          .map((m) => LaunchOpsCostItem(
              category: _s(m['title']), monthlyCost: _s(m['details'])))
          .where((i) => i.category.isNotEmpty)
          .toList();
      _recommendations = (gen['recommendations'] ?? [])
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
