import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/services/user_service.dart';

const Color _kAccentColor = Color(0xFFFFC812);
const Color _kPrimaryText = Color(0xFF1F2933);
const Color _kSecondaryText = Color(0xFF6B7280);
const Color _kBorderColor = Color(0xFFE5E7EB);
const Color _kCardShadow = Color(0x14000000);

class ProjectFrameworkNextScreen extends StatefulWidget {
  const ProjectFrameworkNextScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectFrameworkNextScreen()),
    );
  }

  @override
  State<ProjectFrameworkNextScreen> createState() => _ProjectFrameworkNextScreenState();
}

class _ProjectFrameworkNextScreenState extends State<ProjectFrameworkNextScreen> {
  final List<TextEditingController> _goalTitleControllers = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> _goalDescControllers = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> _goalYearControllers = List.generate(3, (_) => TextEditingController());
  final List<List<_Milestone>> _goalMilestones = List.generate(3, (_) => [_Milestone()]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectData = ProjectDataHelper.getData(context);
      
      // Populate from project goals
      if (projectData.projectGoals.isNotEmpty) {
        for (int i = 0; i < projectData.projectGoals.length && i < 3; i++) {
          final goal = projectData.projectGoals[i];
          _goalTitleControllers[i].text = goal.name;
          _goalDescControllers[i].text = goal.description;
        }
      }
      
      // Populate from planning goals if available
      for (int i = 0; i < projectData.planningGoals.length && i < 3; i++) {
        final planningGoal = projectData.planningGoals[i];
        if (planningGoal.title.isNotEmpty) {
          _goalTitleControllers[i].text = planningGoal.title;
        }
        if (planningGoal.description.isNotEmpty) {
          _goalDescControllers[i].text = planningGoal.description;
        }
        _goalYearControllers[i].text = planningGoal.targetYear;
        
        // Populate milestones
        _goalMilestones[i].clear();
        for (final milestone in planningGoal.milestones) {
          final m = _Milestone();
          m.titleController.text = milestone.title;
          m.deadlineController.text = milestone.deadline;
          _goalMilestones[i].add(m);
        }
        if (_goalMilestones[i].isEmpty) {
          _goalMilestones[i].add(_Milestone());
        }
      }
      
      setState(() {});
    });
  }

  @override
  void dispose() {
    for (var c in _goalTitleControllers) {
      c.dispose();
    }
    for (var c in _goalDescControllers) {
      c.dispose();
    }
    for (var c in _goalYearControllers) {
      c.dispose();
    }
    for (var milestones in _goalMilestones) {
      for (var m in milestones) {
        m.dispose();
      }
    }
    super.dispose();
  }

  bool _areAllGoalsFilled() {
    for (int i = 0; i < 3; i++) {
      if (_goalTitleControllers[i].text.trim().isEmpty ||
          _goalDescControllers[i].text.trim().isEmpty ||
          _goalYearControllers[i].text.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  void _navigateToNext() async {
    if (!_areAllGoalsFilled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all three goals before proceeding.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    final planningGoals = List.generate(3, (i) {
      return PlanningGoal(
        goalNumber: i + 1,
        title: _goalTitleControllers[i].text.trim(),
        description: _goalDescControllers[i].text.trim(),
        targetYear: _goalYearControllers[i].text.trim(),
        milestones: _goalMilestones[i].map((m) => PlanningMilestone(
          title: m.titleController.text.trim(),
          deadline: m.deadlineController.text.trim(),
        )).toList(),
      );
    });

    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'planning_phase',
      nextScreenBuilder: () => const WorkBreakdownStructureScreen(),
      dataUpdater: (data) => data.copyWith(planningGoals: planningGoals),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Project Summary'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeaderRow(),
                    const SizedBox(height: 32),
                    const PlanningAiNotesCard(
                      title: 'Notes',
                      sectionLabel: 'Project Summary',
                      noteKey: 'planning_project_summary_notes',
                      checkpoint: 'project_framework_next',
                      description: 'Summarize planning goals, milestones, and delivery themes.',
                    ),
                    const SizedBox(height: 24),
                    const _LabeledField(label: 'Potential Solution', value: 'Refactor Homepage Logic'),
                    const SizedBox(height: 24),
                    const _LabeledField(label: 'Project Objective  (Detailed aim of the project.)', value: 'Refactor Homepage Logic'),
                    const SizedBox(height: 40),
                    _GoalsSection(
                      titleControllers: _goalTitleControllers,
                      descControllers: _goalDescControllers,
                      yearControllers: _goalYearControllers,
                      goalMilestones: _goalMilestones,
                      onAddMilestone: (goalIndex) {
                        setState(() {
                          _goalMilestones[goalIndex].add(_Milestone());
                        });
                      },
                    ),
                    const SizedBox(height: 48),
                    const _MilestonesSection(),
                    const SizedBox(height: 32),
                    const _GoalFilters(),
                    const SizedBox(height: 24),
                    _BottomGuidance(onNext: _navigateToNext),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final userInitial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final email = user?.email ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _circleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.maybePop(context)),
        const SizedBox(width: 12),
        _circleIconButton(icon: Icons.arrow_forward_ios_rounded, backgroundColor: _kAccentColor),
        const SizedBox(width: 16),
        const Text(
          'Planning Phase',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _kPrimaryText),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorderColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _kAccentColor,
                child: Text(userInitial, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimaryText)),
              ),
              const SizedBox(width: 10),
              Text(displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimaryText)),
              const SizedBox(width: 6),
              StreamBuilder<bool>(
                stream: UserService.watchAdminStatus(),
                builder: (context, snapshot) {
                  final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
                  final role = isAdmin ? 'Admin' : 'Member';
                  return Text(role, style: const TextStyle(fontSize: 12, color: _kSecondaryText));
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: _kPrimaryText,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: const Text('+ Add New Contract', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  static Widget _circleIconButton({required IconData icon, Color? backgroundColor, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _kBorderColor),
          boxShadow: const [BoxShadow(color: _kCardShadow, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimaryText)),
        const SizedBox(height: 12),
        Container(
          height: 56,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kBorderColor),
          ),
          alignment: Alignment.centerLeft,
          child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimaryText)),
        ),
      ],
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({
    required this.titleControllers,
    required this.descControllers,
    required this.yearControllers,
    required this.goalMilestones,
    required this.onAddMilestone,
  });

  final List<TextEditingController> titleControllers;
  final List<TextEditingController> descControllers;
  final List<TextEditingController> yearControllers;
  final List<List<_Milestone>> goalMilestones;
  final void Function(int goalIndex) onAddMilestone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(text: 'Project Goals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimaryText)),
              TextSpan(text: ' (Breakdown the project objective into attainable areas)', style: TextStyle(fontSize: 14, color: _kSecondaryText, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < 3; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: _GoalCard(
                    goalNumber: i + 1,
                    titleController: titleControllers[i],
                    descController: descControllers[i],
                    yearController: yearControllers[i],
                    milestones: goalMilestones[i],
                    onAddMilestone: () => onAddMilestone(i),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Milestone {
  _Milestone() : titleController = TextEditingController(), deadlineController = TextEditingController();
  final TextEditingController titleController;
  final TextEditingController deadlineController;

  void dispose() {
    titleController.dispose();
    deadlineController.dispose();
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goalNumber,
    required this.titleController,
    required this.descController,
    required this.yearController,
    required this.milestones,
    required this.onAddMilestone,
  });

  final int goalNumber;
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController yearController;
  final List<_Milestone> milestones;
  final VoidCallback onAddMilestone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kBorderColor),
        boxShadow: const [BoxShadow(color: _kCardShadow, blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Goal $goalNumber Title',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimaryText),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(999)),
                child: const Text('High priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.content_copy_outlined, size: 18, color: _kSecondaryText),
              const SizedBox(width: 10),
              const Icon(Icons.delete_outline_rounded, size: 18, color: _kSecondaryText),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondaryText)),
          const SizedBox(height: 8),
          Container(
            height: 52,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kBorderColor),
            ),
            child: TextField(
              controller: descController,
              decoration: const InputDecoration(
                hintText: 'Enter description',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimaryText),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Target Completion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondaryText)),
          const SizedBox(height: 8),
          Container(
            height: 52,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kBorderColor),
            ),
            child: TextField(
              controller: yearController,
              decoration: const InputDecoration(
                hintText: 'Year (e.g., 2025)',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimaryText),
            ),
          ),
          const SizedBox(height: 20),
          ...milestones.map((milestone) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFE0A3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.sync_rounded, size: 22, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: milestone.titleController,
                          decoration: const InputDecoration(
                            hintText: 'Milestone title',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimaryText),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: milestone.deadlineController,
                          decoration: const InputDecoration(
                            hintText: 'Deadline (e.g., July 15, 2025)',
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 12, color: _kSecondaryText, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const Text('in progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                ],
              ),
            ),
          )),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onAddMilestone,
                child: const Text('+ Add Milestone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kAccentColor)),
              ),
              const Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimaryText)),
              const Text('Delete', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestonesSection extends StatelessWidget {
  const _MilestonesSection();

  static const List<String> _headers = [
    'No',
    'Milestones',
    'No',
    'Discipline',
    'No',
    'Due Date',
    'No',
    'References (paste)',
    'No',
    'Comments',
  ];

  static final List<List<String>> _rows = List.generate(
    4,
    (_) => const [
      '1',
      'Edit Column 2',
      '1',
      'Edit Column 2',
      '1',
      'Edit Column 2',
      '1',
      'Edit Column 2',
      '1',
      'Edit Column 2',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(text: 'Key Project Milestones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimaryText)),
              TextSpan(text: ' (List core milestones associated with each goal)', style: TextStyle(fontSize: 14, color: _kSecondaryText, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 280),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _kBorderColor),
            boxShadow: const [BoxShadow(color: _kCardShadow, blurRadius: 16, offset: Offset(0, 8))],
          ),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  children: [
                    for (int i = 0; i < _headers.length; i++)
                      Expanded(
                        flex: i.isEven ? 1 : 3,
                        child: _HeaderCell(label: _headers[i]),
                      ),
                  ],
                ),
              ),
              for (int index = 0; index < _rows.length; index++)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: _kBorderColor.withOpacity(index == _rows.length - 1 ? 0 : 0.6)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      for (int cell = 0; cell < _rows[index].length; cell++)
                        Expanded(
                          flex: cell.isEven ? 1 : 3,
                          child: _DataCell(text: _rows[index][cell]),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimaryText)),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondaryText)),
    );
  }
}

class _GoalFilters extends StatelessWidget {
  const _GoalFilters();

  @override
  Widget build(BuildContext context) {
    final filters = [
      _FilterChipData(label: 'Goal 1', color: const Color(0xFFFFC107)),
      _FilterChipData(label: 'Goal 2', color: const Color(0xFF0EA5E9)),
      _FilterChipData(label: 'Goal 3', color: const Color(0xFFFB923C)),
      _FilterChipData(label: 'View All', color: const Color(0xFF10B981)),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: filters.map((chip) => _GoalFilterChip(data: chip)).toList(),
    );
  }
}

class _FilterChipData {
  const _FilterChipData({required this.label, required this.color});

  final String label;
  final Color color;
}

class _GoalFilterChip extends StatelessWidget {
  const _GoalFilterChip({required this.data});

  final _FilterChipData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(data.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: data.color.darken())),
    );
  }
}

class _BottomGuidance extends StatelessWidget {
  const _BottomGuidance({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFD6ECFF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Goal milestones would be a foundation for the project schedule. Focus on the key milestones required for project success.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimaryText),
            ),
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccentColor,
            foregroundColor: _kPrimaryText,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

extension on Color {
  Color darken([double amount = .12]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
