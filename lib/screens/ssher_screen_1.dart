import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:ndu_project/screens/ssher_components.dart';
import 'package:ndu_project/screens/ssher_screen_2.dart';
import 'package:ndu_project/screens/team_management_screen.dart';
import 'package:ndu_project/screens/change_management_screen.dart';
import 'package:ndu_project/screens/home_screen.dart';
import 'package:ndu_project/screens/lessons_learned_screen.dart';
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/screens/settings_screen.dart';

class SsherScreen1 extends StatelessWidget {
  const SsherScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _Header(title: 'SSHER'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Sidebar(current: 'SSHER'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Plan Summary
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.08),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), shape: BoxShape.circle),
                                      child: const Icon(Icons.receipt_long, size: 18, color: Colors.blue),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text('SSHER Plan Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                                ),
                                child: Text(
                                  'This SSHER plan encompasses comprehensive risk management across all operational domains. Safety protocols focus on workplace injury prevention and emergency response procedures. Security measures address both physical and cyber threats with multi- layered protection strategies. Health initiatives promote employee wellbeing and occupational health standards. Environmental considerations ensure sustainable practices and regulatory compliance. Regulatory frameworks maintain adherence to industry standards and legal requirements .',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Safety section
                        SsherSectionCard(
                          leadingIcon: Icons.health_and_safety,
                          accentColor: const Color(0xFF34A853),
                          title: 'Safety',
                          subtitle: 'Workplace safety protocols and risk management',
                          detailsPlaceholder:
                              'Comprehensive safety protocols including personal protective equipment requirements, emergency evacuation procedures, incident reporting systems , and regular safety training programs for all personnel .',
                          itemsLabel: '12 Items',
                          addButtonLabel: 'Add Safety Item',
                          columns: const ['#', 'Department', 'Team Member', 'Safety Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
                          rows: [
                            [
                              const Text('1', style: TextStyle(fontSize: 12)),
                              const Text('Operations', style: TextStyle(fontSize: 13)),
                              const Text('Sarah Johnson', style: TextStyle(fontSize: 13)),
                              const Text('Chemical exposure i...', style: TextStyle(fontSize: 13, color: Colors.black87)),
                              const RiskBadge.high(),
                              const Text('Enhanced ventilation s...', style: TextStyle(fontSize: 13)),
                              const ActionButtons(),
                            ],
                            [
                              const Text('2', style: TextStyle(fontSize: 12)),
                              const Text('Manufacturing', style: TextStyle(fontSize: 13)),
                              const Text('Mike Chen', style: TextStyle(fontSize: 13)),
                              const Text('Heavy machinery o...', style: TextStyle(fontSize: 13)),
                              const RiskBadge.high(),
                              const Text('Operator certification, ...', style: TextStyle(fontSize: 13)),
                              const ActionButtons(),
                            ],
                          ],
                        ),

                        // Security header only (as shown in first screenshot)
                        SsherSectionCard(
                          leadingIcon: Icons.shield_outlined,
                          accentColor: const Color(0xFFEF5350),
                          title: 'Security',
                          subtitle: 'Physical and cyber security measures',
                          detailsPlaceholder:
                              'Multi- layered security approach including physical access controls, cybersecurity measures, surveillance systems, and incident response',
                          itemsLabel: '12 Items',
                          addButtonLabel: 'Add Safety Item',
                          columns: const ['#', 'Department', 'Team Member', 'Security Concern', 'Risk Level', 'Mitigation Strategy', 'Actions'],
                          rows: const [],
                        ),

                        // navigation to next page
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SsherScreen2())),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      child: Row(
        children: [
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
        ],
      ),
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
