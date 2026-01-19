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
import 'package:ndu_project/providers/project_data_provider.dart';

class EngineeringDesignScreen extends StatefulWidget {
  const EngineeringDesignScreen({super.key});

  @override
  State<EngineeringDesignScreen> createState() => _EngineeringDesignScreenState();
}

class _EngineeringDesignScreenState extends State<EngineeringDesignScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _keyDecisionsController = TextEditingController();
  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;

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

  @override
  void initState() {
    super.initState();
    _coreLayers = _defaultCoreLayers();
    _components = _defaultComponents();
    _readinessItems = _defaultReadinessItems();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
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
    try {
      final doc = await _docFor(projectId).get();
      final data = doc.data() ?? {};
      _suspendSave = true;
      if (!mounted) return;
      setState(() {
        _notesController.text = data['notes']?.toString() ?? '';
        _keyDecisionsController.text = data['keyDecisions']?.toString() ?? '';
        final layers = _CoreLayerItem.fromList(data['coreLayers']);
        final components = _ComponentItem.fromList(data['components']);
        final readiness = _ReadinessItem.fromList(data['readinessItems']);
        _coreLayers = layers.isEmpty ? _defaultCoreLayers() : layers;
        _components = components.isEmpty ? _defaultComponents() : components;
        _readinessItems = readiness.isEmpty ? _defaultReadinessItems() : readiness;
      });
    } catch (error) {
      debugPrint('Engineering design load error: $error');
    } finally {
      _suspendSave = false;
      if (mounted) setState(() => _isLoading = false);
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
    } catch (error) {
      debugPrint('Engineering design save error: $error');
    }
  }

  List<_CoreLayerItem> _defaultCoreLayers() {
    return [
      _CoreLayerItem(id: _newId(), name: 'Presentation layer', description: 'Web & mobile'),
      _CoreLayerItem(id: _newId(), name: 'Service layer', description: 'APIs & orchestration'),
      _CoreLayerItem(id: _newId(), name: 'Data layer', description: 'OLTP + analytics'),
    ];
  }

  List<_ComponentItem> _defaultComponents() {
    return [
      _ComponentItem(
        id: _newId(),
        name: 'Auth service',
        responsibility: 'Identity, SSO, tokens',
        statusLabel: 'Defined',
      ),
      _ComponentItem(
        id: _newId(),
        name: 'Order service',
        responsibility: 'Order lifecycle & rules',
        statusLabel: 'In review',
      ),
      _ComponentItem(
        id: _newId(),
        name: 'Reporting engine',
        responsibility: 'Aggregations & exports',
        statusLabel: 'Draft',
      ),
      _ComponentItem(
        id: _newId(),
        name: 'Integration hub',
        responsibility: 'External systems & webhooks',
        statusLabel: 'Planned',
      ),
    ];
  }

  List<_ReadinessItem> _defaultReadinessItems() {
    return [
      _ReadinessItem(
        id: _newId(),
        title: 'Architecture review',
        description: 'Validate target architecture & non-functionals',
        owner: 'Lead architect',
      ),
      _ReadinessItem(
        id: _newId(),
        title: 'Component design freeze',
        description: 'Lock interfaces & data contracts',
        owner: 'Domain engineers',
      ),
      _ReadinessItem(
        id: _newId(),
        title: 'Implementation kickoff',
        description: 'Handover to dev squads',
        owner: 'Tech lead',
      ),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _updateCoreLayer(_CoreLayerItem updated) {
    final index = _coreLayers.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _coreLayers[index] = updated);
    _scheduleSave();
  }

  void _addCoreLayer() {
    setState(() {
      _coreLayers.add(_CoreLayerItem(id: _newId(), name: '', description: ''));
    });
    _scheduleSave();
  }

  void _removeCoreLayer(String id) {
    setState(() => _coreLayers.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _updateComponent(_ComponentItem updated) {
    final index = _components.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _components[index] = updated);
    _scheduleSave();
  }

  void _addComponent() {
    setState(() {
      _components.add(_ComponentItem(id: _newId(), name: '', responsibility: '', statusLabel: _statusOptions.first));
    });
    _scheduleSave();
  }

  void _removeComponent(String id) {
    setState(() => _components.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _updateReadiness(_ReadinessItem updated) {
    final index = _readinessItems.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _readinessItems[index] = updated);
    _scheduleSave();
  }

  void _addReadiness() {
    setState(() {
      _readinessItems.add(_ReadinessItem(id: _newId(), title: '', description: '', owner: ''));
    });
    _scheduleSave();
  }

  void _removeReadiness(String id) {
    setState(() => _readinessItems.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Engineering',
      body: Stack(
        children: [
          Column(
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
                      // Page Title
                      Text(
                        'ENGINEERING DESIGN',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: LightModeColors.accent,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Engineering the system architecture and technical blueprint',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Define the architecture, components, interfaces, and data models so developers have a clear and buildable engineering plan before coding starts.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 24),

                      // Notes Input - Dark themed with subtle border
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A3441),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.transparent, width: 0),
                        ),
                        child: TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Capture engineering notes here... design assumptions, constraints, standards, and open technical decisions.',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Helper Text
                      Text(
                        'Use this view to turn conceptual designs into concrete engineering specifications and responsibilities.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      // Three Cards - responsive layout
                      if (isMobile)
                        Column(
                          children: [
                            _buildSystemArchitectureCard(),
                            const SizedBox(height: 16),
                            _buildComponentsInterfacesCard(),
                            const SizedBox(height: 16),
                            _buildEngineeringReadinessCard(),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildSystemArchitectureCard(),
                            const SizedBox(height: 16),
                            _buildComponentsInterfacesCard(),
                            const SizedBox(height: 16),
                            _buildEngineeringReadinessCard(),
                          ],
                        ),
                      const SizedBox(height: 32),

      // Bottom Navigation
      _buildBottomNavigation(isMobile),
    ],
  ),
),
              ),
            ],
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
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
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        onChanged: (value) => _updateCoreLayer(layer.copyWith(name: value)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('core-layer-desc-${layer.id}'),
                        initialValue: layer.description,
                        decoration: _inlineInputDecoration('Responsibility'),
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        onChanged: (value) => _updateCoreLayer(layer.copyWith(description: value)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeCoreLayer(layer.id),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
              )),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addCoreLayer,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add architecture layer'),
            ),
          ),
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
            decoration: _inlineInputDecoration('Document trade-offs, constraints, and technical decisions.'),
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
        ),
        const SizedBox(height: 20),
        // Header Row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                'Component',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Responsibility',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600]),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                'Interface status',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600]),
              ),
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
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      onChanged: (value) => _updateComponent(component.copyWith(name: value)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      key: ValueKey('component-resp-${component.id}'),
                      initialValue: component.responsibility,
                      decoration: _inlineInputDecoration('Responsibility'),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      onChanged: (value) => _updateComponent(component.copyWith(responsibility: value)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusOptions.contains(component.statusLabel)
                          ? component.statusLabel
                          : _statusOptions.first,
                      decoration: _inlineInputDecoration('Status'),
                      items: _statusOptions
                          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        _updateComponent(component.copyWith(statusLabel: value));
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _removeComponent(component.id),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            )),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addComponent,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add component'),
          ),
        ),
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
                          decoration: _inlineInputDecoration('Readiness item'),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87),
                          onChanged: (value) => _updateReadiness(item.copyWith(title: value)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: ValueKey('readiness-desc-${item.id}'),
                          initialValue: item.description,
                          decoration: _inlineInputDecoration('Description'),
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          onChanged: (value) => _updateReadiness(item.copyWith(description: value)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 180,
                    child: TextFormField(
                      key: ValueKey('readiness-owner-${item.id}'),
                      initialValue: item.owner,
                      decoration: _inlineInputDecoration('Owner'),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      onChanged: (value) => _updateReadiness(item.copyWith(owner: value)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeReadiness(item.id),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 8),
        // Add engineering entry button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _addReadiness,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: Colors.grey[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Add engineering entry',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Export button
        Center(
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side:
                  const BorderSide(color: LightModeColors.accent, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export engineering blueprint'),
          ),
        ),
      ],
    ),
  );

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

  Widget _buildBottomNavigation(bool isMobile) => Column(
    children: [
      if (isMobile)
        Column(
          children: [
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/${AppRoutes.uiUxDesign}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back: Backend design'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Design phase · Engineering Design',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go('/${AppRoutes.technicalDevelopment}'),
                style: FilledButton.styleFrom(
                  backgroundColor: LightModeColors.accent,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next: Engineering Design'),
              ),
            ),
          ],
        )
      else
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go('/${AppRoutes.uiUxDesign}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back: Backend design'),
            ),
            const SizedBox(width: 16),
            Text(
              'Design phase · Engineering Design',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => context.go('/${AppRoutes.technicalDevelopment}'),
              style: FilledButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Next: Engineering Design'),
            ),
          ],
        ),
      const SizedBox(height: 24),
      // Tip section
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 18, color: LightModeColors.accent),
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
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
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
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
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
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
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
      borderSide: const BorderSide(color: Color(0xFF2563EB)),
    ),
  );
}

class _Debouncer {
  _Debouncer({Duration? delay}) : delay = delay ?? const Duration(milliseconds: 700);

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
