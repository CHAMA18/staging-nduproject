import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';

class IssueManagementScreen extends StatefulWidget {
  const IssueManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IssueManagementScreen()),
    );
  }

  @override
  State<IssueManagementScreen> createState() => _IssueManagementScreenState();
}

class _IssueManagementScreenState extends State<IssueManagementScreen> {
  String _selectedFilter = 'All Issues';

  final List<_IssueMetric> _metrics = const [];
  final List<_MilestoneIssues> _milestones = const [];
  final List<_IssueLogEntry> _logEntries = const [];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 36;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Issue Management'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopUtilityBar(onBack: () => Navigator.maybePop(context)),
                        const SizedBox(height: 24),
                        const PlanningAiNotesCard(
                          title: 'AI Notes',
                          sectionLabel: 'Issue Management',
                          noteKey: 'planning_issue_management_notes',
                          checkpoint: 'issue_management',
                          description: 'Summarize key issues, escalation paths, and resolution priorities.',
                        ),
                        const SizedBox(height: 24),
                        const _PageTitle(),
                        const SizedBox(height: 24),
                        _IssuesOverviewCard(metrics: _metrics),
                        const SizedBox(height: 24),
                        _IssuesByMilestoneCard(
                          milestones: _milestones,
                          selectedFilter: _selectedFilter,
                          onFilterChanged: (value) => setState(() => _selectedFilter = value),
                        ),
                        const SizedBox(height: 24),
                        _ProjectIssuesLogCard(entries: _logEntries),
                        const SizedBox(height: 80),
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
}

