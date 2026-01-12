import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';

class TechnicalDebtManagementScreen extends StatefulWidget {
  const TechnicalDebtManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TechnicalDebtManagementScreen()),
    );
  }

  @override
  State<TechnicalDebtManagementScreen> createState() => _TechnicalDebtManagementScreenState();
}

class _TechnicalDebtManagementScreenState extends State<TechnicalDebtManagementScreen> {
  final Set<String> _selectedFilters = {'All'};
  ProjectDataProvider? _provider;
  bool _aiSeeded = false;
  bool _isGenerating = false;
  List<TechnicalDebtStatData> _stats = [];
  List<TechnicalDebtItemData> _debtItems = [];
  List<TechnicalDebtInsightData> _rootCauses = [];
  List<TechnicalDebtTrackData> _tracks = [];
  List<TechnicalDebtOwnerData> _owners = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ProjectDataHelper.getData(context);
      _loadTechnicalDebt(data.technicalDebtManagementData);
      final hasContent = _debtItems.isNotEmpty || _stats.isNotEmpty || _tracks.isNotEmpty || _rootCauses.isNotEmpty;
      if (!hasContent && !_aiSeeded) {
        _generateTechnicalDebt();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider ??= ProjectDataInherited.maybeOf(context);
  }

  void _loadTechnicalDebt(TechnicalDebtManagementData data) {
    _aiSeeded = data.aiSeeded;
    _stats = List<TechnicalDebtStatData>.from(data.stats);
    _debtItems = List<TechnicalDebtItemData>.from(data.items);
    _rootCauses = List<TechnicalDebtInsightData>.from(data.insights);
    _tracks = List<TechnicalDebtTrackData>.from(data.tracks);
    _owners = List<TechnicalDebtOwnerData>.from(data.owners);
  }

  TechnicalDebtManagementData _buildTechnicalDebt() {
    return TechnicalDebtManagementData(
      stats: _stats,
      items: _debtItems,
      insights: _rootCauses,
      tracks: _tracks,
      owners: _owners,
      aiSeeded: _aiSeeded,
    );
  }

  Future<void> _saveTechnicalDebt() async {
    final provider = _provider;
    if (provider == null) return;
    provider.updateField((data) => data.copyWith(technicalDebtManagementData: _buildTechnicalDebt()));
    await provider.saveToFirebase(checkpoint: 'technical_debt_management');
  }

