import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'project_framework_screen.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';

const Color _kSurfaceBackground = Color(0xFFF7F8FC);
const Color _kAccentColor = Color(0xFFFFC812);
const Color _kPrimaryText = Color(0xFF1A1D1F);
const Color _kSecondaryText = Color(0xFF6B7280);
const Color _kCardBorder = Color(0xFFE4E7EC);

class WorkBreakdownStructureScreen extends StatelessWidget {
  const WorkBreakdownStructureScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WorkBreakdownStructureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurfaceBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: AppBreakpoints.sidebarWidth(context),
                  child: const InitiationLikeSidebar(activeItemLabel: 'Work Breakdown Structure'),
                ),
                Expanded(child: _WorkBreakdownStructureBody()),
              ],
            ),
            const KazAiChatBubble(),
          ],
        ),
      ),
    );
  }
}

class _WorkBreakdownStructureBody extends StatefulWidget {
  const _WorkBreakdownStructureBody();

  @override
  State<_WorkBreakdownStructureBody> createState() => _WorkBreakdownStructureBodyState();
}

class _WorkBreakdownStructureBodyState extends State<_WorkBreakdownStructureBody> {
  final List<String> _criteriaOptions = const [
    'Project Area',
    'Discipline',
    'Contract Type',
    'Sub Scope',
  ];

