import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'package:ndu_project/screens/ssher_stacked_screen.dart';
import 'package:ndu_project/services/sidebar_navigation_service.dart';
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
  final List<bool> _isHighPriority = [false, false, false];
  
  String _potentialSolution = '';
  String _projectObjective = '';
  String _currentFilter = 'View All';

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
        _isHighPriority[i] = planningGoal.isHighPriority;
        
        // Populate milestones
        _goalMilestones[i].clear();
        for (final milestone in planningGoal.milestones) {
          final m = _Milestone();
          m.titleController.text = milestone.title;
          m.deadlineController.text = milestone.deadline;
          m.status = milestone.status;
          _goalMilestones[i].add(m);
        }
        if (_goalMilestones[i].isEmpty) {
          _goalMilestones[i].add(_Milestone());
        }
      }
      
      
      // Fetch context data
      final analysis = projectData.preferredSolutionAnalysis;
      // Heuristic: If selectedSolutionTitle exists, use it. Else first potential solution.
      if (analysis?.selectedSolutionTitle != null && analysis!.selectedSolutionTitle!.isNotEmpty) {
        _potentialSolution = analysis?.selectedSolutionTitle ?? '';
      } else if (projectData.potentialSolutions.isNotEmpty) {
        _potentialSolution = projectData.potentialSolutions.first.title;
      }
      
      // Fetch Objective (from Business Case Scope or similar if specialized field missing)
      // Assuming 'projectObjective' might not be a direct string on ProjectData yet based on imports.
      // Looking at usage in other screens, Scope Statement often serves as objective.
      _projectObjective = projectData.businessCase.isNotEmpty ? projectData.businessCase : '';

      setState(() {});
    });
  }

  void _clearGoal(int index) {
    setState(() {
      _goalTitleControllers[index].clear();
      _goalDescControllers[index].clear();
      _goalYearControllers[index].clear();
      _goalMilestones[index] = [_Milestone()];
      _isHighPriority[index] = false;
    });
  }

  void _copyGoal(int index) {
    // Find first empty slot
    int? targetIndex;
    for (int i = 0; i < 3; i++) {
      if (i != index && _goalTitleControllers[i].text.isEmpty && _goalDescControllers[i].text.isEmpty) {
        targetIndex = i;
        break;
      }
    }

    if (targetIndex != null) {
      setState(() {
        _goalTitleControllers[targetIndex!].text = _goalTitleControllers[index].text;
        _goalDescControllers[targetIndex!].text = _goalDescControllers[index].text;
        _goalYearControllers[targetIndex!].text = _goalYearControllers[index].text;
        _isHighPriority[targetIndex!] = _isHighPriority[index];
        _goalMilestones[targetIndex!] = _goalMilestones[index].map((m) {
          final newM = _Milestone();
          newM.titleController.text = m.titleController.text;
          newM.deadlineController.text = m.deadlineController.text;
          newM.status = m.status;
          return newM;
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No empty goal slots available to copy to.')),
      );
    }
  }

  void _togglePriority(int index) {
    setState(() {
      _isHighPriority[index] = !_isHighPriority[index];
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
        isHighPriority: _isHighPriority[i],
        milestones: _goalMilestones[i].map((m) => PlanningMilestone(
          title: m.titleController.text.trim(),
          deadline: m.deadlineController.text.trim(),
          status: m.status,
        )).toList(),
      );
    });

    final isBasicPlan = ProjectDataHelper.getData(context).isBasicPlanProject;
    
    // Find next accessible item from 'project_goals_milestones'
    final nextItem = SidebarNavigationService.instance.getNextAccessibleItem('project_goals_milestones', isBasicPlan);
    
    Widget nextScreen;
    if (nextItem?.checkpoint == 'ssher') {
      nextScreen = const SsherStackedScreen();
    } else {
      nextScreen = const SsherStackedScreen(); // Default/Fallback
    }

    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'project_goals_milestones',
      nextScreenBuilder: () => nextScreen,
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Project Goals & Milestones'),
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
                    const SizedBox(height: 24),
                    _LabeledField(label: 'Potential Solution', value: _potentialSolution.isNotEmpty ? _potentialSolution : 'Not selected'),
                    const SizedBox(height: 24),
                    _LabeledField(label: 'Project Objective  (Detailed aim of the project.)', value: _projectObjective.isNotEmpty ? _projectObjective : 'Pending input'),
                    const SizedBox(height: 40),
                    _GoalsSection(
                      titleControllers: _goalTitleControllers,
                      descControllers: _goalDescControllers,
                      yearControllers: _goalYearControllers,
                      goalMilestones: _goalMilestones,
                      isHighPriority: _isHighPriority,
                      currentFilter: _currentFilter,
                      onAddMilestone: (goalIndex) {
                        setState(() {
                          _goalMilestones[goalIndex].add(_Milestone());
                        });
                      },
                      onClear: _clearGoal,
                      onCopy: _copyGoal,
                      onTogglePriority: _togglePriority,
                      onDeleteMilestone: (goalIndex, milestoneIndex) {
                        setState(() {
                          _goalMilestones[goalIndex].removeAt(milestoneIndex);
                        });
                      },
                    ),
                    const SizedBox(height: 48),
                    _MilestonesSection(
                      goalMilestones: _goalMilestones,
                      goalTitles: _goalTitleControllers.map((c) => c.text).toList(),
                      currentFilter: _currentFilter,
                    ),
                    const SizedBox(height: 32),
                    _GoalFilters(
                      currentFilter: _currentFilter,
                      onSelect: (val) => setState(() => _currentFilter = val),
                    ),
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
    required this.isHighPriority,
    required this.currentFilter,
    required this.onAddMilestone,
    required this.onClear,
    required this.onCopy,
    required this.onTogglePriority,
    required this.onDeleteMilestone,
  });

  final List<TextEditingController> titleControllers;
  final List<TextEditingController> descControllers;
  final List<TextEditingController> yearControllers;
  final List<List<_Milestone>> goalMilestones;
  final List<bool> isHighPriority;
  final String currentFilter;
  final void Function(int goalIndex) onAddMilestone;
  final void Function(int index) onClear;
  final void Function(int index) onCopy;
  final void Function(int index) onTogglePriority;
  final void Function(int goalIndex, int milestoneIndex) onDeleteMilestone;

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
              if (currentFilter == 'View All' || currentFilter == 'Goal ${i + 1}')
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: _GoalCard(
                      goalNumber: i + 1,
                      titleController: titleControllers[i],
                      descController: descControllers[i],
                      yearController: yearControllers[i],
                      milestones: goalMilestones[i],
                      isHighPriority: isHighPriority[i],
                      onAddMilestone: () => onAddMilestone(i),
                      onClear: () => onClear(i),
                      onCopy: () => onCopy(i),
                      onTogglePriority: () => onTogglePriority(i),
                      onDeleteMilestone: (mIndex) => onDeleteMilestone(i, mIndex),
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()), // Placeholder to keep layout alignment if using Row
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
  String status = 'In Progress'; // Default status

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
    required this.isHighPriority,
    required this.onAddMilestone,
    required this.onClear,
    required this.onCopy,
    required this.onTogglePriority,
    required this.onDeleteMilestone,
  });

  final int goalNumber;
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController yearController;
  final List<_Milestone> milestones;
  final bool isHighPriority;
  final VoidCallback onAddMilestone;
  final VoidCallback onClear;
  final VoidCallback onCopy;
  final VoidCallback onTogglePriority;
  final void Function(int) onDeleteMilestone;

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
              GestureDetector(
                onTap: onTogglePriority,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHighPriority ? const Color(0xFFFEE2E2) : Colors.grey[100], 
                    borderRadius: BorderRadius.circular(999)
                  ),
                  child: Text(
                    'High priority', 
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w700, 
                      color: isHighPriority ? const Color(0xFFDC2626) : Colors.grey[500]
                    )
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onCopy,
                child: const Icon(Icons.content_copy_outlined, size: 18, color: _kSecondaryText),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.delete_outline_rounded, size: 18, color: _kSecondaryText),
              ),
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
          ...milestones.asMap().entries.map((entry) {
            final index = entry.key;
            final milestone = entry.value;
            return Padding(
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
                    StatefulBuilder(
                      builder: (context, setState) {
                        return PopupMenuButton<String>(
                          initialValue: milestone.status,
                          onSelected: (val) {
                            setState(() => milestone.status = val);
                          },
                          child: Text(
                            milestone.status,
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w700, 
                              color: milestone.status == 'Completed' ? const Color(0xFF10B981) 
                               : (milestone.status == 'In Progress' ? const Color(0xFFEF4444) : Colors.grey)
                            )
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'Not Started', child: Text('Not Started')),
                            const PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
                            const PopupMenuItem(value: 'Completed', child: Text('Completed')),
                          ],
                        );
                      }
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onAddMilestone,
                child: const Text('+ Add Milestone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kAccentColor)),
              ),
              GestureDetector(
                onTap: onClear, // Originally 'Edit' - change to clear/edit actions if needed. Using Clear as requested.
                child: const Text('Clear', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimaryText)),
              ),
              // Delete just clears it for now as per functionality
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestonesSection extends StatelessWidget {
  const _MilestonesSection({
    required this.goalMilestones,
    required this.goalTitles,
    required this.currentFilter,
  });

  final List<List<_Milestone>> goalMilestones;
  final List<String> goalTitles;
  final String currentFilter;

  static const List<String> _headers = [
    'No',
    'Milestones',
    'Status',
    'Due Date',
  ];

  @override
  Widget build(BuildContext context) {
    // Flatten rows based on filter
    final List<List<String>> rows = [];
    for (int i = 0; i < 3; i++) {
       if (currentFilter != 'View All' && currentFilter != 'Goal ${i + 1}') continue;
       
       for (final m in goalMilestones[i]) {
         if (m.titleController.text.isNotEmpty || m.deadlineController.text.isNotEmpty) {
           rows.add([
             '${i + 1}',
             m.titleController.text.isEmpty ? 'Untitled Milestone' : m.titleController.text,
             m.status,
             m.deadlineController.text.isEmpty ? 'No Deadline' : m.deadlineController.text,
           ]);
         }
       }
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

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
          constraints: const BoxConstraints(minHeight: 100), // Adjusted
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
                        flex: i == 1 ? 3 : 1,
                        child: _HeaderCell(label: _headers[i]),
                      ),
                  ],
                ),
              ),
              for (int index = 0; index < rows.length; index++)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: _kBorderColor.withOpacity(index == rows.length - 1 ? 0 : 0.6)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    children: [
                      for (int cell = 0; cell < rows[index].length; cell++)
                        Expanded(
                          flex: cell == 1 ? 3 : 1,
                          child: _DataCell(text: rows[index][cell]),
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
  const _GoalFilters({
    required this.currentFilter,
    required this.onSelect,
  });

  final String currentFilter;
  final ValueChanged<String> onSelect;

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
      children: filters.map((chip) => GestureDetector(
        onTap: () => onSelect(chip.label),
        child: _GoalFilterChip(
          data: chip, 
          isSelected: currentFilter == chip.label,
        ),
      )).toList(),
    );
  }
}

class _FilterChipData {
  const _FilterChipData({required this.label, required this.color});

  final String label;
  final Color color;
}

class _GoalFilterChip extends StatelessWidget {
  const _GoalFilterChip({
    required this.data,
    required this.isSelected,
  });

  final _FilterChipData data;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? data.color : data.color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(22),
        border: isSelected ? null : Border.all(color: data.color.withOpacity(0.3)),
      ),
      child: Text(
        data.label, 
        style: TextStyle(
          fontSize: 13, 
          fontWeight: FontWeight.w700, 
          color: isSelected ? Colors.white : data.color.darken()
        )
      ),
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
