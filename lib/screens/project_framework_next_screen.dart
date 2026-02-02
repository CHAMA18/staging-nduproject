import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:ndu_project/utils/planning_phase_navigation.dart';

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
  
  // FocusNodes for auto-save on blur
  final List<FocusNode> _titleFocusNodes = List.generate(3, (_) => FocusNode());
  final List<FocusNode> _descFocusNodes = List.generate(3, (_) => FocusNode());
  final List<FocusNode> _yearFocusNodes = List.generate(3, (_) => FocusNode());
  
  String _potentialSolution = '';
  String _projectObjective = '';
  String _currentFilter = 'View All';

  /// Saves goal data to provider when focus is lost
  void _saveData() {
    if (!mounted) return;
    
    final planningGoals = <PlanningGoal>[];
    for (int i = 0; i < 3; i++) {
      final milestones = _goalMilestones[i].map((m) => PlanningMilestone(
        title: m.titleController.text.trim(),
        deadline: m.deadlineController.text.trim(),
        status: m.status,
      )).toList();
      
      planningGoals.add(PlanningGoal(
        goalNumber: i + 1,
        title: _goalTitleControllers[i].text.trim(),
        description: _goalDescControllers[i].text.trim(),
        targetYear: _goalYearControllers[i].text.trim(),
        isHighPriority: _isHighPriority[i],
        milestones: milestones,
      ));
    }
    
    ProjectDataHelper.getProvider(context).updateField(
      (data) => data.copyWith(planningGoals: planningGoals),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectData = ProjectDataHelper.getProvider(context).projectData;
      
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

      // Add listeners for real-time title updates in filters
      for (var controller in _goalTitleControllers) {
        controller.addListener(() {
          if (mounted) setState(() {});
        });
      }
      
      // Fetch context data
      final analysis = projectData.preferredSolutionAnalysis;
      // Heuristic: If selectedSolutionTitle exists, use it. Else first potential solution.
      if (analysis?.selectedSolutionTitle != null && analysis!.selectedSolutionTitle!.isNotEmpty) {
        _potentialSolution = analysis.selectedSolutionTitle ?? '';
      } else if (projectData.potentialSolutions.isNotEmpty) {
        _potentialSolution = projectData.potentialSolutions.first.title;
      }
      
      // Fetch Objective (from Business Case Scope or similar if specialized field missing)
      // Assuming 'projectObjective' might not be a direct string on ProjectData yet based on imports.
      // Looking at usage in other screens, Scope Statement often serves as objective.
      _projectObjective = projectData.projectObjective.isNotEmpty 
          ? projectData.projectObjective 
          : (projectData.businessCase.isNotEmpty ? projectData.businessCase : '');

      // Setup nomenclature listeners
      for (int i = 0; i < 3; i++) {
        _setupGoalNomenclature(i);
        // Manually trigger for pre-existing data
        if (_goalDescControllers[i].text.isNotEmpty) {
          final text = _goalDescControllers[i].text.trim();
          final words = text.split(RegExp(r'\s+')).take(3);
          final initials = words.where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase()).join();
          if (initials.isNotEmpty) {
            _goalTitleControllers[i].text = 'G${i + 1} $initials';
          }
        }
      }

      // Setup focus listeners for auto-save on blur
      for (int i = 0; i < 3; i++) {
        _titleFocusNodes[i].addListener(() {
          if (!_titleFocusNodes[i].hasFocus) _saveData();
        });
        _descFocusNodes[i].addListener(() {
          if (!_descFocusNodes[i].hasFocus) _saveData();
        });
        _yearFocusNodes[i].addListener(() {
          if (!_yearFocusNodes[i].hasFocus) _saveData();
        });
      }

      setState(() {});
    });
  }

  void _setupGoalNomenclature(int index) {
    _goalDescControllers[index].addListener(() {
      final text = _goalDescControllers[index].text.trim();
      if (text.isNotEmpty) {
        final words = text.split(RegExp(r'\s+')).take(3);
        final initials = words.where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase()).join();
        if (initials.isNotEmpty) {
          final newTitle = 'G${index + 1} $initials';
          if (_goalTitleControllers[index].text != newTitle) {
            _goalTitleControllers[index].text = newTitle;
          }
        }
      } else {
        final defaultTitle = 'Goal ${index + 1}';
        if (_goalTitleControllers[index].text != defaultTitle) {
          _goalTitleControllers[index].text = defaultTitle;
        }
      }
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
    // Dispose FocusNodes
    for (var node in _titleFocusNodes) {
      node.dispose();
    }
    for (var node in _descFocusNodes) {
      node.dispose();
    }
    for (var node in _yearFocusNodes) {
      node.dispose();
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
    // Validation removed to match top navigation behavior


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

    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'project_goals_milestones',
      nextScreenBuilder: () {
        final nextIdx = PlanningPhaseNavigation.getPageIndex('project_goals_milestones') + 1;
        return PlanningPhaseNavigation.pages[nextIdx].builder(context);
      },
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
                    _LabeledField(label: '', value: _potentialSolution.isNotEmpty ? _potentialSolution : 'Not selected'),
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
                      onTogglePriority: _togglePriority,
                      onDeleteMilestone: (goalIndex, milestoneIndex) {
                        setState(() {
                          _goalMilestones[goalIndex].removeAt(milestoneIndex);
                        });
                      },
                      titleFocusNodes: _titleFocusNodes,
                      descFocusNodes: _descFocusNodes,
                      yearFocusNodes: _yearFocusNodes,
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
                      goalTitles: _goalTitleControllers.map((c) => c.text).toList(),
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
        _circleIconButton(
          icon: Icons.arrow_back_ios_new_rounded, 
          onTap: () {
            final idx = PlanningPhaseNavigation.getPageIndex('project_goals_milestones');
            if (idx > 0) {
              final prevPage = PlanningPhaseNavigation.pages[idx - 1];
              Navigator.pushReplacement(context, MaterialPageRoute(builder: prevPage.builder));
            } else {
              Navigator.maybePop(context);
            }
          }
        ),
        const SizedBox(width: 12),
        _circleIconButton(
          icon: Icons.arrow_forward_ios_rounded, 
          backgroundColor: _kAccentColor,
          onTap: () {
            final idx = PlanningPhaseNavigation.getPageIndex('project_goals_milestones');
            if (idx < PlanningPhaseNavigation.pages.length - 1) {
              final nextPage = PlanningPhaseNavigation.pages[idx + 1];
              Navigator.pushReplacement(context, MaterialPageRoute(builder: nextPage.builder));
            }
          }
        ),
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
    required this.onTogglePriority,
    required this.onDeleteMilestone,
    required this.titleFocusNodes,
    required this.descFocusNodes,
    required this.yearFocusNodes,
  });

  final List<TextEditingController> titleControllers;
  final List<TextEditingController> descControllers;
  final List<TextEditingController> yearControllers;
  final List<List<_Milestone>> goalMilestones;
  final List<bool> isHighPriority;
  final String currentFilter;
  final void Function(int goalIndex) onAddMilestone;
  final void Function(int index) onClear;
  final void Function(int index) onTogglePriority;
  final void Function(int goalIndex, int milestoneIndex) onDeleteMilestone;
  final List<FocusNode> titleFocusNodes;
  final List<FocusNode> descFocusNodes;
  final List<FocusNode> yearFocusNodes;

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
                    child: GestureDetector(
                      onTap: () => _showExpandedGoalDialog(
                        context,
                        goalNumber: i + 1,
                        titleController: titleControllers[i],
                        descController: descControllers[i],
                        yearController: yearControllers[i],
                        milestones: goalMilestones[i],
                        isHighPriority: isHighPriority[i],
                        onAddMilestone: () => onAddMilestone(i),
                        onClear: () => onClear(i),
                        onTogglePriority: () => onTogglePriority(i),
                        onDeleteMilestone: (mIndex) => onDeleteMilestone(i, mIndex),
                      ),
                      child: _GoalCard(
                        goalNumber: i + 1,
                        titleController: titleControllers[i],
                        descController: descControllers[i],
                        yearController: yearControllers[i],
                        milestones: goalMilestones[i],
                        isHighPriority: isHighPriority[i],
                        onAddMilestone: () => onAddMilestone(i),
                        onClear: () => onClear(i),
                        onTogglePriority: () => onTogglePriority(i),
                        onDeleteMilestone: (mIndex) => onDeleteMilestone(i, mIndex),
                        titleFocusNode: titleFocusNodes[i],
                        descFocusNode: descFocusNodes[i],
                        yearFocusNode: yearFocusNodes[i],
                      ),
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

  void _showExpandedGoalDialog(
    BuildContext context, {
    required int goalNumber,
    required TextEditingController titleController,
    required TextEditingController descController,
    required TextEditingController yearController,
    required List<_Milestone> milestones,
    required bool isHighPriority,
    required VoidCallback onAddMilestone,
    required VoidCallback onClear,
    required VoidCallback onTogglePriority,
    required void Function(int) onDeleteMilestone,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _GoalCardExpandedDialog(
        goalNumber: goalNumber,
        titleController: titleController,
        descController: descController,
        yearController: yearController,
        milestones: milestones,
        isHighPriority: isHighPriority,
        onAddMilestone: onAddMilestone,
        onClear: onClear,
        onTogglePriority: onTogglePriority,
        onDeleteMilestone: onDeleteMilestone,
      ),
    );
  }
}


class _Milestone {
  _Milestone() : titleController = TextEditingController(), deadlineController = TextEditingController();
  final TextEditingController titleController;
  final TextEditingController deadlineController;
  String status = 'Not Started'; // Default status
  DateTime? deadlineDate; // Stores actual date

  void dispose() {
    titleController.dispose();
    deadlineController.dispose();
  }
}

class _GoalCard extends StatefulWidget {
  const _GoalCard({
    required this.goalNumber,
    required this.titleController,
    required this.descController,
    required this.yearController,
    required this.milestones,
    required this.isHighPriority,
    required this.onAddMilestone,
    required this.onClear,
    required this.onTogglePriority,
    required this.onDeleteMilestone,
    this.titleFocusNode,
    this.descFocusNode,
    this.yearFocusNode,
  });

  final int goalNumber;
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController yearController;
  final List<_Milestone> milestones;
  final bool isHighPriority;
  final VoidCallback onAddMilestone;
  final VoidCallback onClear;
  final VoidCallback onTogglePriority;
  final void Function(int) onDeleteMilestone;
  final FocusNode? titleFocusNode;
  final FocusNode? descFocusNode;
  final FocusNode? yearFocusNode;

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  DateTime? _targetCompletionDate;

  @override
  void initState() {
    super.initState();
    // Parse existing date from yearController if available
    _parseTargetDate();
  }

  void _parseTargetDate() {
    final text = widget.yearController.text.trim();
    if (text.isNotEmpty) {
      // Try to parse as year first
      final year = int.tryParse(text);
      if (year != null && year > 2000 && year < 2100) {
        _targetCompletionDate = DateTime(year, 12, 31);
      } else {
        // Try to parse as full date
        try {
          _targetCompletionDate = DateTime.parse(text);
        } catch (_) {}
      }
    }
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetCompletionDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kAccentColor,
              onPrimary: _kPrimaryText,
              surface: Colors.white,
              onSurface: _kPrimaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _targetCompletionDate = picked;
        widget.yearController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickMilestoneDate(_Milestone milestone) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: milestone.deadlineDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kAccentColor,
              onPrimary: _kPrimaryText,
              surface: Colors.white,
              onSurface: _kPrimaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        milestone.deadlineDate = picked;
        milestone.deadlineController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

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
                  controller: widget.titleController,
                  focusNode: widget.titleFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Goal ${widget.goalNumber} Title',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimaryText),
                ),
              ),
              GestureDetector(
                onTap: widget.onTogglePriority,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isHighPriority ? const Color(0xFFFEE2E2) : Colors.grey[100], 
                    borderRadius: BorderRadius.circular(999)
                  ),
                  child: Text(
                    'High priority', 
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w700, 
                      color: widget.isHighPriority ? const Color(0xFFDC2626) : Colors.grey[500]
                    )
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onClear,
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
              controller: widget.descController,
              focusNode: widget.descFocusNode,
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
          GestureDetector(
            onTap: _pickTargetDate,
            child: Container(
              height: 52,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _kBorderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: _kSecondaryText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _targetCompletionDate != null ? _formatDate(_targetCompletionDate) : 'Select target date',
                      style: TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w600, 
                        color: _targetCompletionDate != null ? _kPrimaryText : _kSecondaryText,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: _kSecondaryText),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...widget.milestones.asMap().entries.map((entry) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.sync_rounded, size: 22, color: Color(0xFFF59E0B)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: milestone.titleController,
                            decoration: const InputDecoration(
                              hintText: 'Milestone title',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimaryText),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onDeleteMilestone(index),
                          child: const Icon(Icons.close_rounded, size: 18, color: _kSecondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date picker and status on same row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickMilestoneDate(milestone),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFFE0A3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 14, color: _kSecondaryText),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      milestone.deadlineDate != null 
                                          ? _formatDate(milestone.deadlineDate)
                                          : 'Select deadline',
                                      style: TextStyle(
                                        fontSize: 12, 
                                        fontWeight: FontWeight.w500, 
                                        color: milestone.deadlineDate != null ? _kPrimaryText : _kSecondaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status dropdown on same row
                        Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFE0A3)),
                          ),
                          child: PopupMenuButton<String>(
                            initialValue: milestone.status,
                            onSelected: (val) {
                              setState(() => milestone.status = val);
                            },
                            offset: const Offset(0, 36),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: milestone.status == 'Completed' 
                                        ? const Color(0xFF10B981) 
                                        : (milestone.status == 'In Progress' 
                                            ? const Color(0xFFEF4444) 
                                            : Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  milestone.status,
                                  style: TextStyle(
                                    fontSize: 12, 
                                    fontWeight: FontWeight.w600, 
                                    color: milestone.status == 'Completed' 
                                        ? const Color(0xFF10B981) 
                                        : (milestone.status == 'In Progress' 
                                            ? const Color(0xFFEF4444) 
                                            : Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _kSecondaryText),
                              ],
                            ),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'Not Started', child: Text('Not Started')),
                              const PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
                              const PopupMenuItem(value: 'Completed', child: Text('Completed')),
                            ],
                          ),
                        ),
                      ],
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
                onTap: widget.onAddMilestone,
                child: const Text('+ Add Milestone', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kAccentColor)),
              ),
              GestureDetector(
                onTap: widget.onClear,
                child: const Text('Clear', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimaryText)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _GoalCardExpandedDialog extends StatefulWidget {
  const _GoalCardExpandedDialog({
    required this.goalNumber,
    required this.titleController,
    required this.descController,
    required this.yearController,
    required this.milestones,
    required this.isHighPriority,
    required this.onAddMilestone,
    required this.onClear,
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
  final VoidCallback onTogglePriority;
  final void Function(int) onDeleteMilestone;

  @override
  State<_GoalCardExpandedDialog> createState() => _GoalCardExpandedDialogState();
}

class _GoalCardExpandedDialogState extends State<_GoalCardExpandedDialog> {
  DateTime? _targetCompletionDate;

  @override
  void initState() {
    super.initState();
    _parseTargetDate();
  }

  void _parseTargetDate() {
    final text = widget.yearController.text.trim();
    if (text.isNotEmpty) {
      final year = int.tryParse(text);
      if (year != null && year > 2000 && year < 2100) {
        _targetCompletionDate = DateTime(year, 12, 31);
      } else {
        try {
          _targetCompletionDate = DateTime.parse(text);
        } catch (_) {}
      }
    }
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetCompletionDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kAccentColor,
              onPrimary: _kPrimaryText,
              surface: Colors.white,
              onSurface: _kPrimaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _targetCompletionDate = picked;
        widget.yearController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickMilestoneDate(_Milestone milestone) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: milestone.deadlineDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kAccentColor,
              onPrimary: _kPrimaryText,
              surface: Colors.white,
              onSurface: _kPrimaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        milestone.deadlineDate = picked;
        milestone.deadlineController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7E6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.titleController,
                      decoration: InputDecoration(
                        hintText: 'Goal ${widget.goalNumber} Title',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kPrimaryText),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onTogglePriority,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.isHighPriority ? const Color(0xFFFEE2E2) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'High priority',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.isHighPriority ? const Color(0xFFDC2626) : Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: _kSecondaryText),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kSecondaryText)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kBorderColor),
                      ),
                      child: TextField(
                        controller: widget.descController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'Enter a detailed description of this goal...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kPrimaryText),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Target Completion', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kSecondaryText)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickTargetDate,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _kBorderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 20, color: _kSecondaryText),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _targetCompletionDate != null ? _formatDate(_targetCompletionDate) : 'Select target date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _targetCompletionDate != null ? _kPrimaryText : _kSecondaryText,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: _kSecondaryText),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Text('Milestones', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kSecondaryText)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            widget.onAddMilestone();
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _kAccentColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16, color: _kPrimaryText),
                                SizedBox(width: 6),
                                Text('Add Milestone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimaryText)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...widget.milestones.asMap().entries.map((entry) {
                      final index = entry.key;
                      final milestone = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7E6),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFE0A3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                                  child: const Icon(Icons.flag_outlined, size: 22, color: Color(0xFFF59E0B)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: milestone.titleController,
                                    decoration: const InputDecoration(
                                      hintText: 'Milestone title',
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimaryText),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    widget.onDeleteMilestone(index);
                                    setState(() {});
                                  },
                                  child: const Icon(Icons.delete_outline_rounded, size: 20, color: _kSecondaryText),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _pickMilestoneDate(milestone),
                                    child: Container(
                                      height: 44,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFFE0A3)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, size: 16, color: _kSecondaryText),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              milestone.deadlineDate != null
                                                  ? _formatDate(milestone.deadlineDate)
                                                  : 'Select deadline',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: milestone.deadlineDate != null ? _kPrimaryText : _kSecondaryText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFFE0A3)),
                                  ),
                                  child: PopupMenuButton<String>(
                                    initialValue: milestone.status,
                                    onSelected: (val) {
                                      setState(() => milestone.status = val);
                                    },
                                    offset: const Offset(0, 44),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: milestone.status == 'Completed'
                                                ? const Color(0xFF10B981)
                                                : (milestone.status == 'In Progress'
                                                    ? const Color(0xFFEF4444)
                                                    : Colors.grey),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          milestone.status,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: milestone.status == 'Completed'
                                                ? const Color(0xFF10B981)
                                                : (milestone.status == 'In Progress'
                                                    ? const Color(0xFFEF4444)
                                                    : Colors.grey),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _kSecondaryText),
                                      ],
                                    ),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'Not Started', child: Text('Not Started')),
                                      const PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
                                      const PopupMenuItem(value: 'Completed', child: Text('Completed')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                border: Border(top: BorderSide(color: _kBorderColor.withValues(alpha: 0.5))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      widget.onClear();
                      setState(() {});
                    },
                    child: const Text('Clear', style: TextStyle(color: _kSecondaryText, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccentColor,
                      foregroundColor: _kPrimaryText,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                      bottom: BorderSide(color: _kBorderColor.withValues(alpha: index == rows.length - 1 ? 0 : 0.6)),
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
    required this.goalTitles,
    required this.onSelect,
  });

  final String currentFilter;
  final List<String> goalTitles;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final filters = [
      _FilterChipData(
        label: goalTitles.isNotEmpty && goalTitles[0].trim().isNotEmpty ? goalTitles[0] : 'Goal 1', 
        value: 'Goal 1',
        color: const Color(0xFFFFC107)
      ),
      _FilterChipData(
        label: goalTitles.length > 1 && goalTitles[1].trim().isNotEmpty ? goalTitles[1] : 'Goal 2', 
        value: 'Goal 2',
        color: const Color(0xFF0EA5E9)
      ),
      _FilterChipData(
        label: goalTitles.length > 2 && goalTitles[2].trim().isNotEmpty ? goalTitles[2] : 'Goal 3', 
        value: 'Goal 3',
        color: const Color(0xFFFB923C)
      ),
      _FilterChipData(label: 'View All', value: 'View All', color: const Color(0xFF10B981)),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: filters.map((chip) => GestureDetector(
        onTap: () => onSelect(chip.value),
        child: _GoalFilterChip(
          data: chip, 
          isSelected: currentFilter == chip.value,
        ),
      )).toList(),
    );
  }
}

class _FilterChipData {
  const _FilterChipData({required this.label, required this.value, required this.color});

  final String label;
  final String value;
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
        color: isSelected ? data.color : data.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: isSelected ? null : Border.all(color: data.color.withValues(alpha: 0.3)),
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
