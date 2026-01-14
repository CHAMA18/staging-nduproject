import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/screens/startup_planning_screen.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';

class InterfaceManagementScreen extends StatelessWidget {
  const InterfaceManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InterfaceManagementScreen()),
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Interface Management'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final gap = 24.0;
                        final twoCol = width >= 980;
                        final halfWidth = twoCol ? (width - gap) / 2 : width;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(onBack: () => Navigator.maybePop(context)),
                            const SizedBox(height: 12),
                            const Text(
                              'Coordinate system interfaces, dependencies, and handoffs.',
                              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            const PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: 'Interface Management',
                              noteKey: 'planning_interface_management_notes',
                              checkpoint: 'interface_management',
                              description: 'Summarize interface ownership, dependency risks, and governance cadence.',
                            ),
                            const SizedBox(height: 24),
                            const _MetricsRow(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(width: halfWidth, child: const _InterfaceMapCard()),
                                SizedBox(width: halfWidth, child: const _GovernanceCard()),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const _InterfaceRegisterCard(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(width: halfWidth, child: const _RisksCard()),
                                SizedBox(width: halfWidth, child: const _DecisionLogCard()),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const SizedBox(height: 12),
                            LaunchPhaseNavigation(
                              backLabel: 'Back: Technology',
                              nextLabel: 'Next: Start-Up Planning',
                              onBack: () => Navigator.of(context).maybePop(),
                              onNext: () => StartUpPlanningScreen.open(context),
                            ),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
                  ),
                  const Positioned(right: 24, bottom: 24, child: KazAiChatBubble()),
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
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const _CircleIconButton(icon: Icons.arrow_forward_ios_rounded),
        const SizedBox(width: 16),
        const Text(
          'Interface Management',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
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
    final displayName = user?.displayName ?? user?.email ?? 'User';

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
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Text('Product manager', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: const [
        _MetricCard(label: 'Active Interfaces', value: '12', accent: Color(0xFF2563EB)),
        _MetricCard(label: 'Critical Dependencies', value: '4', accent: Color(0xFFF59E0B)),
        _MetricCard(label: 'Integration Owners', value: '6', accent: Color(0xFF10B981)),
        _MetricCard(label: 'Open Issues', value: '3', accent: Color(0xFFEF4444)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.accent});

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
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent),
          ),
        ],
      ),
    );
  }
}

class _InterfaceMapCard extends StatelessWidget {
  const _InterfaceMapCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Interface Architecture Overview',
      subtitle: 'Key systems and integration touchpoints.',
      child: Column(
        children: const [
          _SystemRow(name: 'Admin Portal', detail: 'API Gateway, Auth Service', color: Color(0xFFE0F2FE)),
          _SystemRow(name: 'Vendor Management', detail: 'Procurement DB, Contract Service', color: Color(0xFFFFF4CC)),
          _SystemRow(name: 'Analytics Hub', detail: 'Event Stream, Data Lake', color: Color(0xFFE8F5E9)),
        ],
      ),
    );
  }
}

class _GovernanceCard extends StatelessWidget {
  const _GovernanceCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Governance & Cadence',
      subtitle: 'How interfaces are reviewed and approved.',
      child: Column(
        children: const [
          _ChecklistRow(text: 'Weekly interface sync with owners and QA'),
          _ChecklistRow(text: 'Monthly dependency risk review'),
          _ChecklistRow(text: 'Change requests logged within 24h'),
          _ChecklistRow(text: 'Integration test sign-off before release'),
        ],
      ),
    );
  }
}

class _InterfaceRegisterCard extends StatelessWidget {
  const _InterfaceRegisterCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Interface Register',
      subtitle: 'Track ownership, status, and risk for every interface.',
      child: Column(
        children: const [
          _RegisterHeader(),
          SizedBox(height: 10),
          _RegisterRow(system: 'Payment Gateway', owner: 'IT Ops', status: 'In Progress', risk: 'Medium', lastSync: '2 days ago'),
          _RegisterRow(system: 'Identity Provider', owner: 'Security', status: 'Approved', risk: 'Low', lastSync: 'Yesterday'),
          _RegisterRow(system: 'CRM System', owner: 'Data', status: 'Pending', risk: 'High', lastSync: '5 days ago'),
        ],
      ),
    );
  }
}

class _RisksCard extends StatelessWidget {
  const _RisksCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Dependency Risks',
      subtitle: 'Critical items to resolve before baseline freeze.',
      child: Column(
        children: const [
          _BulletRow(text: 'Vendor API throttling limits require caching strategy.'),
          _BulletRow(text: 'Payment gateway certification still pending QA review.'),
          _BulletRow(text: 'Data sync latency exceeds 2-minute SLA.'),
        ],
      ),
    );
  }
}

class _DecisionLogCard extends StatelessWidget {
  const _DecisionLogCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Decision Log',
      subtitle: 'Recent interface decisions and approvals.',
      child: Column(
        children: const [
          _DecisionRow(title: 'Auth service to use OAuth2', owner: 'Security Team', date: 'May 2'),
          _DecisionRow(title: 'API Gateway SLA updated to 99.5%', owner: 'Platform', date: 'Apr 29'),
          _DecisionRow(title: 'CRM sync to run hourly', owner: 'Data Team', date: 'Apr 25'),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});

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
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SystemRow extends StatelessWidget {
  const _SystemRow({required this.name, required this.detail, required this.color});

  final String name;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.device_hub, size: 18, color: Color(0xFF1F2937)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(detail, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
              ],
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
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
        ],
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Text('System', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        SizedBox(width: 110, child: Text('Owner', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        SizedBox(width: 90, child: Text('Status', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        SizedBox(width: 80, child: Text('Risk', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        SizedBox(width: 90, child: Text('Last Sync', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
      ],
    );
  }
}

class _RegisterRow extends StatelessWidget {
  const _RegisterRow({
    required this.system,
    required this.owner,
    required this.status,
    required this.risk,
    required this.lastSync,
  });

  final String system;
  final String owner;
  final String status;
  final String risk;
  final String lastSync;

  Color _riskColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(system, style: const TextStyle(fontSize: 12, color: Color(0xFF111827)))),
          SizedBox(width: 110, child: Text(owner, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          SizedBox(
            width: 90,
            child: Text(status, style: TextStyle(fontSize: 12, color: _statusColor(status))),
          ),
          SizedBox(
            width: 80,
            child: Text(risk, style: TextStyle(fontSize: 12, color: _riskColor(risk))),
          ),
          SizedBox(width: 90, child: Text(lastSync, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
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
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4))),
        ],
      ),
    );
  }
}

class _DecisionRow extends StatelessWidget {
  const _DecisionRow({required this.title, required this.owner, required this.date});

  final String title;
  final String owner;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          SizedBox(width: 120, child: Text(owner, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          SizedBox(width: 70, child: Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
        ],
      ),
    );
  }
}
