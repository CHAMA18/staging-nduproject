import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';

class TransitionToProdTeamScreen extends StatefulWidget {
  const TransitionToProdTeamScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransitionToProdTeamScreen()),
    );
  }

  @override
  State<TransitionToProdTeamScreen> createState() => _TransitionToProdTeamScreenState();
}

class _TransitionToProdTeamScreenState extends State<TransitionToProdTeamScreen> {
  // Guided transition steps state
  final Map<String, _StepStatus> _stepsState = {
    'confirm_ownership': _StepStatus.complete,
    'finalize_runbooks': _StepStatus.gaps,
    'wire_monitoring': _StepStatus.inProgress,
    'address_risks': _StepStatus.requiresReview,
    'capture_acceptance': _StepStatus.notStarted,
  };

  // Sign-off state
  final Map<String, _SignoffStatus> _signoffState = {
    'casey_morgan': _SignoffStatus.signed,
    'jordan_lee': _SignoffStatus.pending,
    'client_rep': _SignoffStatus.pending,
    'exec_sponsor': _SignoffStatus.notRequested,
  };

  // Artifact filter
  String _artifactFilter = 'all';

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
              child: const InitiationLikeSidebar(activeItemLabel: 'Transition To Production Team'),
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 900;
                            if (isCompact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTransitionSummaryCard(context),
                                  const SizedBox(height: 24),
                                  _buildGuidedTransitionSteps(context),
                                  const SizedBox(height: 24),
                                  _buildKeyHandoverArtifacts(context),
                                  const SizedBox(height: 24),
                                  _buildOpsClientSignOff(context),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildTransitionSummaryCard(context),
                                      const SizedBox(height: 24),
                                      _buildGuidedTransitionSteps(context),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildKeyHandoverArtifacts(context),
                                      const SizedBox(height: 24),
                                      _buildOpsClientSignOff(context),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
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
                'Transition to Prod Team · Guided flow',
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
                  'Phase 4 · Closure · Pulling data from planning, design & execution',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4338CA),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Step-by-step handover checklist that stitches together staffing, knowledge, monitoring and risks into a single, finishable flow.',
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
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Preview handover dossier'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
              label: const Text('Mark transition complete'),
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

