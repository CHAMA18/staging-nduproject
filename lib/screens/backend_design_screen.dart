import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/screens/ui_ux_design_screen.dart';
import 'package:ndu_project/screens/engineering_design_screen.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';

class BackendDesignScreen extends StatefulWidget {
  const BackendDesignScreen({super.key});

  @override
  State<BackendDesignScreen> createState() => _BackendDesignScreenState();
}

class _BackendDesignScreenState extends State<BackendDesignScreen> {
  final TextEditingController _architectureSummaryController = TextEditingController();
  final TextEditingController _databaseSummaryController = TextEditingController();

  final List<_ArchitectureComponent> _components = [];
  final List<_ArchitectureDataFlow> _dataFlows = [];
  final List<_DesignDocument> _designDocuments = [];
  final List<_DbEntity> _entities = [];
  final List<_DbField> _fields = [];

  final _Debouncer _saveDebounce = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;

  final List<String> _componentTypes = const ['Client', 'Service', 'Data store', 'Integration', 'Queue', 'Analytics'];
  final List<String> _componentStatuses = const ['Planned', 'In progress', 'Live', 'Deprecated'];
  final List<String> _protocolOptions = const ['HTTP', 'gRPC', 'Event', 'Batch', 'Streaming'];
  final List<String> _documentStatuses = const ['Draft', 'In review', 'Approved', 'Deprecated'];

  @override
  void initState() {
    super.initState();
    _architectureSummaryController.addListener(_scheduleSave);
    _databaseSummaryController.addListener(_scheduleSave);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
  }

