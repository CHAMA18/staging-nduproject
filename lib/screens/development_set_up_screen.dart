import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class DevelopmentSetUpScreen extends StatefulWidget {
  const DevelopmentSetUpScreen({super.key});

  @override
  State<DevelopmentSetUpScreen> createState() => _DevelopmentSetUpScreenState();
}

class _DevelopmentSetUpScreenState extends State<DevelopmentSetUpScreen> {
  final TextEditingController _envSummaryController = TextEditingController();
  final TextEditingController _buildSummaryController = TextEditingController();
  final TextEditingController _toolingSummaryController = TextEditingController();

  final List<_SetupChecklistItem> _envChecklist = [];
  final List<_SetupChecklistItem> _buildChecklist = [];
  final List<_SetupChecklistItem> _toolingChecklist = [];

  final _Debouncer _saveDebounce = _Debouncer();

  bool _isLoading = false;
  bool _suspendSave = false;

  String _envStatus = 'Not started';
  String _buildStatus = 'Not started';
  String _toolingStatus = 'Not started';

  final List<String> _sectionStatusOptions = const ['Not started', 'In progress', 'At risk', 'Ready'];
  final List<String> _itemStatusOptions = const ['Not started', 'In progress', 'Blocked', 'Done'];

  @override
  void initState() {
    super.initState();
    _envSummaryController.addListener(_scheduleSave);
    _buildSummaryController.addListener(_scheduleSave);
    _toolingSummaryController.addListener(_scheduleSave);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final projectId = provider?.projectData.projectId;
      if (projectId != null && projectId.isNotEmpty) {
        await ProjectNavigationService.instance.saveLastPage(projectId, 'development-set-up');
      }
      await _loadFromFirestore();
    });
  }

  @override
  void dispose() {
    _envSummaryController.dispose();
    _buildSummaryController.dispose();
    _toolingSummaryController.dispose();
    _saveDebounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Development Set Up',
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Design Phase',
            showImportButton: false,
            showContentButton: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                  if (_isLoading) const SizedBox(height: 16),
                  _buildHeader(isMobile),
                  const SizedBox(height: 28),
                  _buildSetupSection(
                    icon: Icons.storage_outlined,
                    title: 'Environments & Access',
                    subtitle: 'Confirm where the system runs and who can access what.',
                    helperText: 'Document environments, access provisioning, and seed data readiness.',
                    status: _envStatus,
                    onStatusChanged: (value) {
                      setState(() => _envStatus = value);
                      _scheduleSave();
                    },
                    summaryController: _envSummaryController,
                    items: _envChecklist,
                    onAddItem: _addEnvChecklistItem,
                    onUpdateItem: _updateEnvChecklistItem,
                    onDeleteItem: _deleteEnvChecklistItem,
                  ),
                  const SizedBox(height: 20),
                  _buildSetupSection(
                    icon: Icons.alt_route_outlined,
                    title: 'Build & Deployment Flow',
                    subtitle: 'Show how code moves safely to an environment.',
                    helperText: 'Capture CI/CD steps, gating checks, and promotion approvals.',
                    status: _buildStatus,
                    onStatusChanged: (value) {
                      setState(() => _buildStatus = value);
                      _scheduleSave();
                    },
                    summaryController: _buildSummaryController,
                    items: _buildChecklist,
                    onAddItem: _addBuildChecklistItem,
                    onUpdateItem: _updateBuildChecklistItem,
                    onDeleteItem: _deleteBuildChecklistItem,
                  ),
                  const SizedBox(height: 20),
                  _buildSetupSection(
                    icon: Icons.construction_outlined,
                    title: 'Tooling & Ownership',
                    subtitle: 'Avoid confusion about tools and responsibility.',
                    helperText: 'List tools, owners, onboarding steps, and support contacts.',
                    status: _toolingStatus,
                    onStatusChanged: (value) {
                      setState(() => _toolingStatus = value);
                      _scheduleSave();
                    },
                    summaryController: _toolingSummaryController,
                    items: _toolingChecklist,
                    onAddItem: _addToolingChecklistItem,
                    onUpdateItem: _updateToolingChecklistItem,
                    onDeleteItem: _deleteToolingChecklistItem,
                  ),
                  const SizedBox(height: 32),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: Technical alignment',
                    nextLabel: 'Next: Development set up',
                    onBack: () => Navigator.of(context).maybePop(),
                    onNext: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _projectId() => ProjectDataHelper.getData(context).projectId;

  Future<void> _loadFromFirestore() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('design_phase_sections')
          .doc('development_set_up')
          .get();
      final data = doc.data() ?? {};
      final env = Map<String, dynamic>.from(data['environmentsAccess'] ?? {});
      final build = Map<String, dynamic>.from(data['buildDeployment'] ?? {});
      final tooling = Map<String, dynamic>.from(data['toolingOwnership'] ?? {});

      _suspendSave = true;
      _envSummaryController.text = env['summary']?.toString() ?? '';
      _buildSummaryController.text = build['summary']?.toString() ?? '';
      _toolingSummaryController.text = tooling['summary']?.toString() ?? '';
      _envStatus = _normalizeStatus(env['status']?.toString());
      _buildStatus = _normalizeStatus(build['status']?.toString());
      _toolingStatus = _normalizeStatus(tooling['status']?.toString());
      _suspendSave = false;

      final envItems = _SetupChecklistItem.fromList(env['checklist']);
      final buildItems = _SetupChecklistItem.fromList(build['checklist']);
      final toolingItems = _SetupChecklistItem.fromList(tooling['checklist']);

      if (!mounted) return;
      setState(() {
        _envChecklist
          ..clear()
          ..addAll(envItems);
        _buildChecklist
          ..clear()
          ..addAll(buildItems);
        _toolingChecklist
          ..clear()
          ..addAll(toolingItems);
      });
    } catch (error) {
      debugPrint('Failed to load development set up data: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scheduleSave() {
    if (_suspendSave) return;
    _saveDebounce.run(_saveToFirestore);
  }

  Future<void> _saveToFirestore() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    final payload = {
      'environmentsAccess': {
        'summary': _envSummaryController.text.trim(),
        'status': _envStatus,
        'checklist': _envChecklist.map((item) => item.toJson()).toList(),
      },
      'buildDeployment': {
        'summary': _buildSummaryController.text.trim(),
        'status': _buildStatus,
        'checklist': _buildChecklist.map((item) => item.toJson()).toList(),
      },
      'toolingOwnership': {
        'summary': _toolingSummaryController.text.trim(),
        'status': _toolingStatus,
        'checklist': _toolingChecklist.map((item) => item.toJson()).toList(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('design_phase_sections')
        .doc('development_set_up')
        .set(payload, SetOptions(merge: true));
  }

  String _normalizeStatus(String? raw) {
    if (raw == null || raw.isEmpty) return _sectionStatusOptions.first;
    final match = _sectionStatusOptions.firstWhere(
      (option) => option.toLowerCase() == raw.toLowerCase(),
      orElse: () => _sectionStatusOptions.first,
    );
    return match;
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Development Set Up',
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            _buildTag(
              label: 'Readiness checkpoint',
              background: AppSemanticColors.warningSurface,
              foreground: const Color(0xFFB45309),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Prepare environments, access, and workflows so development can start without blockers. Document only what is required for day-one readiness.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildTag({required String label, required Color background, required Color foreground}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }

  void _addEnvChecklistItem() {
    setState(() => _envChecklist.add(_SetupChecklistItem.empty()));
    _scheduleSave();
  }

  void _updateEnvChecklistItem(_SetupChecklistItem updated) {
    final index = _envChecklist.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _envChecklist[index] = updated);
    _scheduleSave();
  }

  void _deleteEnvChecklistItem(String id) {
    setState(() => _envChecklist.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addBuildChecklistItem() {
    setState(() => _buildChecklist.add(_SetupChecklistItem.empty()));
    _scheduleSave();
  }

  void _updateBuildChecklistItem(_SetupChecklistItem updated) {
    final index = _buildChecklist.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _buildChecklist[index] = updated);
    _scheduleSave();
  }

  void _deleteBuildChecklistItem(String id) {
    setState(() => _buildChecklist.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addToolingChecklistItem() {
    setState(() => _toolingChecklist.add(_SetupChecklistItem.empty()));
    _scheduleSave();
  }

  void _updateToolingChecklistItem(_SetupChecklistItem updated) {
    final index = _toolingChecklist.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _toolingChecklist[index] = updated);
    _scheduleSave();
  }

  void _deleteToolingChecklistItem(String id) {
    setState(() => _toolingChecklist.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  Widget _buildSetupSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required String helperText,
    required String status,
    required ValueChanged<String> onStatusChanged,
    required TextEditingController summaryController,
    required List<_SetupChecklistItem> items,
    required VoidCallback onAddItem,
    required ValueChanged<_SetupChecklistItem> onUpdateItem,
    required ValueChanged<String> onDeleteItem,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF111827), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              _buildStatusDropdown(status, onStatusChanged),
            ],
          ),
          const SizedBox(height: 16),
          _LabeledTextArea(
            label: 'Readiness notes',
            controller: summaryController,
            hintText: helperText,
          ),
          const SizedBox(height: 16),
          _buildChecklistTable(
            items: items,
            onAddItem: onAddItem,
            onUpdateItem: onUpdateItem,
            onDeleteItem: onDeleteItem,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(String status, ValueChanged<String> onChanged) {
    final color = _statusColor(status);
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String>(
        initialValue: status,
        items: _sectionStatusOptions
            .map((option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        decoration: InputDecoration(
          labelText: 'Status',
          labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          filled: true,
          fillColor: color.withValues(alpha: 0.12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
        return AppSemanticColors.success;
      case 'in progress':
        return const Color(0xFFF59E0B);
      case 'at risk':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Widget _buildChecklistTable({
    required List<_SetupChecklistItem> items,
    required VoidCallback onAddItem,
    required ValueChanged<_SetupChecklistItem> onUpdateItem,
    required ValueChanged<String> onDeleteItem,
  }) {
    final columns = [
      const _TableColumnDef('Checklist item', 240),
      const _TableColumnDef('Owner', 160),
      const _TableColumnDef('Target date', 140),
      const _TableColumnDef('Status', 160),
      const _TableColumnDef('Notes', 220),
      const _TableColumnDef('', 60),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Readiness checklist', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add item'),
              style: TextButton.styleFrom(
                foregroundColor: LightModeColors.accent,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const _InlineEmptyState(
            title: 'No checklist items yet',
            message: 'Add readiness checkpoints and owners.',
          )
        else
          _EditableTable(
            columns: columns,
            rows: [
              for (final item in items)
                _EditableRow(
                  key: ValueKey(item.id),
                  columns: columns,
                  cells: [
                    _TextCell(
                      value: item.title,
                      fieldKey: '${item.id}_title',
                      hintText: 'Checklist item',
                      onChanged: (value) => onUpdateItem(item.copyWith(title: value)),
                    ),
                    _TextCell(
                      value: item.owner,
                      fieldKey: '${item.id}_owner',
                      hintText: 'Owner',
                      onChanged: (value) => onUpdateItem(item.copyWith(owner: value)),
                    ),
                    _DateCell(
                      value: item.targetDate,
                      fieldKey: '${item.id}_date',
                      hintText: 'YYYY-MM-DD',
                      onChanged: (value) => onUpdateItem(item.copyWith(targetDate: value)),
                    ),
                    _DropdownCell(
                      value: item.status,
                      fieldKey: '${item.id}_status',
                      options: _itemStatusOptions,
                      onChanged: (value) => onUpdateItem(item.copyWith(status: value)),
                    ),
                    _TextCell(
                      value: item.notes,
                      fieldKey: '${item.id}_notes',
                      hintText: 'Notes',
                      onChanged: (value) => onUpdateItem(item.copyWith(notes: value)),
                    ),
                    _DeleteCell(
                      onPressed: () async {
                        final confirmed = await _confirmDelete('checklist item');
                        if (confirmed) onDeleteItem(item.id);
                      },
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  Future<bool> _confirmDelete(String label) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Are you sure you want to delete this $label?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _LabeledTextArea extends StatelessWidget {
  const _LabeledTextArea({
    required this.label,
    required this.controller,
    required this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
        ),
      ],
    );
  }
}

class _EditableTable extends StatelessWidget {
  const _EditableTable({required this.columns, required this.rows});

  final List<_TableColumnDef> columns;
  final List<_EditableRow> rows;

  @override
  Widget build(BuildContext context) {
    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: columns
            .map((column) => SizedBox(
                  width: column.width,
                  child: Text(
                    column.label.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.7, color: Color(0xFF6B7280)),
                  ),
                ))
            .toList(),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth =
            columns.fold<double>(0, (total, col) => total + col.width);
        final minWidth = constraints.maxWidth > totalWidth ? constraints.maxWidth : totalWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const SizedBox(height: 8),
                for (int i = 0; i < rows.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: i.isEven ? Colors.white : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: rows[i],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditableRow extends StatelessWidget {
  const _EditableRow({super.key, required this.columns, required this.cells});

  final List<_TableColumnDef> columns;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        cells.length,
        (index) => SizedBox(width: columns[index].width, child: cells[index]),
      ),
    );
  }
}

class _TableColumnDef {
  const _TableColumnDef(this.label, this.width);

  final String label;
  final double width;
}

class _TextCell extends StatelessWidget {
  const _TextCell({
    required this.value,
    required this.fieldKey,
    required this.onChanged,
    this.hintText,
  });

  final String value;
  final String fieldKey;
  final ValueChanged<String> onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(fieldKey),
      initialValue: value,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
      onChanged: onChanged,
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.value,
    required this.fieldKey,
    required this.onChanged,
    this.hintText,
  });

  final String value;
  final String fieldKey;
  final ValueChanged<String> onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final displayText = value.trim();
    final textStyle = TextStyle(
      fontSize: 12,
      color: displayText.isEmpty ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
    );

    return InkWell(
      key: ValueKey(fieldKey),
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final parsed = _tryParseDate(displayText);
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: parsed ?? DateTime(now.year, now.month, now.day),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked == null) return;
        final formatted = _formatDate(picked);
        onChanged(formatted);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        child: Text(
          displayText.isEmpty ? (hintText ?? '') : displayText,
          style: textStyle,
        ),
      ),
    );
  }

  DateTime? _tryParseDate(String raw) {
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }
}

class _DropdownCell extends StatelessWidget {
  const _DropdownCell({
    required this.value,
    required this.fieldKey,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final String fieldKey;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final resolved = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<String>(
      key: ValueKey(fieldKey),
      initialValue: resolved,
      items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
    );
  }
}

class _DeleteCell extends StatelessWidget {
  const _DeleteCell({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.info_outline, size: 18, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupChecklistItem {
  const _SetupChecklistItem({
    required this.id,
    required this.title,
    required this.owner,
    required this.targetDate,
    required this.status,
    required this.notes,
  });

  final String id;
  final String title;
  final String owner;
  final String targetDate;
  final String status;
  final String notes;

  factory _SetupChecklistItem.empty() {
    return _SetupChecklistItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '',
      owner: '',
      targetDate: '',
      status: 'Not started',
      notes: '',
    );
  }

  _SetupChecklistItem copyWith({
    String? title,
    String? owner,
    String? targetDate,
    String? status,
    String? notes,
  }) {
    return _SetupChecklistItem(
      id: id,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'owner': owner,
      'targetDate': targetDate,
      'status': status,
      'notes': notes,
    };
  }

  static List<_SetupChecklistItem> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _SetupChecklistItem(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: data['title']?.toString() ?? '',
        owner: data['owner']?.toString() ?? '',
        targetDate: data['targetDate']?.toString() ?? '',
        status: data['status']?.toString() ?? 'Not started',
        notes: data['notes']?.toString() ?? '',
      );
    }).toList();
  }
}

class _Debouncer {
  _Debouncer({Duration? delay}) : delay = delay ?? const Duration(milliseconds: 600);

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
