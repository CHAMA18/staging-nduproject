import 'package:flutter/material.dart';
import 'package:ndu_project/screens/agile_development_iterations_screen.dart';
import 'package:ndu_project/screens/stakeholder_alignment_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/project_insights_service.dart';

class ScopeTrackingImplementationScreen extends StatefulWidget {
  const ScopeTrackingImplementationScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScopeTrackingImplementationScreen()),
    );
  }

  @override
  State<ScopeTrackingImplementationScreen> createState() => _ScopeTrackingImplementationScreenState();
}

class _ScopeTrackingImplementationScreenState extends State<ScopeTrackingImplementationScreen> {
  final Set<String> _selectedFilters = {'All scope'};

  static const List<String> _scopeStatusOptions = [
    'On track',
    'Variance',
    'At risk',
    'Pending',
  ];

  static const List<String> _changeStatusOptions = ['Pending', 'Approved', 'Rejected'];

  final List<_ScopeItem> _scopeItems = [
    _ScopeItem('SC-301', 'Core platform rollout', 'On track', '0%', 'Engineering', 'Oct 18'),
    _ScopeItem('SC-308', 'Reporting dashboards', 'Variance', '+6%', 'Analytics', 'Oct 22'),
    _ScopeItem('SC-315', 'Integration hub', 'At risk', '+3%', 'Platform', 'Oct 20'),
  ];

  final List<_VarianceSignal> _varianceSignals = [
    _VarianceSignal('Scope variance', '2 items exceed baseline by 5%.'),
    _VarianceSignal('Change request backlog', '3 items awaiting approval.'),
    _VarianceSignal('Dependency gap', 'Vendor milestone shifted by 2 weeks.'),
  ];

  final List<_ChangeItem> _changeItems = [
    _ChangeItem('CR-019', 'Add analytics export', 'In Review', 'Oct 18'),
    _ChangeItem('CR-021', 'Integrate vendor payment gateway', 'Approved', 'Oct 22'),
    _ChangeItem('CR-024', 'Extend onboarding flow', 'Submitted', 'Oct 20'),
  ];

  final List<_BaselineCheckpoint> _baselineItems = [
    _BaselineCheckpoint('Milestone review', 'Ready', true),
    _BaselineCheckpoint('Runbook refresh', 'In review', false),
    _BaselineCheckpoint('Disaster recovery drill', 'Pending', false),
  ];

  final Map<String, Color> _statColors = const {
    'Blue': Color(0xFF2563EB),
    'Green': Color(0xFF10B981),
    'Orange': Color(0xFFF59E0B),
    'Purple': Color(0xFF8B5CF6),
  };

  final List<_StatCardData> _stats = [
    _StatCardData('Scope items', '32', '4 critical', Color(0xFF2563EB)),
    _StatCardData('Variance', '2.4%', 'Within guardrails', Color(0xFF10B981)),
    _StatCardData('Change requests', '3', '1 pending', Color(0xFFF59E0B)),
    _StatCardData('Acceptance', '84%', 'Stakeholder aligned', Color(0xFF8B5CF6)),
  ];

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;

