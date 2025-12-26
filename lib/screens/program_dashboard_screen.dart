import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../routing/app_router.dart';
import '../models/program_model.dart';
import '../services/navigation_context_service.dart';
import '../services/program_service.dart';
import '../services/project_service.dart';
import '../widgets/kaz_ai_chat_bubble.dart';

class ProgramDashboardScreen extends StatefulWidget {
  const ProgramDashboardScreen({super.key});

  @override
  State<ProgramDashboardScreen> createState() => _ProgramDashboardScreenState();
}

class _ProgramDashboardScreenState extends State<ProgramDashboardScreen> {
  ProgramModel? _currentProgram;
  List<ProjectRecord> _projects = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription<List<ProgramModel>>? _programSubscription;
  StreamSubscription<List<ProjectRecord>>? _projectSubscription;

  @override
  void initState() {
    super.initState();
    _loadProgramData();
  }

  @override
  void dispose() {
    _programSubscription?.cancel();
    _projectSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProgramData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please sign in to view program data';
      });
      return;
    }

    try {
      // Listen to user's programs and get the first one
      _programSubscription?.cancel();
      _programSubscription = ProgramService.streamPrograms(ownerId: user.uid).listen((programs) {
        if (!mounted) return;
        
        if (programs.isEmpty) {
          _projectSubscription?.cancel();
          setState(() {
            _isLoading = false;
            _currentProgram = null;
            _projects = [];
            _error = null;
          });
          return;
        }

        final program = programs.first;
        final programChanged = _currentProgram?.id != program.id;

        // Now stream projects for this program
        _projectSubscription?.cancel();
        if (program.projectIds.isNotEmpty) {
          if (programChanged) {
            setState(() {
              _currentProgram = program;
              _projects = [];
              _isLoading = true;
              _error = null;
            });
          } else {
            setState(() {
              _currentProgram = program;
              _error = null;
            });
          }

          _projectSubscription = ProjectService.streamProjectsByIds(program.projectIds).listen((projects) {
            if (!mounted) return;
            setState(() {
              _projects = projects;
              _isLoading = false;
              _error = null;
            });
          }, onError: (e) {
            debugPrint('Error streaming projects: $e');
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _error = 'Failed to load projects';
            });
          });
        } else {
          setState(() {
            _currentProgram = program;
            _projects = [];
            _isLoading = false;
            _error = null;
          });
        }
      }, onError: (e) {
        debugPrint('Error streaming programs: $e');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Failed to load program data';
        });
      });
    } catch (e) {
      debugPrint('Error loading program data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'An error occurred while loading data';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    NavigationContextService.instance.setLastClientDashboard(AppRoutes.programDashboard);
    const background = Color(0xFFF7F8FC);
    final showEmptyState = !_isLoading && _error == null && _currentProgram == null;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1180;
                final horizontalPadding = constraints.maxWidth < 900 ? 20.0 : 32.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 28, horizontalPadding, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        isWide: isWide,
                        programName: _currentProgram?.name,
                      ),
                      const SizedBox(height: 24),
                      if (showEmptyState)
                        _EmptyStateCard(
                          onCreate: () => context.go('/${AppRoutes.dashboard}'),
                        )
                      else ...[
                        _SummaryChips(isWide: isWide, projectCount: _projects.length),
                        const SizedBox(height: 24),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    _ProjectsCard(
                                      projects: _projects,
                                      isLoading: _isLoading,
                                      error: _error,
                                    ),
                                    const SizedBox(height: 18),
                                    const _ProgramActionsCard(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              const Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    _InterfaceCard(),
                                    SizedBox(height: 18),
                                    _RollupCard(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _ProjectsCard(
                                projects: _projects,
                                isLoading: _isLoading,
                                error: _error,
                              ),
                              const SizedBox(height: 18),
                              const _ProgramActionsCard(),
                              const SizedBox(height: 18),
                              const _InterfaceCard(),
                              const SizedBox(height: 18),
                              const _RollupCard(),
                            ],
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isWide, this.programName});

  final bool isWide;
  final String? programName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trimmedName = programName?.trim();
    final title = (trimmedName != null && trimmedName.isNotEmpty) ? trimmedName : 'Program dashboard';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5D7),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFFE7A8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF8A5800)),
                        SizedBox(width: 8),
                        Text(
                          'Program workspace overview',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8A5800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/${AppRoutes.home}');
                      }
                    },
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF343741)),
                    label: const Text(
                      'Back',
                      style: TextStyle(color: Color(0xFF343741), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0E1017),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Coordinate up to three related projects with shared outcomes. Manage interfaces, prioritize delivery, and roll estimates and risk into a single program view before promoting to a portfolio.',
                style: textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF4D5060),
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _PrimaryButton(label: 'Add project to program'),
            _GhostButton(label: 'Add another program'),
            _GhostButton(label: 'Create portfolio'),
          ],
        ),
      ],
    );
  }
}

