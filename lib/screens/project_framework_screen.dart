import 'package:flutter/material.dart';
import 'package:ndu_project/models/design_phase_models.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/utils/rich_text_editing_controller.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/widgets/text_formatting_toolbar.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'project_framework_next_screen.dart';
import 'package:ndu_project/screens/ssher_stacked_screen.dart';
import 'package:ndu_project/services/sidebar_navigation_service.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';

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
  late final OpenAiServiceSecure _openAi;
  bool _isGeneratingObjective = false;
  bool _objectiveGenerationAttempted = false;
  bool _isGeneratingGoals = false;
  bool _goalsGenerationAttempted = false;

  @override
  void initState() {
    super.initState();
    _projectNameController = TextEditingController();
    _projectObjectiveController = RichTextEditingController();
    _projectNameFocus = FocusNode()..addListener(_onFocusChange);
    _projectObjectiveFocus = FocusNode()..addListener(_onFocusChange);
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final projectData = ProjectDataHelper.getData(context);
      _selectedOverallFramework = projectData.overallFramework;

      // Enhanced project name population with fallback hierarchy
      String projectName = projectData.projectName;
      if (projectName.isEmpty) {
        projectName = projectData.solutionTitle;
      }
      if (projectName.isEmpty) {
        projectName = projectData.potentialSolution;
      }
      if (projectName.isEmpty && projectData.potentialSolutions.isNotEmpty) {
        projectName = projectData.potentialSolutions.first.title;
      }
      _projectNameController.text = projectName;

      _projectObjectiveController.text = projectData.projectObjective.trim();

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
      } else if (projectData.planningGoals.isNotEmpty &&
          projectData.planningGoals.any((g) => g.title.isNotEmpty)) {
        // Fallback: Populate from Planning Goals (Charter) if Project Goals are empty
        _goals.clear();
        int idCounter = 1;
        for (final planGoal in projectData.planningGoals) {
          if (planGoal.title.isNotEmpty) {
            final g = _Goal(
                id: idCounter++,
                name: planGoal.title,
                description: planGoal.description.isNotEmpty
                    ? planGoal.description
                    : null,
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
      final fwNotes =
          projectData.planningNotes['planning_framework_notes'] ?? '';
      if (fwNotes.startsWith(
          'The Project Management Framework for the Ndu tests project is designed')) {
        ProjectDataHelper.getProvider(context).updateField((d) {
          final newNotes = Map<String, String>.from(d.planningNotes);
          newNotes['planning_framework_notes'] = '';
          return d.copyWith(planningNotes: newNotes);
        });
      }

      await _ensureProjectObjectiveSummary(projectData);
      await _ensureProjectGoalsFromContext(projectData);
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

  DesignManagementData? _syncedDesignManagementData(ProjectDataModel data) {
    final mappedMethodology =
        ProjectDataHelper.projectMethodologyFromOverallFramework(
      _selectedOverallFramework,
    );
    if (mappedMethodology == null) return data.designManagementData;
    return (data.designManagementData ?? DesignManagementData()).copyWith(
      methodology: mappedMethodology,
    );
  }

  Future<void> _saveData() async {
    if (!mounted) return;

    final projectGoals = _goals
        .map((g) => ProjectGoal(
              name: g.nameController.text.trim(),
              description: g.controller.text.trim(),
              framework: g.framework,
            ))
        .toList();

    try {
      await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'project_framework',
        dataUpdater: (data) {
          return data.copyWith(
            projectName: _projectNameController.text.trim(),
            projectObjective: _projectObjectiveController.text.trim(),
            overallFramework: _selectedOverallFramework,
            projectGoals: projectGoals,
            designManagementData: _syncedDesignManagementData(data),
          );
        },
        showSnackbar: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _ensureProjectObjectiveSummary(
      ProjectDataModel projectData) async {
    if (_objectiveGenerationAttempted || _isGeneratingObjective) return;

    final existing = projectData.projectObjective.trim();
    final fallbackCandidates = [
      projectData.businessCase.trim(),
      projectData.solutionDescription.trim(),
      projectData.charterAssumptions.trim(),
    ];
    final isFallback = existing.isEmpty ||
        fallbackCandidates.any((v) => v.isNotEmpty && v == existing);

    if (!isFallback) return;

    final objectiveContext =
        ProjectDataHelper.buildProjectObjectiveContext(projectData).trim();
    if (objectiveContext.isEmpty) return;

    _objectiveGenerationAttempted = true;
    setState(() => _isGeneratingObjective = true);

    try {
      final summary = await _openAi.generateProjectObjectiveSummary(
        context: objectiveContext,
      );
      final cleaned = _clampToMaxSentences(summary.trim(), 5);
      if (cleaned.isEmpty || !mounted) return;
      _projectObjectiveController.text = cleaned;
      await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'project_framework',
        dataUpdater: (data) => data.copyWith(projectObjective: cleaned),
        showSnackbar: false,
      );
    } catch (e) {
      debugPrint('Error generating project objective summary: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingObjective = false);
      }
    }
  }

  String _clampToMaxSentences(String text, int maxSentences) {
    if (text.isEmpty) return text;
    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (sentences.length <= maxSentences) return text;
    return sentences.take(maxSentences).join(' ').trim();
  }

  Future<void> _ensureProjectGoalsFromContext(
      ProjectDataModel projectData) async {
    if (_goalsGenerationAttempted || _isGeneratingGoals) return;

    bool isMeaningfulName(String name) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) return false;
      final isDefaultName =
          RegExp(r'^Goal\\s+\\d+$', caseSensitive: false).hasMatch(trimmed);
      return !isDefaultName;
    }

    final hasMeaningfulGoals = _goals.any((g) {
      final name = g.nameController.text.trim();
      final desc = g.controller.text.trim();
      return isMeaningfulName(name) || desc.isNotEmpty;
    });
    if (hasMeaningfulGoals) return;

    final goalContext =
        ProjectDataHelper.buildProjectObjectiveContext(projectData).trim();
    if (goalContext.isEmpty) return;

    _goalsGenerationAttempted = true;
    setState(() => _isGeneratingGoals = true);

    try {
      final result =
          await _openAi.suggestProjectFrameworkGoals(context: goalContext);
      if (!mounted) return;

      final generatedGoals = result.goals.take(5).toList();
      if (generatedGoals.isEmpty) return;

      setState(() {
        _goals.clear();
        for (int i = 0; i < generatedGoals.length; i++) {
          final g = generatedGoals[i];
          final goal = _Goal(
            id: i + 1,
            name: g.name.isNotEmpty ? g.name : 'Goal ${i + 1}',
            description: g.description,
            framework: (_selectedOverallFramework == 'Waterfall' ||
                    _selectedOverallFramework == 'Agile')
                ? _selectedOverallFramework
                : null,
          );
          _attachGoalListeners(goal);
          _goals.add(goal);
          _setupGoalNomenclature(goal);
        }
        if ((_selectedOverallFramework ?? '').isEmpty &&
            result.framework.isNotEmpty) {
          _selectedOverallFramework = result.framework;
        }
      });

      await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'project_framework',
        dataUpdater: (data) {
          return data.copyWith(
            overallFramework: _selectedOverallFramework,
            projectGoals: _goals
                .map((g) => ProjectGoal(
                      name: g.nameController.text.trim(),
                      description: g.controller.text.trim(),
                      framework: g.framework,
                    ))
                .toList(),
            designManagementData: _syncedDesignManagementData(data),
          );
        },
        showSnackbar: false,
      );
    } catch (e) {
      debugPrint('Error generating project goals: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingGoals = false);
      }
    }
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
    if (_goals.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum of 5 goals allowed'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    setState(() {
      final g = _Goal(
          id: _goals.length + 1,
          name: 'Goal ${_goals.length + 1}',
          framework: (_selectedOverallFramework == 'Waterfall' ||
                  _selectedOverallFramework == 'Agile')
              ? _selectedOverallFramework
              : null);
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
        final initials = words
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase())
            .join();
        if (initials.isNotEmpty) {
          final newTitle = 'S${goal.id} $initials';
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
    final projectGoals = _goals
        .map((g) => ProjectGoal(
              name: g.nameController.text.trim(),
              description: g.controller.text.trim(),
              framework: g.framework,
            ))
        .toList();

    final missingFields = <String>[];
    if (_selectedOverallFramework == null ||
        _selectedOverallFramework!.isEmpty) {
      missingFields.add('Overall Framework');
    }
    if (projectGoals.isEmpty) {
      missingFields.add('Project Goals');
    }

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Continuing with partial project details. Missing: ${missingFields.join(', ')}.',
          ),
          backgroundColor: const Color(0xFFD97706),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    final isBasicPlan =
        ProjectDataHelper.getProvider(context).projectData.isBasicPlanProject;

    // Use SidebarNavigationService to find the next accessible step given the current checkpoint 'project_framework'
    final nextItem = SidebarNavigationService.instance
        .getNextAccessibleItem('project_framework', isBasicPlan);

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
      saveInBackground: true,
      nextScreenBuilder: () => nextScreen,
      dataUpdater: (data) {
        return data.copyWith(
          projectName: _projectNameController.text.trim(),
          projectObjective: _projectObjectiveController.text.trim(),
          overallFramework: _selectedOverallFramework,
          projectGoals: projectGoals,
          designManagementData: _syncedDesignManagementData(data),
        );
      },
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
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Project Details'),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const PlanningAiNotesCard(
                                title: 'Notes',
                                sectionLabel: 'Project Details',
                                noteKey: 'planning_framework_notes',
                                checkpoint: 'project_framework',
                                description:
                                    'Capture the framework approach, governance model, and key objectives.',
                              ),
                              const SizedBox(height: 40),
                              _MainContentCard(
                                projectNameController: _projectNameController,
                                projectObjectiveController:
                                    _projectObjectiveController,
                                projectNameFocus: _projectNameFocus,
                                projectObjectiveFocus: _projectObjectiveFocus,
                                selectedOverallFramework:
                                    _selectedOverallFramework,
                                onBeforeUndo: _saveData,
                                onOverallFrameworkChanged: (value) {
                                  setState(() {
                                    _selectedOverallFramework = value;
                                    // If Waterfall or Agile is selected, enforce it on all goals
                                    if (value == 'Waterfall' ||
                                        value == 'Agile') {
                                      for (var goal in _goals) {
                                        goal.framework = value;
                                      }
                                    }
                                  });
                                  _saveData();
                                },
                                goals: _goals,
                                onAddGoal: _addGoal,
                                onDeleteGoal: (goalId) {
                                  _deleteGoal(goalId);
                                  _saveData();
                                },
                                onGoalTitleResize: (goalId, height) {
                                  setState(() {
                                    _goals
                                        .firstWhere((g) => g.id == goalId)
                                        .titleHeight = height;
                                  });
                                },
                                onGoalDescriptionResize: (goalId, height) {
                                  setState(() {
                                    _goals
                                        .firstWhere((g) => g.id == goalId)
                                        .descriptionHeight = height;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                              LaunchPhaseNavigation(
                                backLabel: PlanningPhaseNavigation.backLabel(
                                    'project_framework'),
                                nextLabel: PlanningPhaseNavigation.nextLabel(
                                    'project_framework'),
                                onBack: () =>
                                    PlanningPhaseNavigation.goToPrevious(
                                        context, 'project_framework'),
                                onNext: () => PlanningPhaseNavigation.goToNext(
                                    context, 'project_framework'),
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
  _Goal({
    required this.id,
    String? name,
    this.framework,
    String? description,
  })  : controller = TextEditingController(text: description),
        nameController = TextEditingController(text: name),
        nameFocus = FocusNode(),
        descFocus = FocusNode(),
        titleHeight = 0,
        descriptionHeight = 0;

  final int id;
  final TextEditingController nameController;
  final TextEditingController controller;
  final FocusNode nameFocus;
  final FocusNode descFocus;
  String? framework;
  double titleHeight;
  double descriptionHeight;

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
    required this.onBeforeUndo,
    required this.goals,
    required this.onAddGoal,
    required this.onDeleteGoal,
    required this.onGoalTitleResize,
    required this.onGoalDescriptionResize,
  });

  final TextEditingController projectNameController;
  final TextEditingController projectObjectiveController;
  final FocusNode projectNameFocus;
  final FocusNode projectObjectiveFocus;
  final String? selectedOverallFramework;
  final ValueChanged<String?> onOverallFrameworkChanged;
  final VoidCallback onBeforeUndo;
  final List<_Goal> goals;
  final VoidCallback onAddGoal;
  final void Function(int goalId) onDeleteGoal;
  final void Function(int goalId, double height) onGoalTitleResize;
  final void Function(int goalId, double height) onGoalDescriptionResize;

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
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Manage your project details, objectives, and overall framework structure.',
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 40),

          // Project Name
          const Text('Project Name',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
          const SizedBox(height: 8),
          _roundedField(
              controller: projectNameController,
              focusNode: projectNameFocus,
              hint: 'Enter project name...'),
          const SizedBox(height: 24),

          // Project Objective
          const Text('Project Objective',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151))),
          const SizedBox(height: 8),
          TextFormattingToolbar(
            controller: projectObjectiveController,
            onBeforeUndo: onBeforeUndo,
          ),
          const SizedBox(height: 8),
          _roundedField(
              controller: projectObjectiveController,
              focusNode: projectObjectiveFocus,
              hint: 'What is the main objective of this project?',
              minLines: 4),
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
            onAddGoal: onAddGoal,
            onDeleteGoal: onDeleteGoal,
            onGoalTitleResize: onGoalTitleResize,
            onGoalDescriptionResize: onGoalDescriptionResize,
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
    const options = [
      _FrameworkOption(
        value: 'Waterfall',
        title: 'Waterfall',
        description:
            'A linear project method where work is completed in sequential phases. Most suitable for traditional and physical projects.',
      ),
      _FrameworkOption(
        value: 'Agile',
        title: 'Agile',
        description:
            'A flexible, iterative project method where work is delivered in small increments, allowing continuous feedback, adaptation, and improvement throughout the project. Most suitable for software projects.',
      ),
      _FrameworkOption(
        value: 'Hybrid',
        title: 'Hybrid',
        description:
            'A combination of Waterfall and Agile approaches, using structured planning for some phases and flexible, iterative development for others.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Project Framework',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;
            if (isNarrow) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: options
                    .map((option) => SizedBox(
                          width: constraints.maxWidth,
                          child: _FrameworkOptionCard(
                            title: option.title,
                            description: option.description,
                            isSelected: selectedFramework == option.value,
                            onTap: () => onChanged(option.value),
                          ),
                        ))
                    .toList(),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _FrameworkOptionCard(
                    title: options[0].title,
                    description: options[0].description,
                    isSelected: selectedFramework == options[0].value,
                    onTap: () => onChanged(options[0].value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FrameworkOptionCard(
                    title: options[1].title,
                    description: options[1].description,
                    isSelected: selectedFramework == options[1].value,
                    onTap: () => onChanged(options[1].value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FrameworkOptionCard(
                    title: options[2].title,
                    description: options[2].description,
                    isSelected: selectedFramework == options[2].value,
                    onTap: () => onChanged(options[2].value),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'If \'Waterfall\' or \'Agile\' is chosen, all goals will inherit this framework. If \'Hybrid\' is chosen, set a framework for each goal in the WBS.',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _FrameworkOption {
  const _FrameworkOption({
    required this.value,
    required this.title,
    required this.description,
  });

  final String value;
  final String title;
  final String description;
}

class _FrameworkOptionCard extends StatelessWidget {
  const _FrameworkOptionCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isSelected ? const Color(0xFF111827) : const Color(0xFFD1D5DB);
    final backgroundColor = isSelected ? const Color(0xFFFFF3BF) : Colors.white;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({
    required this.goals,
    required this.onAddGoal,
    required this.onDeleteGoal,
    required this.onGoalTitleResize,
    required this.onGoalDescriptionResize,
  });

  final List<_Goal> goals;
  final VoidCallback onAddGoal;
  final void Function(int goalId) onDeleteGoal;
  final void Function(int goalId, double height) onGoalTitleResize;
  final void Function(int goalId, double height) onGoalDescriptionResize;

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
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Indicate upto 5 key high-level outcomes for this project',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280)),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: onAddGoal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A50),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Add Goal',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...goals.asMap().entries.map((entry) {
          final index = entry.key;
          final goal = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _GoalCard(
              index: index,
              goal: goal,
              onDelete: () => onDeleteGoal(goal.id),
              onTitleResize: (height) => onGoalTitleResize(goal.id, height),
              onDescriptionResize: (height) =>
                  onGoalDescriptionResize(goal.id, height),
            ),
          );
        }),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.index,
    required this.goal,
    required this.onDelete,
    required this.onTitleResize,
    required this.onDescriptionResize,
  });

  final int index;
  final _Goal goal;
  final VoidCallback onDelete;
  final ValueChanged<double> onTitleResize;
  final ValueChanged<double> onDescriptionResize;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3BF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: _ResizableTextField(
                  controller: goal.nameController,
                  focusNode: goal.nameFocus,
                  minHeight: 44,
                  maxHeight: 110,
                  height: goal.titleHeight,
                  maxLines: 2,
                  hintText: 'Goal title',
                  textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827)),
                  onResize: onTitleResize,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _ResizableTextField(
                  controller: goal.controller,
                  focusNode: goal.descFocus,
                  minHeight: 90,
                  maxHeight: 220,
                  height: goal.descriptionHeight,
                  maxLines: null,
                  hintText: 'Enter goal description...',
                  textStyle:
                      const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                  onResize: onDescriptionResize,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444)),
                tooltip: 'Delete goal',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  padding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResizableTextField extends StatelessWidget {
  const _ResizableTextField({
    required this.controller,
    required this.focusNode,
    required this.height,
    required this.minHeight,
    required this.maxHeight,
    required this.hintText,
    required this.textStyle,
    required this.maxLines,
    required this.onResize,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final double height;
  final double minHeight;
  final double maxHeight;
  final String hintText;
  final TextStyle textStyle;
  final int? maxLines;
  final ValueChanged<double> onResize;

  @override
  Widget build(BuildContext context) {
    final clampedHeight = height.clamp(minHeight, maxHeight);
    final isExpandable = maxLines == null;

    return Stack(
      children: [
        Container(
          height: clampedHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            minLines: isExpandable ? null : 1,
            maxLines: isExpandable ? null : maxLines,
            expands: isExpandable,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            ),
            style: textStyle,
          ),
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
              onPanUpdate: (details) {
                final next = (clampedHeight + details.delta.dy)
                    .clamp(minHeight, maxHeight);
                onResize(next);
              },
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.drag_handle,
                    size: 14, color: Color(0xFF6B7280)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay();

  @override
  Widget build(BuildContext context) {
    final state =
        context.findAncestorStateOfType<_ProjectFrameworkScreenState>();
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          elevation: 0,
        ),
        child: const Text('Next',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

Widget _roundedField(
    {required TextEditingController controller,
    FocusNode? focusNode,
    required String hint,
    int minLines = 1}) {
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
