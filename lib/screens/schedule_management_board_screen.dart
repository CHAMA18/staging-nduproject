import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/responsive.dart';

const String _currencySymbol = r'$';

class ScheduleManagementBoardScreen extends StatelessWidget {
  const ScheduleManagementBoardScreen({super.key});

  static const List<_ScheduleColumnData> _columns = [
    _ScheduleColumnData(
      title: 'To Do',
      count: 3,
      background: Color(0xFFF5F7FE),
      cards: [
        _ScheduleCardData(
          title: 'Frontend Setup',
          tags: ['medium', 'Technology'],
          assignee: 'Mike Johnson',
          dueDate: 'Due Jul 01',
          estimatedHours: '80.00h estimated',
          status: _CardStatus.inProgress,
          progressPercent: 0.3,
        ),
        _ScheduleCardData(
          title: 'UI/UX Design Implementation',
          tags: ['progress', 'Design'],
          assignee: 'Jane Smith',
          dueDate: 'Due Aug 15',
          estimatedHours: '90.00h estimated',
          status: _CardStatus.pending,
          progressPercent: 0.0,
        ),
        _ScheduleCardData(
          title: 'System Testing',
          tags: ['high', 'Quality'],
          assignee: 'MJ',
          dueDate: 'Due Nov 01',
          estimatedHours: '100.00h estimated',
          status: _CardStatus.critical,
          progressPercent: 0.0,
        ),
      ],
    ),
    _ScheduleColumnData(
      title: 'In Progress',
      count: 2,
      background: Color(0xFFEAF4FF),
      cards: [
        _ScheduleCardData(
          title: 'API Development',
          tags: ['high', 'Technology'],
          assignee: 'Jane Smith',
          dueDate: 'Due Apr 01',
          estimatedHours: '200.00h estimated',
          status: _CardStatus.inProgress,
          progressPercent: 0.45,
        ),
        _ScheduleCardData(
          title: 'Core Integration (Critical)',
          tags: ['critical', 'Technology'],
          assignee: 'John Doe',
          dueDate: 'Due Jan 10',
          estimatedHours: '160.00h estimated',
          status: _CardStatus.critical,
          progressPercent: 0.3,
        ),
      ],
    ),
    _ScheduleColumnData(
      title: 'Done',
      count: 1,
      background: Color(0xFFE9F9F2),
      cards: [
        _ScheduleCardData(
          title: 'Backend Infrastructure Setup',
          tags: ['high', 'Technology'],
          assignee: 'John Doe',
          dueDate: 'Due Feb 15',
          estimatedHours: '120.00h estimated',
          status: _CardStatus.completed,
          progressPercent: 1.0,
        ),
      ],
    ),
    _ScheduleColumnData(
      title: 'Overdue',
      count: 0,
      background: Color(0xFFFDECF1),
      cards: [],
    ),
  ];

  static const List<_MetricChip> _metricSummary = [
    _MetricChip('Project Cost', '${_currencySymbol}235,000'),
    _MetricChip('Tasks', '120 tasks'),
    _MetricChip('Team Effort', '1800 hrs'),
    _MetricChip('Critical Path', 'Active'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppBreakpoints.pagePadding(context),
                vertical: AppBreakpoints.sectionGap(context) + 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHeader(isMobile: isMobile),
                  const SizedBox(height: 24),
                  _NotesArea(isMobile: isMobile),
                  const SizedBox(height: 24),
                  _ScheduleToolbar(isMobile: isMobile),
                  const SizedBox(height: 24),
                  _WorkBreakdownStructure(isMobile: isMobile, metrics: _metricSummary),
                  const SizedBox(height: 32),
                  _TimelineTabs(isMobile: isMobile),
                  const SizedBox(height: 24),
                  _KanbanBoard(isMobile: isMobile, columns: _columns),
                  const SizedBox(height: 28),
                  _BoardFooter(isMobile: isMobile),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = Text(
      'Schedule Management',
      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
    );

    final chips = Wrap(
      spacing: 12,
      children: const [
        _SoftBadge(icon: Icons.group_outlined, label: 'Teams'),
        _SoftBadge(icon: Icons.bar_chart_outlined, label: 'Analytics'),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 12),
          chips,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        chips,
      ],
    );
  }
}

class _NotesArea extends StatelessWidget {
  const _NotesArea({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: TextField(
        minLines: isMobile ? 4 : 6,
        maxLines: isMobile ? 6 : 10,
        decoration: InputDecoration(
          hintText: 'Input your notes here...',
          border: InputBorder.none,
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
        ),
      ),
    );
  }
}

