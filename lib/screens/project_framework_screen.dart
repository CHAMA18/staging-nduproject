import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'project_framework_next_screen.dart';
import 'package:ndu_project/screens/project_charter_screen.dart';
import 'package:ndu_project/screens/ssher_stacked_screen.dart';
import 'package:ndu_project/services/sidebar_navigation_service.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';

class ProjectFrameworkScreen extends StatefulWidget {
  const ProjectFrameworkScreen({super.key});

  static void open(BuildContext context) {
    PhaseTransitionHelper.pushPhaseAware(
      context: context,
      builder: (_) => const ProjectFrameworkScreen(),
      destinationCheckpoint: 'project_framework',
    );
  }

  @override
  State<ProjectFrameworkScreen> createState() => _ProjectFrameworkScreenState();
}

class _ProjectFrameworkScreenState extends State<ProjectFrameworkScreen> {
  String? _selectedOverallFramework;
  final List<_Goal> _goals = [_Goal(id: 1, name: 'Goal 1', framework: null)];
  late TextEditingController _projectNameController;
  late TextEditingController _projectObjectiveController;
  late FocusNode _projectNameFocus;
  late FocusNode _projectObjectiveFocus;

  @override
  void initState() {
    super.initState();
    _projectNameController = TextEditingController();
    _projectObjectiveController = TextEditingController();
    _projectNameFocus = FocusNode()..addListener(_onFocusChange);
    _projectObjectiveFocus = FocusNode()..addListener(_onFocusChange);
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final projectData = ProjectDataHelper.getData(context);
      _selectedOverallFramework = projectData.overallFramework;
      _projectNameController.text = projectData.projectName;
      _projectObjectiveController.text = projectData.projectObjective.isNotEmpty 
          ? projectData.projectObjective 
          : projectData.businessCase;
      
      if (projectData.projectGoals.isNotEmpty) {
        _goals.clear();
        for (int i = 0; i < projectData.projectGoals.length; i++) {
          final goal = projectData.projectGoals[i];
          final g = _Goal(
            id: i + 1,
            name: goal.name.isEmpty ? 'Goal ${i + 1}' : goal.name,
            framework: goal.framework,
            description: goal.description,
          );
          _attachGoalListeners(g);
          _goals.add(g);
          _setupGoalNomenclature(g);
        }
        setState(() {});
      } else if (projectData.planningGoals.isNotEmpty && projectData.planningGoals.any((g) => g.title.isNotEmpty)) {
        // Fallback: Populate from Planning Goals (Charter) if Project Goals are empty
        _goals.clear();
        int idCounter = 1;
        for (final planGoal in projectData.planningGoals) {
          if (planGoal.title.isNotEmpty) {
            final g = _Goal(
              id: idCounter++,
              name: planGoal.title,
              description: planGoal.description.isNotEmpty ? planGoal.description : null,
              framework: null);
            _attachGoalListeners(g);
            _goals.add(g);
            _setupGoalNomenclature(g);
          }
        }
        if (_goals.isEmpty) {
           final g = _Goal(id: 1, name: 'Goal 1', framework: null);
           _attachGoalListeners(g);
           _goals.add(g);
           _setupGoalNomenclature(g);
        }
        setState(() {});
      }

      // Cleanup: If specific auto-generated text is present in notes, clear it.
      final fwNotes = projectData.planningNotes['planning_framework_notes'] ?? '';
      if (fwNotes.startsWith('The Project Management Framework for the Ndu tests project is designed')) {
        ProjectDataHelper.getProvider(context).updateField((d) {
           final newNotes = Map<String, String>.from(d.planningNotes);
           newNotes['planning_framework_notes'] = '';
           return d.copyWith(planningNotes: newNotes);
        });
      }
    });
  }

  void _onFocusChange() {
    if (!_projectNameFocus.hasFocus && !_projectObjectiveFocus.hasFocus) {
       _saveData();
    }
  }

  void _attachGoalListeners(_Goal goal) {
    goal.nameFocus.addListener(() {
      if (!goal.nameFocus.hasFocus) _saveData();
    });
    goal.descFocus.addListener(() {
      if (!goal.descFocus.hasFocus) _saveData();
    });
  }

  Future<void> _saveData() async {
    if (!mounted) return;
    
    final projectGoals = _goals.map((g) => ProjectGoal(
      name: g.nameController.text.trim(),
      description: g.controller.text.trim(),
      framework: g.framework,
    )).toList();

    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'project_framework',
      dataUpdater: (data) => data.copyWith(
        projectName: _projectNameController.text.trim(),
        projectObjective: _projectObjectiveController.text.trim(),
        overallFramework: _selectedOverallFramework,
        projectGoals: projectGoals,
      ),
      showSnackbar: false,
    );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectObjectiveController.dispose();
    _projectNameFocus.dispose();
    _projectObjectiveFocus.dispose();
    for (var goal in _goals) {
      goal.dispose();
    }
    super.dispose();
  }

  void _addGoal() {
    if (_goals.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum of 3 goals allowed'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    setState(() {
      String initialFramework;
      if (_selectedOverallFramework == 'Waterfall' || _selectedOverallFramework == 'Agile') {
        initialFramework = _selectedOverallFramework!;
      } else {
        initialFramework = 'Agile'; // or null, but the UI expects a value often?
        // Actually, logic: if Hybrid, user can select. If W/A, user cannot. 
        // When adding new goal, if locked, it MUST start as locked value.
      }
      final g = _Goal(
        id: _goals.length + 1, 
        name: 'Goal ${_goals.length + 1}', 
        framework: (_selectedOverallFramework == 'Waterfall' || _selectedOverallFramework == 'Agile') 
            ? _selectedOverallFramework 
            : null
      );
      _attachGoalListeners(g);
      _goals.add(g);
      _setupGoalNomenclature(g);
    });
    _saveData();
  }

  void _setupGoalNomenclature(_Goal goal) {
    goal.controller.addListener(() {
      final text = goal.controller.text.trim();
      if (text.isNotEmpty) {
        final words = text.split(RegExp(r'\s+')).take(3);
        final initials = words.where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase()).join();
        if (initials.isNotEmpty) {
          final newTitle = 'G${goal.id} $initials';
          if (goal.nameController.text != newTitle) {
            goal.nameController.text = newTitle;
          }
        }
      } else {
        final defaultTitle = 'Goal ${goal.id}';
        if (goal.nameController.text != defaultTitle) {
          goal.nameController.text = defaultTitle;
        }
      }
    });
  }

  void _deleteGoal(int goalId) {
    setState(() {
      final goal = _goals.firstWhere((g) => g.id == goalId);
      goal.dispose();
      _goals.removeWhere((g) => g.id == goalId);
    });
  }


  Future<void> _handleNextPressed() async {
    // Validate required fields before proceeding
    if (_selectedOverallFramework == null || _selectedOverallFramework!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an Overall Framework before proceeding.'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final projectGoals = _goals.map((g) => ProjectGoal(
      name: g.nameController.text.trim(),
      description: g.controller.text.trim(),
      framework: g.framework,
    )).toList();

    if (projectGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one Project Goal before proceeding.'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final isBasicPlan = ProjectDataHelper.getProvider(context).projectData.isBasicPlanProject;
    
    // Use SidebarNavigationService to find the next accessible step given the current checkpoint 'project_framework'
    final nextItem = SidebarNavigationService.instance.getNextAccessibleItem('project_framework', isBasicPlan);
    
    Widget nextScreen;
    if (nextItem?.checkpoint == 'project_goals_milestones') {
      nextScreen = const ProjectFrameworkNextScreen();
    } else if (nextItem?.checkpoint == 'work_breakdown_structure') {
      nextScreen = const WorkBreakdownStructureScreen(); 
    } else if (nextItem?.checkpoint == 'ssher') {
      nextScreen = const SsherStackedScreen();
    } else {
      // Fallback
      nextScreen = const WorkBreakdownStructureScreen();
    }

    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'project_framework',
      nextScreenBuilder: () => nextScreen,
      dataUpdater: (data) => data.copyWith(
        projectName: _projectNameController.text.trim(),
        projectObjective: _projectObjectiveController.text.trim(),
        overallFramework: _selectedOverallFramework,
        projectGoals: projectGoals,
      ),
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Project Details'),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FrontEndPlanningHeader(title: 'Project Details'),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const PlanningAiNotesCard(
                                title: 'Notes',
                                sectionLabel: 'Project Details',
                                noteKey: 'planning_framework_notes',
                                checkpoint: 'project_framework',
                                description: 'Capture the framework approach, governance model, and key objectives.',
                              ),
                              const SizedBox(height: 40),
                              _MainContentCard(
                                projectNameController: _projectNameController,
                                projectObjectiveController: _projectObjectiveController,
                                projectNameFocus: _projectNameFocus,
                                projectObjectiveFocus: _projectObjectiveFocus,
                                selectedOverallFramework: _selectedOverallFramework,
                                onOverallFrameworkChanged: (value) {
                                  setState(() {
                                    _selectedOverallFramework = value;
                                    // If Waterfall or Agile is selected, enforce it on all goals
                                    if (value == 'Waterfall' || value == 'Agile') {
                                      for (var goal in _goals) {
                                        goal.framework = value;
                                      }
                                    }
                                  });
                                  _saveData();
                                },
                                goals: _goals,
                                onGoalFrameworkChanged: (goalId, framework) {
                                  setState(() {
                                    _goals.firstWhere((g) => g.id == goalId).framework = framework;
                                  });
                                  _saveData();
                                },
                                onAddGoal: _addGoal,
                                onDeleteGoal: (goalId) {
                                   _deleteGoal(goalId);
                                   _saveData();
                                },
                              ),
                              const SizedBox(height: 24),
                              LaunchPhaseNavigation(
                                backLabel: 'Back: Project Charter',
                                nextLabel: 'Next',
                                onBack: () => ProjectCharterScreen.open(context),
                                onNext: _handleNextPressed,
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _Goal {
  _Goal({required this.id, String? name, this.framework, String? description}) 
      : controller = TextEditingController(text: description),
        nameController = TextEditingController(text: name),
        nameFocus = FocusNode(),
        descFocus = FocusNode();

  final int id;
  final TextEditingController nameController;
  final TextEditingController controller;
  final FocusNode nameFocus;
  final FocusNode descFocus;
  String? framework;
  
  void dispose() {
    nameController.dispose();
    controller.dispose();
    nameFocus.dispose();
    descFocus.dispose();
  }
}

class _MainContentCard extends StatelessWidget {
  const _MainContentCard({
    required this.projectNameController,
    required this.projectObjectiveController,
    required this.projectNameFocus,
    required this.projectObjectiveFocus,
    required this.selectedOverallFramework,
    required this.onOverallFrameworkChanged,
    required this.goals,
    required this.onGoalFrameworkChanged,
    required this.onAddGoal,
    required this.onDeleteGoal,
  });

  final TextEditingController projectNameController;
  final TextEditingController projectObjectiveController;
  final FocusNode projectNameFocus;
  final FocusNode projectObjectiveFocus;
  final String? selectedOverallFramework;
  final ValueChanged<String?> onOverallFrameworkChanged;
  final List<_Goal> goals;
  final void Function(int goalId, String? framework) onGoalFrameworkChanged;
  final VoidCallback onAddGoal;
  final void Function(int goalId) onDeleteGoal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Details',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Manage your project details, objectives, and overall framework structure.',
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 40),
          
          // Project Name
          const Text('Project Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          _roundedField(controller: projectNameController, focusNode: projectNameFocus, hint: 'Enter project name...'),
          const SizedBox(height: 24),

          // Project Objective
          const Text('Project Objective', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 8),
          _roundedField(controller: projectObjectiveController, focusNode: projectObjectiveFocus, hint: 'What is the main objective of this project?', minLines: 4),
          const SizedBox(height: 48),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 48),

          _OverallFrameworkSection(
            selectedFramework: selectedOverallFramework,
            onChanged: onOverallFrameworkChanged,
          ),
          const SizedBox(height: 48),
          _GoalsSection(
            goals: goals,
            overallFramework: selectedOverallFramework,
            onGoalFrameworkChanged: onGoalFrameworkChanged,
            onAddGoal: onAddGoal,
            onDeleteGoal: onDeleteGoal,
          ),
        ],
      ),
    );
  }
}

