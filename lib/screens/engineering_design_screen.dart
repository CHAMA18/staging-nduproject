import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/activity_log_service.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/utils/design_planning_document.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class EngineeringDesignScreen extends StatefulWidget {
  const EngineeringDesignScreen({super.key});

  @override
  State<EngineeringDesignScreen> createState() =>
      _EngineeringDesignScreenState();
}

class _EngineeringDesignScreenState extends State<EngineeringDesignScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _keyDecisionsController = TextEditingController();
  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;
  bool _didSeedDefaults = false;
  bool _registersExpanded = false;
  Map<String, dynamic>? _backendDesignContext;

  // Core layers data
  List<_CoreLayerItem> _coreLayers = [];

  // Components & interfaces data
  List<_ComponentItem> _components = [];

  // Engineering readiness items
  List<_ReadinessItem> _readinessItems = [];

  static const List<String> _statusOptions = [
    'Defined',
    'In review',
    'Draft',
    'Planned',
  ];

  List<String> _ownerOptions({String? currentValue}) {
    final provider = ProjectDataInherited.maybeOf(context);
    final members = provider?.projectData.teamMembers ?? [];
    final names = members
        .map((member) {
          final name = member.name.trim();
          if (name.isNotEmpty) return name;
          final email = member.email.trim();
          if (email.isNotEmpty) return email;
          return member.role.trim();
        })
        .where((value) => value.isNotEmpty)
        .toList();
    final options = names.isEmpty ? <String>['Owner'] : names.toSet().toList();
    final normalized = currentValue?.trim() ?? '';
    if (normalized.isNotEmpty && !options.contains(normalized)) {
      return [normalized, ...options];
    }
    return options;
  }

  Widget _buildOwnerDropdown({
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final options = _ownerOptions(currentValue: value);
    final normalized = value.trim();
    final resolved = normalized.isNotEmpty && options.contains(normalized)
        ? normalized
        : options.first;
    return DropdownButtonFormField<String>(
      initialValue: resolved,
      alignment: Alignment.center,
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      items: options
          .map((owner) =>
              DropdownMenuItem(value: owner, child: Center(child: Text(owner))))
          .toList(),
      onChanged: (newValue) {
        if (newValue == null) return;
        onChanged(newValue);
      },
      decoration: _inlineInputDecoration('Owner'),
    );
  }

  @override
  void initState() {
    super.initState();
    _coreLayers = _defaultCoreLayers();
    _components = _defaultComponents();
    _readinessItems = _defaultReadinessItems();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final projectId = provider?.projectData.projectId;
      if (projectId != null && projectId.isNotEmpty) {
        await ProjectNavigationService.instance.saveLastPage(
          projectId,
          'engineering',
        );
      }
      await _loadFromFirestore();
    });
    _notesController.addListener(_scheduleSave);
    _keyDecisionsController.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _keyDecisionsController.dispose();
    _saveDebouncer.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> _docFor(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('design_phase_sections')
        .doc('engineering_design');
  }

  void _scheduleSave() {
    if (_suspendSave) return;
    _saveDebouncer.run(_saveToFirestore);
  }

  Future<void> _loadFromFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    bool shouldSeedDefaults = false;
    try {
      final engineeringFuture = _docFor(projectId).get();
      final backendFuture = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('design_phase_sections')
          .doc('backend_design')
          .get();
      final results = await Future.wait<DocumentSnapshot<Map<String, dynamic>>>(
        [engineeringFuture, backendFuture],
      );
      final doc = results[0];
      final backendDoc = results[1];
      final data = doc.data() ?? {};
      final backendData = backendDoc.data() ?? {};
      shouldSeedDefaults = data.isEmpty && !_didSeedDefaults;
      _suspendSave = true;
      if (!mounted) return;
      setState(() {
        _backendDesignContext = backendData;
        final layers = _CoreLayerItem.fromList(data['coreLayers']);
        final components = _ComponentItem.fromList(data['components']);
        final readiness = _ReadinessItem.fromList(data['readinessItems']);
        if (shouldSeedDefaults) {
          final planningDoc = DesignPlanningDocument.fromProjectData(
            provider?.projectData ?? ProjectDataModel(),
          );
          final moduleSeed = planningDoc.modules
              .where((item) => item.name.trim().isNotEmpty)
              .map(
                (item) => _CoreLayerItem(
                  id: _newId(),
                  name: item.name,
                  description: item.purpose,
                ),
              )
              .toList();
          final integrationSeed = planningDoc.integrations
              .where((item) => item.name.trim().isNotEmpty)
              .map(
                (item) => _ComponentItem(
                  id: _newId(),
                  name: item.name,
                  responsibility: item.purpose,
                  statusLabel: item.status.isEmpty ? 'Planned' : item.status,
                ),
              )
              .toList();
          final readinessSeed = planningDoc.validationSummary
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .map(
                (line) => _ReadinessItem(
                  id: _newId(),
                  title: line,
                  description: line,
                  owner: 'Owner',
                ),
              )
              .toList();
          _didSeedDefaults = true;
          _notesController.text = [
            planningDoc.architectureSummary.trim(),
            planningDoc.buildTechnicalDigest().trim(),
          ].where((value) => value.isNotEmpty).join('\n\n');
          _keyDecisionsController.text = planningDoc.decisions
              .map((item) => item.decision.trim())
              .where((value) => value.isNotEmpty)
              .join('\n');
          _coreLayers = moduleSeed.isEmpty ? _defaultCoreLayers() : moduleSeed;
          _components =
              integrationSeed.isEmpty ? _defaultComponents() : integrationSeed;
          _readinessItems =
              readinessSeed.isEmpty ? _defaultReadinessItems() : readinessSeed;
        } else {
          _notesController.text = data['notes']?.toString() ?? '';
          _keyDecisionsController.text = data['keyDecisions']?.toString() ?? '';
          _coreLayers = layers.isEmpty ? _defaultCoreLayers() : layers;
          _components = components.isEmpty ? _defaultComponents() : components;
          _readinessItems =
              readiness.isEmpty ? _defaultReadinessItems() : readiness;
        }
      });
    } catch (error) {
      debugPrint('Engineering design load error: $error');
    } finally {
      _suspendSave = false;
      if (mounted) setState(() => _isLoading = false);
      if (shouldSeedDefaults) _scheduleSave();
    }
  }

  Future<void> _saveToFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    try {
      await _docFor(projectId).set({
        'notes': _notesController.text.trim(),
        'keyDecisions': _keyDecisionsController.text.trim(),
        'coreLayers': _coreLayers.map((e) => e.toMap()).toList(),
        'components': _components.map((e) => e.toMap()).toList(),
        'readinessItems': _readinessItems.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await ActivityLogService.instance.logActivity(
        projectId: projectId,
        phase: 'Design Phase',
        page: 'Engineering',
        action: 'Updated Engineering data',
      );
    } catch (error) {
      debugPrint('Engineering design save error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save Engineering changes right now. Please try again.',
          ),
        ),
      );
    }
  }

  List<_CoreLayerItem> _defaultCoreLayers() {
    return [
      _CoreLayerItem(
        id: _newId(),
        name: 'Structural modeling layer',
        description:
            'UML diagrams, steel framing logic, and coordination drawings',
      ),
      _CoreLayerItem(
        id: _newId(),
        name: 'Integration layer',
        description:
            'APIs, physical joints, HVAC interfaces, and vendor handoffs',
      ),
      _CoreLayerItem(
        id: _newId(),
        name: 'Verification layer',
        description:
            'Load checks, latency budgets, code compliance, and stamped approvals',
      ),
    ];
  }

  List<_ComponentItem> _defaultComponents() {
    return [
      _ComponentItem(
        id: _newId(),
        name: 'Ticketing API',
        responsibility:
            'REST contract for ticket validation and gate access rules',
        statusLabel: 'Defined',
      ),
      _ComponentItem(
        id: _newId(),
        name: 'Primary roof truss joint',
        responsibility: 'Physical joint specification and load transfer detail',
        statusLabel: 'In review',
      ),
      _ComponentItem(
        id: _newId(),
        name: 'HVAC control interface',
        responsibility:
            'Environmental control signals and occupancy response logic',
        statusLabel: 'Draft',
      ),
      _ComponentItem(
        id: _newId(),
        name: 'Steel grade reference pack',
        responsibility:
            'Datasheet and compliance mapping for fabricated members',
        statusLabel: 'Planned',
      ),
    ];
  }

  List<_ReadinessItem> _defaultReadinessItems() {
    return [
      _ReadinessItem(
        id: _newId(),
        title: 'Structural sign-off ready',
        description: 'Finalize stamped calculations and member schedules',
        owner: 'Structural engineer',
      ),
      _ReadinessItem(
        id: _newId(),
        title: 'Electrical coordination review',
        description:
            'Verify power loads, cable paths, and control panel interfaces',
        owner: 'Electrical engineer',
      ),
      _ReadinessItem(
        id: _newId(),
        title: 'Software interface freeze',
        description:
            'Approve API schemas, latency budgets, and deployment handoff',
        owner: 'Software lead',
      ),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _logActivity(String action, {Map<String, dynamic>? details}) {
    final projectId =
        ProjectDataInherited.maybeOf(context)?.projectData.projectId?.trim() ??
            '';
    if (projectId.isEmpty) return;
    unawaited(
      ActivityLogService.instance.logActivity(
        projectId: projectId,
        phase: 'Design Phase',
        page: 'Engineering',
        action: action,
        details: details,
      ),
    );
  }

  void _updateCoreLayer(_CoreLayerItem updated) {
    final index = _coreLayers.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _coreLayers[index] = updated);
    _scheduleSave();
  }

  void _addCoreLayer() {
    _openCoreLayerDialog();
  }

  void _removeCoreLayer(String id) {
    setState(() => _coreLayers.removeWhere((item) => item.id == id));
    _scheduleSave();
    _logActivity('Deleted core layer row', details: {'itemId': id});
  }

  void _updateComponent(_ComponentItem updated) {
    final index = _components.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _components[index] = updated);
    _scheduleSave();
  }

  void _addComponent() {
    _openComponentDialog();
  }

  void _removeComponent(String id) {
    setState(() => _components.removeWhere((item) => item.id == id));
    _scheduleSave();
    _logActivity('Deleted component row', details: {'itemId': id});
  }

  void _updateReadiness(_ReadinessItem updated) {
    final index = _readinessItems.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _readinessItems[index] = updated);
    _scheduleSave();
  }

  void _addReadiness() {
    _openReadinessDialog();
  }

  void _removeReadiness(String id) {
    setState(() => _readinessItems.removeWhere((item) => item.id == id));
    _scheduleSave();
    _logActivity('Deleted readiness row', details: {'itemId': id});
  }

  Future<void> _openCoreLayerDialog({_CoreLayerItem? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null
            ? 'Add architecture layer'
            : 'Edit architecture layer'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Layer name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Responsibility',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(existing == null ? 'Add layer' : 'Save changes'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    final item = _CoreLayerItem(
      id: existing?.id ?? _newId(),
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
    );
    setState(() {
      if (existing == null) {
        _coreLayers.add(item);
      } else {
        final index =
            _coreLayers.indexWhere((entry) => entry.id == existing.id);
        if (index != -1) _coreLayers[index] = item;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null ? 'Added core layer row' : 'Edited core layer row',
      details: {'itemId': item.id},
    );
  }

  Future<void> _openComponentDialog({_ComponentItem? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final responsibilityController =
        TextEditingController(text: existing?.responsibility ?? '');
    String status = existing?.statusLabel ?? _statusOptions.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Add component' : 'Edit component'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Component name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: responsibilityController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Responsibility / specification',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: _statusOptions
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => status = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(existing == null ? 'Add component' : 'Save changes'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final item = _ComponentItem(
      id: existing?.id ?? _newId(),
      name: nameController.text.trim(),
      responsibility: responsibilityController.text.trim(),
      statusLabel: status,
    );
    setState(() {
      if (existing == null) {
        _components.add(item);
      } else {
        final index =
            _components.indexWhere((entry) => entry.id == existing.id);
        if (index != -1) _components[index] = item;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null ? 'Added component row' : 'Edited component row',
      details: {'itemId': item.id},
    );
  }

  Future<void> _openReadinessDialog({_ReadinessItem? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    String owner = existing?.owner ?? _ownerOptions().first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null
              ? 'Add engineering entry'
              : 'Edit engineering entry'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Entry title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue:
                      _ownerOptions(currentValue: owner).contains(owner)
                          ? owner
                          : _ownerOptions(currentValue: owner).first,
                  items: _ownerOptions(currentValue: owner)
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => owner = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Owner',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(existing == null ? 'Add entry' : 'Save changes'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final item = _ReadinessItem(
      id: existing?.id ?? _newId(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      owner: owner,
    );
    setState(() {
      if (existing == null) {
        _readinessItems.add(item);
      } else {
        final index =
            _readinessItems.indexWhere((entry) => entry.id == existing.id);
        if (index != -1) _readinessItems[index] = item;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null ? 'Added readiness row' : 'Edited readiness row',
      details: {'itemId': item.id},
    );
  }

  Future<void> _exportEngineeringChecklist() async {
    final doc = pw.Document();
    final notes = _notesController.text.trim();
    final keyDecisions = _keyDecisionsController.text.trim();
    final coreLayers = _coreLayers
        .map((layer) {
          final name = layer.name.trim();
          final desc = layer.description.trim();
          if (name.isEmpty && desc.isEmpty) return '';
          return desc.isEmpty ? name : '$name — $desc';
        })
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final components = _components
        .map((component) {
          final name = component.name.trim();
          final resp = component.responsibility.trim();
          final status = component.statusLabel.trim();
          if (name.isEmpty && resp.isEmpty && status.isEmpty) return '';
          final base = resp.isEmpty ? name : '$name — $resp';
          return status.isEmpty ? base : '$base ($status)';
        })
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final readiness = _readinessItems
        .map((item) {
          final title = item.title.trim();
          final desc = item.description.trim();
          final owner = item.owner.trim();
          if (title.isEmpty && desc.isEmpty && owner.isEmpty) return '';
          final base = desc.isEmpty ? title : '$title — $desc';
          return owner.isEmpty ? base : '$base (Owner: $owner)';
        })
        .where((line) => line.trim().isNotEmpty)
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Engineering Checklist',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          _pdfTextBlock('Notes', notes),
          _pdfTextBlock('Key decisions', keyDecisions),
          _pdfSection('System architecture', coreLayers),
          _pdfSection('Components & interfaces', components),
          _pdfSection('Engineering readiness', readiness),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'engineering-checklist.pdf',
    );
  }

  pw.Widget _pdfTextBlock(String title, String content) {
    final normalized = content.trim().isEmpty ? 'No entries.' : content.trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(normalized, style: const pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _pdfSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        if (items.isEmpty)
          pw.Text('No entries.', style: const pw.TextStyle(fontSize: 12))
        else
          pw.Column(
            children: items.map((item) => pw.Bullet(text: item)).toList(),
          ),
        pw.SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);
    final provider = ProjectDataInherited.maybeOf(context);
    final projectData = provider?.projectData ?? ProjectDataModel();
    final snapshot = _EngineeringDashboardSnapshot.from(
      projectData: projectData,
      backendDesignContext: _backendDesignContext,
      notes: _notesController.text,
      keyDecisions: _keyDecisionsController.text,
      coreLayers: _coreLayers,
      components: _components,
      readinessItems: _readinessItems,
    );

    return ResponsiveScaffold(
      activeItemLabel: 'Engineering',
      floatingActionButton: const KazAiChatBubble(positioned: false),
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Engineering',
            showImportButton: false,
            showContentButton: false,
            showNavigationButtons: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 24),
                  _buildBlueprintHero(
                    isMobile: isMobile,
                    snapshot: snapshot,
                  ),
                  const SizedBox(height: 24),
                  _buildBlueprintsTopSection(snapshot, isMobile),
                  const SizedBox(height: 20),
                  _buildSpecificationsGrid(snapshot),
                  const SizedBox(height: 20),
                  _buildGovernanceSection(snapshot, isMobile),
                  const SizedBox(height: 20),
                  _buildDetailedRegistersPanel(),
                  const SizedBox(height: 32),
                  _buildBottomNavigation(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueprintHero({
    required bool isMobile,
    required _EngineeringDashboardSnapshot snapshot,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1220),
            Color(0xFF132238),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Structural & Technical Detailing Hub',
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Engineering for ${snapshot.projectLabel}. This workspace brings together technical blueprints, calculations, approvals, interface detail, compliance evidence, simulation outcomes, and engineering change notices before implementation starts.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.84),
              height: 1.5,
            ),
          ),
          if (_notesController.text.trim().isNotEmpty ||
              _keyDecisionsController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
              child: Text(
                [
                  _notesController.text.trim(),
                  _keyDecisionsController.text.trim(),
                ].where((value) => value.isNotEmpty).join('\n\n'),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withOpacity(0.82),
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _buildHeroMetricsSection(snapshot),
        ],
      ),
    );
  }

  Widget _buildHeroMetricsSection(_EngineeringDashboardSnapshot snapshot) {
    final metrics = [
      _buildHeroMetricPill('Models', '${snapshot.modelFiles.length}'),
      _buildHeroMetricPill('Sign-offs', '${snapshot.signoffs.length}'),
      _buildHeroMetricPill('Specs', '${snapshot.interfaceSpecs.length}'),
      _buildHeroMetricPill('ECNs', '${snapshot.ecnItems.length}'),
      _buildHeroMetricPill('AI Signals', '${snapshot.aiSignalCount}'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: metrics,
          );
        }

        return Row(
          children: [
            for (var index = 0; index < metrics.length; index++) ...[
              Expanded(child: metrics[index]),
              if (index < metrics.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBlueprintsTopSection(
    _EngineeringDashboardSnapshot snapshot,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        children: [
          _buildModelingPanel(snapshot),
          const SizedBox(height: 20),
          _buildSignoffPanel(snapshot),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _buildModelingPanel(snapshot)),
        const SizedBox(width: 20),
        Expanded(flex: 5, child: _buildSignoffPanel(snapshot)),
      ],
    );
  }

  Widget _buildSpecificationsGrid(_EngineeringDashboardSnapshot snapshot) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 560;

        if (isStacked) {
          return Column(
            children: [
              _buildInterfaceSpecsPanel(snapshot),
              const SizedBox(height: 20),
              _buildCalculationsPanel(snapshot),
              const SizedBox(height: 20),
              _buildDatasheetsPanel(snapshot),
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: _buildInterfaceSpecsPanel(snapshot),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 6,
                  child: _buildCalculationsPanel(snapshot),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDatasheetsPanel(snapshot),
          ],
        );
      },
    );
  }

  Widget _buildGovernanceSection(
    _EngineeringDashboardSnapshot snapshot,
    bool isMobile,
  ) {
    if (isMobile) {
      return Column(
        children: [
          _buildCompliancePanel(snapshot),
          const SizedBox(height: 20),
          _buildSimulationPanel(snapshot),
          const SizedBox(height: 20),
          _buildEcnPanel(snapshot),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildCompliancePanel(snapshot)),
        const SizedBox(width: 20),
        Expanded(child: _buildSimulationPanel(snapshot)),
        const SizedBox(width: 20),
        Expanded(child: _buildEcnPanel(snapshot)),
      ],
    );
  }

  Widget _buildDetailedRegistersPanel() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _registersExpanded,
          onExpansionChanged: (value) {
            setState(() => _registersExpanded = value);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: const Text(
            'Detailed Registers',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          subtitle: const Text(
            'Edit the source notes, layers, interfaces, and readiness records feeding the dashboard above.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          children: [
            _buildEngineeringBriefCard(),
            const SizedBox(height: 16),
            _buildSystemArchitectureCard(),
            const SizedBox(height: 16),
            _buildComponentsInterfacesCard(),
            const SizedBox(height: 16),
            _buildEngineeringReadinessCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineeringBriefCard() {
    return _buildDashboardPanel(
      title: 'Engineering Brief & Key Decisions',
      subtitle:
          'Working notes and technical decision log behind the structured engineering dashboard.',
      icon: Icons.edit_note_outlined,
      accent: const Color(0xFF1D4ED8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Capture engineering assumptions, code requirements, detailing notes, and unresolved technical questions.',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyDecisionsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Record key approvals, calculation assumptions, sign-off gates, and coordination decisions.',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPanel({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withOpacity(0.18)),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildHeroMetricPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildModelingPanel(_EngineeringDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Architecture & Structural Modeling',
      subtitle:
          'Blueprint and model registry covering software diagrams and physical technical models.',
      icon: Icons.grid_view_rounded,
      accent: const Color(0xFF1D4ED8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Model File',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Model Type',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'View',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < snapshot.modelFiles.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      snapshot.modelFiles[i].name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      snapshot.modelFiles[i].modelType,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      snapshot.modelFiles[i].view,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildStatusBadge(
                        snapshot.modelFiles[i].status,
                        _statusTone(snapshot.modelFiles[i].status),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != snapshot.modelFiles.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildSignoffPanel(_EngineeringDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Verification & Sign-off Status',
      subtitle:
          'Formal approval matrix for engineering disciplines with signature placeholders.',
      icon: Icons.approval_outlined,
      accent: const Color(0xFF0F766E),
      child: Column(
        children: snapshot.signoffs
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.discipline,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.engineerName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(
                            item.status == 'Approved'
                                ? Icons.verified_outlined
                                : Icons.edit_note_outlined,
                            color: _statusTone(item.status),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              item.stamp,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInterfaceSpecsPanel(_EngineeringDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Interface & Integration Specifications',
      subtitle:
          'Connection-point register covering APIs and physical joints with technical detail.',
      icon: Icons.link_rounded,
      accent: const Color(0xFF1D4ED8),
      child: Column(
        children: snapshot.interfaceSpecs
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.interfaceId,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        _buildStatusBadge(item.type, const Color(0xFF1D4ED8)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.specification,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalculationsPanel(_EngineeringDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Technical Calculations & Analysis',
      subtitle:
          'Repository of calculation subjects, outcomes, and referenced documents.',
      icon: Icons.calculate_outlined,
      accent: const Color(0xFF0F766E),
      child: Column(
        children: snapshot.calculations
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.subject,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(item.result, _resultTone(item.result)),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.document,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDatasheetsPanel(_EngineeringDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Technical Specifications & Data Sheets',
      subtitle:
          'Library of engineered components and physical materials with data-sheet references.',
      icon: Icons.library_books_outlined,
      accent: const Color(0xFF1D4ED8),
      child: Column(
        children: snapshot.datasheets
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.component,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          item.datasheet,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.attributes,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCompliancePanel(_EngineeringDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Standards & Code Compliance Check',
      subtitle:
          'Verification matrix for design adherence against software and physical standards.',
      icon: Icons.fact_check_outlined,
      accent: const Color(0xFF0F766E),
      child: Column(
        children: snapshot.complianceItems
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.standard,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    _buildStatusBadge(
                      item.status,
                      _statusTone(item.status),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSimulationPanel(_EngineeringDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Simulation & Prototype Results',
      subtitle:
          'Visual repository of heat maps, stress visuals, and prototype test outcomes.',
      icon: Icons.photo_library_outlined,
      accent: const Color(0xFF1D4ED8),
      child: Column(
        children: snapshot.simulations
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 132,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: item.colors,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Center(child: _buildSimulationPreview(item)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              _buildStatusBadge(
                                item.outcome,
                                _resultTone(item.outcome),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.caption,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEcnPanel(_EngineeringDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Engineering Change Notices (ECN)',
      subtitle:
          'Log of engineering changes with reasons and downstream impact detail.',
      icon: Icons.assignment_late_outlined,
      accent: const Color(0xFF1D4ED8),
      child: Column(
        children: snapshot.ecnItems
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.id,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.reason,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.impact,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSimulationPreview(_SimulationItem item) {
    switch (item.previewType) {
      case _SimulationPreviewType.heatMap:
        return Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFFF59E0B), Color(0xFFDC2626)],
            ),
          ),
        );
      case _SimulationPreviewType.stress:
        return CustomPaint(
          size: const Size(120, 80),
          painter: _StressPreviewPainter(),
        );
      case _SimulationPreviewType.signal:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  width: 18,
                  height: 18 + index * 10,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? const Color(0xFFDBEAFE)
                        : const Color(0xFFBFDBFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  Color _statusTone(String status) {
    switch (status) {
      case 'Approved':
      case 'Defined':
      case 'Compliant':
        return AppSemanticColors.success;
      case 'In review':
      case 'Drafting':
      case 'Draft':
        return AppSemanticColors.warning;
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _resultTone(String result) {
    switch (result) {
      case 'Pass':
      case 'Approved':
        return AppSemanticColors.success;
      case 'Fail':
        return const Color(0xFFDC2626);
      default:
        return AppSemanticColors.warning;
    }
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
            ),
            if (action != null) action,
          ],
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSystemArchitectureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'System architecture',
            subtitle: 'High-level layers and responsibilities',
            action: TextButton.icon(
              onPressed: _addCoreLayer,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add layer'),
            ),
          ),
          const SizedBox(height: 20),
          ..._coreLayers.map((layer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('core-layer-name-${layer.id}'),
                        initialValue: layer.name,
                        decoration: _inlineInputDecoration('Layer name'),
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF1F2937)),
                        onChanged: (value) =>
                            _updateCoreLayer(layer.copyWith(name: value)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('core-layer-desc-${layer.id}'),
                        initialValue: layer.description,
                        decoration: _inlineInputDecoration('Responsibility'),
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF1F2937)),
                        onChanged: (value) => _updateCoreLayer(
                            layer.copyWith(description: value)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openCoreLayerDialog(existing: layer),
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: Color(0xFF2563EB)),
                    ),
                    IconButton(
                      onPressed: () => _removeCoreLayer(layer.id),
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          Text('Key decisions',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700])),
          const SizedBox(height: 8),
          TextField(
            controller: _keyDecisionsController,
            maxLines: 3,
            decoration: _inlineInputDecoration(
                'Document trade-offs, constraints, and technical decisions.'),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentsInterfacesCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppSemanticColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Components & interfaces',
              subtitle: 'Who owns what and how they talk',
              action: TextButton.icon(
                onPressed: _addComponent,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add component'),
              ),
            ),
            const SizedBox(height: 20),
            // Header Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Component'),
                ),
                Expanded(
                  flex: 2,
                  child: _tableHeaderCell('Responsibility'),
                ),
                Expanded(
                  flex: 1,
                  child: _tableHeaderCell('Interface status'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._components.map((component) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          key: ValueKey('component-name-${component.id}'),
                          initialValue: component.name,
                          decoration: _inlineInputDecoration('Component'),
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF1F2937)),
                          onChanged: (value) =>
                              _updateComponent(component.copyWith(name: value)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          key: ValueKey('component-resp-${component.id}'),
                          initialValue: component.responsibility,
                          decoration: _inlineInputDecoration('Responsibility'),
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF1F2937)),
                          onChanged: (value) => _updateComponent(
                              component.copyWith(responsibility: value)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              _statusOptions.contains(component.statusLabel)
                                  ? component.statusLabel
                                  : _statusOptions.first,
                          alignment: Alignment.center,
                          isExpanded: true,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF1F2937)),
                          selectedItemBuilder: (context) => _statusOptions
                              .map((status) => Align(
                                    alignment: Alignment.center,
                                    child: Text(status,
                                        textAlign: TextAlign.center),
                                  ))
                              .toList(),
                          decoration: _inlineInputDecoration('Status'),
                          items: _statusOptions
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Center(
                                      child: Text(status,
                                          textAlign: TextAlign.center),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            _updateComponent(
                                component.copyWith(statusLabel: value));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () =>
                            _openComponentDialog(existing: component),
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF2563EB)),
                      ),
                      IconButton(
                        onPressed: () => _removeComponent(component.id),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );

  Widget _buildEngineeringReadinessCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppSemanticColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Engineering readiness',
              subtitle: 'Design reviews, sign-offs, and ownership',
              action: TextButton.icon(
                onPressed: _addReadiness,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add entry'),
              ),
            ),
            const SizedBox(height: 20),
            ..._readinessItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              key: ValueKey('readiness-title-${item.id}'),
                              initialValue: item.title,
                              decoration:
                                  _inlineInputDecoration('Readiness item'),
                              textAlign: TextAlign.center,
                              textAlignVertical: TextAlignVertical.center,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937)),
                              onChanged: (value) =>
                                  _updateReadiness(item.copyWith(title: value)),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              key: ValueKey('readiness-desc-${item.id}'),
                              initialValue: item.description,
                              decoration: _inlineInputDecoration('Description'),
                              textAlign: TextAlign.center,
                              textAlignVertical: TextAlignVertical.center,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF1F2937)),
                              onChanged: (value) => _updateReadiness(
                                  item.copyWith(description: value)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 180,
                        child: _buildOwnerDropdown(
                          value: item.owner,
                          onChanged: (value) =>
                              _updateReadiness(item.copyWith(owner: value)),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openReadinessDialog(existing: item),
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: Color(0xFF2563EB)),
                      ),
                      IconButton(
                        onPressed: () => _removeReadiness(item.id),
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            // Export button
            Center(
              child: OutlinedButton.icon(
                onPressed: _exportEngineeringChecklist,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(
                      color: LightModeColors.accent, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export engineering checklist'),
              ),
            ),
          ],
        ),
      );

  // ignore: unused_element
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'defined':
        return const Color(0xFF22C55E);
      case 'in review':
        return const Color(0xFFFBBF24);
      case 'draft':
        return const Color(0xFFFBBF24);
      case 'planned':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Widget _tableHeaderCell(String label) {
    return Align(
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isMobile) => Column(
        children: [
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/${AppRoutes.backendDesign}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Back: Backend Design'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Design phase | Engineering',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.go('/${AppRoutes.technicalDevelopment}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: LightModeColors.accent,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Next: Technical Development'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/${AppRoutes.backendDesign}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back: Backend Design'),
                ),
                const SizedBox(width: 16),
                Text(
                  'Design phase | Engineering',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () =>
                      context.go('/${AppRoutes.technicalDevelopment}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: LightModeColors.accent,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('Next: Technical Development'),
                ),
              ],
            ),
          const SizedBox(height: 24),
          // Tip section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 18, color: LightModeColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Keep engineering artifacts simple but precise: document architecture diagrams, component responsibilities, and interface contracts so implementation teams can build without reinterpreting the design.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      );
}

class _EngineeringDashboardSnapshot {
  const _EngineeringDashboardSnapshot({
    required this.projectLabel,
    required this.modelFiles,
    required this.signoffs,
    required this.interfaceSpecs,
    required this.calculations,
    required this.datasheets,
    required this.complianceItems,
    required this.simulations,
    required this.ecnItems,
    required this.aiSignalCount,
  });

  final String projectLabel;
  final List<_ModelFileItem> modelFiles;
  final List<_SignoffItem> signoffs;
  final List<_InterfaceSpecItem> interfaceSpecs;
  final List<_CalculationItem> calculations;
  final List<_DatasheetItem> datasheets;
  final List<_ComplianceItem> complianceItems;
  final List<_SimulationItem> simulations;
  final List<_EcnItem> ecnItems;
  final int aiSignalCount;

  factory _EngineeringDashboardSnapshot.from({
    required ProjectDataModel projectData,
    required Map<String, dynamic>? backendDesignContext,
    required String notes,
    required String keyDecisions,
    required List<_CoreLayerItem> coreLayers,
    required List<_ComponentItem> components,
    required List<_ReadinessItem> readinessItems,
  }) {
    final projectLabel = projectData.projectName.trim().isNotEmpty
        ? projectData.projectName.trim()
        : 'the current engineering package';
    final backendArchitecture = Map<String, dynamic>.from(
      backendDesignContext?['architecture'] as Map? ?? const {},
    );
    final backendDatabase = Map<String, dynamic>.from(
      backendDesignContext?['database'] as Map? ?? const {},
    );
    final backendDocuments =
        ((backendArchitecture['documents'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    final backendEntities = ((backendDatabase['entities'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    final modelFiles = <_ModelFileItem>[];
    for (final document in backendDocuments.take(4)) {
      final title = document['title']?.toString().trim() ?? '';
      if (title.isEmpty) continue;
      final description = document['description']?.toString().trim() ?? '';
      final location = document['location']?.toString().trim() ?? '';
      final status = document['status']?.toString().trim().isNotEmpty == true
          ? document['status']!.toString().trim()
          : 'Drafting';
      modelFiles.add(
        _ModelFileItem(
          name: title,
          modelType: _modelTypeFor(title, description),
          view: location.isNotEmpty ? location : 'General View',
          status: status == 'Approved' ? 'Approved' : 'Drafting',
        ),
      );
    }
    if (modelFiles.isEmpty) {
      modelFiles.addAll(const [
        _ModelFileItem(
          name: 'UML Diagram',
          modelType: 'Software Model',
          view: 'System View',
          status: 'Drafting',
        ),
        _ModelFileItem(
          name: 'Structural 3D Model',
          modelType: 'Structural Model',
          view: 'Isometric',
          status: 'Approved',
        ),
        _ModelFileItem(
          name: 'HVAC Coordination Grid',
          modelType: 'MEP Model',
          view: 'Plan View',
          status: 'Drafting',
        ),
      ]);
    }

    final signoffNames = projectData.teamMembers
        .map((member) => {
              'role': member.role.trim(),
              'name': member.name.trim().isNotEmpty
                  ? member.name.trim()
                  : member.email.trim(),
            })
        .where((item) => (item['name'] ?? '').isNotEmpty)
        .toList();

    String engineerFor(String discipline) {
      for (final item in signoffNames) {
        if ((item['role'] ?? '')
            .toLowerCase()
            .contains(discipline.toLowerCase())) {
          return item['name']!;
        }
      }
      for (final item in readinessItems) {
        if (item.owner.trim().isNotEmpty &&
            item.owner.toLowerCase().contains(discipline.toLowerCase())) {
          return item.owner.trim();
        }
      }
      return '$discipline Engineer';
    }

    final signoffs = [
      _SignoffItem(
        discipline: 'Structural',
        engineerName: engineerFor('structural'),
        status: readinessItems
                .any((item) => item.title.toLowerCase().contains('structural'))
            ? 'Approved'
            : 'Drafting',
        stamp: 'Stamp Pending',
      ),
      _SignoffItem(
        discipline: 'Electrical',
        engineerName: engineerFor('electrical'),
        status: readinessItems
                .any((item) => item.title.toLowerCase().contains('electrical'))
            ? 'Approved'
            : 'Drafting',
        stamp: 'Digital Signature',
      ),
      _SignoffItem(
        discipline: 'Software',
        engineerName: engineerFor('software'),
        status: readinessItems
                .any((item) => item.title.toLowerCase().contains('software'))
            ? 'Approved'
            : 'Drafting',
        stamp: 'Seal Pending',
      ),
    ];

    final interfaceSpecs =
        components.take(4).toList().asMap().entries.map((entry) {
      final component = entry.value;
      return _InterfaceSpecItem(
        interfaceId: 'INT-${(entry.key + 1).toString().padLeft(3, '0')}',
        type: _interfaceTypeFor(component.name, component.responsibility),
        specification: component.responsibility.trim().isNotEmpty
            ? component.responsibility.trim()
            : 'Detailed interface specification still in progress.',
      );
    }).toList();

    final calculations = [
      _CalculationItem(
        subject: 'Load Bearing',
        result: readinessItems
                .any((item) => item.title.toLowerCase().contains('structural'))
            ? 'Pass'
            : 'Review',
        document: 'calc-load-a1.pdf',
      ),
      _CalculationItem(
        subject: 'Latency',
        result:
            components.any((item) => item.name.toLowerCase().contains('api'))
                ? 'Pass'
                : 'Review',
        document: 'latency-budget.md',
      ),
      _CalculationItem(
        subject: 'HVAC Airflow',
        result: notes.toLowerCase().contains('hvac') ? 'Pass' : 'Review',
        document: 'hvac-airflow-sheet.xlsx',
      ),
      const _CalculationItem(
        subject: 'Cable Load',
        result: 'Pass',
        document: 'electrical-routing.pdf',
      ),
    ];

    final datasheets = <_DatasheetItem>[
      ...components.take(2).map(
            (item) => _DatasheetItem(
              component:
                  item.name.trim().isNotEmpty ? item.name.trim() : 'Server',
              attributes: item.responsibility.trim().isNotEmpty
                  ? item.responsibility.trim()
                  : 'Technical specification pending.',
              datasheet: 'datasheet.pdf',
            ),
          ),
      if (backendEntities.isNotEmpty)
        _DatasheetItem(
          component: backendEntities.first['name']?.toString() ?? 'Data Model',
          attributes:
              'Entity definition and engineering reference for backend coordination.',
          datasheet: 'schema-reference.md',
        ),
      const _DatasheetItem(
        component: 'Steel Grade S355',
        attributes: 'Yield strength, fabrication note, and finish requirement.',
        datasheet: 'steel-grade-s355.pdf',
      ),
    ];

    final complianceItems = [
      _ComplianceItem(
        standard: 'Building Code',
        status:
            notes.toLowerCase().contains('code') ? 'Compliant' : 'In review',
      ),
      _ComplianceItem(
        standard: 'IEEE',
        status: components.any((item) =>
                item.name.toLowerCase().contains('api') ||
                item.name.toLowerCase().contains('electrical'))
            ? 'Compliant'
            : 'In review',
      ),
      _ComplianceItem(
        standard: 'Fire Safety',
        status:
            notes.toLowerCase().contains('fire') ? 'Compliant' : 'In review',
      ),
      _ComplianceItem(
        standard: 'Accessibility',
        status: keyDecisions.toLowerCase().contains('access')
            ? 'Compliant'
            : 'In review',
      ),
    ];

    final simulations = const [
      _SimulationItem(
        title: 'Thermal Heat Map',
        caption: 'HVAC and crowd load simulation for the main hall.',
        outcome: 'Pass',
        previewType: _SimulationPreviewType.heatMap,
        colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
      ),
      _SimulationItem(
        title: 'Stress Test Visualization',
        caption: 'Structural member stress distribution under peak live load.',
        outcome: 'Pass',
        previewType: _SimulationPreviewType.stress,
        colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
      ),
      _SimulationItem(
        title: 'Latency Burst Prototype',
        caption: 'API and scanner response behaviour under high throughput.',
        outcome: 'Review',
        previewType: _SimulationPreviewType.signal,
        colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
      ),
    ];

    final ecnItems =
        readinessItems.take(3).toList().asMap().entries.map((entry) {
      final item = entry.value;
      return _EcnItem(
        id: 'ECN-${(entry.key + 1).toString().padLeft(3, '0')}',
        reason: item.title.trim().isNotEmpty
            ? item.title.trim()
            : 'Engineering revision required',
        impact: item.description.trim().isNotEmpty
            ? item.description.trim()
            : 'Impact to detailing, procurement, and technical handoff.',
      );
    }).toList();

    final aiSignalCount = projectData.aiUsageCounts.values.fold<int>(
          0,
          (total, value) => total + value,
        ) +
        projectData.aiRecommendations.length +
        projectData.aiIntegrations.length;

    return _EngineeringDashboardSnapshot(
      projectLabel: projectLabel,
      modelFiles: modelFiles,
      signoffs: signoffs,
      interfaceSpecs: interfaceSpecs,
      calculations: calculations,
      datasheets: datasheets.take(4).toList(),
      complianceItems: complianceItems,
      simulations: simulations,
      ecnItems: ecnItems,
      aiSignalCount: aiSignalCount,
    );
  }

  static String _modelTypeFor(String title, String description) {
    final source = '$title $description'.toLowerCase();
    if (source.contains('uml') || source.contains('api')) {
      return 'Software Model';
    }
    if (source.contains('struct') || source.contains('3d')) {
      return 'Structural Model';
    }
    if (source.contains('hvac') || source.contains('electrical')) {
      return 'MEP Model';
    }
    return 'Technical Model';
  }

  static String _interfaceTypeFor(String name, String responsibility) {
    final source = '$name $responsibility'.toLowerCase();
    if (source.contains('joint') ||
        source.contains('steel') ||
        source.contains('truss')) {
      return 'Physical Joint';
    }
    return 'API';
  }
}

class _ModelFileItem {
  const _ModelFileItem({
    required this.name,
    required this.modelType,
    required this.view,
    required this.status,
  });

  final String name;
  final String modelType;
  final String view;
  final String status;
}

class _SignoffItem {
  const _SignoffItem({
    required this.discipline,
    required this.engineerName,
    required this.status,
    required this.stamp,
  });

  final String discipline;
  final String engineerName;
  final String status;
  final String stamp;
}

class _InterfaceSpecItem {
  const _InterfaceSpecItem({
    required this.interfaceId,
    required this.type,
    required this.specification,
  });

  final String interfaceId;
  final String type;
  final String specification;
}

class _CalculationItem {
  const _CalculationItem({
    required this.subject,
    required this.result,
    required this.document,
  });

  final String subject;
  final String result;
  final String document;
}

class _DatasheetItem {
  const _DatasheetItem({
    required this.component,
    required this.attributes,
    required this.datasheet,
  });

  final String component;
  final String attributes;
  final String datasheet;
}

class _ComplianceItem {
  const _ComplianceItem({
    required this.standard,
    required this.status,
  });

  final String standard;
  final String status;
}

enum _SimulationPreviewType { heatMap, stress, signal }

class _SimulationItem {
  const _SimulationItem({
    required this.title,
    required this.caption,
    required this.outcome,
    required this.previewType,
    required this.colors,
  });

  final String title;
  final String caption;
  final String outcome;
  final _SimulationPreviewType previewType;
  final List<Color> colors;
}

class _EcnItem {
  const _EcnItem({
    required this.id,
    required this.reason,
    required this.impact,
  });

  final String id;
  final String reason;
  final String impact;
}

class _StressPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final linePaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..strokeWidth = 3;
    final warningPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 5;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    canvas.drawRRect(rect, borderPaint);
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.78),
      Offset(size.width * 0.44, size.height * 0.22),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.44, size.height * 0.22),
      Offset(size.width * 0.82, size.height * 0.72),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.62),
      Offset(size.width * 0.7, size.height * 0.62),
      warningPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoreLayerItem {
  final String id;
  final String name;
  final String description;

  _CoreLayerItem({
    required this.id,
    required this.name,
    required this.description,
  });

  _CoreLayerItem copyWith({String? name, String? description}) {
    return _CoreLayerItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
      };

  static List<_CoreLayerItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _CoreLayerItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: map['name']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
      );
    }).toList();
  }
}

class _ComponentItem {
  final String id;
  final String name;
  final String responsibility;
  final String statusLabel;

  _ComponentItem({
    required this.id,
    required this.name,
    required this.responsibility,
    required this.statusLabel,
  });

  _ComponentItem copyWith({
    String? name,
    String? responsibility,
    String? statusLabel,
  }) {
    return _ComponentItem(
      id: id,
      name: name ?? this.name,
      responsibility: responsibility ?? this.responsibility,
      statusLabel: statusLabel ?? this.statusLabel,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'responsibility': responsibility,
        'statusLabel': statusLabel,
      };

  static List<_ComponentItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ComponentItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: map['name']?.toString() ?? '',
        responsibility: map['responsibility']?.toString() ?? '',
        statusLabel: map['statusLabel']?.toString() ?? 'Defined',
      );
    }).toList();
  }
}

class _ReadinessItem {
  final String id;
  final String title;
  final String description;
  final String owner;

  _ReadinessItem({
    required this.id,
    required this.title,
    required this.description,
    required this.owner,
  });

  _ReadinessItem copyWith({String? title, String? description, String? owner}) {
    return _ReadinessItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      owner: owner ?? this.owner,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'owner': owner,
      };

  static List<_ReadinessItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ReadinessItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
      );
    }).toList();
  }
}

InputDecoration _inlineInputDecoration(String hint) {
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFFFD700)),
    ),
  );
}

class _Debouncer {
  _Debouncer({Duration? delay})
      : delay = delay ?? const Duration(milliseconds: 700);

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