  @override
  void dispose() {
    _architectureSummaryController.dispose();
    _databaseSummaryController.dispose();
    _saveDebounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Backend Design',
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
                  Text(
                    'Backend Design',
                    style: TextStyle(
                      fontSize: isMobile ? 22 : 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define the backend architecture, database schema, and API endpoints.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  if (isMobile)
                    Column(
                      children: [
                        _buildArchitectureCard(),
                        const SizedBox(height: 16),
                        _buildDatabaseCard(),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildArchitectureCard()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildDatabaseCard()),
                      ],
                    ),
                  const SizedBox(height: 28),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: UI/UX design',
                    nextLabel: 'Next: Engineering',
                    onBack: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UiUxDesignScreen())),
                    onNext: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EngineeringDesignScreen())),
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
          .doc('backend_design')
          .get();
      final data = doc.data() ?? {};
      final architecture = Map<String, dynamic>.from(data['architecture'] ?? {});
      final database = Map<String, dynamic>.from(data['database'] ?? {});

      _suspendSave = true;
      _architectureSummaryController.text = architecture['summary']?.toString() ?? '';
      _databaseSummaryController.text = database['summary']?.toString() ?? '';
      _suspendSave = false;

      final components = _ArchitectureComponent.fromList(architecture['components']);
      final flows = _ArchitectureDataFlow.fromList(architecture['dataFlows']);
      final documents = _DesignDocument.fromList(architecture['documents']);
      final entities = _DbEntity.fromList(database['entities']);
      final fields = _DbField.fromList(database['fields']);

      if (!mounted) return;
      setState(() {
        _components
          ..clear()
          ..addAll(components);
        _dataFlows
          ..clear()
          ..addAll(flows);
        _designDocuments
          ..clear()
          ..addAll(documents);
        _entities
          ..clear()
          ..addAll(entities);
        _fields
          ..clear()
          ..addAll(fields);
      });
    } catch (error) {
      debugPrint('Failed to load backend design data: $error');
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
      'architecture': {
        'summary': _architectureSummaryController.text.trim(),
        'components': _components.map((entry) => entry.toJson()).toList(),
        'dataFlows': _dataFlows.map((entry) => entry.toJson()).toList(),
        'documents': _designDocuments.map((entry) => entry.toJson()).toList(),
      },
      'database': {
        'summary': _databaseSummaryController.text.trim(),
        'entities': _entities.map((entry) => entry.toJson()).toList(),
        'fields': _fields.map((entry) => entry.toJson()).toList(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('design_phase_sections')
        .doc('backend_design')
        .set(payload, SetOptions(merge: true));
  }

  Widget _buildArchitectureCard() {
    return _CardShell(
      title: 'Architecture Overview',
      subtitle: 'Define core services, components, and data flows.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledTextArea(
            label: 'Architecture summary',
            controller: _architectureSummaryController,
            hintText: 'Describe the overall backend topology, critical services, and integration patterns.',
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'System components',
            actionLabel: 'Add component',
            onAction: _addComponent,
          ),
          _buildComponentsTable(),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Data flows',
            actionLabel: 'Add flow',
            onAction: _addDataFlow,
          ),
          _buildDataFlowsTable(),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Design documents',
            actionLabel: 'Add document',
            onAction: _addDesignDocument,
          ),
          _buildDocumentsTable(),
        ],
      ),
    );
  }

  Widget _buildDatabaseCard() {
    return _CardShell(
      title: 'Database Schema',
      subtitle: 'Define entities, fields, and constraints.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledTextArea(
            label: 'Schema summary',
            controller: _databaseSummaryController,
            hintText: 'Capture key database decisions, scaling approach, and indexing strategy.',
          ),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Entities',
            actionLabel: 'Add entity',
            onAction: _addEntity,
          ),
          _buildEntitiesTable(),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Fields',
            actionLabel: 'Add field',
            onAction: _addField,
          ),
          _buildFieldsTable(),
        ],
      ),
    );
  }

  void _addComponent() {
    setState(() => _components.add(_ArchitectureComponent.empty()));
    _scheduleSave();
  }

  void _updateComponent(_ArchitectureComponent updated) {
    final index = _components.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    setState(() => _components[index] = updated);
    _scheduleSave();
  }

  void _deleteComponent(String id) {
    setState(() => _components.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addDataFlow() {
    setState(() => _dataFlows.add(_ArchitectureDataFlow.empty()));
    _scheduleSave();
  }

  void _updateDataFlow(_ArchitectureDataFlow updated) {
    final index = _dataFlows.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    setState(() => _dataFlows[index] = updated);
    _scheduleSave();
  }

  void _deleteDataFlow(String id) {
    setState(() => _dataFlows.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addDesignDocument() {
    setState(() => _designDocuments.add(_DesignDocument.empty()));
    _scheduleSave();
  }

  void _updateDesignDocument(_DesignDocument updated) {
    final index = _designDocuments.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    setState(() => _designDocuments[index] = updated);
    _scheduleSave();
  }

  void _deleteDesignDocument(String id) {
    setState(() => _designDocuments.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addEntity() {
    setState(() => _entities.add(_DbEntity.empty()));
    _scheduleSave();
  }

  void _updateEntity(_DbEntity updated) {
    final index = _entities.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    setState(() => _entities[index] = updated);
    _scheduleSave();
  }

  void _deleteEntity(String id) {
    setState(() => _entities.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addField() {
    setState(() => _fields.add(_DbField.empty()));
    _scheduleSave();
  }

  void _updateField(_DbField updated) {
    final index = _fields.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    setState(() => _fields[index] = updated);
    _scheduleSave();
  }

  void _deleteField(String id) {
    setState(() => _fields.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  Widget _buildComponentsTable() {
    final columns = [
      const _TableColumnDef('Component', 200),
      const _TableColumnDef('Type', 140),
      const _TableColumnDef('Responsibility', 240),
      const _TableColumnDef('Owner', 160),
      const _TableColumnDef('Status', 140),
      const _TableColumnDef('', 60),
    ];

    if (_components.isEmpty) {
      return const _InlineEmptyState(
        title: 'No components yet',
        message: 'Add backend components to define the architecture.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _components)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.name,
                fieldKey: '${entry.id}_name',
                hintText: 'Component',
                onChanged: (value) => _updateComponent(entry.copyWith(name: value)),
              ),
              _DropdownCell(
                value: entry.type,
                fieldKey: '${entry.id}_type',
                options: _componentTypes,
                onChanged: (value) => _updateComponent(entry.copyWith(type: value)),
              ),
              _TextCell(
                value: entry.responsibility,
                fieldKey: '${entry.id}_responsibility',
                hintText: 'Responsibility',
                maxLines: 2,
                onChanged: (value) => _updateComponent(entry.copyWith(responsibility: value)),
              ),
              _TextCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                hintText: 'Owner',
                onChanged: (value) => _updateComponent(entry.copyWith(owner: value)),
              ),
              _DropdownCell(
                value: entry.status,
                fieldKey: '${entry.id}_status',
                options: _componentStatuses,
                onChanged: (value) => _updateComponent(entry.copyWith(status: value)),
              ),
              _DeleteCell(onPressed: () => _deleteComponent(entry.id)),
            ],
          ),
      ],
    );
  }

  Widget _buildDataFlowsTable() {
    final columns = [
      const _TableColumnDef('Source', 180),
      const _TableColumnDef('Destination', 180),
      const _TableColumnDef('Protocol', 140),
      const _TableColumnDef('Notes', 240),
      const _TableColumnDef('', 60),
    ];

    if (_dataFlows.isEmpty) {
      return const _InlineEmptyState(
        title: 'No data flows yet',
        message: 'Map service-to-service data exchange paths.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _dataFlows)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.source,
                fieldKey: '${entry.id}_source',
                hintText: 'Source',
                onChanged: (value) => _updateDataFlow(entry.copyWith(source: value)),
              ),
              _TextCell(
                value: entry.destination,
                fieldKey: '${entry.id}_destination',
                hintText: 'Destination',
                onChanged: (value) => _updateDataFlow(entry.copyWith(destination: value)),
              ),
              _DropdownCell(
                value: entry.protocol,
                fieldKey: '${entry.id}_protocol',
                options: _protocolOptions,
                onChanged: (value) => _updateDataFlow(entry.copyWith(protocol: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                maxLines: 2,
                onChanged: (value) => _updateDataFlow(entry.copyWith(notes: value)),
              ),
              _DeleteCell(onPressed: () => _deleteDataFlow(entry.id)),
            ],
          ),
      ],
    );
  }

  Widget _buildDocumentsTable() {
    final columns = [
      const _TableColumnDef('Document', 200),
      const _TableColumnDef('Description', 220),
      const _TableColumnDef('Owner', 160),
      const _TableColumnDef('Status', 140),
      const _TableColumnDef('Location', 200),
      const _TableColumnDef('', 60),
    ];

    if (_designDocuments.isEmpty) {
      return const _InlineEmptyState(
        title: 'No design documents yet',
        message: 'Add architecture decisions, diagrams, and references.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _designDocuments)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.title,
                fieldKey: '${entry.id}_title',
                hintText: 'Document',
                onChanged: (value) => _updateDesignDocument(entry.copyWith(title: value)),
              ),
              _TextCell(
                value: entry.description,
                fieldKey: '${entry.id}_description',
                hintText: 'Description',
                maxLines: 2,
                onChanged: (value) => _updateDesignDocument(entry.copyWith(description: value)),
              ),
              _TextCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                hintText: 'Owner',
                onChanged: (value) => _updateDesignDocument(entry.copyWith(owner: value)),
              ),
              _DropdownCell(
                value: entry.status,
                fieldKey: '${entry.id}_status',
                options: _documentStatuses,
                onChanged: (value) => _updateDesignDocument(entry.copyWith(status: value)),
              ),
              _TextCell(
                value: entry.location,
                fieldKey: '${entry.id}_location',
                hintText: 'Link or path',
                onChanged: (value) => _updateDesignDocument(entry.copyWith(location: value)),
              ),
              _DeleteCell(onPressed: () => _deleteDesignDocument(entry.id)),
            ],
          ),
      ],
    );
  }

  Widget _buildEntitiesTable() {
    final columns = [
      const _TableColumnDef('Entity/Table', 200),
      const _TableColumnDef('Primary key', 160),
      const _TableColumnDef('Owner', 160),
      const _TableColumnDef('Description', 240),
      const _TableColumnDef('', 60),
    ];

    if (_entities.isEmpty) {
      return const _InlineEmptyState(
        title: 'No entities yet',
        message: 'Add core tables or collections.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _entities)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.name,
                fieldKey: '${entry.id}_name',
                hintText: 'Entity',
                onChanged: (value) => _updateEntity(entry.copyWith(name: value)),
              ),
              _TextCell(
                value: entry.primaryKey,
                fieldKey: '${entry.id}_pk',
                hintText: 'Primary key',
                onChanged: (value) => _updateEntity(entry.copyWith(primaryKey: value)),
              ),
              _TextCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                hintText: 'Owner',
                onChanged: (value) => _updateEntity(entry.copyWith(owner: value)),
              ),
              _TextCell(
                value: entry.description,
                fieldKey: '${entry.id}_description',
                hintText: 'Description',
                maxLines: 2,
                onChanged: (value) => _updateEntity(entry.copyWith(description: value)),
              ),
              _DeleteCell(onPressed: () => _deleteEntity(entry.id)),
            ],
          ),
      ],
    );
  }

  Widget _buildFieldsTable() {
    final columns = [
      const _TableColumnDef('Entity/Table', 160),
      const _TableColumnDef('Field', 160),
      const _TableColumnDef('Type', 140),
      const _TableColumnDef('Constraints', 200),
      const _TableColumnDef('Notes', 220),
      const _TableColumnDef('', 60),
    ];

    if (_fields.isEmpty) {
      return const _InlineEmptyState(
        title: 'No fields yet',
        message: 'Define columns, types, and constraints.',
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in _fields)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.table,
                fieldKey: '${entry.id}_table',
                hintText: 'Entity',
                onChanged: (value) => _updateField(entry.copyWith(table: value)),
              ),
              _TextCell(
                value: entry.field,
                fieldKey: '${entry.id}_field',
                hintText: 'Field',
                onChanged: (value) => _updateField(entry.copyWith(field: value)),
              ),
              _TextCell(
                value: entry.type,
                fieldKey: '${entry.id}_type',
                hintText: 'Type',
                onChanged: (value) => _updateField(entry.copyWith(type: value)),
              ),
              _TextCell(
                value: entry.constraints,
                fieldKey: '${entry.id}_constraints',
                hintText: 'Constraints',
                onChanged: (value) => _updateField(entry.copyWith(constraints: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                maxLines: 2,
                onChanged: (value) => _updateField(entry.copyWith(notes: value)),
              ),
              _DeleteCell(onPressed: () => _deleteField(entry.id)),
            ],
          ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
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
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add, size: 16),
          label: Text(actionLabel),
          style: TextButton.styleFrom(
            foregroundColor: LightModeColors.lightPrimary,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: const Size(0, 32),
          ),
        ),
      ],
    );
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: columns.fold<double>(0, (sum, col) => sum + col.width)),
        child: Column(
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
    this.maxLines = 1,
  });

  final String value;
  final String fieldKey;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(fieldKey),
      initialValue: value,
      maxLines: maxLines,
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
      value: resolved,
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

