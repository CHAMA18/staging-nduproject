import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';

class FinalizeProjectScreen extends StatelessWidget {
  const FinalizeProjectScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FinalizeProjectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = AppBreakpoints.isMobile(context) ? 20 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Finalize Project'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FinalizeHero(),
                        const SizedBox(height: 24),
                        const _FinalizeSnapshot(),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isWide = constraints.maxWidth >= 980;
                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Expanded(child: _FinalizeChecklist()),
                                  SizedBox(width: 20),
                                  Expanded(child: _SignOffPanel()),
                                ],
                              );
                            }
                            return Column(
                              children: const [
                                _FinalizeChecklist(),
                                SizedBox(height: 20),
                                _SignOffPanel(),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const _ClosureInsights(),
                        const SizedBox(height: 28),
                        const _ActionBar(),
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
}

class _FinalizeHero extends StatelessWidget {
  const _FinalizeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 30, offset: const Offset(0, 18)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB020),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Finalization',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1D1F)),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Readiness 92%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7DD3FC)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Finalize Project',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'Lock the scope, verify handoffs, and secure final approvals with a comprehensive closeout flow.',
            style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFFE5E7EB)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _HeroStat(label: 'Open approvals', value: '2'),
              _HeroStat(label: 'Final docs', value: '9/10'),
              _HeroStat(label: 'Risks to watch', value: '1'),
              _HeroStat(label: 'Ops readiness', value: 'On track'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}

class _FinalizeSnapshot extends StatelessWidget {
  const _FinalizeSnapshot();

  @override
  Widget build(BuildContext context) {
    const cards = [
      _SnapshotCardData(
        title: 'Delivery Package',
        subtitle: 'Final artifacts and deployment notes',
        value: '92%',
        accent: Color(0xFF16A34A),
      ),
      _SnapshotCardData(
        title: 'Stakeholder Sign-off',
        subtitle: 'Pending approvals',
        value: '2',
        accent: Color(0xFF2563EB),
      ),
      _SnapshotCardData(
        title: 'Budget Closure',
        subtitle: 'Variance vs. forecast',
        value: '-3.4%',
        accent: Color(0xFFF59E0B),
      ),
      _SnapshotCardData(
        title: 'Ops Readiness',
        subtitle: 'Handover confidence',
        value: 'Ready',
        accent: Color(0xFF7C3AED),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 1024;
        final double gap = 16;
        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: _SnapshotCard(data: cards[i])),
                if (i != cards.length - 1) const SizedBox(width: 16),
              ],
            ],
          );
        }
        final double width = constraints.maxWidth >= 640 ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards) SizedBox(width: width, child: _SnapshotCard(data: card)),
          ],
        );
      },
    );
  }
}

class _SnapshotCardData {
  const _SnapshotCardData({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String value;
  final Color accent;
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.data});

  final _SnapshotCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.task_alt_outlined, color: data.accent, size: 20),
              ),
              Text(
                data.value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: data.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(data.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text(data.subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _FinalizeChecklist extends StatelessWidget {
  const _FinalizeChecklist();

  @override
  Widget build(BuildContext context) {
    const steps = [
      _ChecklistStep(
        title: 'Close remaining change requests',
        detail: 'Confirm the last scope changes and archive CR notes.',
        status: _ChecklistStatus.done,
      ),
      _ChecklistStep(
        title: 'Validate final acceptance criteria',
        detail: 'Gather approvals from executive sponsor and QA.',
        status: _ChecklistStatus.inProgress,
      ),
      _ChecklistStep(
        title: 'Confirm handover readiness',
        detail: 'Finalize runbooks, escalation paths, and support SLAs.',
        status: _ChecklistStatus.pending,
      ),
      _ChecklistStep(
        title: 'Archive delivery artifacts',
        detail: 'Store documentation, release notes, and contracts.',
        status: _ChecklistStatus.pending,
      ),
    ];

    return _SectionCard(
      title: 'Finalization Checklist',
      subtitle: 'Lock down every last dependency before sign-off',
      icon: Icons.check_circle_outline,
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _ChecklistRow(step: steps[i]),
            if (i != steps.length - 1) const Divider(height: 24, color: Color(0xFFE5E7EB)),
          ],
        ],
      ),
    );
  }
}