  Future<void> _generateTechnicalDebt() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final data = ProjectDataHelper.getData(context);
      final contextText = ProjectDataHelper.buildExecutivePlanContext(data, sectionLabel: 'Technical Debt Management');
      final fallbackContext = ProjectDataHelper.buildFepContext(data, sectionLabel: 'Technical Debt Management');
      final ai = OpenAiServiceSecure();
      final generated = await ai.generateTechnicalDebtManagementFromContext(
        contextText.trim().isEmpty ? fallbackContext : contextText,
      );
      if (!mounted) return;
      setState(() {
        _aiSeeded = true;
        _stats = List<TechnicalDebtStatData>.from(generated.stats);
        _debtItems = List<TechnicalDebtItemData>.from(generated.items);
        _rootCauses = List<TechnicalDebtInsightData>.from(generated.insights);
        _tracks = List<TechnicalDebtTrackData>.from(generated.tracks);
        _owners = List<TechnicalDebtOwnerData>.from(generated.owners);
      });
      await _saveTechnicalDebt();
    } catch (e) {
      debugPrint('AI technical debt generation failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _showAddDebtDialog() async {
    final idController = TextEditingController();
    final titleController = TextEditingController();
    final areaController = TextEditingController();
    final ownerController = TextEditingController();
    final targetController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String severity = 'Medium';
    String status = 'Planned';

    final result = await showDialog<TechnicalDebtItemData>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text('Add Debt Item'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: idController,
                        decoration: const InputDecoration(labelText: 'ID'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter an ID' : null,
                      ),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Item'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter an item' : null,
                      ),
                      TextFormField(
                        controller: areaController,
                        decoration: const InputDecoration(labelText: 'Area'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter an area' : null,
                      ),
                      TextFormField(
                        controller: ownerController,
                        decoration: const InputDecoration(labelText: 'Owner'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter an owner' : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: severity,
                        decoration: const InputDecoration(labelText: 'Severity'),
                        items: const [
                          DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                          DropdownMenuItem(value: 'High', child: Text('High')),
                          DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'Low', child: Text('Low')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setInnerState(() => severity = value);
                          }
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'In progress', child: Text('In progress')),
                          DropdownMenuItem(value: 'Backlog', child: Text('Backlog')),
                          DropdownMenuItem(value: 'Planned', child: Text('Planned')),
                          DropdownMenuItem(value: 'In review', child: Text('In review')),
                          DropdownMenuItem(value: 'Blocked', child: Text('Blocked')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setInnerState(() => status = value);
                          }
                        },
                      ),
                      TextFormField(
                        controller: targetController,
                        decoration: const InputDecoration(labelText: 'Target'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a target' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogContext).pop(
                        TechnicalDebtItemData(
                          id: idController.text.trim(),
                          title: titleController.text.trim(),
                          area: areaController.text.trim(),
                          owner: ownerController.text.trim(),
                          severity: severity,
                          status: status,
                          target: targetController.text.trim(),
                        ),
                      );
                    }
                  },
                  child: const Text('Add Item'),
                ),
              ],
            );
          },
        );
      },
    );

    idController.dispose();
    titleController.dispose();
    areaController.dispose();
    ownerController.dispose();
    targetController.dispose();

    if (result != null) {
      setState(() => _debtItems.add(result));
      await _saveTechnicalDebt();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debt item "${result.id}" added'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
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
        _actionButton(Icons.add, 'Add debt item', onPressed: _showAddDebtDialog),
        _actionButton(Icons.tune, 'Prioritize backlog'),
        _actionButton(Icons.description_outlined, 'Generate report'),
        _primaryButton('Launch remediation sprint'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
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

  Widget _buildFilterChips() {
    const filters = ['All', 'Critical', 'High impact', 'Due this month', 'Blocked'];
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
                if (filter != 'All') {
                  _selectedFilters.remove('All');
                } else {
                  _selectedFilters.clear();
                }
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
    final stats = _stats;
    if (stats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'No debt metrics available yet.',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      );
    }

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

  Widget _buildStatCard(TechnicalDebtStatData data) {
    final color = _toneColor(data.tone);
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
          Text(data.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 6),
          Text(data.label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(data.supporting, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildDebtRegister() {
    final items = _filteredDebtItems();
    return _PanelShell(
      title: 'Debt register',
      subtitle: 'Track high-impact debt items and remediation targets',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Column(
                children: [
                  DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Area', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Severity', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                      DataColumn(label: Text('Target', style: TextStyle(fontWeight: FontWeight.w600))),
                    ],
                    rows: items.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item.id, style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9)))),
                        DataCell(Text(item.title, style: const TextStyle(fontSize: 13))),
                        DataCell(_chip(item.area)),
                        DataCell(Text(item.owner, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                        DataCell(_severityChip(item.severity)),
                        DataCell(_statusChip(item.status)),
                        DataCell(Text(item.target, style: const TextStyle(fontSize: 12))),
                      ]);
                    }).toList(),
                  ),
                  if (items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      alignment: Alignment.center,
                      child: const Text(
                        'No debt items available yet.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ),
                ],
              ),
            ),
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
        children: _tracks.isEmpty
            ? [
                const Text(
                  'No remediation tracks yet.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ]
            : _tracks.map((track) {
          final color = _toneColor(track.tone);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(track.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Text('${(track.progress * 100).round()}%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: track.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
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
        children: _rootCauses.isEmpty
            ? [
                const Text(
                  'No root cause insights yet.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ]
            : _rootCauses.map((item) {
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
                Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(item.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
      trailing: _chip(_nextReviewLabel()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _owners.isEmpty
            ? [
                const Text(
                  'No ownership coverage yet.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ]
            : _owners.map((item) {
                return _OwnerItem(item.name, item.count, item.note);
              }).toList(),
      ),
    );
  }

  Color _toneColor(String tone) {
    final t = tone.toLowerCase();
    if (t.contains('critical')) return const Color(0xFFEF4444);
    if (t.contains('warning')) return const Color(0xFFF97316);
    if (t.contains('success')) return const Color(0xFF10B981);
    if (t.contains('info')) return const Color(0xFF0EA5E9);
    return const Color(0xFF6366F1);
  }

  List<TechnicalDebtItemData> _filteredDebtItems() {
    final filters = _selectedFilters;
    if (filters.contains('All') || filters.isEmpty) return _debtItems;
    final monthLabel = _currentMonthLabel();
    return _debtItems.where((item) {
      bool include = false;
      if (filters.contains('Critical')) {
        include = include || item.severity.toLowerCase().contains('critical');
      }
      if (filters.contains('High impact')) {
        include = include ||
            item.severity.toLowerCase().contains('high') ||
            item.severity.toLowerCase().contains('critical');
      }
      if (filters.contains('Due this month')) {
        include = include || item.target.toLowerCase().contains(monthLabel.toLowerCase());
      }
      if (filters.contains('Blocked')) {
        include = include || item.status.toLowerCase().contains('blocked');
      }
      return include;
    }).toList();
  }

  String _currentMonthLabel() {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    return months[now.month - 1];
  }

  String _nextReviewLabel() {
    final next = _parseNextReviewDate();
    if (next == null) return 'Next review: TBD';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Next review: ${months[next.month - 1]} ${next.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseNextReviewDate() {
    if (_debtItems.isEmpty) return null;
    final now = DateTime.now();
    DateTime? candidate;
    for (final item in _debtItems) {
      final parsed = _parseMonthDay(item.target, year: now.year);
      if (parsed == null) continue;
      if (candidate == null || parsed.isBefore(candidate)) {
        candidate = parsed;
      }
    }
    return candidate;
  }

  DateTime? _parseMonthDay(String value, {required int year}) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return null;
    const months = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final month = months[parts[0].toLowerCase()];
    final day = int.tryParse(parts[1]);
    if (month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
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
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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

class _OwnerItem extends StatelessWidget {
  const _OwnerItem(this.name, this.count, this.note);

  final String name;
  final String count;
  final String note;

  @override
  Widget build(BuildContext context) {
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
            child: Text(name.substring(0, 1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(note, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(count, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
