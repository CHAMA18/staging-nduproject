import 'package:flutter/material.dart';

import 'package:ndu_project/screens/detailed_design_screen.dart';
import 'package:ndu_project/screens/scope_tracking_implementation_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/execution_phase_service.dart';
import 'package:ndu_project/models/agile_task.dart';
import 'package:ndu_project/widgets/agile_iteration_table_widget.dart';
import 'package:ndu_project/utils/auto_bullet_text_controller.dart';

class AgileDevelopmentIterationsScreen extends StatefulWidget {
  const AgileDevelopmentIterationsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const AgileDevelopmentIterationsScreen()),
    );
  }

  @override
  State<AgileDevelopmentIterationsScreen> createState() =>
      _AgileDevelopmentIterationsScreenState();
}

class _AgileDevelopmentIterationsScreenState
    extends State<AgileDevelopmentIterationsScreen> {
  final Set<String> _selectedFilters = {'All'};
  List<AgileTask> _tasks = [];
  List<String> _availableRoles = [];
  bool _isLoading = false;

  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
      _loadAvailableRoles();
    });
  }

  Future<void> _loadTasks() async {
    final projectId = _projectId;
    if (projectId == null) return;

    setState(() => _isLoading = true);
    try {
      final tasks =
          await ExecutionPhaseService.loadAgileTasks(projectId: projectId);
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading agile tasks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadAvailableRoles() async {
    final projectId = _projectId;
    if (projectId == null) return;

    try {
      final staffRows =
          await ExecutionPhaseService.loadStaffingRows(projectId: projectId);
      if (mounted) {
        setState(() {
          _availableRoles = staffRows
              .map((row) => row.role)
              .where((role) => role.isNotEmpty)
              .toSet()
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading staff roles: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 18 : 32;
    final isNarrow = MediaQuery.sizeOf(context).width < 980;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Agile Development Iterations'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        if (_isLoading) const SizedBox(height: 16),
                        _buildPageHeader(context),
                        const SizedBox(height: 20),
                        _buildFilterChips(context),
                        const SizedBox(height: 24),
                        _buildStatsRow(isNarrow),
                        const SizedBox(height: 24),
                        _buildIterationTable(),
                        const SizedBox(height: 24),
                        _buildFooterNavigation(context),
                        const SizedBox(height: 48),
                      ],
                    ),
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

  Widget _buildPageHeader(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'AGILE DELIVERY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agile Development Iterations',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Manage sprint cycles, track velocity, and synchronize development tasks with design components.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (!isMobile) _buildHeaderActions(),
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 12),
          _buildHeaderActions(),
        ],
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showAddTaskDialog(context),
          icon: const Icon(Icons.add, size: 18, color: Color(0xFF64748B)),
          label: const Text('Add Task',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.description_outlined,
              size: 18, color: Color(0xFF64748B)),
          label: const Text('Export',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final List<String> filters = [
      'All',
      'To-Do',
      'In-Progress',
      'Testing',
      'Done'
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((label) {
        final isSelected = _selectedFilters.contains(label);
        return GestureDetector(
          onTap: () => setState(() {
            _selectedFilters.clear();
            _selectedFilters.add(label);
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    // Calculate metrics from tasks
    final totalTasks = _tasks.length;
    final completedTasks = _tasks.where((t) => t.status == 'Done').length;
    final iterationProgress =
        totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;
    final sprintVelocity =
        _tasks.fold<int>(0, (sum, task) => sum + task.storyPoints);
    final activeBlockers = _tasks
        .where((t) => t.status == 'To-Do' && t.priority == 'Critical')
        .length;

    final stats = [
      _StatCardData('Iteration Progress', '$iterationProgress%',
          '$completedTasks/$totalTasks tasks', const Color(0xFF0EA5E9)),
      _StatCardData('Sprint Velocity', '$sprintVelocity', 'Total story points',
          const Color(0xFF6366F1)),
      _StatCardData('Active Blockers', '$activeBlockers',
          'Critical tasks pending', const Color(0xFFEF4444)),
    ];

    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _buildStatCard(stat)).toList(),
      );
    }

    return Row(
      children: stats
          .map((stat) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildStatCard(stat),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: data.color),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildIterationTable() {
    final filteredTasks = _selectedFilters.contains('All')
        ? _tasks
        : _tasks.where((t) => _selectedFilters.contains(t.status)).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agile Iteration Table',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track user stories, assign roles, and manage sprint velocity.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          AgileIterationTableWidget(
            tasks: filteredTasks,
            availableRoles: _availableRoles,
            onUpdated: (task) {
              setState(() {
                final index = _tasks.indexWhere((t) => t.id == task.id);
                if (index != -1) {
                  _tasks[index] = task;
                } else {
                  _tasks.add(task);
                }
              });
            },
            onDeleted: (task) {
              setState(() {
                _tasks.removeWhere((t) => t.id == task.id);
              });
            },
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final userStoryController = TextEditingController();
    final taskDescriptionController = TextEditingController();
    final acceptanceCriteriaController = AutoBulletTextController();
    final iterationNotesController = TextEditingController();
    String selectedRole = '';
    int selectedStoryPoints = 1;
    String selectedPriority = 'Medium';
    String selectedStatus = 'To-Do';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: userStoryController,
                decoration:
                    const InputDecoration(labelText: 'User Story/Task *'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _availableRoles.isEmpty
                    ? null
                    : (_availableRoles.contains(selectedRole)
                        ? selectedRole
                        : null),
                decoration: const InputDecoration(labelText: 'Assigned Role *'),
                items: _availableRoles.map((role) {
                  return DropdownMenuItem<String>(
                      value: role, child: Text(role));
                }).toList(),
                onChanged: (value) => selectedRole = value ?? '',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedStoryPoints,
                decoration: const InputDecoration(labelText: 'Story Points *'),
                items: const [1, 2, 3, 5, 8].map((points) {
                  return DropdownMenuItem<int>(
                      value: points, child: Text('$points'));
                }).toList(),
                onChanged: (value) => selectedStoryPoints = value ?? 1,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority *'),
                items: const ['Critical', 'High', 'Medium', 'Low'].map((p) {
                  return DropdownMenuItem<String>(value: p, child: Text(p));
                }).toList(),
                onChanged: (value) => selectedPriority = value ?? 'Medium',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status *'),
                items:
                    const ['To-Do', 'In-Progress', 'Testing', 'Done'].map((s) {
                  return DropdownMenuItem<String>(value: s, child: Text(s));
                }).toList(),
                onChanged: (value) => selectedStatus = value ?? 'To-Do',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: taskDescriptionController,
                decoration:
                    const InputDecoration(labelText: 'Task Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: acceptanceCriteriaController,
                decoration: const InputDecoration(
                    labelText: 'Acceptance Criteria (use "." bullets)'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iterationNotesController,
                decoration: const InputDecoration(
                    labelText: 'Iteration Notes (manual input only)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (userStoryController.text.isEmpty || selectedRole.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill in required fields')),
                );
                return;
              }

              final newTask = AgileTask(
                userStory: userStoryController.text,
                assignedRole: selectedRole,
                storyPoints: selectedStoryPoints,
                priority: selectedPriority,
                status: selectedStatus,
                taskDescription: taskDescriptionController.text,
                acceptanceCriteria: acceptanceCriteriaController.text,
                iterationNotes: iterationNotesController.text,
              );

              setState(() {
                _tasks.add(newTask);
              });

              final projectId = _projectId;
              if (projectId != null) {
                try {
                  await ExecutionPhaseService.saveAgileTasks(
                    projectId: projectId,
                    tasks: _tasks,
                  );
                } catch (e) {
                  debugPrint('Error saving task: $e');
                }
              }

              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNavigation(BuildContext context) {
    return LaunchPhaseNavigation(
      backLabel: 'Back: Detailed Design',
      nextLabel: 'Next: Scope Tracking Implementation',
      onBack: () => DetailedDesignScreen.open(context),
      onNext: () => ScopeTrackingImplementationScreen.open(context),
    );
  }
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.subtitle, this.color);

  final String label;
  final String value;
  final String subtitle;
  final Color color;
}