enum _ChecklistStatus { done, inProgress, pending }

class _ChecklistStep {
  const _ChecklistStep({required this.title, required this.detail, required this.status});

  final String title;
  final String detail;
  final _ChecklistStatus status;
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.step});

  final _ChecklistStep step;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(step.status);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: statusStyle.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(statusStyle.icon, color: statusStyle.color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              const SizedBox(height: 6),
              Text(step.detail, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusStyle.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusStyle.label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusStyle.color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChecklistStatusStyle {
  const _ChecklistStatusStyle({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
}

_ChecklistStatusStyle _statusStyle(_ChecklistStatus status) {
  switch (status) {
    case _ChecklistStatus.done:
      return const _ChecklistStatusStyle(
        label: 'Completed',
        icon: Icons.check_circle_outline,
        color: Color(0xFF16A34A),
        background: Color(0xFFDCFCE7),
      );
    case _ChecklistStatus.inProgress:
      return const _ChecklistStatusStyle(
        label: 'In progress',
        icon: Icons.timelapse_outlined,
        color: Color(0xFF2563EB),
        background: Color(0xFFE0F2FE),
      );
    case _ChecklistStatus.pending:
      return const _ChecklistStatusStyle(
        label: 'Pending',
        icon: Icons.pending_outlined,
        color: Color(0xFFF59E0B),
        background: Color(0xFFFFEDD5),
      );
  }
}

class _SignOffPanel extends StatelessWidget {
  const _SignOffPanel();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Executive Sign-off',
      subtitle: 'Confirm ownership and approval before closing',
      icon: Icons.verified_outlined,
      child: Column(
        children: [
          const _SignOffRow(
            name: 'Project Sponsor',
            role: 'Final approval',
            status: 'Pending',
            statusColor: Color(0xFFF59E0B),
          ),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          const _SignOffRow(
            name: 'Operations Lead',
            role: 'Handover acceptance',
            status: 'Approved',
            statusColor: Color(0xFF16A34A),
          ),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          const _SignOffRow(
            name: 'Finance Controller',
            role: 'Budget closeout',
            status: 'Approved',
            statusColor: Color(0xFF16A34A),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F2937),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Review packet'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Request sign-off'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignOffRow extends StatelessWidget {
  const _SignOffRow({
    required this.name,
    required this.role,
    required this.status,
    required this.statusColor,
  });

  final String name;
  final String role;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFF3F4F6),
          child: Text(name.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              const SizedBox(height: 4),
              Text(role, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
          ),
        ),
      ],
    );
  }
}

class _ClosureInsights extends StatelessWidget {
  const _ClosureInsights();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Closure Insights',
      subtitle: 'Final risks and handover commitments',
      icon: Icons.lightbulb_outline,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return Row(
              children: const [
                Expanded(child: _InsightCard(title: 'Outstanding Risks', detail: '1 low-priority risk requires monitoring.')),
                SizedBox(width: 16),
                Expanded(child: _InsightCard(title: 'Support Coverage', detail: '24/7 escalation in place for the first 30 days.')),
                SizedBox(width: 16),
                Expanded(child: _InsightCard(title: 'Warranty Window', detail: '90-day defect warranty confirmed.')),
              ],
            );
          }
          return Column(
            children: const [
              _InsightCard(title: 'Outstanding Risks', detail: '1 low-priority risk requires monitoring.'),
              SizedBox(height: 16),
              _InsightCard(title: 'Support Coverage', detail: '24/7 escalation in place for the first 30 days.'),
              SizedBox(height: 16),
              _InsightCard(title: 'Warranty Window', detail: '90-day defect warranty confirmed.'),
            ],
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          Text(detail, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4)),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ready to finalize?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                SizedBox(height: 4),
                Text('Run the final checks and close the project with confidence.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Run audit'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB020),
              foregroundColor: const Color(0xFF1A1D1F),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Confirm finalization'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}
