import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/screens/deliverables_roadmap_screen.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';

class StartUpPlanningScreen extends StatelessWidget {
  const StartUpPlanningScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StartUpPlanningScreen()),
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
                  activeItemLabel: 'Start-Up Planning'),
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
                              'Plan readiness, go-live criteria, and transition activities.',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            const PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: 'Start-Up Planning',
                              noteKey: 'planning_startup_planning_notes',
                              checkpoint: 'startup_planning',
                              description:
                                  'Summarize launch readiness, dependencies, and cutover approach.',
                            ),
                            const SizedBox(height: 24),
                            const _ReadinessRow(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                    width: halfWidth,
                                    child: const _GoLiveChecklistCard()),
                                SizedBox(
                                    width: halfWidth,
                                    child: const _TrainingEnablementCard()),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const _CutoverPlanCard(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                    width: halfWidth,
                                    child: const _HypercarePlanCard()),
                                SizedBox(
                                    width: halfWidth,
                                    child: const _OpsHandoffCard()),
                              ],
                            ),
                            const SizedBox(height: 28),
                            LaunchPhaseNavigation(
                              backLabel: 'Back: Interface Management',
                              nextLabel: 'Next: Deliverable Roadmap',
                              onBack: () => Navigator.of(context).maybePop(),
                              onNext: () =>
                                  DeliverablesRoadmapScreen.open(context),
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
          'Start-Up Planning',
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

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: const [
        _MetricCard(
            label: 'Readiness Score', value: '82%', accent: Color(0xFF10B981)),
        _MetricCard(
            label: 'Open Readiness Tasks',
            value: '9',
            accent: Color(0xFFF59E0B)),
        _MetricCard(
            label: 'Launch Window', value: 'Jul 8', accent: Color(0xFF2563EB)),
        _MetricCard(
            label: 'Hypercare Days', value: '14', accent: Color(0xFF8B5CF6)),
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
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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

class _GoLiveChecklistCard extends StatelessWidget {
  const _GoLiveChecklistCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Go-Live Readiness Checklist',
      subtitle: 'Critical items required before launch.',
      child: Column(
        children: const [
          _ChecklistRow(text: 'Data migration validation completed'),
          _ChecklistRow(text: 'Performance tests signed off'),
          _ChecklistRow(text: 'Support escalation paths confirmed'),
          _ChecklistRow(text: 'Stakeholder approval captured'),
        ],
      ),
    );
  }
}

class _TrainingEnablementCard extends StatelessWidget {
  const _TrainingEnablementCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Training & Enablement',
      subtitle: 'Ensure teams are ready for launch day.',
      child: Column(
        children: const [
          _BulletRow(
              text: 'Role-based training sessions scheduled for all teams.'),
          _BulletRow(
              text: 'Runbooks distributed and validated with support leads.'),
          _BulletRow(text: 'Internal FAQ and escalation guides published.'),
        ],
      ),
    );
  }
}

class _CutoverPlanCard extends StatelessWidget {
  const _CutoverPlanCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Cutover & Launch Timeline',
      subtitle: 'Sequenced steps for the go-live window.',
      child: Column(
        children: const [
          _TimelineRow(
              time: 'T-48h', task: 'Freeze scope and final smoke tests'),
          _TimelineRow(
              time: 'T-24h', task: 'Data migration + validation checks'),
          _TimelineRow(
              time: 'T-4h', task: 'Enable monitoring + switch traffic routing'),
          _TimelineRow(
              time: 'T+0', task: 'Launch announcement + live verification'),
          _TimelineRow(time: 'T+4h', task: 'Hypercare war room begins'),
        ],
      ),
    );
  }
}

class _HypercarePlanCard extends StatelessWidget {
  const _HypercarePlanCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Hypercare Plan',
      subtitle: 'Post-launch monitoring and support.',
      child: Column(
        children: const [
          _ChecklistRow(text: 'Daily incident review with owners'),
          _ChecklistRow(text: 'Real-time SLA tracking dashboard'),
          _ChecklistRow(text: 'Bug triage and prioritization within 2 hours'),
        ],
      ),
    );
  }
}

class _OpsHandoffCard extends StatelessWidget {
  const _OpsHandoffCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Operations Handoff',
      subtitle: 'Ownership transition after launch.',
      child: Column(
        children: const [
          _BulletRow(text: 'Ops runbooks completed and reviewed'),
          _BulletRow(text: 'Support contacts and SLAs shared with teams'),
          _BulletRow(text: 'Monthly health checks scheduled'),
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

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.time, required this.task});

  final String time;
  final String task;

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
              width: 60,
              child: Text(time,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(
              child: Text(task,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
        ],
      ),
    );
  }
}