class _SummaryChips extends StatelessWidget {
  const _SummaryChips({required this.isWide, required this.projectCount});

  final bool isWide;
  final int projectCount;

  @override
  Widget build(BuildContext context) {
    final chips = [
      _InfoChip(label: '$projectCount of 3 projects in this program'),
      const _InfoChip(label: 'Interface manager assigned', color: Color(0xFFDFF2FF), foreground: Color(0xFF0C4DA2)),
      const _InfoChip(label: 'Rolled up estimate: \$5.4M', color: Color(0xFFECF8F5), foreground: Color(0xFF0D8A5A)),
    ];

    if (isWide) {
      return Row(
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            Expanded(child: chips[i]),
            if (i != chips.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }

    return Column(
      children: [
        for (int i = 0; i < chips.length; i++) ...[
          chips[i],
          if (i != chips.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No programs yet', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Create a program from three projects to see a live program dashboard here.',
            style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF565970), height: 1.45),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCreate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111111),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Go to project dashboard'),
          ),
        ],
      ),
    );
  }
}

class _ProjectsCard extends StatelessWidget {
  const _ProjectsCard({
    required this.projects,
    required this.isLoading,
    this.error,
  });

  final List<ProjectRecord> projects;
  final bool isLoading;
  final String? error;

  // Convert ProjectRecord to display info
  _ProjectInfo _toProjectInfo(ProjectRecord record, int index) {
    // Determine stage color based on status
    Color stageColor;
    switch (record.status.toLowerCase()) {
      case 'initiation':
        stageColor = const Color(0xFF9747FF);
        break;
      case 'front-end planning':
      case 'planning':
        stageColor = const Color(0xFF0B7AE4);
        break;
      case 'execution':
      case 'in progress':
        stageColor = const Color(0xFF17A673);
        break;
      case 'close-out':
      case 'complete':
        stageColor = const Color(0xFF565970);
        break;
      default:
        stageColor = const Color(0xFF0B7AE4);
    }

    // Determine priority color based on index (P1, P2, P3)
    final priorityColors = [
      const Color(0xFFFFB02E), // P1 - Primary driver (yellow/orange)
      const Color(0xFF4B61D1), // P2 - Dependent (blue)
      const Color(0xFF17A673), // P3 - Support (green)
    ];
    final priorityLabels = ['P1 · Primary driver', 'P2 · Dependent', 'P3 · Support'];

    // Extract category from tags or use default
    String category = 'General';
    if (record.tags.isNotEmpty) {
      category = record.tags.first;
    }

    // Generate project code
    final projectCode = 'PRJ-${(index + 1).toString().padLeft(3, '0')} · $category';

    return _ProjectInfo(
      title: record.name.isEmpty ? 'Untitled Project' : record.name,
      code: projectCode,
      stage: record.status.isEmpty ? 'Initiation' : record.status,
      stageColor: stageColor,
      priority: priorityLabels[index.clamp(0, 2)],
      priorityColor: priorityColors[index.clamp(0, 2)],
      owner: record.ownerName.isEmpty ? 'Unassigned' : record.ownerName,
      status: 'Open',
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final remainingSlots = 3 - projects.length;

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Projects in this program', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'Review selection, prioritize work, and manage shared outcomes before rolling up to portfolio.',
                      style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF565970), height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const _SoftButton(label: 'Up to 3 related projects', icon: Icons.layers_outlined),
            ],
          ),
          const SizedBox(height: 18),
          _InsetCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: _HeaderLabel('Project')),
                      Expanded(flex: 2, child: _HeaderLabel('Stage')),
                      Expanded(flex: 2, child: _HeaderLabel('Priority')),
                      Expanded(flex: 2, child: _HeaderLabel('Owner')),
                      SizedBox(width: 64, child: Center(child: _HeaderLabel('Actions'))),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE6E7EE)),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        error!,
                        style: textTheme.bodyMedium?.copyWith(color: Colors.red),
                      ),
                    ),
                  )
                else if (projects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No projects in this program yet. Add a project to get started.',
                        style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF565970)),
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < projects.length; i++) ...[
                    _ProjectRow(info: _toProjectInfo(projects[i], i)),
                    if (i != projects.length - 1) const Divider(height: 1, color: Color(0xFFE6E7EE)),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (remainingSlots > 0)
            _Banner(
              message: remainingSlots == 1
                  ? 'There is room for one more project in this program. Keep all three aligned under a single interface plan.'
                  : 'There is room for $remainingSlots more projects in this program. Keep all three aligned under a single interface plan.',
              actionLabel: 'Add another project',
              onTap: () {},
            )
          else
            _Banner(
              message: 'This program has reached the maximum of 3 projects.',
              actionLabel: 'View all',
              onTap: () {},
            ),
        ],
      ),
    );
  }
}