class _ScheduleToolbar extends StatelessWidget {
  const _ScheduleToolbar({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppSemanticColors.border),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: 'Waterfall',
          items: const [DropdownMenuItem(value: 'Waterfall', child: Text('Waterfall'))],
          onChanged: (_) {},
        ),
      ),
    );

    final controls = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ToolbarButton(icon: Icons.group_work_outlined, label: 'Team'),
        _ToolbarButton(icon: Icons.filter_alt_outlined, label: 'Filter'),
        _ToolbarButton(icon: Icons.speed, label: 'Estimates'),
        _ToolbarButton(icon: Icons.cloud_download_outlined, label: 'Import'),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('New Task'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 12)),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Methodology', style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 8),
                dropdown,
                const SizedBox(height: 16),
                controls,
              ],
            )
          : Row(
              children: [
                Text('Schedule Management', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                dropdown,
                const Spacer(),
                controls,
              ],
            ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        side: BorderSide(color: AppSemanticColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _WorkBreakdownStructure extends StatelessWidget {
  const _WorkBreakdownStructure({required this.isMobile, required this.metrics});

  final bool isMobile;
  final List<_MetricChip> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Work Breakdown Structure', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics.map((metric) => _MetricTile(metric: metric)).toList(),
        ),
        const SizedBox(height: 24),
        _LegendList(items: const [
          _LegendItem(label: 'Project Cost', color: Color(0xFF2563EB)),
          _LegendItem(label: 'Schedule Drift', color: Color(0xFFF59E0B)),
          _LegendItem(label: 'Critical Path Impact', color: Color(0xFFFF5A5F)),
          _LegendItem(label: 'Team Utilization', color: Color(0xFF16A34A)),
        ]),
      ],
    );

    final rightColumn = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _WbsLane(
            badgeLabel: 'Infrastructure Development',
            badgeColor: Color(0xFF2563EB),
            entries: [
              _WbsEntry(title: 'Unassigned Deliverables', subtitle: 'Filter to discipline', statusLabel: 'Unassigned'),
              _WbsEntry(title: 'Safety & Health Risk Assessment', subtitle: 'SSHER', statusLabel: 'Unassigned'),
              _WbsEntry(
                title: 'Environmental Documentation',
                subtitle: 'Environmental Impact Assessment',
                statusLabel: 'Engineering',
                indicatorColor: Color(0xFFFF5A5F),
              ),
              _WbsEntry(title: 'Site Preparation Complete', subtitle: 'All contractors mobilized', statusLabel: 'Site Prep'),
            ],
          ),
          SizedBox(height: 12),
          _WbsLane(
            badgeLabel: 'Foundation Systems',
            badgeColor: Color(0xFF16A34A),
            entries: [
              _WbsEntry(title: 'Permits & Approvals', subtitle: 'Construction', statusLabel: 'Engineering'),
            ],
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftColumn,
                const SizedBox(height: 24),
                rightColumn,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: leftColumn),
                const SizedBox(width: 24),
                Expanded(flex: 6, child: rightColumn),
              ],
            ),
    );
  }
}

class _TimelineTabs extends StatelessWidget {
  const _TimelineTabs({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const tabs = ['Gantt', 'List', 'Board'];

    final buttons = tabs.map((tab) => _TimelineTab(label: tab, selected: tab == 'Board')).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Project Timeline', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Wrap(spacing: 12, runSpacing: 12, children: buttons),
                const SizedBox(height: 16),
                const _ViewControls(isMobile: true),
              ],
            )
          : Row(
              children: [
                Text('Project Timeline', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 24),
                Wrap(spacing: 12, children: buttons),
                const Spacer(),
                const _ViewControls(isMobile: false),
              ],
            ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  const _TimelineTab({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primary : Colors.grey[100],
        borderRadius: BorderRadius.circular(999),
        boxShadow: selected
            ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.32), blurRadius: 16, offset: const Offset(0, 8))]
            : null,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: selected ? Colors.white : Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ViewControls extends StatelessWidget {
  const _ViewControls({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppSemanticColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('View:', style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey[600])),
              const SizedBox(width: 8),
              Text('Days', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Validate'),
        ),
      ],
    );
  }
}

class _KanbanBoard extends StatelessWidget {
  const _KanbanBoard({required this.isMobile, required this.columns});

  final bool isMobile;
  final List<_ScheduleColumnData> columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final gap = AppBreakpoints.isTablet(context) ? 16.0 : 20.0;
        final columnWidth = isMobile
            ? availableWidth
            : (availableWidth - gap * (columns.length - 1)) / columns.length;

