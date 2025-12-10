import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';

class DeliverProjectClosureScreen extends StatefulWidget {
  const DeliverProjectClosureScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DeliverProjectClosureScreen()),
    );
  }

  @override
  State<DeliverProjectClosureScreen> createState() => _DeliverProjectClosureScreenState();
}

class _DeliverProjectClosureScreenState extends State<DeliverProjectClosureScreen> {
  // Checklist state
  final Map<String, bool> _checklistState = {
    'scope_mapped': true,
    'gaps_reconciled': true,
    'punchlist_closed': false,
    'delivery_review': false,
    'acceptance_captured': false,
    'handover_prepared': false,
    'lessons_logged': false,
  };

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
              child: const InitiationLikeSidebar(activeItemLabel: 'Deliver Project'),
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
                        _buildTopMetrics(isMobile),
                        const SizedBox(height: 24),
                        _buildCompletionScoreCard(context),
                        const SizedBox(height: 24),
                        _buildScopeOutcomesSection(context),
                        const SizedBox(height: 24),
                        _buildDeliveryPerformanceSection(context),
                        const SizedBox(height: 24),
                        _buildOpenItemsSection(context),
                        const SizedBox(height: 24),
                        _buildRisksGapsSection(context),
                        const SizedBox(height: 24),
                        _buildStakeholdersSection(context),
                        const SizedBox(height: 24),
                        _buildChecklistSection(context),
                        const SizedBox(height: 24),
                        _buildFooterNavigation(context),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deliver Project · Closure Summary',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Phase 4 · Closure · Consolidated from planning, design & execution',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4338CA),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Single place to confirm that promised scope has been delivered, verified, and accepted — before handing over to operations and closing the project.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export delivery dossier'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
              label: const Text('Confirm project delivered'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopMetrics(bool isMobile) {
    final metrics = [
      _TopMetric('Scope delivered', '94%', Icons.check_box_outlined),
      _TopMetric('Items pending verification', '12', Icons.pending_actions_outlined),
      _TopMetric('Client acceptance rate', '88%', Icons.thumb_up_alt_outlined),
      _TopMetric('Residual risks impacting closure', '4 open', Icons.warning_amber_outlined),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: metrics.map((m) => _buildMetricChip(m, isMobile)).toList(),
    );
  }

  Widget _buildMetricChip(_TopMetric metric, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(metric.icon, size: 20, color: const Color(0xFF6366F1)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                metric.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metric.value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScoreCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCompletionGauge(),
                const SizedBox(height: 24),
                _buildCompletionDetails(),
                const SizedBox(height: 24),
                _buildSourcesPanel(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompletionGauge(),
              const SizedBox(width: 32),
              Expanded(child: _buildCompletionDetails()),
              const SizedBox(width: 32),
              Expanded(child: _buildSourcesPanel()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompletionGauge() {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'End-to-end delivery completion score',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF166534),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 0.92,
                  strokeWidth: 10,
                  backgroundColor: const Color(0xFFDCFCE7),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                ),
                const Text(
                  '92%',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildScoreRow('Baseline scope items completed', '96%', const Color(0xFF16A34A), 'On track'),
          const SizedBox(height: 8),
          _buildScoreRow('Verified against requirements', '88%', const Color(0xFF16A34A), 'Verification in progress'),
          const SizedBox(height: 8),
          _buildScoreRow('Outstanding changes & gaps', '6', const Color(0xFFF59E0B), 'Needs reconciliation'),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, String value, Color color, String status) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  Widget _buildCompletionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From planning', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  Text(
                    'Original scope baseline, milestones and success measures from execution & scope dashboards.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From design', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  Text(
                    'Detailed requirements, technical specs and acceptance criteria from design management.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('From execution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  Text(
                    'Actual delivery performance, punchlists, risks and tech debt from execution & tracking boards.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSourcesPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Performance at a glance',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Open performance breakdown', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGlanceRow('On-time delivery', 'Amber'),
          _buildGlanceRow('Budget adherence', 'Green'),
          _buildGlanceRow('Quality metrics', 'Green'),
          _buildGlanceRow('Scope stability', 'Amber (11 approved CRs)'),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          const Text(
            'Use in close-out',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Feeds final close-out report, executive summary and lessons learned.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlanceRow(String label, String value) {
    Color dotColor = const Color(0xFF16A34A);
    if (value.contains('Amber')) dotColor = const Color(0xFFF59E0B);
    if (value.contains('Red')) dotColor = const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B5563))),
          ),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dotColor)),
        ],
      ),
    );
  }

  Widget _buildScopeOutcomesSection(BuildContext context) {
    return _buildSectionCard(
      title: '1. Scope & outcomes delivered',
      subtitle: 'Roll-up of what was promised vs what was actually delivered, across all phases.',
      actionLabel: 'View full scope completion',
      onAction: () {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 800;
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScopeItem('Baseline scope coverage', '96% complete', 'Source: Scope Dashboard, Progress Tracking. Open: 5 minor enhancements, 1 defer to roadmap', const Color(0xFF16A34A)),
                const SizedBox(height: 16),
                _buildScopeItem('Key outcomes & benefits', 'Aligned', 'Throughput +28% vs baseline. On-time departure improvement: +9 pts', const Color(0xFF16A34A)),
                const SizedBox(height: 16),
                _buildScopeItem('Out-of-scope & exclusions', 'Documented', 'Captured to avoid scope creep at closure', const Color(0xFF6B7280)),
                const SizedBox(height: 20),
                _buildCompletionByDimension(),
                const SizedBox(height: 16),
                _buildLinkedSources(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScopeItem('Baseline scope coverage', '96% complete', 'Source: Scope Dashboard, Progress Tracking. Open: 5 minor enhancements, 1 defer to roadmap', const Color(0xFF16A34A)),
                    const SizedBox(height: 16),
                    _buildScopeItem('Key outcomes & benefits', 'Aligned', 'Throughput +28% vs baseline. On-time departure improvement: +9 pts', const Color(0xFF16A34A)),
                    const SizedBox(height: 16),
                    _buildScopeItem('Out-of-scope & exclusions', 'Documented', 'Captured to avoid scope creep at closure', const Color(0xFF6B7280)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompletionByDimension(),
                    const SizedBox(height: 16),
                    _buildLinkedSources(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScopeItem(String title, String status, String detail, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(detail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionByDimension() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Completion by dimension', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          _buildDimensionRow('Functional scope', '95%'),
          _buildDimensionRow('Non-functional (performance, security)', '90%'),
          _buildDimensionRow('Compliance & regulatory', '100%'),
        ],
      ),
    );
  }

  Widget _buildDimensionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        ],
      ),
    );
  }

  Widget _buildLinkedSources() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Linked sources', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0369A1))),
          SizedBox(height: 8),
          Text(
            'Scope Completion, Risk Tracking, Gap Reconciliation, Agile Hub, Contracts Dashboard',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0C4A6E)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPerformanceSection(BuildContext context) {
    return _buildSectionCard(
      title: '2. Delivery performance snapshot',
      subtitle: 'How the project delivered vs plan across schedule, cost, quality and scope.',
      actionLabel: 'Open performance breakdown',
      onAction: () {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 800;
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPerformanceMetric('Schedule performance', '+3 weeks', 'Planned completion vs actual · driven by design change cycle & vendor delays', const Color(0xFFF59E0B)),
                const SizedBox(height: 12),
                _buildPerformanceMetric('Cost performance', '+4% under budget', 'Source: Execution Dashboard, Contracts & Vendor Tracking', const Color(0xFF16A34A)),
                const SizedBox(height: 12),
                _buildPerformanceMetric('Quality & defects', '98% pass rate', 'Defects at closure: 7 open (all low severity)', const Color(0xFF16A34A)),
                const SizedBox(height: 20),
                _buildPerformanceGlance(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPerformanceMetric('Schedule performance', '+3 weeks', 'Planned completion vs actual · driven by design change cycle & vendor delays', const Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    _buildPerformanceMetric('Cost performance', '+4% under budget', 'Source: Execution Dashboard, Contracts & Vendor Tracking', const Color(0xFF16A34A)),
                    const SizedBox(height: 12),
                    _buildPerformanceMetric('Quality & defects', '98% pass rate', 'Defects at closure: 7 open (all low severity)', const Color(0xFF16A34A)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: _buildPerformanceGlance()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPerformanceMetric(String title, String value, String detail, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceGlance() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance at a glance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          SizedBox(height: 12),
          _GlanceItem(label: 'On-time delivery', value: 'Amber'),
          _GlanceItem(label: 'Budget adherence', value: 'Green'),
          _GlanceItem(label: 'Quality metrics', value: 'Green'),
          _GlanceItem(label: 'Scope stability', value: 'Amber (11 approved CRs)'),
          SizedBox(height: 16),
          Divider(color: Color(0xFFE5E7EB)),
          SizedBox(height: 12),
          Text('Use in close-out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          SizedBox(height: 6),
          Text('Feeds final close-out report, executive summary and lessons learned.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildOpenItemsSection(BuildContext context) {
    return _buildSectionCard(
      title: '3. Open items, punchlists & dependencies',
      subtitle: 'Everything that must be cleared or consciously accepted before calling the project delivered.',
      actionLabel: 'Go to punchlist dashboard',
      onAction: () {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 800;
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOpenItem('Punchlist items', '24 open', 'Critical: 0 · High: 3 · Medium: 9 · Low: 12. Source: Punchlist Dashboard, Scope Completion', const Color(0xFFF59E0B)),
                const SizedBox(height: 12),
                _buildOpenItem('Linked technical debt', '15 items', 'Planned into Technical Debt Management & post-go-live sprints', const Color(0xFF6366F1)),
                const SizedBox(height: 12),
                _buildOpenItem('Cross-phase dependencies', 'Mapped', 'Dependencies on: Warranty start, Ops staffing, Vendor closure', const Color(0xFF6B7280)),
                const SizedBox(height: 20),
                _buildBlockersPanel(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOpenItem('Punchlist items', '24 open', 'Critical: 0 · High: 3 · Medium: 9 · Low: 12. Source: Punchlist Dashboard, Scope Completion', const Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    _buildOpenItem('Linked technical debt', '15 items', 'Planned into Technical Debt Management & post-go-live sprints', const Color(0xFF6366F1)),
                    const SizedBox(height: 12),
                    _buildOpenItem('Cross-phase dependencies', 'Mapped', 'Dependencies on: Warranty start, Ops staffing, Vendor closure', const Color(0xFF6B7280)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: _buildBlockersPanel()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOpenItem(String title, String status, String detail, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockersPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Blockers to "Delivered" state', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          const Text('5 blocking defects. 2 items must be accepted as known limitations.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          const Text('Acceptance guidance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          const Text('Use this view in client sign-off to document what is open, deferred or moved to operations roadmap.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildRisksGapsSection(BuildContext context) {
    return _buildSectionCard(
      title: '4. Risks, gaps & reconciled scope',
      subtitle: 'How residual risks, gaps and reconciled scope are documented for closure.',
      actionLabel: 'Review risk & gap log',
      onAction: () {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 800;
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRiskItem('Residual risks at closure', '4 active', 'Source: Risk Tracking · All with owners & mitigation plans into production.', const Color(0xFFF59E0B)),
                const SizedBox(height: 12),
                _buildRiskItem('Actual vs planned gaps', 'Reconciled', 'Gap Reconciliation: 9 identified · 8 resolved · 1 accepted by client', const Color(0xFF16A34A)),
                const SizedBox(height: 12),
                _buildRiskItem('Scope concessions & trade-offs', 'Captured', 'Linked to change requests, contracts and stakeholder approvals.', const Color(0xFF6B7280)),
                const SizedBox(height: 20),
                _buildImpactPanel(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRiskItem('Residual risks at closure', '4 active', 'Source: Risk Tracking · All with owners & mitigation plans into production.', const Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    _buildRiskItem('Actual vs planned gaps', 'Reconciled', 'Gap Reconciliation: 9 identified · 8 resolved · 1 accepted by client', const Color(0xFF16A34A)),
                    const SizedBox(height: 12),
                    _buildRiskItem('Scope concessions & trade-offs', 'Captured', 'Linked to change requests, contracts and stakeholder approvals.', const Color(0xFF6B7280)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: _buildImpactPanel()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRiskItem(String title, String status, String detail, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Impact overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          SizedBox(height: 12),
          _ImpactRow(label: 'Service impact', value: 'Low'),
          _ImpactRow(label: 'Cost impact', value: 'Within approved variance'),
          _ImpactRow(label: 'Client satisfaction', value: 'High (no unresolved critical gaps)'),
          SizedBox(height: 16),
          Divider(color: Color(0xFFE5E7EB)),
          SizedBox(height: 12),
          Text('Where this is used', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          SizedBox(height: 6),
          Text('Inputs for: Final close-out report, executive briefing, warranty & support commitments.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildStakeholdersSection(BuildContext context) {
    return _buildSectionCard(
      title: '5. Stakeholders, approvals & communications',
      subtitle: 'Ensuring the right people have seen, understood and accepted what has been delivered.',
      actionLabel: 'Open stakeholder alignment',
      onAction: () {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 800;
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStakeholderItem('Key stakeholder groups', 'Mapped', 'Client execs · Ops leads · Vendors · Internal sponsors'),
                const SizedBox(height: 12),
                _buildStakeholderItem('Approval coverage', '86% complete', 'From Stakeholder Alignment & Project Closure workflows'),
                const SizedBox(height: 12),
                _buildStakeholderItem('Communication pack', 'Ready', 'Launch updates, final status report, FAQ & transition notes prepared'),
                const SizedBox(height: 20),
                _buildEngagementPanel(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStakeholderItem('Key stakeholder groups', 'Mapped', 'Client execs · Ops leads · Vendors · Internal sponsors'),
                    const SizedBox(height: 12),
                    _buildStakeholderItem('Approval coverage', '86% complete', 'From Stakeholder Alignment & Project Closure workflows'),
                    const SizedBox(height: 12),
                    _buildStakeholderItem('Communication pack', 'Ready', 'Launch updates, final status report, FAQ & transition notes prepared'),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(child: _buildEngagementPanel()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStakeholderItem(String title, String status, String detail) {
    Color color = const Color(0xFF16A34A);
    if (status.contains('complete')) color = const Color(0xFF2563EB);
    if (status == 'Mapped') color = const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Engagement signals', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          SizedBox(height: 8),
          Text('Stakeholder alignment score · 87%. No outstanding critical objections.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
          SizedBox(height: 16),
          Divider(color: Color(0xFFE5E7EB)),
          SizedBox(height: 12),
          Text('Next communication steps', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          SizedBox(height: 6),
          Text('Schedule final steering committee review, share closure pack, capture final feedback & satisfaction score.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildChecklistSection(BuildContext context) {
    return _buildSectionCard(
      title: '6. Deliver-project checklist & sign-off trail',
      subtitle: 'Action-oriented view of what remains before you can formally state that the project is delivered.',
      actionLabel: 'Open detailed close-out checklist',
      onAction: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 800;
              if (isCompact) {
                return Column(
                  children: [
                    _buildCheckItem('All scope items mapped to completion status', 'Sourced from Scope Dashboard & Execution boards.', 'scope_mapped'),
                    _buildCheckItem('Major gaps analysed & reconciled', 'Gap Analysis & Scope Reconciliation completed with client.', 'gaps_reconciled'),
                    _buildCheckItem('All punchlist items either closed or accepted', 'Remaining items documented with owners, dates and impact.', 'punchlist_closed'),
                    _buildCheckItem('Final delivery review with client stakeholders', 'Session scheduled; use this page as the single source of truth.', 'delivery_review'),
                    const SizedBox(height: 16),
                    _buildCheckItem('Formal acceptance captured', 'Electronic sign-off from client, sponsor and internal governance.', 'acceptance_captured'),
                    _buildCheckItem('Handover packages prepared', 'Inputs to Prod Team, O&M Planning, Warranty and Salvage flows.', 'handover_prepared'),
                    _buildCheckItem('Lessons learned logged & shared', 'Summaries pushed to knowledge base and portfolio view.', 'lessons_logged'),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildCheckItem('All scope items mapped to completion status', 'Sourced from Scope Dashboard & Execution boards.', 'scope_mapped'),
                        _buildCheckItem('Major gaps analysed & reconciled', 'Gap Analysis & Scope Reconciliation completed with client.', 'gaps_reconciled'),
                        _buildCheckItem('All punchlist items either closed or accepted', 'Remaining items documented with owners, dates and impact.', 'punchlist_closed'),
                        _buildCheckItem('Final delivery review with client stakeholders', 'Session scheduled; use this page as the single source of truth.', 'delivery_review'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildCheckItem('Formal acceptance captured', 'Electronic sign-off from client, sponsor and internal governance.', 'acceptance_captured'),
                        _buildCheckItem('Handover packages prepared', 'Inputs to Prod Team, O&M Planning, Warranty and Salvage flows.', 'handover_prepared'),
                        _buildCheckItem('Lessons learned logged & shared', 'Summaries pushed to knowledge base and portfolio view.', 'lessons_logged'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String title, String detail, String key) {
    final isChecked = _checklistState[key] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChecked ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isChecked ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _checklistState[key] = !isChecked),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? const Color(0xFF16A34A) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isChecked ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB), width: 2),
              ),
              child: isChecked ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isChecked ? const Color(0xFF166534) : const Color(0xFF111827),
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'This Deliver Project view is the narrative layer on top of all planning, design and execution data — use it to demonstrate that you have truly delivered what was committed before moving to contract, vendor and operations closure.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0C4A6E)),
            ),
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () {},
            child: const Text('Continue to Transition to Prod Team', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
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
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _TopMetric {
  final String label;
  final String value;
  final IconData icon;

  _TopMetric(this.label, this.value, this.icon);
}

class _GlanceItem extends StatelessWidget {
  final String label;
  final String value;

  const _GlanceItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    Color dotColor = const Color(0xFF16A34A);
    if (value.contains('Amber')) dotColor = const Color(0xFFF59E0B);
    if (value.contains('Red')) dotColor = const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)))),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: dotColor)),
        ],
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  final String label;
  final String value;

  const _ImpactRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                children: [
                  TextSpan(text: '$label · ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
