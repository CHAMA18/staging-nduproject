import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/premium_edit_dialog.dart';

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
                _circleIconButton(Icons.arrow_back_ios, onTap: () => Navigator.maybePop(context)),
                const SizedBox(width: 12),
                _circleIconButton(Icons.arrow_forward_ios, onTap: () async {
                   final navIndex = PlanningPhaseNavigation.getPageIndex('team_training');
                   if (navIndex != -1 && navIndex < PlanningPhaseNavigation.pages.length - 1) {
                     final nextPage = PlanningPhaseNavigation.pages[navIndex + 1];
                     Navigator.pushReplacement(context, MaterialPageRoute(builder: nextPage.builder));
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No next screen available')));
                   }
                }),
                const SizedBox(width: 16),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Team Training and Team Building',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                  ),
                ),
                _profileCluster(context),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _yellowButton(
                  label: 'Add Training Event',
                  icon: Icons.school_outlined,
                  onPressed: () async {
                    final newActivity = TrainingActivity(title: 'New Training', category: 'Training');
                    await ProjectDataHelper.saveAndNavigate(
                      context: context,
                      checkpoint: 'team_training',
                      nextScreenBuilder: () => const TeamTrainingAndBuildingScreen(),
                      dataUpdater: (d) => d.copyWith(trainingActivities: [...d.trainingActivities, newActivity]),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _yellowButton(
                  label: 'Add Team Building',
                  icon: Icons.favorite_outline,
                  onPressed: () async {
                    final newActivity = TrainingActivity(title: 'New Event', category: 'Team Building');
                    await ProjectDataHelper.saveAndNavigate(
                      context: context,
                      checkpoint: 'team_training',
                      nextScreenBuilder: () => const TeamTrainingAndBuildingScreen(),
                      dataUpdater: (d) => d.copyWith(trainingActivities: [...d.trainingActivities, newActivity]),
                    );
                  },
                ),
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
                              'Continuous learning and skill development are essential for project success and professional growth.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _StatTile(
                                  icon: Icons.school_outlined, 
                                  label: 'Total Training', 
                                  value: ProjectDataHelper.getData(context).trainingActivities
                                      .where((a) => a.category == 'Training').length.toString(),
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _StatTile(
                                  icon: Icons.verified_outlined, 
                                  label: 'Completed', 
                                  value: ProjectDataHelper.getData(context).trainingActivities
                                      .where((a) => a.category == 'Training' && a.status == 'Completed').length.toString(),
                                )),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _UpcomingTrainingList(
                              activities: ProjectDataHelper.getData(context).trainingActivities
                                  .where((a) => a.category == 'Training').toList(),
                              accent: Colors.blue,
                              onEdit: (activity) => _editActivity(context, activity),
                              onDelete: (activity) => _deleteActivity(context, activity),
                            ),
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
                              'Team building activities strengthen relationships and improve communication.',
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _StatTile(
                                  icon: Icons.event_available_outlined, 
                                  label: 'Team Events', 
                                  value: ProjectDataHelper.getData(context).trainingActivities
                                      .where((a) => a.category == 'Team Building').length.toString(),
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _StatTile(
                                  icon: Icons.check_circle_outline, 
                                  label: 'Completed', 
                                  value: ProjectDataHelper.getData(context).trainingActivities
                                      .where((a) => a.category == 'Team Building' && a.status == 'Completed').length.toString(),
                                )),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _UpcomingTrainingList(
                              activities: ProjectDataHelper.getData(context).trainingActivities
                                  .where((a) => a.category == 'Team Building').toList(),
                              accent: Colors.purple,
                              heart: true,
                              onEdit: (activity) => _editActivity(context, activity),
                              onDelete: (activity) => _deleteActivity(context, activity),
                            ),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _editActivity(BuildContext context, TrainingActivity activity) {
    final titleController = TextEditingController(text: activity.title);
    final dateController = TextEditingController(text: activity.date);
    final durationController = TextEditingController(text: activity.duration);

    showDialog(
      context: context,
      builder: (context) => PremiumEditDialog(
        title: 'Edit ${activity.category}',
        icon: activity.category == 'Training' ? Icons.school_outlined : Icons.favorite_border,
        onSave: () async {
          final updated = List<TrainingActivity>.from(ProjectDataHelper.getData(context).trainingActivities);
          final index = updated.indexWhere((a) => a.id == activity.id);
          if (index != -1) {
            updated[index] = activity.copyWith(
              title: titleController.text.trim(),
              date: dateController.text.trim(),
              duration: durationController.text.trim(),
            );
          }
          Navigator.pop(context);
          await ProjectDataHelper.saveAndNavigate(
            context: context,
            checkpoint: 'team_training',
            nextScreenBuilder: () => const TeamTrainingAndBuildingScreen(),
            dataUpdater: (d) => d.copyWith(trainingActivities: updated),
          );
        },
        children: [
          PremiumEditDialog.fieldLabel('Title'),
          PremiumEditDialog.textField(controller: titleController, hint: 'Activity name...'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumEditDialog.fieldLabel('Date'),
                    PremiumEditDialog.textField(controller: dateController, hint: 'e.g. Q3 2024'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PremiumEditDialog.fieldLabel('Duration / Interval'),
                    PremiumEditDialog.textField(controller: durationController, hint: 'e.g. 2 hours'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteActivity(BuildContext context, TrainingActivity activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final updated = List<TrainingActivity>.from(ProjectDataHelper.getData(context).trainingActivities);
              updated.removeWhere((a) => a.id == activity.id);
              Navigator.pop(context);
              await ProjectDataHelper.saveAndNavigate(
                context: context,
                checkpoint: 'team_training',
                nextScreenBuilder: () => const TeamTrainingAndBuildingScreen(),
                dataUpdater: (d) => d.copyWith(trainingActivities: updated),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _yellowButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _circleIconButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 16, color: Colors.grey[700]),
      ),
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

class _UpcomingTrainingList extends StatelessWidget {
  final List<TrainingActivity> activities;
  final Color accent;
  final bool heart;
  final ValueChanged<TrainingActivity>? onEdit;
  final ValueChanged<TrainingActivity>? onDelete;
  
  const _UpcomingTrainingList({
    required this.activities, 
    required this.accent, 
    this.heart = false,
    this.onEdit,
    this.onDelete,
  });

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
                Text(heart ? 'Upcoming Events' : 'Upcoming Training', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No upcoming activities.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            )
          else
            ...activities.map<Widget>((a) => Column(
              children: [
                _trainingItem(a),
                if (a != activities.last) const Divider(height: 1),
              ],
            )),
        ],
      ),
    );
  }

  Widget _trainingItem(TrainingActivity activity) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(activity.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.event_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(activity.date.isEmpty ? 'TBD' : activity.date, style: const TextStyle(color: Colors.black87)),
                const SizedBox(width: 12),
                const Icon(Icons.schedule_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(activity.duration.isEmpty ? 'TBD' : activity.duration, style: const TextStyle(color: Colors.black87)),
              ]),
            ]),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: () => onEdit!(activity),
              icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => onDelete!(activity),
              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
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
