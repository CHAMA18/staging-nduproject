import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:ndu_project/screens/ssher_components.dart';
import 'package:ndu_project/screens/team_management_screen.dart';
import 'package:ndu_project/screens/change_management_screen.dart';
import 'package:ndu_project/screens/home_screen.dart';
import 'package:ndu_project/screens/lessons_learned_screen.dart';
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/screens/settings_screen.dart';

class SsherScreen4 extends StatelessWidget {
  const SsherScreen4({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(children: [
        const _Header(title: 'SSHER'),
        Expanded(
          child: Row(children: [
            const _Sidebar(current: 'SSHER'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  SsherSectionCard(
                    leadingIcon: Icons.gavel_outlined,
                    accentColor: const Color(0xFF8E24AA),
                    title: 'Regulatory',
                    subtitle: 'Compliance and regulatory requirements',
                    detailsPlaceholder:
                        'EComprehensive regulatory compliance framework ensuring adherence to industry standards, legal requirements, and best practices. Regular audits documentation',
                    itemsLabel: '7 Items',
                    addButtonLabel: 'Add Regulatory Item',
                    columns: const ['#', 'Department', 'Team Member', 'Health Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
                    rows: const [
                      [
                        Text('1', style: TextStyle(fontSize: 12)),
                        Text('Operations', style: TextStyle(fontSize: 13)),
                        Text('Sarah Johnson', style: TextStyle(fontSize: 13)),
                        Text('Chemical exposure i...', style: TextStyle(fontSize: 13)),
                        RiskBadge.high(),
                        Text('Enhanced ventilation s...', style: TextStyle(fontSize: 13)),
                        ActionButtons(),
                      ],
                      [
                        Text('2', style: TextStyle(fontSize: 12)),
                        Text('Manufacturing', style: TextStyle(fontSize: 13)),
                        Text('Mike Chen', style: TextStyle(fontSize: 13)),
                        Text('Heavy machinery o...', style: TextStyle(fontSize: 13)),
                        RiskBadge.high(),
                        Text('Operator certification, ...', style: TextStyle(fontSize: 13)),
                        ActionButtons(),
                      ],
                    ],
                  ),
                ]),
              ),
            )
          ]),
        )
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        AppLogo(
          height: 56,
          width: 148,
        ),
        const SizedBox(width: 24),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, size: 16)),
        const SizedBox(width: 4),
        IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_forward_ios, size: 16)),
        const Spacer(),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const Spacer(),
        Row(children: [
          Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Samuel kamanga', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('Owner', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
        ]),
      ]),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String current;
  const _Sidebar({required this.current});
  @override
  Widget build(BuildContext context) {
    Widget menu(IconData icon, String title, {VoidCallback? onTap}) {
      final isActive = title == current;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? Colors.grey.withValues(alpha: 0.06) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700]), softWrap: true, maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      );
    }

    return Container(
      width: 320,
      color: Colors.white,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('StackOne', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
            ]),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(vertical: 20), children: [
            menu(Icons.home_outlined, 'Home', onTap: () => HomeScreen.open(context)),
            menu(Icons.shield_outlined, 'SSHER', onTap: () {}),
            menu(Icons.palette_outlined, 'Design'),
            menu(Icons.assignment_outlined, 'Execution Plan'),
            menu(Icons.computer_outlined, 'Technology'),
            menu(Icons.people_outline, 'Team Management', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamManagementScreen()),
              );
            }),
            menu(Icons.contact_mail_outlined, 'Contact'),
            menu(Icons.shopping_cart_outlined, 'Procurement'),
            menu(Icons.schedule_outlined, 'Schedule'),
            menu(Icons.attach_money_outlined, 'Cost Estimate'),
            menu(Icons.change_circle_outlined, 'Change Management', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeManagementScreen()),
              );
            }),
            menu(Icons.assessment_outlined, 'Project Plan'),
            menu(Icons.people_alt_outlined, 'Stakeholder Management'),
            menu(Icons.warning_outlined, 'Risk Assessment'),
            menu(Icons.bug_report_outlined, 'Issue Management'),
            menu(Icons.school_outlined, 'Lessons Learned', onTap: () => LessonsLearnedScreen.open(context)),
            menu(Icons.group_work_outlined, 'Team Training and Team Building'),
            const SizedBox(height: 20),
            menu(Icons.settings_outlined, 'Settings', onTap: () => SettingsScreen.open(context)),
            menu(Icons.logout_outlined, 'LogOut', onTap: () => AuthNav.signOutAndExit(context)),
          ]),
        )
      ]),
    );
  }
}
