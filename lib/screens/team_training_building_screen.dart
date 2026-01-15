import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/screens/training_project_tasks_screen.dart';

class TeamTrainingAndBuildingScreen extends StatelessWidget {
  const TeamTrainingAndBuildingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          DraggableSidebar(
            openWidth: sidebarWidth,
            child: const InitiationLikeSidebar(activeItemLabel: 'Team Training and Team Building'),
          ),
          Expanded(child: _buildMain(context)),
        ],
      ),
    );
  }


  Widget _buildMain(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _circleIconButton(Icons.arrow_back_ios),
                const SizedBox(width: 12),
                _circleIconButton(Icons.arrow_forward_ios),
                const SizedBox(width: 16),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Team Training and Team Building',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                  ),
                ),
                _profileCluster(context),
              ],
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.only(left: 6.0),
              child: Text(
                'Identify team training opportunities and team building intervals',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 16),
            const PlanningAiNotesCard(
              title: 'Notes',
              sectionLabel: 'Team Training and Team Building',
              noteKey: 'planning_team_training_notes',
              checkpoint: 'team_training',
              description: 'Outline training themes, cadence, and team-building priorities.',
            ),
            const SizedBox(height: 16),
            // Main overview card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Team Development Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Identify team training opportunities and team building intervals to boost team spirit and collaboration. Could be team shares (like safety moments).',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Training & Development
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Training & Development', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              'Continuous learning and skill development are essential for project success and professional growth. Our training program ensures team members have the knowledge and skills needed to excel in their roles.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: const [
                                Expanded(child: _StatTile(icon: Icons.school_outlined, label: 'Total Training Events', value: '5')),
                                SizedBox(width: 12),
                                Expanded(child: _StatTile(icon: Icons.verified_outlined, label: 'Completed Trainings', value: '2')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _UpcomingTrainingCard(accent: Colors.blue, heart: false),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Team Building
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Team Building', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              'Team building activities strengthen relationships, improve communication, and foster a collaborative environment. Regular team building events create a positive team culture and enhance productivity.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: const [
                                Expanded(child: _StatTile(icon: Icons.event_available_outlined, label: 'Team Building Events', value: '5')),
                                SizedBox(width: 12),
                                Expanded(child: _StatTile(icon: Icons.check_circle_outline, label: 'Completed Events', value: '2')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const _UpcomingTrainingCard(accent: Colors.purple, heart: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Benefits row
            Row(
              children: const [
                Expanded(child: _BenefitCard(icon: Icons.lightbulb_outline, title: 'Skill Development', subtitle: 'Enhance technical and soft skills through structured learning')),
                SizedBox(width: 12),
                Expanded(child: _BenefitCard(icon: Icons.favorite_border, title: 'Team Cohesion', subtitle: 'Build stronger relationships and mutual trust')),
                SizedBox(width: 12),
                Expanded(child: _BenefitCard(icon: Icons.speed_outlined, title: 'Improved Performance', subtitle: 'Boost productivity and quality of deliverables')),
                SizedBox(width: 12),
                Expanded(child: _BenefitCard(icon: Icons.auto_awesome_outlined, title: 'Innovation', subtitle: 'Enhance technical and soft skills through structured learning')),
              ],
            ),

            const SizedBox(height: 20),
            // Bottom segment with navigation
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TrainingProjectTasksScreen()),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text('Training Events', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 44, color: Colors.grey.withValues(alpha: 0.2)),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(child: Text('Team Building Activities', style: TextStyle(color: Colors.grey))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIconButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, size: 16, color: Colors.grey[700]),
    );
  }

  Widget _profileCluster(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final email = user?.email ?? '';
    final name = displayName.isNotEmpty ? displayName : (email.isNotEmpty ? email : 'User');
    final photoUrl = user?.photoURL ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<bool>(
          stream: UserService.watchAdminStatus(),
          builder: (context, snapshot) {
            final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
            final role = isAdmin ? 'Admin' : 'Member';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue[400],
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(role, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, color: Colors.grey[700], size: 18),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}


class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[600]),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ]),
        ],
      ),
    );
  }
}

class _UpcomingTrainingCard extends StatelessWidget {
  final Color accent;
  final bool heart;
  const _UpcomingTrainingCard({required this.accent, this.heart = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(heart ? Icons.favorite_border : Icons.auto_awesome, color: accent),
                const SizedBox(width: 8),
                Text('Upcoming Training', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          _trainingItem(),
          const Divider(height: 1),
          _trainingItem(),
        ],
      ),
    );
  }

  Widget _trainingItem() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Agile Project Management Fundamentals', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(children: const [
          Icon(Icons.event_outlined, size: 18, color: Colors.grey),
          SizedBox(width: 6),
          Text('2025-04-10', style: TextStyle(color: Colors.black87)),
          SizedBox(width: 12),
          Icon(Icons.schedule_outlined, size: 18, color: Colors.grey),
          SizedBox(width: 6),
          Text('16 hours', style: TextStyle(color: Colors.black87)),
        ]),
      ]),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _BenefitCard({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundColor: Colors.grey.withValues(alpha: 0.15), child: Icon(icon, color: Colors.blueGrey[700])),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