class _ProgramActionsCard extends StatelessWidget {
  const _ProgramActionsCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final actions = [
      _ProgramAction(
        title: 'Gate approvals',
        description: 'Use the same approval path for all projects in this program.',
        appliesTo: 'Applies to all',
        isOn: true,
      ),
      _ProgramAction(
        title: 'Shared risk register',
        description: 'Surface program-level risks and mitigation once across all work.',
        appliesTo: 'Applies to all',
        isOn: true,
      ),
      _ProgramAction(
        title: 'Common change control',
        description: 'Route change requests through a single program board.',
        appliesTo: 'Project-specific',
        isOn: false,
        badgeColor: const Color(0xFFF0F1FF),
        badgeTextColor: const Color(0xFF3D3FA5),
      ),
    ];

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Program-level actions', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Choose which governance, risks, and costs apply to the entire program.',
            style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF565970), height: 1.45),
          ),
          const SizedBox(height: 18),
          _InsetCard(
            child: Column(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  _ProgramActionRow(action: actions[i]),
                  if (i != actions.length - 1) const Divider(height: 1, color: Color(0xFFE6E7EE)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E1017),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Apply selections'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterfaceCard extends StatelessWidget {
  const _InterfaceCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final items = _demoInterfaces;

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interface management', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'Track dependencies and shared interfaces across all projects in this program.',
                      style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF565970), height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _BadgePill(
                text: 'Interface Manager: Taylor Brooks',
                color: const Color(0xFFFFF0C2),
                textColor: const Color(0xFF8A5800),
                icon: Icons.person_outline,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InsetCard(
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _InterfaceRow(item: items[i]),
                  if (i != items.length - 1) const Divider(height: 1, color: Color(0xFFE6E7EE)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E1017),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Update interfaces for all'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RollupCard extends StatelessWidget {
  const _RollupCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final schedules = [
      _ScheduleItem(label: 'Goal 1', startMonths: 0, endMonths: 11, color: const Color(0xFF00B69A)),
      _ScheduleItem(label: 'Goal 2', startMonths: 3, endMonths: 18, color: const Color(0xFF3E8BFF)),
      _ScheduleItem(label: 'Goal 3', startMonths: 6, endMonths: 12, color: const Color(0xFFF5A524)),
    ];

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rolled up estimates', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'See combined cost, schedule, and risk posture for the entire program.',
            style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF565970), height: 1.45),
          ),
          const SizedBox(height: 18),
          _InsetCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isStacked = constraints.maxWidth < 500;
                return isStacked
                    ? Column(
                        children: [
                        _RollupSummary(slices: _demoSlices),
                          const SizedBox(height: 16),
                          _ScheduleList(items: schedules),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _RollupSummary(slices: _demoSlices)),
                          const SizedBox(width: 16),
                          Expanded(child: _ScheduleList(items: schedules)),
                        ],
                      );
              },
            ),
          ),
          const SizedBox(height: 12),
          _BadgePill(
            text: 'Risk posture: Medium · 3 open high risks across all goals · Aligned to program critical path',
            color: const Color(0xFFFFF0C2),
            textColor: const Color(0xFF8A5800),
            icon: Icons.shield_moon_outlined,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0E1017),
                    side: const BorderSide(color: Color(0xFFE6E7EE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Export program dashboard'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC812),
                    foregroundColor: const Color(0xFF0E1017),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    elevation: 4,
                    shadowColor: const Color(0xFFFFC812).withOpacity(0.45),
                  ),
                  child: const Text('Roll up to portfolio'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RollupSummary extends StatelessWidget {
  const _RollupSummary({required this.slices});

  final List<_RollupSlice> slices;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.amount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PieChart(size: 140, slices: slices),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final slice in slices)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          _Dot(color: slice.color),
                          const SizedBox(width: 8),
                          Text(slice.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text('\$${slice.amount.toStringAsFixed(1)}M · ${(slice.percent * 100).round()}%',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF565970))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text('Total cost by Program estimate: \$${total.toStringAsFixed(1)}M',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF565970))),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({required this.items});

  final List<_ScheduleItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Schedule by goal (Gantt)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final item in items) ...[
          _ScheduleRow(item: item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.item});

  final _ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    const double maxMonths = 18;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Dot(color: item.color),
            const SizedBox(width: 8),
            Text(item.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${item.startMonths.toInt()}–${item.endMonths.toInt()} months',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF565970))),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final left = (item.startMonths / maxMonths) * totalWidth;
            final width = ((item.endMonths - item.startMonths) / maxMonths) * totalWidth;
            return Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Positioned(
                  left: left,
                  child: Container(
                    height: 12,
                    width: width,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.info});

  final _ProjectInfo info;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(info.code, style: textTheme.bodySmall?.copyWith(color: const Color(0xFF6B6D80))),
              ],
            ),
          ),
          Expanded(flex: 2, child: _Pill(label: info.stage, color: info.stageColor)),
          Expanded(flex: 2, child: _Pill(label: info.priority, color: info.priorityColor, foreground: Colors.white)),
          Expanded(
            flex: 2,
            child: Text(info.owner, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            width: 64,
            child: Center(
              child: Text(info.status, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterfaceRow extends StatelessWidget {
  const _InterfaceRow({required this.item});

  final _InterfaceItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                _BadgePill(text: item.appliesTo, color: const Color(0xFFEFF3FF), textColor: const Color(0xFF0C4DA2)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.tags
                      .map((tag) => _BadgePill(text: tag, color: const Color(0xFFF3F4FA), textColor: const Color(0xFF2F3045)))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _BadgePill(text: item.riskLabel, color: item.riskColor.withOpacity(0.18), textColor: item.riskColor),
              const SizedBox(height: 12),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgramActionRow extends StatelessWidget {
  const _ProgramActionRow({required this.action});

  final _ProgramAction action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Switch.adaptive(value: action.isOn, onChanged: (_) {}),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(action.description, style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF565970), height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _BadgePill(
            text: action.appliesTo,
            color: action.badgeColor ?? const Color(0xFFEFF4FF),
            textColor: action.badgeTextColor ?? const Color(0xFF0C4DA2),
          ),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  const _PieChart({required this.size, required this.slices});

  final double size;
  final List<_RollupSlice> slices;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PieChartPainter(slices: slices),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.slices});

  final List<_RollupSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 18;
    double start = -math.pi / 2;

    for (final slice in slices) {
      final sweep = slice.percent * 2 * math.pi;
      paint.color = slice.color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 6), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) => oldDelegate.slices != slices;
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 22, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: child,
    );
  }
}

class _InsetCard extends StatelessWidget {
  const _InsetCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E7EE)),
      ),
      child: child,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.actionLabel, required this.onTap});

  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8A5800)),
            ),
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add, color: Color(0xFF8A5800)),
            label: Text(actionLabel, style: const TextStyle(color: Color(0xFF8A5800), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF6B6D80),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.foreground});

  final String label;
  final Color color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: foreground ?? color,
            ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.text, required this.color, required this.textColor, this.icon});

  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: textColor),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.color = const Color(0xFFE7F0FF), this.foreground = const Color(0xFF0C4DA2)});

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 18, color: foreground),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFC812),
        foregroundColor: const Color(0xFF0E1017),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        elevation: 4,
        shadowColor: const Color(0xFFFFC812).withOpacity(0.45),
      ),
      child: Text(label),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFD9DBE3)),
        foregroundColor: const Color(0xFF0E1017),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2FA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0E1017)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0E1017))),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ProjectInfo {
  const _ProjectInfo({
    required this.title,
    required this.code,
    required this.stage,
    required this.stageColor,
    required this.priority,
    required this.priorityColor,
    required this.owner,
    required this.status,
  });

  final String title;
  final String code;
  final String stage;
  final Color stageColor;
  final String priority;
  final Color priorityColor;
  final String owner;
  final String status;
}