        return Wrap(
          spacing: gap,
          runSpacing: 16,
          children: columns.map((column) {
            final width = columnWidth.clamp(280.0, 360.0);
            return SizedBox(width: width, child: _KanbanColumn(column: column));
          }).toList(),
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({required this.column});

  final _ScheduleColumnData column;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: column.background,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(column.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              _SoftBadge(label: column.count.toString()),
              const Spacer(),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
            ],
          ),
          const SizedBox(height: 16),
          if (column.cards.isEmpty)
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text('No items yet', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[500])),
              ),
            )
          else
            Column(
              children: [
                for (final card in column.cards) ...[
                  _KanbanCard(card: card),
                  const SizedBox(height: 16),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({required this.card});

  final _ScheduleCardData card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: card.tags.map((tag) => _StatusPill(label: tag)).toList(),
          ),
          const SizedBox(height: 12),
          Text(card.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _ProgressIndicator(status: card.status, progress: card.progressPercent),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  card.assigneeInitials,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.assignee, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text(card.dueDate, style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(card.estimatedHours, style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoardFooter extends StatelessWidget {
  const _BoardFooter({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final legendItems = const [
      _LegendItem(label: 'Completed', color: Color(0xFF16A34A)),
      _LegendItem(label: 'In Progress', color: Color(0xFF2563EB)),
      _LegendItem(label: 'Pending', color: Color(0xFFF59E0B)),
      _LegendItem(label: 'Critical Path', color: Color(0xFFFF5A5F)),
    ];

    final buttons = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.note_add_outlined), label: const Text('Add Note')),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.report_problem_outlined), label: const Text('Review Required')),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.verified_user_outlined), label: const Text('Approve Baseline')),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendList(items: legendItems),
                const SizedBox(height: 24),
                buttons,
              ],
            )
          : Row(
              children: [
                Expanded(child: _LegendList(items: legendItems)),
                const SizedBox(width: 24),
                buttons,
              ],
            ),
    );
  }
}

class _LegendList extends StatelessWidget {
  const _LegendList({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 12,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 8),
            Text(item.label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey[700])),
          ],
        );
      }).toList(),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  Color _resolveColor(BuildContext context) {
    final lower = label.toLowerCase();
    switch (lower) {
      case 'critical':
      case 'critical path':
        return const Color(0xFFFF5A5F);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'pending':
      case 'progress':
      case 'in progress':
        return const Color(0xFF2563EB);
      case 'design':
        return const Color(0xFF9333EA);
      case 'quality':
        return const Color(0xFF0EA5E9);
      case 'technology':
        return const Color(0xFF1D4ED8);
      case 'completed':
        return AppSemanticColors.success;
      case 'unassigned':
        return Colors.grey.shade600;
      case 'engineering':
        return const Color(0xFF0EA5E9);
      case 'site prep':
        return const Color(0xFF16A34A);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.status, required this.progress});

  final _CardStatus status;
  final double progress;

  Color _statusColor(BuildContext context) {
    switch (status) {
      case _CardStatus.completed:
        return AppSemanticColors.success;
      case _CardStatus.critical:
        return const Color(0xFFFF5A5F);
      case _CardStatus.inProgress:
        return Theme.of(context).colorScheme.primary;
      case _CardStatus.pending:
        return const Color(0xFFF59E0B);
    }
  }

  String _statusLabel() {
    switch (status) {
      case _CardStatus.completed:
        return 'Completed';
      case _CardStatus.critical:
        return 'Critical';
      case _CardStatus.inProgress:
        return 'In Progress';
      case _CardStatus.pending:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_statusLabel(), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${(progress * 100).round()}%', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.02, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _SoftBadge extends StatelessWidget {
  const _SoftBadge({this.icon, required this.label});

  final IconData? icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
          ],
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _MetricChip metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(metric.value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WbsLane extends StatelessWidget {
  const _WbsLane({required this.badgeLabel, required this.badgeColor, required this.entries});

  final String badgeLabel;
  final Color badgeColor;
  final List<_WbsEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
          child: Text(badgeLabel, style: theme.textTheme.labelLarge?.copyWith(color: badgeColor, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            for (final entry in entries) ...[
              _WbsCard(entry: entry),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ],
    );
  }
}

class _WbsCard extends StatelessWidget {
  const _WbsCard({required this.entry});

  final _WbsEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppSemanticColors.border),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(entry.subtitle, style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
              _StatusPill(label: entry.statusLabel),
            ],
          ),
          if (entry.indicatorColor != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.error_outline, size: 20, color: entry.indicatorColor),
                const SizedBox(width: 8),
                Text('Critical action required', style: theme.textTheme.labelMedium?.copyWith(color: entry.indicatorColor)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum _CardStatus { completed, inProgress, pending, critical }

class _ScheduleColumnData {
  const _ScheduleColumnData({
    required this.title,
    required this.count,
    required this.background,
    required this.cards,
  });

  final String title;
  final int count;
  final Color background;
  final List<_ScheduleCardData> cards;
}

class _ScheduleCardData {
  const _ScheduleCardData({
    required this.title,
    required this.tags,
    required this.assignee,
    required this.dueDate,
    required this.estimatedHours,
    required this.status,
    required this.progressPercent,
  });

  final String title;
  final List<String> tags;
  final String assignee;
  final String dueDate;
  final String estimatedHours;
  final _CardStatus status;
  final double progressPercent;

  String get assigneeInitials {
    final parts = assignee.trim().split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return parts.take(2).map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}

class _MetricChip {
  const _MetricChip(this.label, this.value);

  final String label;
  final String value;
}

class _LegendItem {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;
}

class _WbsEntry {
  const _WbsEntry({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    this.indicatorColor,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Color? indicatorColor;
}