class _OverallFrameworkSection extends StatelessWidget {
  const _OverallFrameworkSection({
    required this.selectedFramework,
    required this.onChanged,
  });

  final String? selectedFramework;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overall Project Framework',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedFramework,
              hint: const Text('Select a Framework', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 15)),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
              items: ['Waterfall', 'Agile', 'Hybrid'].map((framework) {
                return DropdownMenuItem<String>(value: framework, child: Text(framework));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'If \'Waterfall\' or \'Agile\' is chosen, all goals below will inherit this framework. If \'Hybrid\' is chosen, you can set a framework for each goal individually .',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({
    required this.goals,
    required this.overallFramework,
    required this.onGoalFrameworkChanged,
    required this.onAddGoal,
    required this.onDeleteGoal,
  });

  final List<_Goal> goals;
  final String? overallFramework;
  final void Function(int goalId, String? framework) onGoalFrameworkChanged;
  final VoidCallback onAddGoal;
  final void Function(int goalId) onDeleteGoal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Project Goals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Breakdown the project objective into attainable areas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: onAddGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Add Goal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...goals.map((goal) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _GoalCard(
            goal: goal,
            isLocked: overallFramework == 'Waterfall' || overallFramework == 'Agile',
            onFrameworkChanged: (framework) => onGoalFrameworkChanged(goal.id, framework),
            onDelete: () => onDeleteGoal(goal.id),
          ),
        )),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.isLocked,
    required this.onFrameworkChanged,
    required this.onDelete,
  });

  final _Goal goal;
  final bool isLocked;
  final ValueChanged<String?> onFrameworkChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: goal.nameController,
                  focusNode: goal.nameFocus,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Goal Name',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: TextField(
                    controller: goal.controller,
                    focusNode: goal.descFocus,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Enter goal description...',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    ),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 200,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: goal.framework,
                    hint: const Text('Select Framework', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                    items: ['Waterfall', 'Agile', 'Hybrid'].map((framework) {
                      return DropdownMenuItem<String>(value: framework, child: Text(framework, style: const TextStyle(fontSize: 14)));
                    }).toList(),
                    onChanged: isLocked ? null : onFrameworkChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                tooltip: 'Delete goal',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  padding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_ProjectFrameworkScreenState>();
    return Positioned(
      right: 24,
      bottom: 24,
      child: ElevatedButton(
        onPressed: () async {
          if (state != null) {
            await state._handleNextPressed();
          } else {
            ProjectFrameworkNextScreen.open(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC812),
          foregroundColor: const Color(0xFF111827),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 0,
        ),
        child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

Widget _roundedField({required TextEditingController controller, FocusNode? focusNode, required String hint, int minLines = 1}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE4E7EC)),
    ),
    padding: const EdgeInsets.all(14),
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: minLines,
      maxLines: null,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
    ),
  );
}
