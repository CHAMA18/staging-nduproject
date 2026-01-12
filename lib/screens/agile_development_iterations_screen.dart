import 'package:flutter/material.dart';

import 'package:ndu_project/screens/detailed_design_screen.dart';
import 'package:ndu_project/screens/scope_tracking_implementation_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/agile_service.dart';

class AgileDevelopmentIterationsScreen extends StatefulWidget {
  const AgileDevelopmentIterationsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AgileDevelopmentIterationsScreen()),
    );
  }

  @override
  State<AgileDevelopmentIterationsScreen> createState() => _AgileDevelopmentIterationsScreenState();
}

class _AgileDevelopmentIterationsScreenState extends State<AgileDevelopmentIterationsScreen> {
  final Set<String> _selectedFilters = {'Single view of iteration health'};
  final TextEditingController _notesController = TextEditingController();
  bool _expandAllStories = false;
  
  String? _getProjectId() {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }
  
  Map<_BoardStatus, List<AgileStoryModel>> _groupStoriesByStatus(List<AgileStoryModel> stories) {
    final grouped = <_BoardStatus, List<AgileStoryModel>>{
      _BoardStatus.planned: [],
      _BoardStatus.inProgress: [],
      _BoardStatus.readyToDemo: [],
    };
    
    for (final story in stories) {
      switch (story.status.toLowerCase()) {
        case 'planned':
          grouped[_BoardStatus.planned]!.add(story);
          break;
        case 'inprogress':
        case 'in_progress':
          grouped[_BoardStatus.inProgress]!.add(story);
          break;
        case 'readytodemo':
        case 'ready_to_demo':
          grouped[_BoardStatus.readyToDemo]!.add(story);
          break;
      }
    }
    
    return grouped;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 18 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Agile Development Iterations'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(context),
                        const SizedBox(height: 20),
                        _buildFilterChips(context),
                        const SizedBox(height: 24),
                        _buildOverviewCard(context),
                        const SizedBox(height: 20),
                        _buildMetricsRow(context, isMobile),
                        const SizedBox(height: 20),
                        _buildBoardAndRhythmRow(context, isMobile),
                        const SizedBox(height: 20),
                        _buildMilestonesAndRiskRow(context, isMobile),
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
        Text(
          'Agile Development Iterations',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'See what is planned, what is moving, and what is at risk in the current and upcoming iterations.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
            height: 1.5,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final List<String> filters = [
      'Single view of iteration health',
      'Connect work to scope and dates',
      'Highlight only the decisions that matter',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((label) {
        final isSelected = _selectedFilters.contains(label);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              _selectedFilters.remove(label);
            } else {
              _selectedFilters.add(label);
            }
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

  Widget _buildOverviewCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          Text(
            'Use this page during stand-ups, iteration kick-offs, and demos to ground the team on what must land this cycle, how confident you are, and which dependencies could slow you down.',
            style: TextStyle(fontSize: 14, color: const Color(0xFF6B7280), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context, bool isMobile) {
    final metrics = [
      _MetricData(
        badgeLabel: 'Sprint window',
        title: 'Sprint 8 · 10 days',
        subtitle: 'Mar 4 – Mar 15 · Focus on core launch-critical stories only.',
        header: 'Current iteration',
      ),
      _MetricData(
        badgeLabel: 'Throughput',
        title: '21 committed',
        subtitle: '16 in progress · 3 done · 2 flagged as at risk.',
        header: 'Stories this iteration',
      ),
      _MetricData(
        badgeLabel: 'Confidence',
        title: 'Amber · 78%',
        subtitle: 'Blocked on environment stability and one external integration dependency.',
        header: 'Delivery health',
        titleColor: const Color(0xFFD97706),
      ),
    ];

    if (isMobile) {
      return Column(
        children: metrics.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMetricCard(m),
        )).toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: metrics.map((m) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: m == metrics.last ? 0 : 12),
          child: _buildMetricCard(m),
        ),
      )).toList(),
    );
  }

  Widget _buildMetricCard(_MetricData data) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.header,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  data.badgeLabel,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: data.titleColor ?? const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardAndRhythmRow(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildIterationBoardCard(context),
        const SizedBox(height: 12),
        _buildIterationRhythmCard(context),
      ],
    );
  }

  Widget _buildIterationBoardCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Iteration board snapshot',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _expandAllStories = !_expandAllStories),
                    icon: Icon(_expandAllStories ? Icons.unfold_less : Icons.unfold_more, size: 16),
                    label: Text(_expandAllStories ? 'Collapse all' : 'Expand all'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  _buildOutlineBadge('Stand-up view'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A compressed view of the board focusing only on launch-critical work. Use this to steer conversations away from noise.',
            style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          _buildKanbanBoard(),
        ],
      ),
    );
  }

  Widget _buildKanbanBoard() {
    final projectId = _getProjectId();
    if (projectId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No project selected. Please open a project first.',
              style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }
    
    return StreamBuilder<List<AgileStoryModel>>(
      stream: AgileService.streamStories(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Error loading stories: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        final stories = snapshot.data ?? [];
        final groupedStories = _groupStoriesByStatus(stories);
        
        final columns = [
          _BoardStatus.planned,
          _BoardStatus.inProgress,
          _BoardStatus.readyToDemo,
        ];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < columns.length; i++) ...[
              Expanded(child: _buildKanbanColumn(columns[i], groupedStories[columns[i]] ?? [])),
              if (i != columns.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildKanbanColumn(_BoardStatus status, List<AgileStoryModel> stories) {
    return DragTarget<_StoryDragData>(
      onWillAcceptWithDetails: (data) => data != null && data.from != status,
      onAcceptWithDetails: (data) => _moveStory(data, status),
      builder: (context, candidateData, _) {
        final isActive = candidateData.isNotEmpty;
        final header = _statusLabel(status);
        final count = '${stories.length} stories';
        final badgeColors = _statusBadgeColors(status);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? badgeColors.highlight : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? badgeColors.border : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                header,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: badgeColors.foreground),
                ),
              ),
              const SizedBox(height: 12),
              ...stories.map((story) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDraggableStory(status, story),
              )),
              if (stories.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Text(
                    'Drag stories here',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showAddStoryDialog(context, status),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Story'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableStory(_BoardStatus status, AgileStoryModel story) {
    final card = _buildStoryCard(story, isExpanded: _expandAllStories, status: status);
    return Draggable<_StoryDragData>(
      data: _StoryDragData(from: status, story: story),
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Opacity(opacity: 0.95, child: _buildStoryCard(story, isExpanded: true, isDragging: true, status: status)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.45, child: card),
      child: card,
    );
  }

  Widget _buildStoryCard(AgileStoryModel story, {required bool isExpanded, bool isDragging = false, required _BoardStatus status}) {
    return GestureDetector(
      onTap: () => _showEditStoryDialog(context, story),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isDragging ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB)),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    story.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, size: 16, color: Color(0xFF6B7280)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Edit'),
                      onTap: () => Future.delayed(Duration.zero, () => _showEditStoryDialog(context, story)),
                    ),
                    PopupMenuItem(
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      onTap: () => Future.delayed(Duration.zero, () => _showDeleteStoryDialog(context, story)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Owner: ${story.owner}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                Text(
                  story.points,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              story.notes,
              maxLines: isExpanded ? null : 2,
              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showAddStoryDialog(BuildContext context, _BoardStatus status) {
    final projectId = _getProjectId();
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    
    String statusString;
    switch (status) {
      case _BoardStatus.planned:
        statusString = 'planned';
        break;
      case _BoardStatus.inProgress:
        statusString = 'inProgress';
        break;
      case _BoardStatus.readyToDemo:
        statusString = 'readyToDemo';
        break;
    }
    
    final titleController = TextEditingController();
    final ownerController = TextEditingController();
    final pointsController = TextEditingController();
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Story'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 12),
              TextField(controller: ownerController, decoration: const InputDecoration(labelText: 'Owner *')),
              const SizedBox(height: 12),
              TextField(controller: pointsController, decoration: const InputDecoration(labelText: 'Points *')),
              const SizedBox(height: 12),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes *'), maxLines: 3),
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
              if (titleController.text.isEmpty || ownerController.text.isEmpty || pointsController.text.isEmpty || notesController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all required fields')),
                );
                return;
              }
              
              try {
                await AgileService.createStory(
                  projectId: projectId,
                  title: titleController.text,
                  owner: ownerController.text,
                  points: pointsController.text,
                  notes: notesController.text,
                  status: statusString,
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Story added successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _showEditStoryDialog(BuildContext context, AgileStoryModel story) {
    final projectId = _getProjectId();
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    
    final titleController = TextEditingController(text: story.title);
    final ownerController = TextEditingController(text: story.owner);
    final pointsController = TextEditingController(text: story.points);
    final notesController = TextEditingController(text: story.notes);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Story'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title *')),
              const SizedBox(height: 12),
              TextField(controller: ownerController, decoration: const InputDecoration(labelText: 'Owner *')),
              const SizedBox(height: 12),
              TextField(controller: pointsController, decoration: const InputDecoration(labelText: 'Points *')),
              const SizedBox(height: 12),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes *'), maxLines: 3),
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
              if (titleController.text.isEmpty || ownerController.text.isEmpty || pointsController.text.isEmpty || notesController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all required fields')),
                );
                return;
              }
              
              try {
                await AgileService.updateStory(
                  projectId: projectId,
                  storyId: story.id,
                  title: titleController.text,
                  owner: ownerController.text,
                  points: pointsController.text,
                  notes: notesController.text,
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Story updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteStoryDialog(BuildContext context, AgileStoryModel story) {
    final projectId = _getProjectId();
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story'),
        content: Text('Are you sure you want to delete "${story.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await AgileService.deleteStory(projectId: projectId, storyId: story.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Story deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting story: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildIterationRhythmCard(BuildContext context) {
    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Iteration rhythm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              _buildOutlineBadge('10-day cadence'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Keep a lightweight but disciplined rhythm so that every iteration produces visible, reviewable progress.',
            style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Burndown trend',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          _buildBurndownBar(),
          const SizedBox(height: 8),
          Text(
            'Slightly behind ideal line · 4 pts to pull into next sprint if risk remains.',
            style: TextStyle(fontSize: 12, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          _buildRhythmBullet('Align scope for the next sprint while there are still 3–4 days left in the current one.'),
          _buildRhythmBullet('Reserve capacity every iteration for technical debt and stabilization work.'),
          _buildRhythmBullet('Capture 3–5 key learnings in each retrospective and link them to concrete actions.'),
        ],
      ),
    );
  }

  Widget _buildBurndownBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 0.72,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildRhythmBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF6B7280),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesAndRiskRow(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildUpcomingMilestonesCard(context),
        const SizedBox(height: 12),
        _buildDependencyRiskCard(context),
      ],
    );
  }

  Widget _buildUpcomingMilestonesCard(BuildContext context) {
    final milestones = [
      _MilestoneItem(title: 'Beta launch feature-complete', date: 'Mar 29'),
      _MilestoneItem(title: 'Security & compliance sign-off', date: 'Apr 05'),
      _MilestoneItem(title: 'Production readiness review', date: 'Apr 18'),
    ];

    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming milestones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              _buildOutlineBadge('Next 30 days'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Anchor the team on the few milestones that really matter for this execution phase.',
            style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          ...milestones.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  m.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
                ),
                Text(
                  m.date,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDependencyRiskCard(BuildContext context) {
    final risks = [
      'Payments sandbox instability could delay end-to-end checkout testing by 3–5 days.',
      'Environment capacity upgrades must land before load-testing window opens.',
      'Design bandwidth is tight; agree on what can move to a later iteration.',
    ];

    return _ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dependency & risk watch',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Exec focus',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Only track items that can move dates or compromise launch quality.',
            style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          ...risks.map((r) => _buildRhythmBullet(r)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip('+ Log new iteration risk'),
              _buildActionChip('Link to vendor tracking'),
              _buildActionChip('Export iteration summary'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildOutlineBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
      ),
    );
  }

  Widget _buildFooterNavigation(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to vendor tracking'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            Text(
              'Execution setup · 75% complete',
              style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280)),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.checklist, size: 16),
              label: const Text('Review sprint checklist'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chevron_right, size: 16),
              label: const Text('Next: Scope tracking implementation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC812),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC812),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Ask how to de-risk this iteration'),
                  SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.lightbulb_outline, size: 16, color: const Color(0xFFFFC812)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Use this page as the single answer to: what we promised this iteration, where we stand today, and which decisions we need from leadership.',
                style: TextStyle(fontSize: 12, color: const Color(0xFF6B7280), fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LaunchPhaseNavigation(
          backLabel: 'Back: Detailed Design',
          nextLabel: 'Next: Scope Tracking Implementation',
          onBack: () => DetailedDesignScreen.open(context),
          onNext: () => ScopeTrackingImplementationScreen.open(context),
        ),
      ],
    );
  }

  Future<void> _moveStory(_StoryDragData data, _BoardStatus target) async {
    final projectId = _getProjectId();
    if (projectId == null) return;
    
    String statusString;
    switch (target) {
      case _BoardStatus.planned:
        statusString = 'planned';
        break;
      case _BoardStatus.inProgress:
        statusString = 'inProgress';
        break;
      case _BoardStatus.readyToDemo:
        statusString = 'readyToDemo';
        break;
    }
    
    try {
      await AgileService.updateStory(
        projectId: projectId,
        storyId: data.story.id,
        status: statusString,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating story: $e')),
        );
      }
    }
  }

  String _statusLabel(_BoardStatus status) {
    switch (status) {
      case _BoardStatus.planned:
        return 'PLANNED';
      case _BoardStatus.inProgress:
        return 'IN PROGRESS';
      case _BoardStatus.readyToDemo:
        return 'READY TO DEMO';
    }
  }

  _StatusBadgeColors _statusBadgeColors(_BoardStatus status) {
    switch (status) {
      case _BoardStatus.planned:
        return const _StatusBadgeColors(
          background: Color(0xFFE0F2FE),
          foreground: Color(0xFF0369A1),
          border: Color(0xFF93C5FD),
          highlight: Color(0xFFF0F9FF),
        );
      case _BoardStatus.inProgress:
        return const _StatusBadgeColors(
          background: Color(0xFFEDE9FE),
          foreground: Color(0xFF6D28D9),
          border: Color(0xFFC4B5FD),
          highlight: Color(0xFFF5F3FF),
        );
      case _BoardStatus.readyToDemo:
        return const _StatusBadgeColors(
          background: Color(0xFFDCFCE7),
          foreground: Color(0xFF15803D),
          border: Color(0xFF86EFAC),
          highlight: Color(0xFFF0FDF4),
        );
    }
  }
}

class _ContentCard extends StatelessWidget {
  final Widget child;
  const _ContentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _MetricData {
  final String header;
  final String badgeLabel;
  final String title;
  final String subtitle;
  final Color? titleColor;

  _MetricData({
    required this.header,
    required this.badgeLabel,
    required this.title,
    required this.subtitle,
    this.titleColor,
  });
}

enum _BoardStatus { planned, inProgress, readyToDemo }

class _StoryDragData {
  final _BoardStatus from;
  final AgileStoryModel story;

  _StoryDragData({required this.from, required this.story});
}

class _StatusBadgeColors {
  const _StatusBadgeColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.highlight,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color highlight;
}

class _MilestoneItem {
  final String title;
  final String date;

  _MilestoneItem({required this.title, required this.date});
}
