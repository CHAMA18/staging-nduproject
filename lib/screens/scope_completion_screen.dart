import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';

class ScopeCompletionScreen extends StatefulWidget {
  const ScopeCompletionScreen({super.key});

  static void open(BuildContext context) {
    context.push('/${AppRoutes.scopeCompletion}');
  }

  @override
  State<ScopeCompletionScreen> createState() => _ScopeCompletionScreenState();
}

class _ScopeCompletionScreenState extends State<ScopeCompletionScreen> {
  final Set<String> _selectedFilters = {'Clear view of delivered scope'};

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
              child: const InitiationLikeSidebar(activeItemLabel: 'Scope Completion'),
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
                        _buildFilterChips(context),
                        const SizedBox(height: 24),
                        _buildOverviewCard(context),
                        const SizedBox(height: 20),
                        _buildMainContentRow(context, isMobile),
                        const SizedBox(height: 24),
                        _buildFooterNavigation(context),
                        const SizedBox(height: 12),
                        _buildTipRow(context),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  const _AiHelperButton(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'SCOPE WRAP-UP',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Scope Completion',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Confirm what was delivered, what changed, and that sponsors agree the project scope is formally complete.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
            height: 1.5,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final List<String> filters = [
      'Clear view of delivered scope',
      'Changes captured and approved',
      'Ready for handover',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((label) {
        final isSelected = _selectedFilters.contains(label);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              _selectedFilters.remove(label);
            } else {
              _selectedFilters.add(label);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Text(
            'This page summarizes how closely delivery matched the agreed scope. Use it to show completion status, scope changes, and final acceptance so everyone understands what is in and out.',
            style: TextStyle(fontSize: 14, color: const Color(0xFF6B7280), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentRow(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildScopeCompletionStatusCard(context),
          const SizedBox(height: 16),
          _buildSponsorAcceptanceCard(context),
          const SizedBox(height: 16),
          _buildScopeChangeSummaryCard(context),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildScopeCompletionStatusCard(context),
        const SizedBox(height: 16),
        _buildSponsorAcceptanceCard(context),
        const SizedBox(height: 16),
        _buildScopeChangeSummaryCard(context),
      ],
    );
  }

  Widget _buildScopeCompletionStatusCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scope completion status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Execution summary',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Most planned scope has been delivered with a few items consciously deferred into a follow-up phase.',
            style: TextStyle(fontSize: 14, color: const Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 16),
          _buildMetricsRow(context),
          const SizedBox(height: 20),
          const Text(
            'Key work packages',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          _buildWorkPackageItem(
            title: 'Core platform rollout',
            description: 'Production deployment, monitoring, and access patterns delivered as designed.',
            status: 'Delivered',
            statusColor: const Color(0xFF10B981),
            owner: 'Engineering',
            impact: 'critical',
            milestone: 'Milestone M4',
          ),
          const SizedBox(height: 12),
          _buildWorkPackageItem(
            title: 'Reporting & dashboards',
            description: 'Baseline reports live; advanced analytics intentionally moved to next phase.',
            status: 'Partially delivered',
            statusColor: const Color(0xFFF59E0B),
            owner: 'Data lead',
            deferredLabel: 'Deferred items listed',
            milestone: 'Phase 2',
          ),
          const SizedBox(height: 12),
          _buildWorkPackageItem(
            title: 'Training & enablement',
            description: 'Key user groups trained; self-serve materials available in knowledge base.',
            status: 'Delivered',
            statusColor: const Color(0xFF10B981),
            owner: 'Change team',
            milestone: 'Completed',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricBox(
            value: '92%',
            label: 'Original scope delivered',
            statusLabel: 'On track',
            statusColor: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricBox(
            value: '3',
            label: 'Items deferred',
            statusLabel: 'Tracked in backlog',
            statusColor: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricBox(
            value: '1',
            label: 'Critical gap',
            statusLabel: 'Requires explicit sign-off',
            statusColor: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required String value,
    required String label,
    required String statusLabel,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: statusColor),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkPackageItem({
    required String title,
    required String description,
    required String status,
    required Color statusColor,
    required String owner,
    String? impact,
    String? deferredLabel,
    required String milestone,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
              ),
              Text(
                milestone,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildStatusChip(status, statusColor),
              _buildInfoChip('Owner: $owner'),
              if (impact != null) _buildInfoChip('Impact: $impact'),
              if (deferredLabel != null) _buildDeferredChip(deferredLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildDeferredChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFD97706)),
      ),
    );
  }

  Widget _buildSponsorAcceptanceCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sponsor acceptance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Sign-off readiness',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sponsors acknowledge that the delivered scope meets the agreed objectives and that any remaining items are either out-of-scope or planned as follow-up work.',
            style: TextStyle(fontSize: 14, color: const Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Acceptance checkpoints',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          _buildCheckpointItem('Scope baseline and all approved changes reviewed with sponsors.'),
          const SizedBox(height: 6),
          _buildCheckpointItem('Remaining items documented with owners and target timelines.'),
          const SizedBox(height: 6),
          _buildCheckpointItem('Support and operations confirm they can own the solution.'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildAcceptanceChip('Business sponsor verbally agreed', const Color(0xFF1F2937), Colors.white),
              _buildAcceptanceChip('Formal sign-off pending', const Color(0xFFF3F4F6), const Color(0xFF374151)),
              _buildAcceptanceChip('Ops + support aligned', const Color(0xFFF3F4F6), const Color(0xFF374151)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  ', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptanceChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  Widget _buildScopeChangeSummaryCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scope change summary',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Change log',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Not all changes need to be shown here — only the ones that meaningfully changed scope, budget, or timeline.',
            style: TextStyle(fontSize: 14, color: const Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 14),
          const Text(
            'Most impactful changes:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          _buildChangeItem('Added: vendor integration health dashboard.'),
          const SizedBox(height: 4),
          _buildChangeItem('Removed: in-sprint legacy migration (moved to separate track).'),
          const SizedBox(height: 4),
          _buildChangeItem('Adjusted: training scope expanded for frontline teams.'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildChangeChip('Total approved changes: 6', const Color(0xFFF3F4F6), const Color(0xFF374151)),
              _buildChangeChip('Unapproved changes: 0', const Color(0xFFFEE2E2), const Color(0xFFEF4444)),
              _buildChangeChip('Open change requests: 1', const Color(0xFFF3F4F6), const Color(0xFF374151)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  ', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  Widget _buildFooterNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF374151)),
            label: const Text(
              'Back to risk tracking',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Execution wrap-up · Scope view',
            style: TextStyle(fontSize: 13, color: const Color(0xFF9CA3AF)),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('Download scope report'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Finalize execution scope'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFC812),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lightbulb_outline, size: 18, color: const Color(0xFFFFC812)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'If someone reads only this page, can they quickly see what was delivered, what moved, and that the right people have agreed?',
            style: TextStyle(fontSize: 13, color: const Color(0xFF9CA3AF), fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  final Widget child;

  const _ContentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _AiHelperButton extends StatelessWidget {
  const _AiHelperButton();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 90,
      right: 100,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Help me summarize scope',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF374151)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
