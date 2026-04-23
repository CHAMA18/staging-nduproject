import 'package:flutter/material.dart';
import 'package:ndu_project/screens/identify_staff_ops_team_screen.dart';
import 'package:ndu_project/screens/punchlist_actions_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/execution_phase_ai_seed.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';

class TechnicalDebtManagementScreen extends StatefulWidget {
  const TechnicalDebtManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TechnicalDebtManagementScreen()),
    );
  }

  @override
  State<TechnicalDebtManagementScreen> createState() =>
      _TechnicalDebtManagementScreenState();
}

class _TechnicalDebtManagementScreenState
    extends State<TechnicalDebtManagementScreen> {
  final Set<String> _selectedFilters = {'All'};

  // Local copies updated from provider
  List<DebtItem> _debtItems = [];
  List<DebtInsight> _rootCauses = [];
  List<RemediationTrack> _tracks = [];
  List<OwnerItem> _owners = [];

  final _ai = OpenAiServiceSecure();
  bool _autoGenerationTriggered = false;
  bool _isAutoGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPopulateIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ProjectDataHelper.getData(context).frontEndPlanning;
    // sync local view lists from persisted project data
    _debtItems = data.technicalDebtItems;
    _rootCauses = data.technicalDebtRootCauses;
    _tracks = data.technicalDebtTracks;
    _owners = data.technicalDebtOwners;
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Technical Debt Management',
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
                _buildStatsRow(isNarrow),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDebtRegister(),
                    const SizedBox(height: 20),
                    _buildRemediationPanel(),
                    const SizedBox(height: 20),
                    _buildRootCausePanel(),
                    const SizedBox(height: 20),
                    _buildOwnershipPanel(),
                    const SizedBox(height: 24),
                    LaunchPhaseNavigation(
                      backLabel: 'Back: Punchlist Actions',
                      nextLabel: 'Next: Identify & Staff Ops Team',
                      onBack: () => PunchlistActionsScreen.open(context),
                      onNext: () => IdentifyStaffOpsTeamScreen.open(context),
                    ),
                  ],
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
            'EXECUTION HEALTH',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Technical Debt Management',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Track residual debt, prioritize remediation, and align owners before project close-out.',
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
        _actionButton(Icons.add, 'Add debt item',
            onPressed: _showAddDebtItemDialog),
        _actionButton(Icons.tune, 'Prioritize backlog', onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Use severity, status, and target fields to prioritize the backlog.')),
          );
        }),
        _actionButton(Icons.description_outlined, 'Generate report',
            onPressed: _showDebtSnapshotReport),
        _primaryButton('Launch remediation sprint'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      label: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _primaryButton(String label) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Remediation sprint launched. Keep debt status and targets updated to track closure velocity.'),
          ),
        );
      },
      icon: const Icon(Icons.play_arrow, size: 18),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = [
      'All',
      'Critical',
      'High impact',
      'Due this month',
      'Blocked'
    ];
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

  Widget _buildStatsRow(bool isNarrow) {
    final stats = [
      _StatCardData(
          'Open debt items', '18', '6 critical', const Color(0xFFEF4444)),
      _StatCardData(
          'In remediation', '7', '2 sprint owners', const Color(0xFF0EA5E9)),
      _StatCardData(
          'Monthly burn-down', '14%', 'Goal 20%', const Color(0xFF10B981)),
      _StatCardData('Owner coverage', '92%', '2 gaps', const Color(0xFF6366F1)),
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
          Text(data.value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: data.color)),
          const SizedBox(height: 6),
          Text(data.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(data.supporting,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: data.color)),
        ],
      ),
    );
  }

  Widget _buildDebtRegister() {
    return _PanelShell(
      title: 'Debt register',
      subtitle: 'Track high-impact debt items and remediation targets',
      trailing: Row(children: [
        _actionButton(Icons.filter_list, 'Filter', onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Use the chips above to filter the register.')),
          );
        }),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () async {
            try {
              final ctx = ProjectDataHelper.buildExecutivePlanContext(
                ProjectDataHelper.getData(context),
                sectionLabel: 'Technical Debt Management',
              );
              final text = await _ai.generateFepSectionText(
                section: 'Technical Debt',
                context: ctx,
                maxTokens: 700,
              );
              if (!mounted) return;
              final lines = text
                  .split(RegExp(r'[\n\r]+'))
                  .map((s) => s.replaceAll('*', '').trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              if (lines.isEmpty) return;

              final now = DateTime.now().millisecondsSinceEpoch;
              final newItems =
                  lines.take(6).toList().asMap().entries.map((entry) {
                final line = entry.value;
                return DebtItem(
                  id: 'TD-${now + entry.key}',
                  title: line,
                  area: 'Architecture',
                  owner: '',
                  severity: 'Medium',
                  status: 'Backlog',
                  target: '',
                );
              }).toList();

              await _upsertDebtItems([..._debtItems, ...newItems]);
              if (!mounted) return;
              setState(() => _debtItems = [..._debtItems, ...newItems]);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Added ${newItems.length} AI debt items.')),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('AI auto-populate failed: $e')),
              );
            }
          },
          icon: const Icon(Icons.auto_fix_high, size: 16),
          label: const Text('Auto-populate (AI)'),
        ),
      ]),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final isNarrow = availableWidth < 800;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Container(
                padding: EdgeInsets.all(isNarrow ? 10 : 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    _TableHeaderCell('ID', flex: isNarrow ? 0.6 : 0.5),
                    _TableHeaderCell('Item', flex: 2.0),
                    _TableHeaderCell('Area', flex: 1.0),
                    _TableHeaderCell('Owner', flex: 1.2),
                    _TableHeaderCell('Severity', flex: 1.0),
                    _TableHeaderCell('Status', flex: 1.1),
                    _TableHeaderCell('Target', flex: 1.0),
                    _TableHeaderCell('Actions', flex: 0.8),
                  ],
                ),
              ),
              // Data rows
              if (_debtItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  child: const Text(
                    'No debt items yet. Use + Add debt item to get started.',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ..._debtItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Container(
                    padding: EdgeInsets.all(isNarrow ? 10 : 12),
                    decoration: BoxDecoration(
                      color: index % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        _TableCell(item.id,
                            flex: isNarrow ? 0.6 : 0.5,
                            textStyle: const TextStyle(
                                fontSize: 12, color: Color(0xFF0EA5E9))),
                        _TableCell(item.title,
                            flex: 2.0,
                            textStyle: const TextStyle(fontSize: 13)),
                        _TableCell(item.area,
                            flex: 1.0, isChip: true),
                        _TableCell(item.owner,
                            flex: 1.2,
                            textStyle: const TextStyle(
                                fontSize: 13, color: Color(0xFF64748B))),
                        _TableCell(item.severity,
                            flex: 1.0,
                            isSeverityChip: true),
                        _TableCell(item.status,
                            flex: 1.1, isStatusChip: true),
                        _TableCell(item.target,
                            flex: 1.0,
                            textStyle: const TextStyle(fontSize: 12)),
                        _ActionsCell(
                          flex: 0.8,
                          onEdit: () => _showEditDebtItemDialog(item),
                          onDelete: () => _deleteDebtItem(item),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRemediationPanel() {
    return _PanelShell(
      title: 'Remediation runway',
      subtitle: 'Progress by priority lane',
      trailing: _chip('Weekly cadence'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _tracks.map((track) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(track.label,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600))),
                    Text('${(track.progress * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: track.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(track.colorValue)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRootCausePanel() {
    return _PanelShell(
      title: 'Root cause signals',
      subtitle: 'Clustered themes driving technical debt',
      child: Column(
        children: _rootCauses.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(item.subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOwnershipPanel() {
    return _PanelShell(
      title: 'Ownership coverage',
      subtitle: 'Confirm accountable owners and next review',
      trailing: _chip('Next review: Oct 14'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            _owners.map((o) => _OwnerItem(o.name, o.count, o.note)).toList(),
      ),
    );
  }

  Future<void> _autoPopulateIfNeeded() async {
    if (_autoGenerationTriggered || _isAutoGenerating) return;
    _autoGenerationTriggered = true;
    final fep = ProjectDataHelper.getData(context).frontEndPlanning;
    if (fep.technicalDebtItems.isNotEmpty ||
        fep.technicalDebtRootCauses.isNotEmpty ||
        fep.technicalDebtTracks.isNotEmpty ||
        fep.technicalDebtOwners.isNotEmpty) {
      return;
    }

    setState(() => _isAutoGenerating = true);
    Map<String, List<LaunchEntry>> generated = {};
    try {
      generated = await ExecutionPhaseAiSeed.generateEntries(
        context: context,
        section: 'Technical Debt Management',
        sections: const {
          'debt_items': 'Technical debt items with owner, severity, status',
          'root_causes': 'Root cause themes driving technical debt',
          'remediation_tracks': 'Remediation tracks with progress',
          'owners': 'Owner coverage and next review notes',
        },
        itemsPerSection: 4,
      );
    } catch (error) {
      debugPrint('Technical debt AI call failed: $error');
    }

    if (!mounted) return;
    final debtItems = _mapDebtItems(generated['debt_items']);
    final rootCauses = _mapRootCauses(generated['root_causes']);
    final tracks = _mapRemediationTracks(generated['remediation_tracks']);
    final owners = _mapOwners(generated['owners']);

    await _upsertTechnicalDebtData(
      items: debtItems.isNotEmpty ? debtItems : _debtItems,
      rootCauses: rootCauses.isNotEmpty ? rootCauses : _rootCauses,
      tracks: tracks.isNotEmpty ? tracks : _tracks,
      owners: owners.isNotEmpty ? owners : _owners,
    );

    if (!mounted) return;
    setState(() {
      if (debtItems.isNotEmpty) _debtItems = debtItems;
      if (rootCauses.isNotEmpty) _rootCauses = rootCauses;
      if (tracks.isNotEmpty) _tracks = tracks;
      if (owners.isNotEmpty) _owners = owners;
      _isAutoGenerating = false;
    });
  }

  String _extractField(String text, String key) {
    final match = RegExp('$key\\s*[:=-]\\s*([^|;\\n]+)',
            caseSensitive: false)
        .firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  double _parsePercent(String text) {
    final match = RegExp(r'(\\d{1,3})').firstMatch(text);
    final value = match != null ? int.tryParse(match.group(1) ?? '') : null;
    if (value == null) return 0.4;
    return (value.clamp(10, 95) / 100);
  }

  List<DebtItem> _mapDebtItems(List<LaunchEntry>? entries) {
    if (entries == null) return [];
    return entries
        .map((entry) {
          final details = entry.details;
          final owner = _extractField(details, 'Owner');
          final area = _extractField(details, 'Area');
          final severity = _extractField(details, 'Severity');
          final status = entry.status?.trim().isNotEmpty == true
              ? entry.status!.trim()
              : _extractField(details, 'Status');
          final target = _extractField(details, 'Target');
          return DebtItem(
            id: 'TD-${DateTime.now().millisecondsSinceEpoch}',
            title: entry.title.trim(),
            area: area.isNotEmpty ? area : 'Architecture',
            owner: owner,
            severity: severity.isNotEmpty ? severity : 'Medium',
            status: status.isNotEmpty ? status : 'Backlog',
            target: target,
          );
        })
        .where((item) => item.title.isNotEmpty)
        .toList();
  }

  List<DebtInsight> _mapRootCauses(List<LaunchEntry>? entries) {
    if (entries == null) return [];
    return entries
        .map((entry) => DebtInsight(
              title: entry.title.trim(),
              subtitle: entry.details.trim().isNotEmpty
                  ? entry.details.trim()
                  : 'Capture mitigation actions.',
            ))
        .where((item) => item.title.isNotEmpty)
        .toList();
  }

  List<RemediationTrack> _mapRemediationTracks(List<LaunchEntry>? entries) {
    if (entries == null) return [];
    return entries
        .map((entry) => RemediationTrack(
              label: entry.title.trim(),
              progress: _parsePercent('${entry.details} ${entry.status ?? ''}'),
              colorValue: const Color(0xFF0EA5E9).value,
            ))
        .where((item) => item.label.isNotEmpty)
        .toList();
  }

  List<OwnerItem> _mapOwners(List<LaunchEntry>? entries) {
    if (entries == null) return [];
    return entries
        .map((entry) {
          final count = _extractField(entry.details, 'Count');
          return OwnerItem(
            name: entry.title.trim(),
            count: count.isNotEmpty ? count : '1',
            note: entry.details.trim(),
          );
        })
        .where((item) => item.name.isNotEmpty)
        .toList();
  }

  void _showDebtSnapshotReport() {
    final critical =
        _debtItems.where((item) => item.severity == 'Critical').length;
    final inProgress =
        _debtItems.where((item) => item.status == 'In progress').length;
    final backlog = _debtItems.where((item) => item.status == 'Backlog').length;
    final resolved = _debtItems.where((item) => item.status == 'Done').length;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Technical Debt Snapshot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total items: ${_debtItems.length}'),
            Text('Critical: $critical'),
            Text('In progress: $inProgress'),
            Text('Backlog: $backlog'),
            Text('Resolved: $resolved'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddDebtItemDialog() {
    _showDebtItemDialog();
  }

  void _showEditDebtItemDialog(DebtItem item) {
    _showDebtItemDialog(existing: item);
  }

  void _showDebtItemDialog({DebtItem? existing}) {
    final isEdit = existing != null;
    final idController = TextEditingController(
      text: existing?.id ?? 'TD-${DateTime.now().millisecondsSinceEpoch}',
    );
    final titleController = TextEditingController(text: existing?.title ?? '');
    final areaController = TextEditingController(text: existing?.area ?? '');
    final ownerController = TextEditingController(text: existing?.owner ?? '');
    final targetController =
        TextEditingController(text: existing?.target ?? '');
    var selectedSeverity = (existing?.severity ?? 'Medium').trim();
    var selectedStatus = (existing?.status ?? 'Backlog').trim();

    if (!['Critical', 'High', 'Medium', 'Low'].contains(selectedSeverity)) {
      selectedSeverity = 'Medium';
    }
    if (!['Backlog', 'In progress', 'Blocked', 'Done']
        .contains(selectedStatus)) {
      selectedStatus = 'Backlog';
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit debt item' : 'Add debt item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'ID *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Item *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: areaController,
                  decoration: const InputDecoration(labelText: 'Area'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ownerController,
                  decoration: const InputDecoration(labelText: 'Owner'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSeverity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: const ['Critical', 'High', 'Medium', 'Low']
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedSeverity = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const ['Backlog', 'In progress', 'Blocked', 'Done']
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(labelText: 'Target / Due'),
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
              onPressed: () async {
                final id = idController.text.trim();
                final title = titleController.text.trim();
                if (id.isEmpty || title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ID and Item are required.')),
                  );
                  return;
                }

                final updatedItem = DebtItem(
                  id: id,
                  title: title,
                  area: areaController.text.trim(),
                  owner: ownerController.text.trim(),
                  severity: selectedSeverity,
                  status: selectedStatus,
                  target: targetController.text.trim(),
                );

                final updatedList = [..._debtItems];
                final existingIndex = updatedList
                    .indexWhere((element) => element.id == updatedItem.id);
                if (existingIndex >= 0) {
                  updatedList[existingIndex] = updatedItem;
                } else {
                  updatedList.add(updatedItem);
                }

                await _upsertDebtItems(updatedList);
                if (!mounted || !dialogContext.mounted) return;
                setState(() => _debtItems = updatedList);
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          isEdit ? 'Debt item updated.' : 'Debt item added.')),
                );
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDebtItem(DebtItem item) async {
    final updated = [..._debtItems]
      ..removeWhere((element) => element.id == item.id);
    await _upsertDebtItems(updated);
    if (!mounted) return;
    setState(() => _debtItems = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed debt item ${item.id}.')),
    );
  }

  Future<void> _upsertDebtItems(List<DebtItem> items) async {
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'technical_debt_management',
      showSnackbar: false,
      dataUpdater: (current) {
        final updatedFep = ProjectDataHelper.updateFEPField(
          current: current.frontEndPlanning,
          technicalDebtItems: items,
        );
        return current.copyWith(frontEndPlanning: updatedFep);
      },
    );
  }

  Future<void> _upsertTechnicalDebtData({
    required List<DebtItem> items,
    required List<DebtInsight> rootCauses,
    required List<RemediationTrack> tracks,
    required List<OwnerItem> owners,
  }) async {
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'technical_debt_management',
      showSnackbar: false,
      dataUpdater: (current) {
        final updatedFep = ProjectDataHelper.updateFEPField(
          current: current.frontEndPlanning,
          technicalDebtItems: items,
          technicalDebtRootCauses: rootCauses,
          technicalDebtTracks: tracks,
          technicalDebtOwners: owners,
        );
        return current.copyWith(frontEndPlanning: updatedFep);
      },
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569))),
    );
  }

  Widget _severityChip(String label) {
    Color color;
    switch (label) {
      case 'Critical':
        color = const Color(0xFFEF4444);
        break;
      case 'High':
        color = const Color(0xFFF97316);
        break;
      case 'Medium':
        color = const Color(0xFF6366F1);
        break;
      default:
        color = const Color(0xFF94A3B8);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _statusChip(String label) {
    final color = label == 'In progress'
        ? const Color(0xFF0EA5E9)
        : label == 'Backlog'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6366F1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _TableHeaderCell(String text, {required double flex}) {
    return Expanded(
      flex: (flex * 10).round(),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _TableCell(
    String text, {
    required double flex,
    TextStyle? textStyle,
    bool isChip = false,
    bool isSeverityChip = false,
    bool isStatusChip = false,
  }) {
    Widget? child;
    if (isChip) {
      child = _chip(text);
    } else if (isSeverityChip) {
      child = _severityChip(text);
    } else if (isStatusChip) {
      child = _statusChip(text);
    } else {
      child = Text(
        text,
        style: textStyle ?? const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      );
    }
    return Expanded(
      flex: (flex * 10).round(),
      child: child,
    );
  }

  Widget _ActionsCell({
    required double flex,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Expanded(
      flex: (flex * 10).round(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            color: const Color(0xFF64748B),
            tooltip: 'Edit',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 16),
            color: const Color(0xFFEF4444),
            tooltip: 'Delete',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
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

class _OwnerItem extends StatelessWidget {
  const _OwnerItem(this.name, this.count, this.note);

  final String name;
  final String count;
  final String note;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
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
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
            child: Text(initial,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0EA5E9))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(note,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(count,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
// Legacy private data classes removed; using persisted models from project_data_model.dart

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