class _ArchitectureComponent {
  const _ArchitectureComponent({
    required this.id,
    required this.name,
    required this.type,
    required this.responsibility,
    required this.owner,
    required this.status,
  });

  final String id;
  final String name;
  final String type;
  final String responsibility;
  final String owner;
  final String status;

  factory _ArchitectureComponent.empty() {
    return _ArchitectureComponent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
      type: 'Service',
      responsibility: '',
      owner: '',
      status: 'Planned',
    );
  }

  _ArchitectureComponent copyWith({
    String? name,
    String? type,
    String? responsibility,
    String? owner,
    String? status,
  }) {
    return _ArchitectureComponent(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      responsibility: responsibility ?? this.responsibility,
      owner: owner ?? this.owner,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'responsibility': responsibility,
      'owner': owner,
      'status': status,
    };
  }

  static List<_ArchitectureComponent> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _ArchitectureComponent(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: data['name']?.toString() ?? '',
        type: data['type']?.toString() ?? 'Service',
        responsibility: data['responsibility']?.toString() ?? '',
        owner: data['owner']?.toString() ?? '',
        status: data['status']?.toString() ?? 'Planned',
      );
    }).toList();
  }
}

class _ArchitectureDataFlow {
  const _ArchitectureDataFlow({
    required this.id,
    required this.source,
    required this.destination,
    required this.protocol,
    required this.notes,
  });

