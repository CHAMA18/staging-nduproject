import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class ActualVsPlannedGapAnalysisScreen extends StatefulWidget {
  const ActualVsPlannedGapAnalysisScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ActualVsPlannedGapAnalysisScreen()),
    );
  }

  @override
  State<ActualVsPlannedGapAnalysisScreen> createState() => _ActualVsPlannedGapAnalysisScreenState();
}

class _ActualVsPlannedGapAnalysisScreenState extends State<ActualVsPlannedGapAnalysisScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: 'Actual vs Planned Gap Analysis',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(context, isMobile),
            const SizedBox(height: 20),
            _buildStatusChips(),
            const SizedBox(height: 16),
            _buildHelperChips(),
            const SizedBox(height: 24),
            _buildMainContent(context, isMobile),
            const SizedBox(height: 24),
            _buildBottomCards(context, isMobile),
            const SizedBox(height: 24),
            _buildFooterNavigation(context),
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
          'ACTUAL VS PLANNED GAP ANALYSIS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Compare what was promised vs. what was delivered',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Summarize where schedule, budget, scope, and quality landed against the original plan so you can close the loop and improve the next launch.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4B5563),
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildStatusChip('Gaps are understood', true),
        _buildStatusChip('Impact on benefits is clear', false),
        _buildStatusChip('Root causes documented', false),
        _buildStatusChip('Recovery actions agreed', false),
        _buildStatusChip('Schedule & milestones', true),
        _buildStatusChip('Budget & costs', false),
        _buildStatusChip('Scope & quality', false),
        _buildStatusChip('Benefits delivered', false),
      ],
    );
  }

  Widget _buildStatusChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? Colors.white : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildHelperChips() {
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: [
        _buildHelperItem('Use the baseline business case as your reference'),
        _buildHelperItem('Quantify gaps where possible'),
        _buildHelperItem('Capture only the 3-5 most material gaps'),
      ],
    );
  }

  Widget _buildHelperItem(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFD1D5DB),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeliveryPerformanceCard(),
              const SizedBox(height: 16),
              _buildScheduleGapCard(),
              const SizedBox(height: 16),
              _buildCostBudgetGapCard(),
              const SizedBox(height: 16),
              _buildScopeQualityCard(),
              const SizedBox(height: 16),
              _buildBenefitsRealizationCard(),
              const SizedBox(height: 16),
              _buildRootCausesCard(),
            ],
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildDeliveryPerformanceCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildScheduleGapCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildCostBudgetGapCard()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildScopeQualityCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildBenefitsRealizationCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildRootCausesCard()),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeliveryPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Delivery performance snapshot',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Mostly on track (minor drift)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'High-level summary of how the project landed vs. plan across time, cost, scope, and benefits.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Schedule:', '+3 weeks vs. baseline launch date', const Color(0xFF2563EB)),
          const SizedBox(height: 10),
          _buildInfoRow('Budget:', '+6% vs. approved budget', const Color(0xFF2563EB)),
          const SizedBox(height: 10),
          _buildInfoRow('Scope:', '92% of planned scope delivered (8% deferred)', const Color(0xFF2563EB)),
          const SizedBox(height: 10),
          _buildInfoRow('Benefits:', '80–85% of year-1 value currently visible', const Color(0xFF6B7280)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: valueColor),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleGapCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Schedule gap analysis',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Time variance',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Compare planned vs. actual dates for major milestones and highlight the main drivers for delay or acceleration.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildBulletItem('List the 3–5 milestones with the largest slippage.'),
          _buildBulletItem('Note whether slippage was internal, vendor, or dependency-driven.'),
          _buildBulletItem('Capture what you would change next time (e.g. buffers, approvals).'),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF6B7280),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBudgetGapCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cost & budget gap',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Cost variance',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Summarize where actual spend diverged from budget and whether over/under-runs are one-off or structural.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildBulletItem('Show total variance and the top 2–3 categories driving it.'),
          _buildBulletItem('Separate launch one-time costs from ongoing run-rate impact.'),
          _buildBulletItem('Note if any savings or efficiencies were achieved vs. plan.'),
        ],
      ),
    );
  }

  Widget _buildScopeQualityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Scope & quality alignment',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'What changed?',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Describe how the delivered scope and quality compare to what was originally committed.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildBulletItem('Highlight any features or deliverables descoped or added.'),
          _buildBulletItem('Capture quality issues (defects, rework, incidents) vs. expectations.'),
          _buildBulletItem('Note customer or stakeholder satisfaction signals.'),
        ],
      ),
    );
  }

  Widget _buildBenefitsRealizationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Benefits realization gap',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Value vs. forecast',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Compare early benefits (revenue, savings, experience lift) to the business case expectations.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildBulletItem('Summarize current vs. planned benefits at launch + 3/6/12 months.'),
          _buildBulletItem('Explain any delays in realizing benefits (adoption, change, market).'),
          _buildBulletItem('State whether benefits are likely to catch up or remain lower.'),
        ],
      ),
    );
  }

  Widget _buildRootCausesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Root causes & learnings',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Why gaps happened',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Group the main drivers behind gaps so they can be addressed in future projects.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildBulletItem('Cluster causes into planning, execution, vendor, or external factors.'),
          _buildBulletItem('Call out any repeated patterns from previous projects.'),
          _buildBulletItem('Capture 3–5 focused lessons to feed back into your playbook.'),
        ],
      ),
    );
  }

  Widget _buildBottomCards(BuildContext context, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecoveryActionsCard(),
              const SizedBox(height: 16),
              _buildOverallGapSummaryCard(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildRecoveryActionsCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildOverallGapSummaryCard()),
          ],
        );
      },
    );
  }

  Widget _buildRecoveryActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recovery actions & follow-ups',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Course corrections',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Document the targeted actions to close the most material gaps or prevent them from worsening.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildBulletItem('List 3–5 concrete actions with owners and dates.'),
          _buildBulletItem('Differentiate between "fix now" vs. "improve next project" items.'),
          _buildBulletItem('Note any approvals or funding needed to execute these actions.'),
        ],
      ),
    );
  }

  Widget _buildOverallGapSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Overall gap summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Story in one page',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Provide a concise narrative that explains how far the project landed from plan and why that is acceptable or not.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildBulletItem('State overall delivery verdict (on track, minor drift, major gap).'),
          _buildBulletItem('Highlight the 2–3 gaps that matter most for leadership.'),
          _buildBulletItem('Confirm how this analysis will be used in future decisions.'),
        ],
      ),
    );
  }

  Widget _buildFooterNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;
          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back: Commerce viability'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Launch phase · Actual vs planned gap analysis',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                      label: const Text('Help me summarize key gaps'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      label: const Text('Next: Demobilize team'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: const Color(0xFFF59E0B).withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Focus this page on signal, not detail. Capture only the gaps big enough to change the project's story or what you would do differently.",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.checklist_outlined, size: 16, color: Colors.white),
                  label: const Text('Review gap analysis summary'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back: Commerce viability'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Launch phase · Actual vs planned gap analysis',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                    label: const Text('Help me summarize key gaps'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                    label: const Text('Next: Demobilize team'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: const Color(0xFFF59E0B).withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Focus this page on signal, not detail. Capture only the gaps big enough to change the project's story or what you would do differently.",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.checklist_outlined, size: 16, color: Colors.white),
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Review gap analysis summary'),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: Colors.white),
                      ],
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