  Widget _buildTransitionSummaryCard(BuildContext context) {
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
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transition summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'High-level view of what remains before Ops fully owns the solution.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.list_alt_outlined, size: 16, color: Color(0xFF2563EB)),
                label: const Text('View detailed checklist', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildSummaryChip('Overall handover', '82%', null),
              _buildSummaryChip('Ops staffing from Ops Staffing', 'Completed', null),
              _buildSummaryChip('Runbooks from Design & Execution', '6 / 8 approved', null),
              _buildSummaryChip('Open handover risks from Risk Tracking', '3', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color? valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidedTransitionSteps(BuildContext context) {
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
          const Text(
            'Guided transition steps',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Minimal set of actions to close the loop with Ops and the client.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          _buildTransitionStep(
            stepNumber: 1,
            title: 'Confirm Ops ownership & coverage',
            description: 'Imported from Ops Staffing & Stakeholder Alignment. L1-L3 contacts and escalation paths saved to directory.',
            actionLabel: 'Review ownership snapshot',
            status: _stepsState['confirm_ownership']!,
          ),
          _buildTransitionStep(
            stepNumber: 2,
            title: 'Finalize runbooks, SOPs & training',
            description: 'Pulling drafts from Execution Dashboard, Design Management, Technical Debt and Launch Checklist.',
            actionLabel: 'Resolve missing procedures',
            status: _stepsState['finalize_runbooks']!,
          ),
          _buildTransitionStep(
            stepNumber: 3,
            title: 'Wire monitoring, alerts & SLAs to Ops tools',
            description: 'Key KPIs, risk alerts and warranties synced from Risk Tracking, Contracts, Vendor Tracking and Ops Maintenance.',
            actionLabel: 'Open monitoring handover',
            status: _stepsState['wire_monitoring']!,
          ),
          _buildTransitionStep(
            stepNumber: 4,
            title: 'Address residual risks & gaps',
            description: 'Links to Gap Reconciliation, Scope Completion, Punchlist Dashboard and Technical Debt modules.',
            actionLabel: 'Review 3 open handover risks',
            status: _stepsState['address_risks']!,
          ),
          _buildTransitionStep(
            stepNumber: 5,
            title: 'Capture formal Ops & client acceptance',
            description: 'Creates the transition record used by Project Closure and portfolio roll-ups.',
            actionLabel: 'Open acceptance form',
            status: _stepsState['capture_acceptance']!,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionStep({
    required int stepNumber,
    required String title,
    required String description,
    required String actionLabel,
    required _StepStatus status,
    bool isLast = false,
  }) {
    Color statusColor;
    String statusText;
    switch (status) {
      case _StepStatus.complete:
        statusColor = const Color(0xFF16A34A);
        statusText = 'Complete';
        break;
      case _StepStatus.gaps:
        statusColor = const Color(0xFFF59E0B);
        statusText = '2 gaps';
        break;
      case _StepStatus.inProgress:
        statusColor = const Color(0xFF2563EB);
        statusText = 'In progress';
        break;
      case _StepStatus.requiresReview:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Requires review';
        break;
      case _StepStatus.notStarted:
        statusColor = const Color(0xFF6B7280);
        statusText = 'Not started';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status == _StepStatus.complete ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == _StepStatus.complete ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: status == _StepStatus.complete ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: status == _StepStatus.complete
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$stepNumber',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: status == _StepStatus.complete ? const Color(0xFF166534) : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {},
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusText,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyHandoverArtifacts(BuildContext context) {
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
          const Text(
            'Key handover artifacts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Curated from planning, design, execution and risk tools.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          // Filter tabs
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterTab('All', 'all'),
              _buildFilterTab('From Planning: Scope & baselines', 'planning'),
              _buildFilterTab('From Design: Detailed design & models', 'design'),
              _buildFilterTab('From Execution: Ops runbooks', 'execution'),
              _buildFilterTab('From Risk: Risk & warranty view', 'risk'),
            ],
          ),
          const SizedBox(height: 20),
          _buildArtifactItem(
            icon: Icons.menu_book_outlined,
            title: 'Operations runbook bundle',
            description: 'SOPs, incident flows, change playbooks · 6 of 8 approved · Linked from Execution Dashboard, Launch Checklist.',
            statusColor: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 12),
          _buildArtifactItem(
            icon: Icons.architecture_outlined,
            title: 'Architecture & design pack',
            description: 'Final models, integrations, interface contracts · From Design Management & Tools Integration hub.',
            statusColor: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 12),
          _buildArtifactItem(
            icon: Icons.warning_amber_outlined,
            title: 'Residual risks & technical debt',
            description: 'Unresolved items from Risk Tracking, Technical Debt, Punchlist Dashboard and Gap Reconciliation.',
            statusColor: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),
          _buildArtifactItem(
            icon: Icons.gavel_outlined,
            title: 'Support SLAs, contracts & warranties',
            description: 'Pulled from Contracts Dashboard, Vendor Tracking, Commerce Warranty and Scope Completion.',
            statusColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isActive = _artifactFilter == value;
    return InkWell(
      onTap: () => setState(() => _artifactFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF4338CA) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildArtifactItem({
    required IconData icon,
    required String title,
    required String description,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpsClientSignOff(BuildContext context) {
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
          const Text(
            'Ops & client sign-off',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Final confirmations before moving to Contract Close Out.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          // Stats row
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildStatChip('Approvals', '2 / 4 captured'),
              _buildStatChip('Warm support window', '90 days'),
              _buildStatChip('Blocked items', '1', valueColor: const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 20),
          _buildSignoffItem('OM', 'Casey Morgan', 'Operations Manager · Owns production run', _signoffState['casey_morgan']!),
          const SizedBox(height: 12),
          _buildSignoffItem('PM', 'Jordan Lee', 'Project Manager · Confirms scope & delivery', _signoffState['jordan_lee']!),
          const SizedBox(height: 12),
          _buildSignoffItem('CR', 'Client rep', 'Client Representative · Accepts service handover', _signoffState['client_rep']!),
          const SizedBox(height: 12),
          _buildSignoffItem('EX', 'Exec sponsor', 'Executive Sponsor · Optional governance approval', _signoffState['exec_sponsor']!),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Request signatures'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                  label: const Text('Continue to Contract Close Out'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignoffItem(String initials, String name, String role, _SignoffStatus status) {
    Color statusColor;
    String statusText;
    Color bgColor;
    switch (status) {
      case _SignoffStatus.signed:
        statusColor = const Color(0xFF16A34A);
        statusText = 'Signed';
        bgColor = const Color(0xFFF0FDF4);
        break;
      case _SignoffStatus.pending:
        statusColor = const Color(0xFFF59E0B);
        statusText = 'Pending';
        bgColor = const Color(0xFFFFFBEB);
        break;
      case _SignoffStatus.notRequested:
        statusColor = const Color(0xFF6B7280);
        statusText = 'Not requested';
        bgColor = const Color(0xFFF9FAFB);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Text(
            statusText,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
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
              'This guided Transition to Prod Team view keeps the focus on a small number of finishable steps, aggregating evidence from earlier phases without overwhelming the Ops lead.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0C4A6E)),
            ),
          ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () {},
            child: const Text('View full Phase 4 closure map', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }
}

enum _StepStatus {
  complete,
  gaps,
  inProgress,
  requiresReview,
  notStarted,
}

enum _SignoffStatus {
  signed,
  pending,
  notRequested,
}
