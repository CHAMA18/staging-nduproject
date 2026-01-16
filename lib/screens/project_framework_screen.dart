import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'project_framework_next_screen.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';

class ProjectFrameworkScreen extends StatefulWidget {
  const ProjectFrameworkScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectFrameworkScreen()),
    );
  }

  @override
  State<ProjectFrameworkScreen> createState() => _ProjectFrameworkScreenState();
}

class _ProjectFrameworkScreenState extends State<ProjectFrameworkScreen> {
  String? _selectedOverallFramework;
  final List<_Goal> _goals = [_Goal(id: 1, name: 'Goal 1', framework: null)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final projectData = ProjectDataHelper.getData(context);
      _selectedOverallFramework = projectData.overallFramework;
      
      if (projectData.projectGoals.isNotEmpty) {
        _goals.clear();
        for (int i = 0; i < projectData.projectGoals.length; i++) {
          final goal = projectData.projectGoals[i];
          _goals.add(_Goal(
            id: i + 1,
            name: goal.name.isEmpty ? 'Goal ${i + 1}' : goal.name,
            framework: goal.framework,
            description: goal.description,
          ));
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

  @override
  void dispose() {
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
      _goals.add(_Goal(
        id: _goals.length + 1, 
        name: 'Goal ${_goals.length + 1}', 
        framework: (_selectedOverallFramework == 'Waterfall' || _selectedOverallFramework == 'Agile') 
            ? _selectedOverallFramework 
            : null
      ));
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
      name: g.name,
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

    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'project_framework',
      nextScreenBuilder: () => const ProjectFrameworkNextScreen(),
      dataUpdater: (data) => data.copyWith(
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Project Management Framework'),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FrontEndPlanningHeader(title: 'Project Management Framework'),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const PlanningAiNotesCard(
                                title: 'Notes',
                                sectionLabel: 'Project Management Framework',
                                noteKey: 'planning_framework_notes',
                                checkpoint: 'project_framework',
                                description: 'Capture the framework approach, governance model, and key objectives.',
                              ),
                              const SizedBox(height: 40),
                              _MainContentCard(
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
                                },
                                goals: _goals,
                                onGoalFrameworkChanged: (goalId, framework) {
                                  setState(() {
                                    _goals.firstWhere((g) => g.id == goalId).framework = framework;
                                  });
                                },
                                onAddGoal: _addGoal,
                                onDeleteGoal: _deleteGoal,
                              ),
                              const SizedBox(height: 24),
                              LaunchPhaseNavigation(
                                backLabel: 'Back: Work Breakdown Structure',
                                nextLabel: 'Next: SSHER',
                                onBack: () => WorkBreakdownStructureScreen.open(context),
                                onNext: _handleNextPressed,
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const _BottomOverlay(),
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
  _Goal({required this.id, required this.name, this.framework, String? description}) : controller = TextEditingController(text: description);
  final int id;
  final String name;
  final TextEditingController controller;
  String? framework;
  
  void dispose() {
    controller.dispose();
  }
}

class _MainContentCard extends StatelessWidget {
  const _MainContentCard({
    required this.selectedOverallFramework,
    required this.onOverallFrameworkChanged,
    required this.goals,
    required this.onGoalFrameworkChanged,
    required this.onAddGoal,
    required this.onDeleteGoal,
  });

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
        children: [
          const Text(
            'Project Management Framework',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select a framework for the overall project and individual goals .',
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
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
            const Text(
              'Project Goals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
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
              Text(
                goal.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
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

Widget _roundedField({required TextEditingController controller, required String hint, int minLines = 1}) {
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