class _InterfaceItem {
  const _InterfaceItem({
    required this.title,
    required this.appliesTo,
    required this.tags,
    required this.riskLabel,
    required this.riskColor,
  });

  final String title;
  final String appliesTo;
  final List<String> tags;
  final String riskLabel;
  final Color riskColor;
}

class _ProgramAction {
  const _ProgramAction({
    required this.title,
    required this.description,
    required this.appliesTo,
    required this.isOn,
    this.badgeColor,
    this.badgeTextColor,
  });

  final String title;
  final String description;
  final String appliesTo;
  final bool isOn;
  final Color? badgeColor;
  final Color? badgeTextColor;
}

class _RollupSlice {
  const _RollupSlice({required this.label, required this.amount, required this.percent, required this.color});

  final String label;
  final double amount;
  final double percent;
  final Color color;
}

class _ScheduleItem {
  const _ScheduleItem({required this.label, required this.startMonths, required this.endMonths, required this.color});

  final String label;
  final double startMonths;
  final double endMonths;
  final Color color;
}

const _demoInterfaces = [
  _InterfaceItem(
    title: 'Terminal access windows',
    appliesTo: 'Applies to all projects',
    tags: ['Ops coordination', 'Customer impact'],
    riskLabel: 'Risk: Medium',
    riskColor: Color(0xFFFFB02E),
  ),
  _InterfaceItem(
    title: 'Control room cutover',
    appliesTo: 'Applies to PRJ-001, PRJ-002',
    tags: ['Safety & SHE/R'],
    riskLabel: 'Risk: High',
    riskColor: Color(0xFFE53935),
  ),
  _InterfaceItem(
    title: 'Training & readiness',
    appliesTo: 'Applies to PRJ-002',
    tags: ['People readiness'],
    riskLabel: 'Risk: Low',
    riskColor: Color(0xFF16B673),
  ),
];

const _demoSlices = [
  _RollupSlice(label: 'Goal 1', amount: 2.1, percent: 0.40, color: Color(0xFF00B69A)),
  _RollupSlice(label: 'Goal 2', amount: 1.9, percent: 0.35, color: Color(0xFF3E8BFF)),
  _RollupSlice(label: 'Goal 3', amount: 1.4, percent: 0.25, color: Color(0xFFF5A524)),
];
