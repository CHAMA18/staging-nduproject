import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/screens/change_management_screen.dart';

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

  List<_IssueMetric> _metrics = [];
  List<_MilestoneIssues> _milestones = [];

  Future<void> _handleNewIssue() async {
    final entry = await showDialog<IssueLogItem>(
      context: context,
      builder: (dialogContext) => const _NewIssueDialog(),
    );
    if (entry == null) return;
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'issue_management',
      dataUpdater: (data) => data.copyWith(
        issueLogItems: [...data.issueLogItems, entry],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 36;
    final issueItems = ProjectDataHelper.getData(context).issueLogItems;

    // Build metrics and milestones from persisted issue items
    _metrics = [
      _IssueMetric(label: 'Open', value: issueItems.where((i) => i.status == 'Open').length.toString(), icon: Icons.report_problem_outlined, color: Colors.orange),
      _IssueMetric(label: 'In Progress', value: issueItems.where((i) => i.status == 'In Progress').length.toString(), icon: Icons.autorenew, color: Colors.blue),
      _IssueMetric(label: 'Resolved', value: issueItems.where((i) => i.status == 'Resolved' || i.status == 'Closed').length.toString(), icon: Icons.check_circle_outline, color: Colors.green),
    ];

    final byMilestone = <String, List<IssueLogItem>>{};
    for (final it in issueItems) {
      final key = it.milestone.isEmpty ? 'Unassigned' : it.milestone;
      byMilestone.putIfAbsent(key, () => []).add(it);
    }
    _milestones = byMilestone.entries
        .map((e) => _MilestoneIssues(title: e.key, issuesCountLabel: '${e.value.length} issues', dueDate: '', statusLabel: 'Open', indicatorColor: Colors.orange))
        .toList();

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
                        _TopUtilityBar(
                          onBack: () => Navigator.maybePop(context),
                          onAddIssue: _handleNewIssue,
                        ),
                        const SizedBox(height: 24),
                        const PlanningAiNotesCard(
                          title: 'Notes',
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
                        _ProjectIssuesLogCard(entries: issueItems),
                        const SizedBox(height: 16),
                        LaunchPhaseNavigation(
                          backLabel: 'Back: SSHER',
                          nextLabel: 'Next: Change Management',
                          onBack: () => Navigator.of(context).maybePop(),
                          onNext: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangeManagementScreen())),
                        ),
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
  const _TopUtilityBar({required this.onBack, required this.onAddIssue});

  final VoidCallback onBack;
  final VoidCallback onAddIssue;

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
          const _UserChip(name: '', role: ''),
          const SizedBox(width: 12),
          _YellowButton(label: 'New Issue', onPressed: onAddIssue),
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
          if (metrics.isEmpty)
            const _InlineStatusCard(
              title: 'No issue metrics yet',
              message: 'Capture issues to populate health, status, and resolution metrics.',
              icon: Icons.insights_outlined,
            )
          else
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
          if (milestones.isEmpty)
            const _InlineStatusCard(
              title: 'No milestone issues logged',
              message: 'Add milestone issues to track escalation risk and delivery impact.',
              icon: Icons.flag_outlined,
            )
          else
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
                            _StatusPill(
                              label: milestone.statusLabel,
                              background: const Color(0xFFE9F7EF),
                              foreground: const Color(0xFF059669),
                            ),
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

  final List<IssueLogItem> entries;

  static const List<int> _columnFlex = [2, 3, 2, 2, 2, 2, 2, 2];

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
            ],
          ),
          const SizedBox(height: 22),
          if (entries.isEmpty)
            const _InlineStatusCard(
              title: 'Issue log is empty',
              message: 'Log issues to build a traceable resolution history.',
              icon: Icons.list_alt_outlined,
            )
          else
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
                  ...entries.map((entry) => _IssueLogRow(entry: entry, columnFlex: _columnFlex, onDelete: () async {
                        final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Delete issue?'), content: const Text('This will permanently remove the issue.'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete'))]));
                        if (confirmed == true) {
                          await ProjectDataHelper.updateAndSave(context: context, checkpoint: 'issue_management', dataUpdater: (data) => data.copyWith(issueLogItems: data.issueLogItems.where((i) => i.id != entry.id).toList()));
                          // force rebuild
                          (context as Element).markNeedsBuild();
                        }
                      })),
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
  const _IssueLogRow({required this.entry, required this.columnFlex, this.onDelete});

  final IssueLogItem entry;
  final List<int> columnFlex;
  final VoidCallback? onDelete;

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
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _InlineStatusCard extends StatelessWidget {
  const _InlineStatusCard({required this.title, required this.message, required this.icon});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
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

class _NewIssueDialog extends StatefulWidget {
  const _NewIssueDialog();

  @override
  State<_NewIssueDialog> createState() => _NewIssueDialogState();
}

class _NewIssueDialogState extends State<_NewIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _assigneeCtrl = TextEditingController();
  final TextEditingController _dueDateCtrl = TextEditingController();
  final TextEditingController _milestoneCtrl = TextEditingController();

  final List<String> _types = const ['Scope', 'Schedule', 'Cost', 'Quality', 'Risk', 'Other'];
  final List<String> _severities = const ['Low', 'Medium', 'High', 'Critical'];
  final List<String> _statuses = const ['Open', 'In Progress', 'Resolved', 'Closed'];

  String _selectedType = 'Scope';
  String _selectedSeverity = 'Medium';
  String _selectedStatus = 'Open';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _assigneeCtrl.dispose();
    _dueDateCtrl.dispose();
    _milestoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _selectedDate ?? now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dueDateCtrl.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  String _generateId() {
    final seed = DateTime.now().microsecondsSinceEpoch.toString();
    return 'ISS-${seed.substring(seed.length - 4)}';
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final entry = IssueLogItem(
      id: _generateId(),
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      type: _selectedType,
      severity: _selectedSeverity,
      status: _selectedStatus,
      assignee: _assigneeCtrl.text.trim(),
      dueDate: _dueDateCtrl.text.trim(),
      milestone: _milestoneCtrl.text.trim(),
    );
    Navigator.of(context).pop(entry);
  }

  InputDecoration _decoration(String label, {String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.35))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.35))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFFD54F), width: 1.6)),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Issue'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: _decoration('Title', hint: 'e.g. Data migration delay'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (value) => setState(() => _selectedType = value ?? _selectedType),
                  decoration: _decoration('Type'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSeverity,
                  items: _severities.map((severity) => DropdownMenuItem(value: severity, child: Text(severity))).toList(),
                  onChanged: (value) => setState(() => _selectedSeverity = value ?? _selectedSeverity),
                  decoration: _decoration('Severity'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  items: _statuses.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                  onChanged: (value) => setState(() => _selectedStatus = value ?? _selectedStatus),
                  decoration: _decoration('Status'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _assigneeCtrl,
                  decoration: _decoration('Assignee', hint: 'Owner'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dueDateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: _decoration('Due Date', hint: 'YYYY-MM-DD', suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _milestoneCtrl,
                  decoration: _decoration('Milestone', hint: 'Related milestone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  minLines: 3,
                  maxLines: 5,
                  decoration: _decoration('Description', hint: 'Describe the issue'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = FirebaseAuthService.displayNameOrEmail(fallback: name.isNotEmpty ? name : 'User');
    final email = user?.email ?? '';
    final primary = displayName.isNotEmpty ? displayName : (email.isNotEmpty ? email : name);
    final photoUrl = user?.photoURL ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final resolvedRole = isAdmin ? 'Admin' : 'Member';
        final roleText = role.isNotEmpty ? role : resolvedRole;

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
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(
                        primary.isNotEmpty ? primary[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  ),
                  Text(
                    roleText,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