class _TopUtilityBar extends StatelessWidget {
  const _TopUtilityBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _circleButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 12),
          _circleButton(icon: Icons.arrow_forward_ios_rounded),
          const SizedBox(width: 20),
          const Text(
            'Issues Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          const Spacer(),
          const _UserChip(name: 'Samuel kamanga', role: 'Product manager'),
          const SizedBox(width: 12),
          _OutlinedButton(label: 'Export', onPressed: () {}),
          const SizedBox(width: 12),
          _YellowButton(label: 'New Project', onPressed: () {}),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Issues Management',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        SizedBox(height: 8),
        Text(
          'Traci, manage, and resolve project issues',
          style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _IssuesOverviewCard extends StatelessWidget {
  const _IssuesOverviewCard({required this.metrics});

  final List<_IssueMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const _SectionEmptyState(
        title: 'No issue metrics yet',
        message: 'Capture issues to populate health, status, and resolution metrics.',
        icon: Icons.insights_outlined,
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Issues Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Definition would be at the top of the page or clickable to learn about it . Template would give option to identify what type of issues. Can be sorted fr the different MPs for discussion in meetings',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 640;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: metrics
                    .map((metric) => SizedBox(
                          width: isNarrow ? (constraints.maxWidth - 16) : (constraints.maxWidth - 16 * 2) / 3,
                          child: _MetricCard(metric: metric),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _IssueMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: metric.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(metric.icon, size: 22, color: metric.color),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 4),
              Text(
                metric.label,
                style: TextStyle(fontSize: 13, color: metric.color.withOpacity(0.8), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssuesByMilestoneCard extends StatelessWidget {
  const _IssuesByMilestoneCard({required this.milestones, required this.selectedFilter, required this.onFilterChanged});

  final List<_MilestoneIssues> milestones;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return const _SectionEmptyState(
        title: 'No milestone issues logged',
        message: 'Add milestone issues to track escalation risk and delivery impact.',
        icon: Icons.flag_outlined,
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Issues by Milestone',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedFilter,
                    alignment: Alignment.centerRight,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
                    items: const [
                      DropdownMenuItem(value: 'All Issues', child: Text('All Issues')),
                      DropdownMenuItem(value: 'Open', child: Text('Open')),
                      DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                    ],
                    onChanged: (value) {
                      if (value != null) onFilterChanged(value);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Column(
            children: milestones
                .map(
                  (milestone) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(color: milestone.indicatorColor, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  milestone.title,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  milestone.issuesCountLabel,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            milestone.dueDate,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(width: 16),
                          _StatusPill(label: milestone.statusLabel, background: const Color(0xFFE9F7EF), foreground: const Color(0xFF059669)),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ProjectIssuesLogCard extends StatelessWidget {
  const _ProjectIssuesLogCard({required this.entries});

  final List<_IssueLogEntry> entries;

  static const List<int> _columnFlex = [2, 3, 2, 2, 2, 2, 2, 2];

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const _SectionEmptyState(
        title: 'Issue log is empty',
        message: 'Log issues to build a traceable resolution history.',
        icon: Icons.list_alt_outlined,
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Project Issues Log',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              const Spacer(),
              SizedBox(
                width: 220,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFFD54F)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _OutlinedButton(label: 'Filter', onPressed: () {}),
              const SizedBox(width: 12),
              _OutlinedButton(label: 'Export', onPressed: () {}),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  child: Row(
                    children: [
                      _tableHeaderCell('ID', flex: _columnFlex[0]),
                      _tableHeaderCell('Title', flex: _columnFlex[1]),
                      _tableHeaderCell('Type', flex: _columnFlex[2]),
                      _tableHeaderCell('Severity', flex: _columnFlex[3]),
                      _tableHeaderCell('Status', flex: _columnFlex[4]),
                      _tableHeaderCell('Assignee', flex: _columnFlex[5]),
                      _tableHeaderCell('Due Date', flex: _columnFlex[6]),
                      _tableHeaderCell('Milestone', flex: _columnFlex[7]),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                ...entries.map((entry) => _IssueLogRow(entry: entry, columnFlex: _columnFlex)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeaderCell(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
      ),
    );
  }
}

class _IssueLogRow extends StatelessWidget {
  const _IssueLogRow({required this.entry, required this.columnFlex});

  final _IssueLogEntry entry;
  final List<int> columnFlex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: columnFlex[0],
            child: Text(
              entry.id,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
            ),
          ),
          Expanded(
            flex: columnFlex[1],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: columnFlex[2],
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(
                label: entry.type,
                background: const Color(0xFFEFF6FF),
                foreground: const Color(0xFF2563EB),
              ),
            ),
          ),
          Expanded(
            flex: columnFlex[3],
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(
                label: entry.severity,
                background: const Color(0xFFFFF7ED),
                foreground: const Color(0xFFEA580C),
              ),
            ),
          ),
          Expanded(
            flex: columnFlex[4],
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(
                label: entry.status,
                background: const Color(0xFFFFF7E6),
                foreground: const Color(0xFFB45309),
              ),
            ),
          ),
          Expanded(
            flex: columnFlex[5],
            child: Text(
              entry.assignee,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            ),
          ),
          Expanded(
            flex: columnFlex[6],
            child: Text(
              entry.dueDate,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
            ),
          ),
          Expanded(
            flex: columnFlex[7],
            child: Text(
              entry.milestone,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF4B5563)),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({required this.title, required this.message, required this.icon});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE5E7EB),
            child: Icon(Icons.person, size: 18, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              Text(
                role,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YellowButton extends StatelessWidget {
  const _YellowButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD54F),
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }
}

class _IssueMetric {
  const _IssueMetric({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _MilestoneIssues {
  const _MilestoneIssues({required this.title, required this.issuesCountLabel, required this.dueDate, required this.statusLabel, required this.indicatorColor});

  final String title;
  final String issuesCountLabel;
  final String dueDate;
  final String statusLabel;
  final Color indicatorColor;
}

class _IssueLogEntry {
  const _IssueLogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    required this.status,
    required this.assignee,
    required this.dueDate,
    required this.milestone,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final String severity;
  final String status;
  final String assignee;
  final String dueDate;
  final String milestone;
}