  final String id;
  final String source;
  final String destination;
  final String protocol;
  final String notes;

  factory _ArchitectureDataFlow.empty() {
    return _ArchitectureDataFlow(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      source: '',
      destination: '',
      protocol: 'HTTP',
      notes: '',
    );
  }

  _ArchitectureDataFlow copyWith({
    String? source,
    String? destination,
    String? protocol,
    String? notes,
  }) {
    return _ArchitectureDataFlow(
      id: id,
      source: source ?? this.source,
      destination: destination ?? this.destination,
      protocol: protocol ?? this.protocol,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'destination': destination,
      'protocol': protocol,
      'notes': notes,
    };
  }

  static List<_ArchitectureDataFlow> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _ArchitectureDataFlow(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        source: data['source']?.toString() ?? '',
        destination: data['destination']?.toString() ?? '',
        protocol: data['protocol']?.toString() ?? 'HTTP',
        notes: data['notes']?.toString() ?? '',
      );
    }).toList();
  }
}

class _DesignDocument {
  const _DesignDocument({
    required this.id,
    required this.title,
    required this.description,
    required this.owner,
    required this.status,
    required this.location,
  });

  final String id;
  final String title;
  final String description;
  final String owner;
  final String status;
  final String location;

  factory _DesignDocument.empty() {
    return _DesignDocument(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: '',
      description: '',
      owner: '',
      status: 'Draft',
      location: '',
    );
  }

