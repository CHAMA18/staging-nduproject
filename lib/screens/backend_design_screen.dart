import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/architecture_service.dart';
import 'package:ndu_project/services/activity_log_service.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
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
  final TextEditingController _architectureSummaryController =
      TextEditingController();
  final TextEditingController _databaseSummaryController =
      TextEditingController();
  final TextEditingController _quickComponentNameController =
      TextEditingController();
  final TextEditingController _quickComponentResponsibilityController =
      TextEditingController();
  final TextEditingController _quickEntityNameController =
      TextEditingController();
  final TextEditingController _quickEntityPrimaryKeyController =
      TextEditingController();
  final TextEditingController _quickEntityDescriptionController =
      TextEditingController();

  final List<_ArchitectureComponent> _components = [];
  final List<_ArchitectureDataFlow> _dataFlows = [];
  final List<_DesignDocument> _designDocuments = [];
  final List<_DbEntity> _entities = [];
  final List<_DbField> _fields = [];

  final _Debouncer _saveDebounce = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;
  bool _didSeedDefaults = false;
  bool _registersExpanded = false;
  Map<String, dynamic>? _architectureWorkspace;

  final List<String> _componentTypes = const [
    'Client',
    'Service',
    'Data store',
    'Integration',
    'Queue',
    'Analytics'
  ];
  final List<String> _componentStatuses = const [
    'Planned',
    'In progress',
    'Live',
    'Deprecated'
  ];
  final List<String> _protocolOptions = const [
    'HTTP',
    'gRPC',
    'Event',
    'Batch',
    'Streaming'
  ];
  final List<String> _documentStatuses = const [
    'Draft',
    'In review',
    'Approved',
    'Deprecated'
  ];
  String _quickComponentType = 'Service';
  String _quickComponentStatus = 'Planned';
  String _quickComponentOwner = 'Platform';
  String _quickEntityOwner = 'Operations';

  List<String> _ownerOptions({String? currentValue}) {
    final data = ProjectDataHelper.getData(context);
    final members = data.teamMembers;
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

  @override
  void initState() {
    super.initState();
    _architectureSummaryController.addListener(_scheduleSave);
    _databaseSummaryController.addListener(_scheduleSave);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final projectId = _projectId();
      if (projectId != null && projectId.isNotEmpty) {
        await ProjectNavigationService.instance.saveLastPage(
          projectId,
          'backend-design',
        );
      }
      await _loadFromFirestore();
    });
  }

  @override
  void dispose() {
    _architectureSummaryController.dispose();
    _databaseSummaryController.dispose();
    _quickComponentNameController.dispose();
    _quickComponentResponsibilityController.dispose();
    _quickEntityNameController.dispose();
    _quickEntityPrimaryKeyController.dispose();
    _quickEntityDescriptionController.dispose();
    _saveDebounce.dispose();
    super.dispose();
  }

  String _defaultArchitectureSummary() {
    return 'Invisible architecture covering cloud services, venue plant systems, vendor handoffs, and the operational backbone that supports the visible experience.';
  }

  String _defaultDatabaseSummary() {
    return 'Information architecture for users, guest lists, stock, access control, and operational events flowing from capture to storage and reporting.';
  }

  List<_ArchitectureComponent> _defaultComponents() {
    return [
      _ArchitectureComponent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'API Gateway',
        type: 'Service',
        responsibility:
            'Routes app traffic, ticket scans, and vendor callbacks.',
        owner: 'Platform',
        status: 'Planned',
      ),
      _ArchitectureComponent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'Operational Data Store',
        type: 'Data store',
        responsibility:
            'Stores guest records, material stock, and audit events.',
        owner: 'Data',
        status: 'Planned',
      ),
      _ArchitectureComponent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'Venue Power Grid',
        type: 'Integration',
        responsibility:
            'Feeds registration desks, stage systems, and back-of-house loads.',
        owner: 'Venue Ops',
        status: 'In progress',
      ),
      _ArchitectureComponent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'HVAC Monitoring',
        type: 'Analytics',
        responsibility:
            'Tracks thermal load and occupancy comfort during peak periods.',
        owner: 'Facilities',
        status: 'Planned',
      ),
    ];
  }

  List<_ArchitectureDataFlow> _defaultDataFlows() {
    return [
      _ArchitectureDataFlow(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        source: 'Ticket Scanner',
        destination: 'API Gateway',
        protocol: 'HTTP',
        notes: 'Scan payload in, validation result out.',
      ),
      _ArchitectureDataFlow(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        source: 'Guest Registration Form',
        destination: 'Operational Data Store',
        protocol: 'Event',
        notes:
            'Guest profile, dietary data, and access class persist for operations.',
      ),
      _ArchitectureDataFlow(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        source: 'Fire Alarm Panel',
        destination: 'Sprinkler and Ops Escalation',
        protocol: 'Batch',
        notes: 'Manual handoff fallback if automation path is unavailable.',
      ),
    ];
  }

  List<_DesignDocument> _defaultDocuments() {
    return [
      _DesignDocument(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'Service topology pack',
        description:
            'Cloud services, auth boundary, and vendor integration map.',
        owner: 'Architecture',
        status: 'Draft',
        location: 'AWS Cloud / Architecture repo',
      ),
      _DesignDocument(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: 'Back-of-house operations layout',
        description:
            'Power, comms, storage, and logistics zones behind the customer-facing experience.',
        owner: 'Operations',
        status: 'In review',
        location: 'Venue operations folder',
      ),
    ];
  }

  List<_DbEntity> _defaultEntities() {
    return [
      _DbEntity(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'GuestList',
        primaryKey: 'guest_id',
        owner: 'Operations',
        description:
            'Guest identity, access class, dietary restrictions, and arrival status.',
      ),
      _DbEntity(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'MaterialStock',
        primaryKey: 'stock_id',
        owner: 'Procurement',
        description:
            'Materials, quantities, storage location, and issue history.',
      ),
      _DbEntity(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: 'AccessCredential',
        primaryKey: 'credential_id',
        owner: 'Security',
        description: 'Backstage passes, wristbands, and zone permissions.',
      ),
    ];
  }

  List<_DbField> _defaultFields() {
    return [
      _DbField(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        table: 'GuestList',
        field: 'dietary_restriction',
        type: 'string',
        constraints: 'nullable',
        notes: 'Shared with catering 2 hours before service.',
      ),
      _DbField(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        table: 'MaterialStock',
        field: 'weight_kg',
        type: 'decimal',
        constraints: '>= 0',
        notes: 'Used for load-bearing and transport planning.',
      ),
      _DbField(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        table: 'AccessCredential',
        field: 'zone_access',
        type: 'array',
        constraints: 'required',
        notes: 'Maps digital roles to physical access zones.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);
    final projectData = ProjectDataHelper.getData(context);
    final snapshot = _BackendInfrastructureSnapshot.from(
      projectData: projectData,
      architectureWorkspace: _architectureWorkspace,
      architectureSummary: _architectureSummaryController.text,
      databaseSummary: _databaseSummaryController.text,
      components: _components,
      dataFlows: _dataFlows,
      documents: _designDocuments,
      entities: _entities,
      fields: _fields,
    );

    return ResponsiveScaffold(
      activeItemLabel: 'Backend Design',
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Backend Design',
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
                  if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 24),
                  _buildInfrastructureHero(
                    isMobile: isMobile,
                    snapshot: snapshot,
                  ),
                  const SizedBox(height: 24),
                  _buildInfrastructureTopSection(snapshot, isMobile),
                  const SizedBox(height: 20),
                  _buildContractsAndSecuritySection(snapshot, isMobile),
                  const SizedBox(height: 20),
                  _buildOperationsGrid(snapshot),
                  const SizedBox(height: 20),
                  _buildDetailedRegistersPanel(),
                  const SizedBox(height: 28),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: UI/UX Design',
                    nextLabel: 'Next: Engineering',
                    onBack: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UiUxDesignScreen())),
                    onNext: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EngineeringDesignScreen())),
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
    if (mounted) setState(() => _isLoading = true);
    bool shouldSeedDefaults = false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('design_phase_sections')
          .doc('backend_design')
          .get();
      final architectureWorkspace = await ArchitectureService.load(projectId);
      final data = doc.data() ?? {};
      final architecture =
          Map<String, dynamic>.from(data['architecture'] ?? {});
      final database = Map<String, dynamic>.from(data['database'] ?? {});
      shouldSeedDefaults = data.isEmpty && !_didSeedDefaults;

      _suspendSave = true;
      final components =
          _ArchitectureComponent.fromList(architecture['components']);
      final flows = _ArchitectureDataFlow.fromList(architecture['dataFlows']);
      final documents = _DesignDocument.fromList(architecture['documents']);
      final entities = _DbEntity.fromList(database['entities']);
      final fields = _DbField.fromList(database['fields']);

      if (!mounted) return;
      setState(() {
        _architectureWorkspace = architectureWorkspace;
        if (shouldSeedDefaults) {
          _didSeedDefaults = true;
          _architectureSummaryController.text = _defaultArchitectureSummary();
          _databaseSummaryController.text = _defaultDatabaseSummary();
          _components
            ..clear()
            ..addAll(_defaultComponents());
          _dataFlows
            ..clear()
            ..addAll(_defaultDataFlows());
          _designDocuments
            ..clear()
            ..addAll(_defaultDocuments());
          _entities
            ..clear()
            ..addAll(_defaultEntities());
          _fields
            ..clear()
            ..addAll(_defaultFields());
        } else {
          _architectureSummaryController.text =
              architecture['summary']?.toString() ?? '';
          _databaseSummaryController.text =
              database['summary']?.toString() ?? '';
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
        }
      });
    } catch (error) {
      debugPrint('Failed to load backend design data: $error');
    } finally {
      _suspendSave = false;
      if (mounted) setState(() => _isLoading = false);
      if (shouldSeedDefaults) _scheduleSave();
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

    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('design_phase_sections')
          .doc('backend_design')
          .set(payload, SetOptions(merge: true));
      await ActivityLogService.instance.logActivity(
        projectId: projectId,
        phase: 'Design Phase',
        page: 'Backend Design',
        action: 'Updated Backend Design data',
      );
    } catch (error) {
      debugPrint('Backend design save error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save Backend Design changes right now. Please try again.',
          ),
        ),
      );
    }
  }

  void _logActivity(String action, {Map<String, dynamic>? details}) {
    final projectId = _projectId()?.trim() ?? '';
    if (projectId.isEmpty) return;
    unawaited(
      ActivityLogService.instance.logActivity(
        projectId: projectId,
        phase: 'Design Phase',
        page: 'Backend Design',
        action: action,
        details: details,
      ),
    );
  }

  Widget _buildInfrastructureHero({
    required bool isMobile,
    required _BackendInfrastructureSnapshot snapshot,
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
            'Hidden Infrastructure & Operational Logic',
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Backend Design for ${snapshot.projectLabel}. This hub captures the invisible architecture behind the customer experience: system topology, data movement, interface contracts, security, business rules, operational load, vendor support, and deployment path.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.5,
            ),
          ),
          if (_architectureSummaryController.text.trim().isNotEmpty ||
              _databaseSummaryController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: Text(
                [
                  _architectureSummaryController.text.trim(),
                  _databaseSummaryController.text.trim(),
                ].where((value) => value.isNotEmpty).join('\n\n'),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.45,
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroMetricPill(
                  'Architecture Nodes', '${snapshot.systemNodes.length}'),
              _buildHeroMetricPill(
                  'Data Entities', '${snapshot.dataEntities.length}'),
              _buildHeroMetricPill('Interface Contracts',
                  '${snapshot.interfaceContracts.length}'),
              _buildHeroMetricPill(
                  'Vendors', '${snapshot.vendorDependencies.length}'),
              _buildHeroMetricPill('AI Signals', '${snapshot.aiSignalCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfrastructureTopSection(
    _BackendInfrastructureSnapshot snapshot,
    bool isMobile,
  ) {
    return Column(
      children: [
        _buildSystemArchitecturePanel(snapshot),
        const SizedBox(height: 20),
        _buildDataArchitecturePanel(snapshot),
      ],
    );
  }

  Widget _buildContractsAndSecuritySection(
    _BackendInfrastructureSnapshot snapshot,
    bool isMobile,
  ) {
    return Column(
      children: [
        _buildInterfaceContractsPanel(snapshot),
        const SizedBox(height: 20),
        _buildSecurityAccessPanel(snapshot),
      ],
    );
  }

  Widget _buildOperationsGrid(_BackendInfrastructureSnapshot snapshot) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 20.0;
        final columns = constraints.maxWidth >= 1080
            ? 2
            : constraints.maxWidth >= 760
                ? 2
                : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final cards = [
          _buildBusinessLogicPanel(snapshot),
          _buildPerformancePanel(snapshot),
          _buildVendorDependenciesPanel(snapshot),
          _buildPipelinePanel(snapshot),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              cards.map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
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
            'Edit the architecture, data, and document registers feeding the dashboard above.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          children: [
            _buildArchitectureCard(),
            const SizedBox(height: 16),
            _buildDatabaseCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemArchitecturePanel(
      _BackendInfrastructureSnapshot snapshot) {
    final ownerOptions = _ownerOptions(currentValue: _quickComponentOwner);
    return _buildDashboardPanel(
      title: 'System Architecture & Structural Framework',
      subtitle:
          'High-level component map showing where the hidden system lives and how services or structural systems connect.',
      icon: Icons.account_tree_outlined,
      accent: const Color(0xFF1D4ED8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 760;
              final visibleNodes = snapshot.systemNodes.take(4).toList();
              if (stacked) {
                return Column(
                  children: List.generate(visibleNodes.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == visibleNodes.length - 1 ? 0 : 12,
                      ),
                      child: Column(
                        children: [
                          _buildSystemNodeCard(visibleNodes[index]),
                          if (index != visibleNodes.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Icon(Icons.arrow_downward_rounded,
                                  color: Color(0xFF64748B)),
                            ),
                        ],
                      ),
                    );
                  }),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(visibleNodes.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == visibleNodes.length - 1 ? 0 : 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildSystemNodeCard(visibleNodes[index])),
                          if (index != visibleNodes.length - 1) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.east_rounded,
                                color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            'Connections',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          ...snapshot.systemLinks.map(
            (link) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link.from,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const Icon(Icons.east_rounded, color: Color(0xFF64748B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      link.to,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(link.location, const Color(0xFF1D4ED8)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildInlineComposerCard(
            icon: Icons.add_business_rounded,
            accent: const Color(0xFF1D4ED8),
            title: 'Quick add architecture component',
            subtitle:
                'Capture a new service, integration, or infrastructure block directly in the architecture view.',
            child: Column(
              children: [
                _buildComposerTextField(
                  controller: _quickComponentNameController,
                  label: 'Component name',
                  hint: 'e.g. Access Control Service',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildComposerDropdown(
                        label: 'Type',
                        value: _quickComponentType,
                        items: _componentTypes,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _quickComponentType = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildComposerDropdown(
                        label: 'Status',
                        value: _quickComponentStatus,
                        items: _componentStatuses,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _quickComponentStatus = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildComposerDropdown(
                  label: 'Owner',
                  value: _quickComponentOwner,
                  items: ownerOptions,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _quickComponentOwner = value);
                  },
                ),
                const SizedBox(height: 12),
                _buildComposerTextField(
                  controller: _quickComponentResponsibilityController,
                  label: 'Responsibility',
                  hint: 'Describe what this component owns or enables.',
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _addQuickArchitectureComponent,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Component'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataArchitecturePanel(_BackendInfrastructureSnapshot snapshot) {
    final ownerOptions = _ownerOptions(currentValue: _quickEntityOwner);
    return _buildDashboardPanel(
      title: 'Data Architecture & Information Flow',
      subtitle:
          'Entity and attribute view for the information backbone behind operations and delivery.',
      icon: Icons.dataset_outlined,
      accent: const Color(0xFF0F766E),
      child: Column(
        children: [
          ...snapshot.dataEntities.map(
            (entity) => Container(
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
                          entity.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      _buildStatusBadge(
                          entity.flowLabel, const Color(0xFF0F766E)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entity.attributes
                        .map((attribute) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                attribute,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    entity.flowDetail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildInlineComposerCard(
            icon: Icons.dataset_linked_rounded,
            accent: const Color(0xFF0F766E),
            title: 'Quick add data entity',
            subtitle:
                'Add the next entity and its core key from the information flow panel itself.',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildComposerTextField(
                        controller: _quickEntityNameController,
                        label: 'Entity name',
                        hint: 'e.g. DispatchLedger',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildComposerTextField(
                        controller: _quickEntityPrimaryKeyController,
                        label: 'Primary key',
                        hint: 'e.g. dispatch_id',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildComposerDropdown(
                  label: 'Owner',
                  value: _quickEntityOwner,
                  items: ownerOptions,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _quickEntityOwner = value);
                  },
                ),
                const SizedBox(height: 12),
                _buildComposerTextField(
                  controller: _quickEntityDescriptionController,
                  label: 'Description',
                  hint: 'Summarize the entity purpose and operational flow.',
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _addQuickDataEntity,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Entity'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceContractsPanel(
      _BackendInfrastructureSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'API & Interface Contracts',
      subtitle:
          'Specification list for technical integrations and operational handoff agreements.',
      icon: Icons.cable_outlined,
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
                    'Interface Name',
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
                    'Method/Protocol',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Input / Output',
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
          for (int i = 0; i < snapshot.interfaceContracts.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      snapshot.interfaceContracts[i].name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      snapshot.interfaceContracts[i].method,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Text(
                      snapshot.interfaceContracts[i].ioDescription,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != snapshot.interfaceContracts.length - 1)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityAccessPanel(_BackendInfrastructureSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Security & Access Control Logic',
      subtitle:
          'Matrix of roles, permissions, and protection protocols across digital and physical access.',
      icon: Icons.shield_outlined,
      accent: const Color(0xFF0F766E),
      child: Column(
        children: snapshot.accessRules
            .map(
              (rule) => Container(
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
                        rule.role,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(
                        rule.permission,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _buildStatusBadge(
                          rule.protocol,
                          const Color(0xFF1D4ED8),
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

  Widget _buildBusinessLogicPanel(_BackendInfrastructureSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Business Logic & Rule Engine',
      subtitle:
          'Server-side, operational, and safety rules that decide what happens when conditions change.',
      icon: Icons.rule_outlined,
      accent: const Color(0xFF1D4ED8),
      child: Column(
        children: snapshot.logicRules
            .map(
              (rule) => Container(
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
                      rule.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'IF ${rule.condition}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'THEN ${rule.action}',
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

  Widget _buildPerformancePanel(_BackendInfrastructureSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Performance & Scalability Strategy',
      subtitle:
          'Load handling, resilience, and capacity strategy for software and physical infrastructure.',
      icon: Icons.speed_outlined,
      accent: const Color(0xFF0F766E),
      child: Column(
        children: snapshot.performanceStrategies
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
                            item.metric,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        _buildStatusBadge(item.target, const Color(0xFF1D4ED8)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.strategy,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF334155),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.context,
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

  Widget _buildVendorDependenciesPanel(
      _BackendInfrastructureSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Third-Party Services & Vendor Dependencies',
      subtitle:
          'External services, contracts, and support providers needed to make the backend or operations layer work.',
      icon: Icons.handshake_outlined,
      accent: const Color(0xFF1D4ED8),
      child: Column(
        children: snapshot.vendorDependencies
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
                        item.service,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.purpose,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(
                        item.status, _vendorStatusColor(item.status)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPipelinePanel(_BackendInfrastructureSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'DevOps & Deployment Pipeline',
      subtitle:
          'Implementation path from internal design validation through production or on-site activation.',
      icon: Icons.alt_route_outlined,
      accent: const Color(0xFF0F766E),
      child: Column(
        children: List.generate(snapshot.pipelineStages.length, (index) {
          final stage = snapshot.pipelineStages[index];
          return Container(
            margin: EdgeInsets.only(
              bottom: index == snapshot.pipelineStages.length - 1 ? 0 : 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D4ED8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (index != snapshot.pipelineStages.length - 1)
                      Container(
                        width: 2,
                        height: 54,
                        color: const Color(0xFFCBD5E1),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
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
                                stage.environment,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            _buildStatusBadge(
                              stage.label,
                              const Color(0xFF0F766E),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stage.steps,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
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
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
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

  Widget _buildInlineComposerCard({
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.08),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildComposerTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.4,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComposerDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD8E1EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.4,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroMetricPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.72),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
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

  Widget _buildSystemNodeCard(_SystemNodeItem node) {
    return Container(
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
            node.name,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            node.hostLocation,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusBadge(node.type, const Color(0xFF1D4ED8)),
              _buildStatusBadge(node.status, _statusColor(node.status)),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
      case 'Ready':
      case 'Live':
      case 'Contract Signed':
      case 'API Key Ready':
        return AppSemanticColors.success;
      case 'In review':
      case 'In progress':
      case 'Draft':
        return AppSemanticColors.warning;
      default:
        return const Color(0xFF1D4ED8);
    }
  }

  Color _vendorStatusColor(String status) {
    switch (status) {
      case 'Contract Signed':
      case 'API Key Ready':
        return AppSemanticColors.success;
      case 'Pending':
      case 'Identified':
        return AppSemanticColors.warning;
      default:
        return const Color(0xFF1D4ED8);
    }
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
            hintText:
                'Describe the overall backend topology, critical services, and integration patterns.',
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
            hintText:
                'Capture key database decisions, scaling approach, and indexing strategy.',
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

  Future<void> _addComponent() => _openComponentDialog();

  void _updateComponent(_ArchitectureComponent updated) {
    final index = _components.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    setState(() => _components[index] = updated);
    _scheduleSave();
  }

  void _deleteComponent(String id) {
    setState(() => _components.removeWhere((entry) => entry.id == id));
    _scheduleSave();
    _logActivity('Deleted architecture component row', details: {'itemId': id});
  }

  void _addQuickArchitectureComponent() {
    final name = _quickComponentNameController.text.trim();
    final responsibility = _quickComponentResponsibilityController.text.trim();
    final owner = _quickComponentOwner.trim();
    if (name.isEmpty || responsibility.isEmpty || owner.isEmpty) return;

    setState(() {
      _components.add(
        _ArchitectureComponent(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          type: _quickComponentType,
          responsibility: responsibility,
          owner: owner,
          status: _quickComponentStatus,
        ),
      );
      _quickComponentNameController.clear();
      _quickComponentResponsibilityController.clear();
      _quickComponentType = _componentTypes.first;
      _quickComponentStatus = _componentStatuses.first;
    });
    _scheduleSave();
    _logActivity('Added architecture component row', details: {'name': name});
  }

  Future<void> _addDataFlow() => _openDataFlowDialog();

  void _updateDataFlow(_ArchitectureDataFlow updated) {
    final index = _dataFlows.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    setState(() => _dataFlows[index] = updated);
    _scheduleSave();
  }

  void _deleteDataFlow(String id) {
    setState(() => _dataFlows.removeWhere((entry) => entry.id == id));
    _scheduleSave();
    _logActivity('Deleted data flow row', details: {'itemId': id});
  }

  Future<void> _addDesignDocument() => _openDesignDocumentDialog();

  void _updateDesignDocument(_DesignDocument updated) {
    final index =
        _designDocuments.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    setState(() => _designDocuments[index] = updated);
    _scheduleSave();
  }

  void _deleteDesignDocument(String id) {
    setState(() => _designDocuments.removeWhere((entry) => entry.id == id));
    _scheduleSave();
    _logActivity('Deleted design document row', details: {'itemId': id});
  }

  Future<void> _addEntity() => _openEntityDialog();

  void _updateEntity(_DbEntity updated) {
    final index = _entities.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    setState(() => _entities[index] = updated);
    _scheduleSave();
  }

  void _deleteEntity(String id) {
    setState(() => _entities.removeWhere((entry) => entry.id == id));
    _scheduleSave();
    _logActivity('Deleted data entity row', details: {'itemId': id});
  }

  void _addQuickDataEntity() {
    final name = _quickEntityNameController.text.trim();
    final primaryKey = _quickEntityPrimaryKeyController.text.trim();
    final owner = _quickEntityOwner.trim();
    final description = _quickEntityDescriptionController.text.trim();
    if (name.isEmpty ||
        primaryKey.isEmpty ||
        owner.isEmpty ||
        description.isEmpty) {
      return;
    }

    setState(() {
      _entities.add(
        _DbEntity(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: name,
          primaryKey: primaryKey,
          owner: owner,
          description: description,
        ),
      );
      _quickEntityNameController.clear();
      _quickEntityPrimaryKeyController.clear();
      _quickEntityDescriptionController.clear();
    });
    _scheduleSave();
    _logActivity('Added quick data entity row', details: {'name': name});
  }

  Future<void> _addField() => _openFieldDialog();

  Future<void> _openComponentDialog({_ArchitectureComponent? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final responsibilityController =
        TextEditingController(text: existing?.responsibility ?? '');
    final ownerOptions = _ownerOptions(currentValue: existing?.owner);
    String type = existing?.type ?? _componentTypes.first;
    String owner = existing?.owner.isNotEmpty == true
        ? existing!.owner
        : ownerOptions.first;
    String status = existing?.status ?? _componentStatuses.first;
    final saved = await _showBackendDialog(
      title: existing == null ? 'Add architecture component' : 'Edit component',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
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
            DropdownButtonFormField<String>(
              initialValue: type,
              items: _componentTypes
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() => type = value);
              },
              decoration: const InputDecoration(
                labelText: 'Component type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: responsibilityController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Responsibility',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: owner,
              items: ownerOptions
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() => owner = value);
              },
              decoration: const InputDecoration(
                labelText: 'Owner',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: status,
              items: _componentStatuses
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() => status = value);
              },
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      confirmLabel: existing == null ? 'Add component' : 'Save changes',
    );
    if (saved != true) return;

    final item = _ArchitectureComponent(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      type: type,
      responsibility: responsibilityController.text.trim(),
      owner: owner,
      status: status,
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
      existing == null
          ? 'Added architecture component row'
          : 'Edited architecture component row',
      details: {'itemId': item.id, 'name': item.name},
    );
  }

  Future<void> _openDataFlowDialog({_ArchitectureDataFlow? existing}) async {
    final sourceController =
        TextEditingController(text: existing?.source ?? '');
    final destinationController =
        TextEditingController(text: existing?.destination ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String protocol = existing?.protocol ?? _protocolOptions.first;
    final saved = await _showBackendDialog(
      title: existing == null ? 'Add data flow' : 'Edit data flow',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sourceController,
              decoration: const InputDecoration(
                labelText: 'Source',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: protocol,
              items: _protocolOptions
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() => protocol = value);
              },
              decoration: const InputDecoration(
                labelText: 'Protocol',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      confirmLabel: existing == null ? 'Add flow' : 'Save changes',
    );
    if (saved != true) return;

    final item = _ArchitectureDataFlow(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      source: sourceController.text.trim(),
      destination: destinationController.text.trim(),
      protocol: protocol,
      notes: notesController.text.trim(),
    );
    setState(() {
      if (existing == null) {
        _dataFlows.add(item);
      } else {
        final index = _dataFlows.indexWhere((entry) => entry.id == existing.id);
        if (index != -1) _dataFlows[index] = item;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null ? 'Added data flow row' : 'Edited data flow row',
      details: {'itemId': item.id},
    );
  }

  Future<void> _openDesignDocumentDialog({_DesignDocument? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final locationController =
        TextEditingController(text: existing?.location ?? '');
    final ownerOptions = _ownerOptions(currentValue: existing?.owner);
    String owner = existing?.owner.isNotEmpty == true
        ? existing!.owner
        : ownerOptions.first;
    String status = existing?.status ?? _documentStatuses.first;
    final saved = await _showBackendDialog(
      title: existing == null ? 'Add design document' : 'Edit design document',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Document title',
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
              initialValue: owner,
              items: ownerOptions
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() => owner = value);
              },
              decoration: const InputDecoration(
                labelText: 'Owner',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: status,
              items: _documentStatuses
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() => status = value);
              },
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Link or location',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      confirmLabel: existing == null ? 'Add document' : 'Save changes',
    );
    if (saved != true) return;

    final item = _DesignDocument(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      owner: owner,
      status: status,
      location: locationController.text.trim(),
    );
    setState(() {
      if (existing == null) {
        _designDocuments.add(item);
      } else {
        final index =
            _designDocuments.indexWhere((entry) => entry.id == existing.id);
        if (index != -1) _designDocuments[index] = item;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null
          ? 'Added design document row'
          : 'Edited design document row',
      details: {'itemId': item.id},
    );
  }

  Future<void> _openEntityDialog({_DbEntity? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final primaryKeyController =
        TextEditingController(text: existing?.primaryKey ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final ownerOptions = _ownerOptions(currentValue: existing?.owner);
    String owner = existing?.owner.isNotEmpty == true
        ? existing!.owner
        : ownerOptions.first;
    final saved = await _showBackendDialog(
      title: existing == null ? 'Add data entity' : 'Edit data entity',
      content: StatefulBuilder(
        builder: (context, setDialogState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Entity / collection',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: primaryKeyController,
              decoration: const InputDecoration(
                labelText: 'Primary key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: owner,
              items: ownerOptions
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setDialogState(() => owner = value);
              },
              decoration: const InputDecoration(
                labelText: 'Owner',
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
          ],
        ),
      ),
      confirmLabel: existing == null ? 'Add entity' : 'Save changes',
    );
    if (saved != true) return;

    final item = _DbEntity(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: nameController.text.trim(),
      primaryKey: primaryKeyController.text.trim(),
      owner: owner,
      description: descriptionController.text.trim(),
    );
    setState(() {
      if (existing == null) {
        _entities.add(item);
      } else {
        final index = _entities.indexWhere((entry) => entry.id == existing.id);
        if (index != -1) _entities[index] = item;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null ? 'Added data entity row' : 'Edited data entity row',
      details: {'itemId': item.id},
    );
  }

  Future<void> _openFieldDialog({_DbField? existing}) async {
    final tableController = TextEditingController(text: existing?.table ?? '');
    final fieldController = TextEditingController(text: existing?.field ?? '');
    final typeController = TextEditingController(text: existing?.type ?? '');
    final constraintsController =
        TextEditingController(text: existing?.constraints ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final saved = await _showBackendDialog(
      title: existing == null ? 'Add field' : 'Edit field',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: tableController,
            decoration: const InputDecoration(
              labelText: 'Entity / table',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: fieldController,
            decoration: const InputDecoration(
              labelText: 'Field name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: typeController,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: constraintsController,
            decoration: const InputDecoration(
              labelText: 'Constraints',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      confirmLabel: existing == null ? 'Add field' : 'Save changes',
    );
    if (saved != true) return;

    final item = _DbField(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      table: tableController.text.trim(),
      field: fieldController.text.trim(),
      type: typeController.text.trim(),
      constraints: constraintsController.text.trim(),
      notes: notesController.text.trim(),
    );
    setState(() {
      if (existing == null) {
        _fields.add(item);
      } else {
        final index = _fields.indexWhere((entry) => entry.id == existing.id);
        if (index != -1) _fields[index] = item;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null ? 'Added field row' : 'Edited field row',
      details: {'itemId': item.id},
    );
  }

  Future<bool?> _showBackendDialog({
    required String title,
    required Widget content,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content:
            SizedBox(width: 560, child: SingleChildScrollView(child: content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
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
    _logActivity('Deleted field row', details: {'itemId': id});
  }

  Widget _buildComponentsTable() {
    final columns = [
      const _TableColumnDef('Component', 200),
      const _TableColumnDef('Type', 140),
      const _TableColumnDef('Responsibility', 240),
      const _TableColumnDef('Owner', 160),
      const _TableColumnDef('Status', 140),
      const _TableColumnDef('', 56),
      const _TableColumnDef('', 56),
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
                onChanged: (value) =>
                    _updateComponent(entry.copyWith(name: value)),
              ),
              _DropdownCell(
                value: entry.type,
                fieldKey: '${entry.id}_type',
                options: _componentTypes,
                onChanged: (value) =>
                    _updateComponent(entry.copyWith(type: value)),
              ),
              _TextCell(
                value: entry.responsibility,
                fieldKey: '${entry.id}_responsibility',
                hintText: 'Responsibility',
                maxLines: 2,
                onChanged: (value) =>
                    _updateComponent(entry.copyWith(responsibility: value)),
              ),
              _DropdownCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                options: _ownerOptions(currentValue: entry.owner),
                onChanged: (value) =>
                    _updateComponent(entry.copyWith(owner: value)),
              ),
              _DropdownCell(
                value: entry.status,
                fieldKey: '${entry.id}_status',
                options: _componentStatuses,
                onChanged: (value) =>
                    _updateComponent(entry.copyWith(status: value)),
              ),
              _EditCell(
                onPressed: () => _openComponentDialog(existing: entry),
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
      const _TableColumnDef('', 56),
      const _TableColumnDef('', 56),
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
                onChanged: (value) =>
                    _updateDataFlow(entry.copyWith(source: value)),
              ),
              _TextCell(
                value: entry.destination,
                fieldKey: '${entry.id}_destination',
                hintText: 'Destination',
                onChanged: (value) =>
                    _updateDataFlow(entry.copyWith(destination: value)),
              ),
              _DropdownCell(
                value: entry.protocol,
                fieldKey: '${entry.id}_protocol',
                options: _protocolOptions,
                onChanged: (value) =>
                    _updateDataFlow(entry.copyWith(protocol: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                maxLines: 2,
                onChanged: (value) =>
                    _updateDataFlow(entry.copyWith(notes: value)),
              ),
              _EditCell(
                onPressed: () => _openDataFlowDialog(existing: entry),
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
      const _TableColumnDef('', 56),
      const _TableColumnDef('', 56),
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
                onChanged: (value) =>
                    _updateDesignDocument(entry.copyWith(title: value)),
              ),
              _TextCell(
                value: entry.description,
                fieldKey: '${entry.id}_description',
                hintText: 'Description',
                maxLines: 2,
                onChanged: (value) =>
                    _updateDesignDocument(entry.copyWith(description: value)),
              ),
              _DropdownCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                options: _ownerOptions(currentValue: entry.owner),
                onChanged: (value) =>
                    _updateDesignDocument(entry.copyWith(owner: value)),
              ),
              _DropdownCell(
                value: entry.status,
                fieldKey: '${entry.id}_status',
                options: _documentStatuses,
                onChanged: (value) =>
                    _updateDesignDocument(entry.copyWith(status: value)),
              ),
              _TextCell(
                value: entry.location,
                fieldKey: '${entry.id}_location',
                hintText: 'Link or path',
                onChanged: (value) =>
                    _updateDesignDocument(entry.copyWith(location: value)),
              ),
              _EditCell(
                onPressed: () => _openDesignDocumentDialog(existing: entry),
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
      const _TableColumnDef('', 56),
      const _TableColumnDef('', 56),
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
                onChanged: (value) =>
                    _updateEntity(entry.copyWith(name: value)),
              ),
              _TextCell(
                value: entry.primaryKey,
                fieldKey: '${entry.id}_pk',
                hintText: 'Primary key',
                onChanged: (value) =>
                    _updateEntity(entry.copyWith(primaryKey: value)),
              ),
              _DropdownCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                options: _ownerOptions(currentValue: entry.owner),
                onChanged: (value) =>
                    _updateEntity(entry.copyWith(owner: value)),
              ),
              _TextCell(
                value: entry.description,
                fieldKey: '${entry.id}_description',
                hintText: 'Description',
                maxLines: 2,
                onChanged: (value) =>
                    _updateEntity(entry.copyWith(description: value)),
              ),
              _EditCell(
                onPressed: () => _openEntityDialog(existing: entry),
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
      const _TableColumnDef('', 56),
      const _TableColumnDef('', 56),
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
                onChanged: (value) =>
                    _updateField(entry.copyWith(table: value)),
              ),
              _TextCell(
                value: entry.field,
                fieldKey: '${entry.id}_field',
                hintText: 'Field',
                onChanged: (value) =>
                    _updateField(entry.copyWith(field: value)),
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
                onChanged: (value) =>
                    _updateField(entry.copyWith(constraints: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                maxLines: 2,
                onChanged: (value) =>
                    _updateField(entry.copyWith(notes: value)),
              ),
              _EditCell(
                onPressed: () => _openFieldDialog(existing: entry),
              ),
              _DeleteCell(onPressed: () => _deleteField(entry.id)),
            ],
          ),
      ],
    );
  }
}

class _BackendInfrastructureSnapshot {
  const _BackendInfrastructureSnapshot({
    required this.projectLabel,
    required this.systemNodes,
    required this.systemLinks,
    required this.dataEntities,
    required this.interfaceContracts,
    required this.accessRules,
    required this.logicRules,
    required this.performanceStrategies,
    required this.vendorDependencies,
    required this.pipelineStages,
    required this.aiSignalCount,
  });

  final String projectLabel;
  final List<_SystemNodeItem> systemNodes;
  final List<_SystemLinkItem> systemLinks;
  final List<_DataEntityItem> dataEntities;
  final List<_InterfaceContractItem> interfaceContracts;
  final List<_AccessRuleItem> accessRules;
  final List<_LogicRuleItem> logicRules;
  final List<_PerformanceStrategyItem> performanceStrategies;
  final List<_VendorDependencyItem> vendorDependencies;
  final List<_PipelineStageItem> pipelineStages;
  final int aiSignalCount;

  factory _BackendInfrastructureSnapshot.from({
    required ProjectDataModel projectData,
    required Map<String, dynamic>? architectureWorkspace,
    required String architectureSummary,
    required String databaseSummary,
    required List<_ArchitectureComponent> components,
    required List<_ArchitectureDataFlow> dataFlows,
    required List<_DesignDocument> documents,
    required List<_DbEntity> entities,
    required List<_DbField> fields,
  }) {
    final projectLabel = projectData.projectName.trim().isNotEmpty
        ? projectData.projectName.trim()
        : 'the current design package';
    final summaryContext =
        '$architectureSummary $databaseSummary'.toLowerCase();
    final documentLocations = documents
        .map((document) => document.location.trim())
        .where((location) => location.isNotEmpty)
        .toList();

    final workspaceNodes =
        ((architectureWorkspace?['nodes'] as List?) ?? const [])
            .whereType<Map>()
            .map((raw) => Map<String, dynamic>.from(raw))
            .toList();
    final workspaceEdges =
        ((architectureWorkspace?['edges'] as List?) ?? const [])
            .whereType<Map>()
            .map((raw) => Map<String, dynamic>.from(raw))
            .toList();

    final systemNodes = <_SystemNodeItem>[];
    if (workspaceNodes.isNotEmpty) {
      for (final node in workspaceNodes.take(5)) {
        final label = node['label']?.toString().trim() ?? '';
        if (label.isEmpty) continue;
        systemNodes.add(_SystemNodeItem(
          name: label,
          type: _typeForLabel(label),
          status: 'Mapped',
          hostLocation: documentLocations.isNotEmpty
              ? documentLocations.first
              : _hostForLabel(label),
        ));
      }
    }
    if (systemNodes.isEmpty) {
      for (final component in components.take(5)) {
        final name = component.name.trim();
        if (name.isEmpty) continue;
        systemNodes.add(_SystemNodeItem(
          name: name,
          type: component.type.trim().isNotEmpty
              ? component.type.trim()
              : 'Service',
          status: component.status.trim().isNotEmpty
              ? component.status.trim()
              : 'Planned',
          hostLocation: documentLocations.isNotEmpty
              ? documentLocations.first
              : _hostForComponent(name, component.type),
        ));
      }
    }
    if (systemNodes.isEmpty) {
      systemNodes.addAll(const [
        _SystemNodeItem(
          name: 'Database',
          type: 'Data store',
          status: 'Planned',
          hostLocation: 'AWS Cloud',
        ),
        _SystemNodeItem(
          name: 'Auth Server',
          type: 'Service',
          status: 'Planned',
          hostLocation: 'AWS Cloud',
        ),
        _SystemNodeItem(
          name: 'Power Grid',
          type: 'Integration',
          status: 'In review',
          hostLocation: 'Venue Power Grid',
        ),
        _SystemNodeItem(
          name: 'HVAC System',
          type: 'Integration',
          status: 'Planned',
          hostLocation: 'Plant Room',
        ),
      ]);
    }

    final labelById = <String, String>{
      for (final node in workspaceNodes)
        if ((node['id']?.toString().trim() ?? '').isNotEmpty)
          node['id']!.toString(): node['label']?.toString() ?? '',
    };
    final systemLinks = <_SystemLinkItem>[];
    for (final edge in workspaceEdges.take(4)) {
      final from = labelById[edge['from']?.toString() ?? ''] ?? '';
      final to = labelById[edge['to']?.toString() ?? ''] ?? '';
      if (from.isEmpty || to.isEmpty) continue;
      systemLinks.add(_SystemLinkItem(
        from: from,
        to: to,
        location: _locationForLink(from, to),
      ));
    }
    if (systemLinks.isEmpty) {
      for (final flow in dataFlows.take(4)) {
        final source = flow.source.trim();
        final destination = flow.destination.trim();
        if (source.isEmpty || destination.isEmpty) continue;
        systemLinks.add(_SystemLinkItem(
          from: source,
          to: destination,
          location: _locationForLink(source, destination),
        ));
      }
    }
    if (systemLinks.isEmpty) {
      systemLinks.addAll(const [
        _SystemLinkItem(
          from: 'API Gateway',
          to: 'Operational Data Store',
          location: 'AWS Cloud',
        ),
        _SystemLinkItem(
          from: 'Fire Alarm Panel',
          to: 'Sprinkler and Ops Escalation',
          location: 'Venue Plant Room',
        ),
      ]);
    }

    final groupedFields = <String, List<_DbField>>{};
    for (final field in fields) {
      final key = field.table.trim();
      if (key.isEmpty) continue;
      groupedFields.putIfAbsent(key, () => []).add(field);
    }

    final dataEntities = <_DataEntityItem>[];
    for (final entity in entities.take(4)) {
      final name = entity.name.trim();
      if (name.isEmpty) continue;
      final attributes = groupedFields[name]
              ?.take(3)
              .map((field) => field.field.trim())
              .where((value) => value.isNotEmpty)
              .toList() ??
          [];
      final primaryKey = entity.primaryKey.trim();
      dataEntities.add(_DataEntityItem(
        name: name,
        attributes: attributes.isNotEmpty
            ? attributes
            : [if (primaryKey.isNotEmpty) primaryKey else 'key_attribute'],
        flowLabel: _flowLabelForEntity(name),
        flowDetail: entity.description.trim().isNotEmpty
            ? entity.description.trim()
            : 'Moves from operational input to controlled storage and reporting.',
      ));
    }
    if (dataEntities.isEmpty) {
      dataEntities.addAll(const [
        _DataEntityItem(
          name: 'UserProfile',
          attributes: ['name', 'access_level', 'contact'],
          flowLabel: 'Input -> Storage',
          flowDetail:
              'User and operator identity records for permissions and communication.',
        ),
        _DataEntityItem(
          name: 'GuestList',
          attributes: ['guest_name', 'dietary_restriction', 'ticket_class'],
          flowLabel: 'Capture -> Ops',
          flowDetail:
              'Registration data passed into catering, seating, and access workflows.',
        ),
        _DataEntityItem(
          name: 'MaterialStock',
          attributes: ['sku', 'quantity', 'weight_kg'],
          flowLabel: 'Inventory -> Site',
          flowDetail:
              'Material issue and replenishment flow for physical production planning.',
        ),
      ]);
    }

    final interfaceContracts = <_InterfaceContractItem>[];
    for (final flow in dataFlows.take(4)) {
      final source = flow.source.trim();
      final destination = flow.destination.trim();
      if (source.isEmpty || destination.isEmpty) continue;
      interfaceContracts.add(_InterfaceContractItem(
        name: '$source -> $destination',
        method: flow.protocol.trim().isNotEmpty ? flow.protocol.trim() : 'REST',
        ioDescription: flow.notes.trim().isNotEmpty
            ? flow.notes.trim()
            : 'Input from $source, output to $destination.',
      ));
    }
    if (interfaceContracts.isEmpty) {
      interfaceContracts.addAll(const [
        _InterfaceContractItem(
          name: 'Payment Gateway API',
          method: 'REST',
          ioDescription:
              'Payment request in, authorization status and receipt out.',
        ),
        _InterfaceContractItem(
          name: 'Weather Service',
          method: 'WebSocket',
          ioDescription: 'Weather feed in, event contingency trigger out.',
        ),
        _InterfaceContractItem(
          name: 'Catering Handoff',
          method: 'Manual Handoff',
          ioDescription:
              'Headcount and dietary changes in, service readiness confirmation out.',
        ),
      ]);
    }

    final roles = projectData.teamMembers
        .map((member) => member.role.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (roles.isEmpty) {
      roles.addAll(['Admin', 'Vendor', 'Operations', 'Public']);
    }
    final accessRules = roles.take(4).map((role) {
      final lower = role.toLowerCase();
      if (lower.contains('security') || lower.contains('admin')) {
        return const _AccessRuleItem(
          role: 'Admin',
          permission: 'Read, write, delete, and edit structural plans',
          protocol: 'OAuth 2.0',
        );
      }
      if (lower.contains('vendor')) {
        return const _AccessRuleItem(
          role: 'Vendor',
          permission:
              'Read operational schedule and access assigned zones only',
          protocol: 'Key Card System',
        );
      }
      if (lower.contains('ops') || lower.contains('operations')) {
        return const _AccessRuleItem(
          role: 'Operations',
          permission:
              'Read live status, update logistics checkpoints, access back-of-house',
          protocol: 'Biometric Scanner',
        );
      }
      return const _AccessRuleItem(
        role: 'Public',
        permission: 'Read approved schedules and ticket status only',
        protocol: 'Wristband Access',
      );
    }).toList();

    final logicRules = [
      const _LogicRuleItem(
        name: 'Capacity Limit',
        condition: 'crowd density rises above the approved threshold',
        action: 'pause entry, redirect arrivals, and notify operations control',
      ),
      const _LogicRuleItem(
        name: 'Rain Contingency',
        condition: 'rain forecast exceeds 5mm during the live window',
        action:
            'switch event flow to Hall B and reroute power and signage plans',
      ),
      const _LogicRuleItem(
        name: 'Stock Reorder Trigger',
        condition: 'material stock drops below the safety buffer',
        action: 'create a replenishment request and alert procurement',
      ),
      const _LogicRuleItem(
        name: 'Access Escalation',
        condition: 'an unapproved credential attempts secure-zone entry',
        action: 'deny access and log an incident for security review',
      ),
    ];

    final performanceStrategies = [
      const _PerformanceStrategyItem(
        metric: 'Response Time',
        target: '< 250ms',
        strategy: 'Caching, edge routing, and lean payload contracts.',
        context: 'Supports high-traffic app and scanner validation peaks.',
      ),
      const _PerformanceStrategyItem(
        metric: 'Throughput',
        target: '10k requests/min',
        strategy: 'Load balancing and queue-based retry handling.',
        context: 'Protects check-in and live operations workflows.',
      ),
      const _PerformanceStrategyItem(
        metric: 'Load Bearing Capacity',
        target: '<= approved stage load',
        strategy: 'Reinforced flooring and staged equipment placement.',
        context: 'Ensures hidden structural systems support visible outputs.',
      ),
      _PerformanceStrategyItem(
        metric: 'Voltage Load',
        target: summaryContext.contains('generator')
            ? 'Generator-backed load approved'
            : 'Within venue power envelope',
        strategy: 'Generator backup and split power zones.',
        context:
            'Prevents backend operations and stage services from overload.',
      ),
    ];

    final vendorDependencies = projectData.vendors.isNotEmpty
        ? projectData.vendors.take(4).map((vendor) {
            return _VendorDependencyItem(
              service: vendor.name.trim().isNotEmpty
                  ? vendor.name.trim()
                  : 'External Vendor',
              purpose: vendor.equipmentOrService.trim().isNotEmpty
                  ? vendor.equipmentOrService.trim()
                  : 'Operational support service',
              status: vendor.status.trim().isNotEmpty
                  ? vendor.status.trim()
                  : vendor.procurementStage.trim().isNotEmpty
                      ? vendor.procurementStage.trim()
                      : 'Pending',
            );
          }).toList()
        : [
            const _VendorDependencyItem(
              service: 'Stripe',
              purpose: 'Payment authorization and settlement.',
              status: 'API Key Ready',
            ),
            const _VendorDependencyItem(
              service: 'Power Generator Rental',
              purpose:
                  'Backup power for stage, registration, and back-of-house operations.',
              status: 'Contract Signed',
            ),
            const _VendorDependencyItem(
              service: 'Waste Management',
              purpose:
                  'Supports backend site logistics and environmental compliance.',
              status: 'Pending',
            ),
            const _VendorDependencyItem(
              service: 'Security Crew',
              purpose:
                  'Zone control, credential checks, and incident escalation.',
              status: 'Pending',
            ),
          ];

    final pipelineStages = const [
      _PipelineStageItem(
        environment: 'Staging',
        label: 'Validate',
        steps:
            'CI build -> integration tests -> sandbox scanners and mock vendor handoffs.',
      ),
      _PipelineStageItem(
        environment: 'Production',
        label: 'Release',
        steps:
            'Deploy services -> verify monitoring -> enable live traffic and escalation alerts.',
      ),
      _PipelineStageItem(
        environment: 'Mock-up Site',
        label: 'Rehearse',
        steps:
            'Prefabrication checks -> test kitchen rehearsal -> site safety sign-off.',
      ),
      _PipelineStageItem(
        environment: 'On-site Assembly',
        label: 'Activate',
        steps: 'Shipping -> install -> commissioning -> operational handover.',
      ),
    ];

    final aiSignalCount = projectData.aiUsageCounts.values.fold<int>(
          0,
          (total, value) => total + value,
        ) +
        projectData.aiRecommendations.length +
        projectData.aiIntegrations.length;

    return _BackendInfrastructureSnapshot(
      projectLabel: projectLabel,
      systemNodes: systemNodes,
      systemLinks: systemLinks,
      dataEntities: dataEntities,
      interfaceContracts: interfaceContracts,
      accessRules: accessRules,
      logicRules: logicRules,
      performanceStrategies: performanceStrategies,
      vendorDependencies: vendorDependencies,
      pipelineStages: pipelineStages,
      aiSignalCount: aiSignalCount,
    );
  }

  static String _typeForLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('db') || normalized.contains('data')) {
      return 'Data store';
    }
    if (normalized.contains('power') ||
        normalized.contains('hvac') ||
        normalized.contains('alarm')) {
      return 'Integration';
    }
    if (normalized.contains('queue')) return 'Queue';
    if (normalized.contains('api') || normalized.contains('auth')) {
      return 'Service';
    }
    return 'Component';
  }

  static String _hostForLabel(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('power')) return 'Venue Power Grid';
    if (normalized.contains('hvac')) return 'Plant Room';
    if (normalized.contains('alarm')) return 'Fire Control Panel';
    if (normalized.contains('db') || normalized.contains('data')) {
      return 'AWS Cloud';
    }
    if (normalized.contains('auth') || normalized.contains('api')) {
      return 'Cloud Compute Cluster';
    }
    return 'Back of House Operations';
  }

  static String _hostForComponent(String name, String type) {
    final normalized = '$name $type'.toLowerCase();
    if (normalized.contains('power')) return 'Venue Power Grid';
    if (normalized.contains('hvac')) return 'Plant Room';
    if (normalized.contains('data')) return 'Managed Database Cluster';
    if (normalized.contains('integration')) return 'Vendor Edge Network';
    if (normalized.contains('analytics')) return 'Reporting Warehouse';
    return 'AWS Cloud';
  }

  static String _locationForLink(String from, String to) {
    final combined = '$from $to'.toLowerCase();
    if (combined.contains('power') || combined.contains('hvac')) {
      return 'Plant / Site';
    }
    if (combined.contains('scanner') || combined.contains('guest')) {
      return 'Edge -> Cloud';
    }
    return 'Core Platform';
  }

  static String _flowLabelForEntity(String name) {
    final normalized = name.toLowerCase();
    if (normalized.contains('guest')) return 'Capture -> Ops';
    if (normalized.contains('stock') || normalized.contains('material')) {
      return 'Inventory -> Site';
    }
    if (normalized.contains('access')) return 'Identity -> Control';
    return 'Input -> Storage';
  }
}

class _SystemNodeItem {
  const _SystemNodeItem({
    required this.name,
    required this.type,
    required this.status,
    required this.hostLocation,
  });

  final String name;
  final String type;
  final String status;
  final String hostLocation;
}

class _SystemLinkItem {
  const _SystemLinkItem({
    required this.from,
    required this.to,
    required this.location,
  });

  final String from;
  final String to;
  final String location;
}

class _DataEntityItem {
  const _DataEntityItem({
    required this.name,
    required this.attributes,
    required this.flowLabel,
    required this.flowDetail,
  });

  final String name;
  final List<String> attributes;
  final String flowLabel;
  final String flowDetail;
}

class _InterfaceContractItem {
  const _InterfaceContractItem({
    required this.name,
    required this.method,
    required this.ioDescription,
  });

  final String name;
  final String method;
  final String ioDescription;
}

class _AccessRuleItem {
  const _AccessRuleItem({
    required this.role,
    required this.permission,
    required this.protocol,
  });

  final String role;
  final String permission;
  final String protocol;
}

class _LogicRuleItem {
  const _LogicRuleItem({
    required this.name,
    required this.condition,
    required this.action,
  });

  final String name;
  final String condition;
  final String action;
}

class _PerformanceStrategyItem {
  const _PerformanceStrategyItem({
    required this.metric,
    required this.target,
    required this.strategy,
    required this.context,
  });

  final String metric;
  final String target;
  final String strategy;
  final String context;
}

class _VendorDependencyItem {
  const _VendorDependencyItem({
    required this.service,
    required this.purpose,
    required this.status,
  });

  final String service;
  final String purpose;
  final String status;
}

class _PipelineStageItem {
  const _PipelineStageItem({
    required this.environment,
    required this.label,
    required this.steps,
  });

  final String environment;
  final String label;
  final String steps;
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
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
          child: Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.7,
                        color: Color(0xFF6B7280)),
                  ),
                ))
            .toList(),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            minWidth:
                columns.fold<double>(0, (total, col) => total + col.width)),
        child: Column(
          children: [
            header,
            const SizedBox(height: 8),
            for (int i = 0; i < rows.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      initialValue: resolved,
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
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

class _EditCell extends StatelessWidget {
  const _EditCell({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
      tooltip: 'Edit',
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
            child: const Icon(Icons.info_outline,
                size: 18, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
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
        id: data['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
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
        id: data['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
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
        id: data['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
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
        id: data['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
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
        id: data['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
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
  _Debouncer({Duration? delay})
      : delay = delay ?? const Duration(milliseconds: 600);

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
