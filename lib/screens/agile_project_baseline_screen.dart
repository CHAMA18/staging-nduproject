import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/screens/project_baseline_screen.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';

class AgileProjectBaselineScreen extends StatelessWidget {
  const AgileProjectBaselineScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AgileProjectBaselineScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 20.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Agile Project Baseline'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final gap = 24.0;
                        final twoCol = width >= 980;
                        final halfWidth = twoCol ? (width - gap) / 2 : width;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(
                                onBack: () => Navigator.maybePop(context)),
                            const SizedBox(height: 12),
                            const Text(
                              'Manage roles and responsibilities',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            const PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: 'Agile Project Baseline',
                              noteKey: 'planning_agile_project_baseline_notes',
                              checkpoint: 'agile_project_baseline',
                              description:
                                  'Capture baseline scope, delivery cadence, and key assumptions.',
                            ),
                            const SizedBox(height: 24),
                            _MetricsRow(isMobile: isMobile),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                    width: halfWidth,
                                    child: const _BaselineScopeCard()),
                                SizedBox(
                                    width: halfWidth,
                                    child: const _DefinitionOfDoneCard()),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const _SprintCadenceCard(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                    width: halfWidth,
                                    child: const _AssumptionsCard()),
                                SizedBox(
                                    width: halfWidth,
                                    child: const _ChangeControlCard()),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _RiskSnapshotRow(isMobile: isMobile),
                            const SizedBox(height: 28),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () =>
                                    ProjectBaselineScreen.open(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: const Color(0xFF111827),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 36, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text(
                                  'Next',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
                  ),
                  const Positioned(
                      right: 24,
                      bottom: 24,
                      child: KazAiChatBubble(positioned: false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const _CircleIconButton(icon: Icons.arrow_forward_ios_rounded),
        const SizedBox(width: 16),
        const Text(
          'Agile Project Baseline',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        const Spacer(),
        const _UserChip(),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final email = user?.email ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151)),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(displayName,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(role,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: Color(0xFF9CA3AF)),
            ],
          ),
        );
      },
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final gap = 16.0;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: const [
        _MetricCard(
            label: 'Sprint Length',
            value: '2 weeks',
            accent: Color(0xFF2563EB)),
        _MetricCard(
            label: 'Baseline Velocity',
            value: '42 pts',
            accent: Color(0xFF10B981)),
        _MetricCard(
            label: 'Committed Epics', value: '6', accent: Color(0xFFF59E0B)),
        _MetricCard(
            label: 'Target Release',
            value: 'Aug 2025',
            accent: Color(0xFF8B5CF6)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: accent),
          ),
        ],
      ),
    );
  }
}

class _BaselineScopeCard extends StatelessWidget {
  const _BaselineScopeCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Baseline Scope',
      subtitle: 'Committed epic outcomes for the baseline release.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ScopeChip(text: 'User onboarding & profile flows'),
          _ScopeChip(text: 'Real-time trip tracking'),
          _ScopeChip(text: 'Vendor procurement workflow'),
          _ScopeChip(text: 'Analytics & reporting dashboard'),
          _ScopeChip(text: 'Security hardening & access rules'),
        ],
      ),
    );
  }
}

class _DefinitionOfDoneCard extends StatelessWidget {
  const _DefinitionOfDoneCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Definition of Done',
      subtitle: 'Baseline quality gates applied to every sprint.',
      child: Column(
        children: const [
          _ChecklistRow(
              text: 'Acceptance criteria validated with stakeholders'),
          _ChecklistRow(text: 'Automated tests passing at 90% coverage'),
          _ChecklistRow(text: 'Performance budget met (<= 2s page load)'),
          _ChecklistRow(text: 'Security review signed off'),
        ],
      ),
    );
  }
}

class _SprintCadenceCard extends StatelessWidget {
  const _SprintCadenceCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Sprint Cadence & Release Baseline',
      subtitle: 'Baseline schedule for the next four sprints.',
      child: Column(
        children: const [
          _SprintRow(
              sprint: 'Sprint 1',
              dates: 'May 6 - May 17',
              goal: 'Core flows + baseline QA'),
          _SprintRow(
              sprint: 'Sprint 2',
              dates: 'May 20 - May 31',
              goal: 'Vendor workflows + APIs'),
          _SprintRow(
              sprint: 'Sprint 3',
              dates: 'Jun 3 - Jun 14',
              goal: 'Analytics + reporting'),
          _SprintRow(
              sprint: 'Sprint 4',
              dates: 'Jun 17 - Jun 28',
              goal: 'Security + release hardening'),
        ],
      ),
    );
  }
}

class _AssumptionsCard extends StatelessWidget {
  const _AssumptionsCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Baseline Assumptions',
      subtitle: 'Guardrails that keep delivery aligned to plan.',
      child: Column(
        children: const [
          _BulletRow(
              text:
                  'Team capacity stays at 7 FTE with two dedicated QA resources.'),
          _BulletRow(
              text:
                  'Vendor onboarding completes by Sprint 2 to unblock integrations.'),
          _BulletRow(
              text: 'No additional scope added without Change Control review.'),
        ],
      ),
    );
  }
}

class _ChangeControlCard extends StatelessWidget {
  const _ChangeControlCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Change Control',
      subtitle: 'How baseline scope changes are evaluated.',
      child: Column(
        children: const [
          _StepRow(
              step: '1', text: 'Change request logged with impact summary'),
          _StepRow(
              step: '2', text: 'Product + Delivery review within 48 hours'),
          _StepRow(
              step: '3',
              text: 'Baseline updated if approved by Steering Committee'),
        ],
      ),
    );
  }
}

class _RiskSnapshotRow extends StatelessWidget {
  const _RiskSnapshotRow({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final gap = 16.0;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: const [
        _MiniCard(
            title: 'Capacity Risk', value: 'Medium', color: Color(0xFFF59E0B)),
        _MiniCard(
            title: 'Vendor Dependency',
            value: 'High',
            color: Color(0xFFEF4444)),
        _MiniCard(
            title: 'Scope Volatility', value: 'Low', color: Color(0xFF10B981)),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard(
      {required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
        ],
      ),
    );
  }
}

class _SprintRow extends StatelessWidget {
  const _SprintRow(
      {required this.sprint, required this.dates, required this.goal});

  final String sprint;
  final String dates;
  final String goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(sprint,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600))),
          SizedBox(
              width: 140,
              child: Text(dates,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          Expanded(
              child: Text(goal,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF374151), height: 1.4))),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.text});

  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4CC),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(step,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E))),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
        ],
      ),
    );
  }
}