  _DesignDocument copyWith({
    String? title,
    String? description,
    String? owner,
    String? status,
    String? location,
  }) {
    return _DesignDocument(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'owner': owner,
      'status': status,
      'location': location,
    };
  }

  static List<_DesignDocument> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _DesignDocument(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: data['title']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        owner: data['owner']?.toString() ?? '',
        status: data['status']?.toString() ?? 'Draft',
        location: data['location']?.toString() ?? '',
      );
    }).toList();
  }
}

class _DbEntity {
  const _DbEntity({
    required this.id,
    required this.name,
    required this.primaryKey,
    required this.owner,
    required this.description,
  });

  final String id;
  final String name;
  final String primaryKey;
  final String owner;
  final String description;

  factory _DbEntity.empty() {
    return _DbEntity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
      primaryKey: '',
      owner: '',
      description: '',
    );
  }

  _DbEntity copyWith({
    String? name,
    String? primaryKey,
    String? owner,
    String? description,
  }) {
    return _DbEntity(
      id: id,
      name: name ?? this.name,
      primaryKey: primaryKey ?? this.primaryKey,
      owner: owner ?? this.owner,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primaryKey': primaryKey,
      'owner': owner,
      'description': description,
    };
  }

  static List<_DbEntity> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _DbEntity(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: data['name']?.toString() ?? '',
        primaryKey: data['primaryKey']?.toString() ?? '',
        owner: data['owner']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
      );
    }).toList();
  }
}

class _DbField {
  const _DbField({
    required this.id,
    required this.table,
    required this.field,
    required this.type,
    required this.constraints,
    required this.notes,
  });

  final String id;
  final String table;
  final String field;
  final String type;
  final String constraints;
  final String notes;

  factory _DbField.empty() {
    return _DbField(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      table: '',
      field: '',
      type: '',
      constraints: '',
      notes: '',
    );
  }

  _DbField copyWith({
    String? table,
    String? field,
    String? type,
    String? constraints,
    String? notes,
  }) {
    return _DbField(
      id: id,
      table: table ?? this.table,
      field: field ?? this.field,
      type: type ?? this.type,
      constraints: constraints ?? this.constraints,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'table': table,
      'field': field,
      'type': type,
      'constraints': constraints,
      'notes': notes,
    };
  }

  static List<_DbField> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _DbField(
        id: data['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        table: data['table']?.toString() ?? '',
        field: data['field']?.toString() ?? '',
        type: data['type']?.toString() ?? '',
        constraints: data['constraints']?.toString() ?? '',
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