    if (projectId == null) {
      return ResponsiveScaffold(
        activeItemLabel: 'Scope Tracking Implementation',
        backgroundColor: const Color(0xFFF5F7FB),
        body: Center(
          child: Text(
            'Pick a project to load scope tracking metrics.',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
        ),
      );
    }

    return ResponsiveScaffold(
      activeItemLabel: 'Scope Tracking Implementation',
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isNarrow),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 20),
                _buildStatsHeader(),
                const SizedBox(height: 12),
                _buildStatsRow(isNarrow, projectId),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildScopeRegister(projectId),
                    const SizedBox(height: 20),
                    _buildVariancePanel(),
                    const SizedBox(height: 20),
                    _buildChangeLogPanel(),
                    const SizedBox(height: 20),
                    _buildBaselinePanel(),
                  ],
                ),
                const SizedBox(height: 24),
                LaunchPhaseNavigation(
                  backLabel: 'Back: Agile Development Iterations',
                  nextLabel: 'Next: Stakeholder Alignment',
                  onBack: () => AgileDevelopmentIterationsScreen.open(context),
                  onNext: () => StakeholderAlignmentScreen.open(context),
                ),
              ],
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'SCOPE CONTROL',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Scope Tracking Implementation',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Monitor scope delivery, variance, and change approvals during execution.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (!isNarrow) _buildHeaderActions(),
          ],
        ),
        if (isNarrow) ...[
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
        _actionButton(Icons.add, 'Add scope item', onPressed: () => _showScopeItemDialog()),
        _actionButton(Icons.add_chart, 'Add stat', onPressed: () => _showStatDialog()),
        _actionButton(Icons.sync_alt, 'Sync baseline'),
        _actionButton(Icons.description_outlined, 'Export log'),
        _primaryButton('Run scope review'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _primaryButton(String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.play_arrow, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _panelIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  Widget _cardIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = const Color(0xFF64748B),
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    );
  }

  Widget _buildStatsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Key stats', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        _panelIconButton(
          icon: Icons.add,
          tooltip: 'Add stat',
          onPressed: () => _showStatDialog(),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All scope', 'On track', 'Variance', 'At risk', 'Pending'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final selected = _selectedFilters.contains(filter);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedFilters.remove(filter);
              } else {
                _selectedFilters.add(filter);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              filter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow(bool isNarrow, String projectId) {
    return StreamBuilder<List<ScopeTrackingStat>>(
      stream: ProjectInsightsService.streamScopeStats(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final placeholders = List.generate(4, (_) => ScopeTrackingStat(label: '', value: '—', supporting: '', color: const Color(0xFFB1B5C3)));
          return _statsLayout(isNarrow, placeholders);
        }
        final stats = snapshot.data ?? [];
        if (stats.isEmpty) {
          return _emptyPanelMessage('Scope metrics are not available yet.');
        }
        return _statsLayout(isNarrow, stats);
      },
    );
  }

  Widget _statsLayout(bool isNarrow, List<ScopeTrackingStat> stats) {
    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _buildStatCard(stat)).toList(),
      );
    }
    return Row(
      children: stats.map((stat) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildStatCard(stat),
        ),
      )).toList(),
    );
  }

  Widget _emptyPanelMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF6B7280))),
    );
  }

  Widget _buildStatCard(ScopeTrackingStat data) {
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
            data.value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: data.color),
          ),
          const SizedBox(height: 6),
          Text(data.label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(data.supporting, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: data.color)),
        ],
      ),
    );
  }

  Widget _buildScopeRegister(String projectId) {
    return StreamBuilder<List<ScopeTrackingItem>>(
      stream: ProjectInsightsService.streamScopeItems(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return _emptyPanelMessage('No scope items recorded yet.');
        }
        final filtered = items.where((item) {
          if (_selectedFilters.contains('All scope')) return true;
          final normalized = item.status.trim();
          return _selectedFilters.contains(normalized);
        }).toList();
        if (filtered.isEmpty) {
          return _emptyPanelMessage('No scope items match the selected filters.');
        }
        return _PanelShell(
          title: 'Scope register',
          subtitle: 'Baseline delivery and variance tracking',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _panelIconButton(
                icon: Icons.add,
                tooltip: 'Add scope item',
                onPressed: () => _showScopeItemDialog(),
              ),
              const SizedBox(width: 6),
              _actionButton(Icons.filter_list, 'Filter'),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Scope item', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Variance', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Next review', style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                    rows: filtered.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item.id, style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9)))),
                        DataCell(Text(item.title, style: const TextStyle(fontSize: 13))),
                        DataCell(_statusChip(item.status)),
                        DataCell(Text(item.variance, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        DataCell(Text(item.owner, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                        DataCell(Text(item.nextReview, style: const TextStyle(fontSize: 12))),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVariancePanel() {
    return _PanelShell(
      title: 'Variance signals',
      subtitle: 'Scope drift and dependency impacts',
      trailing: _panelIconButton(
        icon: Icons.add,
        tooltip: 'Add variance signal',
        onPressed: () => _showVarianceDialog(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _varianceSignals.map((signal) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(signal.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(signal.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                _cardIconButton(
                  icon: Icons.edit,
                  tooltip: 'Edit variance signal',
                  onPressed: () => _showVarianceDialog(existing: signal),
                ),
                _cardIconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete variance signal',
                  onPressed: () => _confirmDelete(
                    label: 'variance signal "${signal.title}"',
                    onDelete: () => setState(() => _varianceSignals.remove(signal)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChangeLogPanel() {
    return _PanelShell(
      title: 'Change log',
      subtitle: 'Recent scope change requests',
      trailing: _panelIconButton(
        icon: Icons.add,
        tooltip: 'Add change request',
        onPressed: () => _showChangeDialog(),
      ),
      child: Column(
        children: _changeItems.map((change) {
          final color = change.status == 'Approved' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(change.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(change.date, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(change.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                ),
                const SizedBox(width: 8),
                _cardIconButton(
                  icon: Icons.edit,
                  tooltip: 'Edit change request',
                  onPressed: () => _showChangeDialog(existing: change),
                ),
                _cardIconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete change request',
                  onPressed: () => _confirmDelete(
                    label: 'change request "${change.id}"',
                    onDelete: () => setState(() => _changeItems.remove(change)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBaselinePanel() {
    return _PanelShell(
      title: 'Baseline alignment',
      subtitle: 'Scope checkpoints for sign-off',
      trailing: _panelIconButton(
        icon: Icons.add,
        tooltip: 'Add baseline checkpoint',
        onPressed: () => _showBaselineDialog(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _baselineItems.map((item) {
          return _BaselineItem(
            item.title,
            item.status,
            item.complete,
            onEdit: () => _showBaselineDialog(existing: item),
            onDelete: () => _confirmDelete(
              label: 'baseline checkpoint "${item.title}"',
              onDelete: () => setState(() => _baselineItems.remove(item)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusChip(String label) {
    Color color;
    switch (label) {
      case 'On track':
        color = const Color(0xFF10B981);
        break;
      case 'Variance':
        color = const Color(0xFFF59E0B);
        break;
      case 'At risk':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFF6366F1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Future<void> _confirmDelete({required String label, required VoidCallback onDelete}) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Delete $label? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onDelete();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showScopeItemDialog({_ScopeItem? existing}) async {
    final idController = TextEditingController(text: existing?.id ?? '');
    final titleController = TextEditingController(text: existing?.title ?? '');
    final varianceController = TextEditingController(text: existing?.variance ?? '');
    final ownerController = TextEditingController(text: existing?.owner ?? '');
    final reviewController = TextEditingController(text: existing?.reviewDate ?? '');
    var status = existing?.status ?? _scopeStatusOptions.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(existing == null ? 'Add scope item' : 'Edit scope item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: idController,
                    decoration: const InputDecoration(labelText: 'ID'),
                  ),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Scope item'),
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _scopeStatusOptions
                        .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => status = value);
                    },
                  ),
                  TextField(
                    controller: varianceController,
                    decoration: const InputDecoration(labelText: 'Variance'),
                  ),
                  TextField(
                    controller: ownerController,
                    decoration: const InputDecoration(labelText: 'Owner'),
                  ),
                  TextField(
                    controller: reviewController,
                    decoration: const InputDecoration(labelText: 'Next review'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final id = idController.text.trim();
                  final title = titleController.text.trim();
                  if (id.isEmpty || title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ID and Scope item are required.')),
                    );
                    return;
                  }
                  final updated = _ScopeItem(
                    id,
                    title,
                    status,
                    varianceController.text.trim(),
                    ownerController.text.trim(),
                    reviewController.text.trim(),
                  );
                  setState(() {
                    if (existing == null) {
                      _scopeItems.add(updated);
                    } else {
                      final index = _scopeItems.indexOf(existing);
                      if (index >= 0) {
                        _scopeItems[index] = updated;
                      }
                    }
                  });
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showVarianceDialog({_VarianceSignal? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final subtitleController = TextEditingController(text: existing?.subtitle ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add variance signal' : 'Edit variance signal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: subtitleController,
                decoration: const InputDecoration(labelText: 'Detail'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title is required.')),
                );
                return;
              }
              final updated = _VarianceSignal(title, subtitleController.text.trim());
              setState(() {
                if (existing == null) {
                  _varianceSignals.add(updated);
                } else {
                  final index = _varianceSignals.indexOf(existing);
                  if (index >= 0) {
                    _varianceSignals[index] = updated;
                  }
                }
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeDialog({_ChangeItem? existing}) async {
    final idController = TextEditingController(text: existing?.id ?? '');
    final titleController = TextEditingController(text: existing?.title ?? '');
    final dateController = TextEditingController(text: existing?.date ?? '');
    var status = existing?.status ?? _changeStatusOptions.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(existing == null ? 'Add change request' : 'Edit change request'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: idController,
                    decoration: const InputDecoration(labelText: 'ID'),
                  ),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: _changeStatusOptions
                        .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => status = value);
                    },
                  ),
                  TextField(
                    controller: dateController,
                    decoration: const InputDecoration(labelText: 'Date'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final id = idController.text.trim();
                  final title = titleController.text.trim();
                  if (id.isEmpty || title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ID and Title are required.')),
                    );
                    return;
                  }
                  final updated = _ChangeItem(
                    id,
                    title,
                    status,
                    dateController.text.trim(),
                  );
                  setState(() {
                    if (existing == null) {
                      _changeItems.add(updated);
                    } else {
                      final index = _changeItems.indexOf(existing);
                      if (index >= 0) {
                        _changeItems[index] = updated;
                      }
                    }
                  });
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showBaselineDialog({_BaselineCheckpoint? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final statusController = TextEditingController(text: existing?.status ?? '');
    var complete = existing?.complete ?? false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(existing == null ? 'Add baseline checkpoint' : 'Edit baseline checkpoint'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: statusController,
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Complete'),
                    value: complete,
                    onChanged: (value) => setDialogState(() => complete = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title is required.')),
                    );
                    return;
                  }
                  final updated = _BaselineCheckpoint(
                    title,
                    statusController.text.trim(),
                    complete,
                  );
                  setState(() {
                    if (existing == null) {
                      _baselineItems.add(updated);
                    } else {
                      final index = _baselineItems.indexOf(existing);
                      if (index >= 0) {
                        _baselineItems[index] = updated;
                      }
                    }
                  });
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStatDialog({_StatCardData? existing}) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final valueController = TextEditingController(text: existing?.value ?? '');
    final supportingController = TextEditingController(text: existing?.supporting ?? '');
    var selectedColorName = _statColors.entries.firstWhere(
      (entry) => entry.value == existing?.color,
      orElse: () => _statColors.entries.first,
    ).key;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(existing == null ? 'Add stat' : 'Edit stat'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(labelText: 'Label'),
                  ),
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(labelText: 'Value'),
                  ),
                  TextField(
                    controller: supportingController,
                    decoration: const InputDecoration(labelText: 'Supporting text'),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedColorName,
                    decoration: const InputDecoration(labelText: 'Accent color'),
                    items: _statColors.keys
                        .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedColorName = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final label = labelController.text.trim();
                  final value = valueController.text.trim();
                  if (label.isEmpty || value.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Label and Value are required.')),
                    );
                    return;
                  }
                  final updated = _StatCardData(
                    label,
                    value,
                    supportingController.text.trim(),
                    _statColors[selectedColorName] ?? const Color(0xFF64748B),
                  );
                  setState(() {
                    if (existing == null) {
                      _stats.add(updated);
                    } else {
                      final index = _stats.indexOf(existing);
                      if (index >= 0) {
                        _stats[index] = updated;
                      }
                    }
                  });
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
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
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BaselineItem extends StatelessWidget {
  const _BaselineItem(
    this.title,
    this.status,
    this.complete, {
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String status;
  final bool complete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = complete ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(complete ? Icons.check_circle : Icons.schedule, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(status, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit baseline checkpoint',
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 16, color: Color(0xFF64748B)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete baseline checkpoint',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF64748B)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
        ],
      ),
    );
  }
}

class _ScopeItem {
  const _ScopeItem(this.id, this.title, this.status, this.variance, this.owner, this.reviewDate);

  final String id;
  final String title;
  final String status;
  final String variance;
  final String owner;
  final String reviewDate;
}

class _VarianceSignal {
  const _VarianceSignal(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

class _ChangeItem {
  const _ChangeItem(this.id, this.title, this.status, this.date);

  final String id;
  final String title;
  final String status;
  final String date;
}

class _BaselineCheckpoint {
  const _BaselineCheckpoint(this.title, this.status, this.complete);

  final String title;
  final String status;
  final bool complete;
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