  String? _selectedCriteriaA;
  String? _selectedCriteriaB;
  final List<List<_GoalItem>> _goalItems = [[], [], []];
  final List<String> _goalTitles = List.filled(3, '');
  final List<String> _goalDescriptions = List.filled(3, '');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final projectData = ProjectDataHelper.getData(context);
      _selectedCriteriaA = projectData.wbsCriteriaA;
      _selectedCriteriaB = projectData.wbsCriteriaB;
      _syncGoalContext(projectData);
      _hydrateGoalItems(projectData.goalWorkItems);
      setState(() {});
    });
  }

  Future<void> _handleAddGoalItem(int goalIndex) async {
    final newItem = await _openAddGoalItemDialog();
    if (newItem == null) {
      return;
    }

    setState(() {
      _goalItems[goalIndex].add(newItem);
    });
  }

  Future<_GoalItem?> _openAddGoalItemDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedStatus = _GoalStatus.inProgress;
    _GoalItem? result;

    await showDialog<_GoalItem>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text(
            'Create Goal Deliverable',
            style: TextStyle(fontWeight: FontWeight.w800, color: _kPrimaryText),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 550,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Deliverable Title'),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(labelText: 'Description'),
                          minLines: 4,
                          maxLines: 8,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<_GoalStatus>(
                          initialValue: selectedStatus,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: _GoalStatus.values
                              .map(
                                (status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(_goalStatusLabel(status)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setStateDialog(() {
                              selectedStatus = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                result = _GoalItem(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  status: selectedStatus,
                );
                Navigator.of(dialogContext).pop(result);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccentColor,
                foregroundColor: _kPrimaryText,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    return result;
  }

  void _syncGoalContext(ProjectDataModel data) {
    for (var i = 0; i < 3; i++) {
      _goalTitles[i] = '';
      _goalDescriptions[i] = '';
    }

    for (var i = 0; i < data.planningGoals.length && i < 3; i++) {
      final planningGoal = data.planningGoals[i];
      final title = planningGoal.title.trim();
      final description = planningGoal.description.trim();
      final targetYear = planningGoal.targetYear.trim();
      if (title.isNotEmpty) {
        _goalTitles[i] = title;
      }
      if (description.isNotEmpty) {
        _goalDescriptions[i] = description;
      } else if (targetYear.isNotEmpty) {
        _goalDescriptions[i] = 'Target year: $targetYear';
      }
    }

    for (var i = 0; i < data.projectGoals.length && i < 3; i++) {
      if (_goalTitles[i].isEmpty) {
        _goalTitles[i] = data.projectGoals[i].name.trim();
      }
      if (_goalDescriptions[i].isEmpty) {
        _goalDescriptions[i] = data.projectGoals[i].description.trim();
      }
    }
  }

  void _hydrateGoalItems(List<List<WorkItem>> savedGoals) {
    for (final items in _goalItems) {
      items.clear();
    }

    for (var goalIndex = 0; goalIndex < _goalItems.length; goalIndex++) {
      if (goalIndex >= savedGoals.length) continue;
      for (final item in savedGoals[goalIndex]) {
        final title = item.title.trim();
        final description = item.description.trim();
        if (title.isEmpty && description.isEmpty) continue;
        _goalItems[goalIndex].add(
          _GoalItem(
            title: title.isEmpty ? 'Untitled deliverable' : title,
            description: description,
            status: _goalStatusFromString(item.status),
          ),
        );
      }
    }
  }

  _GoalStatus _goalStatusFromString(String status) {
    final normalized = status.trim().toLowerCase().replaceAll(' ', '_');
    switch (normalized) {
      case 'in_progress':
      case 'inprogress':
        return _GoalStatus.inProgress;
      case 'completed':
      case 'complete':
      case 'done':
        return _GoalStatus.completed;
      default:
        return _GoalStatus.notStarted;
    }
  }

  Widget _buildCriteriaDropdown({required String hint, required String? value, required ValueChanged<String?> onChanged}) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kCardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kCardBorder),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kSecondaryText),
        items: _criteriaOptions
            .map((option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimaryText)),
                ))
            .toList(),
        onChanged: onChanged,
        hint: Text(hint, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kSecondaryText)),
      ),
    );
  }

  Widget _buildCriteriaRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Select Breakdown Criteria:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kPrimaryText),
        ),
        _buildCriteriaDropdown(
          hint: 'Select...',
          value: _selectedCriteriaA,
          onChanged: (value) => setState(() => _selectedCriteriaA = value),
        ),
        _buildCriteriaDropdown(
          hint: 'Select...',
          value: _selectedCriteriaB,
          onChanged: (value) => setState(() => _selectedCriteriaB = value),
        ),
      ],
    );
  }

  Widget _buildAddGoalButton(int goalIndex) {
    return GestureDetector(
      onTap: () => _handleAddGoalItem(goalIndex),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kCardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.add, size: 18, color: _kPrimaryText),
      ),
    );
  }

  Widget _buildGoalHeading(int goalIndex) {
    final goalTitle = _goalTitles[goalIndex];
    final goalDescription = _goalDescriptions[goalIndex];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Goal ${goalIndex + 1}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _kPrimaryText),
              ),
              if (goalTitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  goalTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimaryText),
                ),
              ],
              if (goalDescription.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  goalDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kSecondaryText),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildAddGoalButton(goalIndex),
      ],
    );
  }

  Widget _buildGoalCard({required _GoalItem item, required VoidCallback onDelete}) {
    final bool isExpanded = item.isExpanded;
    return Container(
      decoration: const BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 8))],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(26), topRight: Radius.circular(26)),
                      gradient: LinearGradient(colors: [Color(0xFFFFD149), Color(0xFFFFA904)]),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kPrimaryText),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _kCardBorder),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                              ),
                              child: const Icon(Icons.delete_outline, size: 18, color: _kSecondaryText),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusChip(item.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.description,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondaryText),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => setState(() => item.isExpanded = !isExpanded),
                          child: Text(
                            isExpanded ? 'Collapse' : 'Expand',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFFFA904)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSubScopePanel(),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSection(double maxWidth) {
    const double gap = 22;
    const double minColumnWidth = 240;
    final bool showColumns = maxWidth >= (minColumnWidth * 3) + (gap * 2);

    if (!showColumns) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var goalIndex = 0; goalIndex < _goalItems.length; goalIndex++) ...[
            _buildGoalHeading(goalIndex),
            const SizedBox(height: 12),
            for (var i = 0; i < _goalItems[goalIndex].length; i++) ...[
              _buildGoalCard(
                item: _goalItems[goalIndex][i],
                onDelete: () => _confirmDeleteGoalItem(goalIndex, i),
              ),
              if (i != _goalItems[goalIndex].length - 1) const SizedBox(height: 20),
            ],
            const SizedBox(height: 24),
          ],
        ],
      );
    }

    final double columnWidth = (maxWidth - (gap * 2)) / 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var goalIndex = 0; goalIndex < _goalItems.length; goalIndex++) ...[
              SizedBox(
                width: columnWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGoalHeading(goalIndex),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _goalItems[goalIndex].length; i++) ...[
                      _buildGoalCard(
                        item: _goalItems[goalIndex][i],
                        onDelete: () => _confirmDeleteGoalItem(goalIndex, i),
                      ),
                      if (i != _goalItems[goalIndex].length - 1) const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
              if (goalIndex != _goalItems.length - 1) const SizedBox(width: gap),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _confirmDeleteGoalItem(int goalIndex, int itemIndex) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text(
            'Delete Deliverable',
            style: TextStyle(fontWeight: FontWeight.w800, color: _kPrimaryText),
          ),
          content: const Text(
            'Are you sure you want to delete this deliverable card? This action cannot be undone.',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kSecondaryText),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.12),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _goalItems[goalIndex].removeAt(itemIndex);
    });
  }

  Widget _buildNotesCard() {
    return SizedBox(
      width: 360,
      child: const PlanningAiNotesCard(
  title: 'Notes',
        sectionLabel: 'Work Breakdown Structure',
        noteKey: 'planning_wbs_notes',
        checkpoint: 'wbs',
        description: 'Summarize the WBS structure, criteria decisions, and any key dependencies.',
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFBFD9FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'The WBS is a breakdown of the project into manageable bitesize components for more effective execution. This is dependent on the project type and could be by project area, sub scope, discipline, contract, or a different criteria.',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimaryText),
      ),
    );
  }

  Future<void> _handleNextPressed() async {
    final goalWorkItems = _goalItems.map((items) => 
      items.map((item) => WorkItem(
        title: item.title,
        description: item.description,
        status: item.status.name,
      )).toList()
    ).toList();

    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'wbs',
      nextScreenBuilder: () => const ProjectFrameworkScreen(),
      dataUpdater: (data) => data.copyWith(
        wbsCriteriaA: _selectedCriteriaA,
        wbsCriteriaB: _selectedCriteriaB,
        goalWorkItems: goalWorkItems,
      ),
    );
  }

  Widget _buildNextButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _handleNextPressed,
        child: Container(
          width: 102,
          height: 46,
          decoration: BoxDecoration(
            color: _kAccentColor,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Next',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kPrimaryText),
          ),
        ),
      ),
    );
  }

  Widget _buildSubScopePanel() {
    const bulletColor = Color(0xFF4B5563);
    const borderColor = Color(0xFFE5B100);
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: _kAccentColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'Add Sub-scope',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _kPrimaryText),
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < 4; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == 3 ? 0 : 12),
              child: Row(
                children: const [
                  CircleAvatar(radius: 6, backgroundColor: bulletColor),
                  SizedBox(width: 12),
                  Text(
                    'Sub-scope (discipline) 1',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimaryText),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      color: _kSurfaceBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FrontEndPlanningHeader(title: 'Work Breakdown Structure'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCriteriaRow(),
                              const SizedBox(height: 32),
                              _buildGoalsSection(constraints.maxWidth),
                              const SizedBox(height: 28),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _buildNotesCard(),
                              ),
                              const SizedBox(height: 28),
                              _buildInfoBanner(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: Planning home',
                    nextLabel: 'Next: Project Management Framework',
                    onBack: () => Navigator.of(context).maybePop(),
                    onNext: _handleNextPressed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _GoalStatus { notStarted, inProgress, completed }

class _GoalItem {
  _GoalItem({required this.title, required this.description, required this.status});

  final String title;
  final String description;
  final _GoalStatus status;
  bool isExpanded = false;
}

String _goalStatusLabel(_GoalStatus status) {
  switch (status) {
    case _GoalStatus.notStarted:
      return 'Not Started';
    case _GoalStatus.inProgress:
      return 'In Progress';
    case _GoalStatus.completed:
      return 'Completed';
  }
}

Color _goalStatusColor(_GoalStatus status) {
  switch (status) {
    case _GoalStatus.notStarted:
      return const Color(0xFF6B7280);
    case _GoalStatus.inProgress:
      return const Color(0xFF2563EB);
    case _GoalStatus.completed:
      return const Color(0xFF059669);
  }
}

Widget _buildStatusChip(_GoalStatus status) {
  final color = _goalStatusColor(status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      _goalStatusLabel(status),
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
    ),
  );
}
