import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/screens/backend_design_screen.dart';
import 'package:ndu_project/screens/development_set_up_screen.dart';
import 'package:ndu_project/providers/project_data_provider.dart';

class UiUxDesignScreen extends StatefulWidget {
  const UiUxDesignScreen({super.key});

  @override
  State<UiUxDesignScreen> createState() => _UiUxDesignScreenState();
}

class _UiUxDesignScreenState extends State<UiUxDesignScreen> {
  final TextEditingController _notesController = TextEditingController();
  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;
  bool _didSeedDefaults = false;

  // Primary user journeys data
  List<_JourneyItem> _journeys = [];

  // Interface structure data
  List<_InterfaceItem> _interfaces = [];

  // Design system elements data
  List<_DesignElement> _coreTokens = [];
  List<_DesignElement> _keyComponents = [];

  static const List<String> _journeyStatusOptions = [
    'Mapped',
    'Draft',
    'Planned',
    'In progress',
  ];

  static const List<String> _interfaceStateOptions = [
    'Wireframe',
    'User flow map',
    'To define',
    'Prototype',
    'Final',
  ];

  static const List<String> _elementStatusOptions = [
    'Ready',
    'Draft',
    'In review',
    'Planned',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _saveDebouncer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _journeys = _defaultJourneys();
    _interfaces = _defaultInterfaces();
    _coreTokens = _defaultCoreTokens();
    _keyComponents = _defaultKeyComponents();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
    _notesController.addListener(_scheduleSave);
  }

  DocumentReference<Map<String, dynamic>> _docFor(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('design_phase_sections')
        .doc('ui_ux_design');
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
      final doc = await _docFor(projectId).get();
      final data = doc.data() ?? {};
      _suspendSave = true;
      if (!mounted) return;
      final notes = data['notes']?.toString() ?? '';
      final journeys = _JourneyItem.fromList(data['journeys']);
      final interfaces = _InterfaceItem.fromList(data['interfaces']);
      final coreTokens = _DesignElement.fromList(data['coreTokens']);
      final keyComponents = _DesignElement.fromList(data['keyComponents']);
      final hasJourneysKey = data.containsKey('journeys');
      final hasInterfacesKey = data.containsKey('interfaces');
      final hasCoreTokensKey = data.containsKey('coreTokens');
      final hasKeyComponentsKey = data.containsKey('keyComponents');
      shouldSeedDefaults = data.isEmpty && !_didSeedDefaults;
      setState(() {
        _notesController.text = notes;
        if (shouldSeedDefaults) {
          _didSeedDefaults = true;
          _journeys = _defaultJourneys();
          _interfaces = _defaultInterfaces();
          _coreTokens = _defaultCoreTokens();
          _keyComponents = _defaultKeyComponents();
        } else {
          _journeys = hasJourneysKey ? journeys : _defaultJourneys();
          _interfaces = hasInterfacesKey ? interfaces : _defaultInterfaces();
          _coreTokens = hasCoreTokensKey ? coreTokens : _defaultCoreTokens();
          _keyComponents =
              hasKeyComponentsKey ? keyComponents : _defaultKeyComponents();
        }
      });
    } catch (error) {
      debugPrint('UI/UX design load error: $error');
    } finally {
      _suspendSave = false;
      if (mounted) {
        setState(() => _isLoading = false);
        if (shouldSeedDefaults) _scheduleSave();
      }
    }
  }

  Future<void> _saveToFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    try {
      await _docFor(projectId).set({
        'notes': _notesController.text.trim(),
        'journeys': _journeys.map((e) => e.toMap()).toList(),
        'interfaces': _interfaces.map((e) => e.toMap()).toList(),
        'coreTokens': _coreTokens.map((e) => e.toMap()).toList(),
        'keyComponents': _keyComponents.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('UI/UX design save error: $error');
    }
  }

  List<_JourneyItem> _defaultJourneys() {
    return [
      _JourneyItem(
        id: _newId(),
        title: 'Onboard & first value',
        description: 'From sign-up to experiencing the first meaningful outcome.',
        status: 'Mapped',
      ),
      _JourneyItem(
        id: _newId(),
        title: 'Core task completion',
        description: 'Critical path to complete the main job-to-be-done.',
        status: 'Draft',
      ),
      _JourneyItem(
        id: _newId(),
        title: 'Support & recovery',
        description: 'Error states, help entry points, and escalation paths.',
        status: 'Planned',
      ),
    ];
  }

  List<_InterfaceItem> _defaultInterfaces() {
    return [
      _InterfaceItem(
        id: _newId(),
        area: 'Dashboard',
        purpose: 'One-glance status and key shortcuts into primary actions.',
        state: 'Wireframe',
      ),
      _InterfaceItem(
        id: _newId(),
        area: 'Workflows',
        purpose: 'Step-by-step guidance for complex, multi-screen tasks.',
        state: 'User flow map',
      ),
      _InterfaceItem(
        id: _newId(),
        area: 'Settings & admin',
        purpose: 'Configuration, access management, and audit history.',
        state: 'To define',
      ),
    ];
  }

  List<_DesignElement> _defaultCoreTokens() {
    return [
      _DesignElement(
        id: _newId(),
        title: 'Color & typography',
        description: 'Brand palette, semantic roles, hierarchy, spacing scale.',
        status: 'Ready',
      ),
      _DesignElement(
        id: _newId(),
        title: 'Interactions & feedback',
        description: 'Loading, success, warning, error, and empty states.',
        status: 'Draft',
      ),
    ];
  }

  List<_DesignElement> _defaultKeyComponents() {
    return [
      _DesignElement(
        id: _newId(),
        title: 'Navigation system',
        description: 'Primary, secondary, and breadcrumb navigation patterns.',
        status: 'Planned',
      ),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _addJourney() {
    setState(() {
      _journeys.add(_JourneyItem(
        id: _newId(),
        title: '',
        description: '',
        status: _journeyStatusOptions.first,
      ));
    });
    _scheduleSave();
  }

  void _addInterface() {
    setState(() {
      _interfaces.add(_InterfaceItem(
        id: _newId(),
        area: '',
        purpose: '',
        state: _interfaceStateOptions.first,
      ));
    });
    _scheduleSave();
  }

  void _addCoreToken() {
    setState(() {
      _coreTokens.add(_DesignElement(
        id: _newId(),
        title: '',
        description: '',
        status: _elementStatusOptions.first,
      ));
    });
    _scheduleSave();
  }

  void _addKeyComponent() {
    setState(() {
      _keyComponents.add(_DesignElement(
        id: _newId(),
        title: '',
        description: '',
        status: _elementStatusOptions.first,
      ));
    });
    _scheduleSave();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);
    final sectionGap = AppBreakpoints.sectionGap(context);

    return ResponsiveScaffold(
      activeItemLabel: 'UI/UX Design',
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Design Phase',
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
                  if (_isLoading) const SizedBox(height: 12),
                  _buildPageHeader(isMobile),
                  SizedBox(height: sectionGap),
                  _buildSnapshotStrip(),
                  SizedBox(height: sectionGap),
                  ResponsiveGrid(
                    desktopColumns: 1,
                    tabletColumns: 1,
                    mobileColumns: 1,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildDesignBriefCard(),
                      _buildPrimaryUserJourneysCard(),
                      _buildInterfaceStructureCard(),
                      _buildDesignSystemElementsCard(),
                    ],
                  ),
                  const SizedBox(height: 32),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: Development set up',
                    nextLabel: 'Next: Backend design',
                    onBack: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DevelopmentSetUpScreen(),
                      ),
                    ),
                    onNext: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BackendDesignScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UI/UX Design',
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Define the experience, flows, and system essentials teams need to build consistently.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(height: 6),
        Text(
          'Focus on high-impact touchpoints: discovery, core task completion, and support.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSnapshotStrip() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final tiles = [
          _buildStatTile(
            label: 'Journeys',
            value: _journeys.length,
            background: AppSemanticColors.infoSurface,
            accent: AppSemanticColors.info,
          ),
          _buildStatTile(
            label: 'Interfaces',
            value: _interfaces.length,
            background: AppSemanticColors.subtle,
            accent: const Color(0xFF0F172A),
          ),
          _buildStatTile(
            label: 'Core tokens',
            value: _coreTokens.length,
            background: AppSemanticColors.warningSurface,
            accent: AppSemanticColors.warning,
          ),
          _buildStatTile(
            label: 'Components',
            value: _keyComponents.length,
            background: AppSemanticColors.successSurface,
            accent: AppSemanticColors.success,
          ),
        ];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppSemanticColors.border),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < tiles.length; i++) ...[
                      tiles[i],
                      if (i != tiles.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                )
              : Row(
                  children: [
                    for (int i = 0; i < tiles.length; i++) ...[
                      Expanded(child: tiles[i]),
                      if (i != tiles.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDesignBriefCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Design brief',
            subtitle:
                'Capture constraints, target users, accessibility, and brand guardrails.',
          ),
          const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              minLines: 4,
              maxLines: 8,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText:
                    'Target users, accessibility constraints, brand rules, must-have journeys.',
                alignLabelWithHint: true,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Keep this tight: list critical journeys, devices, and non-negotiable UX requirements.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827)),
            ),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        );

        if (action == null) {
          return titleBlock;
        }
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            action,
          ],
        );
      },
    );
  }

  Widget _buildSubsectionHeader({
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827)),
            ),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        );
        if (action == null) {
          return titleBlock;
        }
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            action,
          ],
        );
      },
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: child,
    );
  }

  Widget _buildStatTile({
    required String label,
    required int value,
    required Color background,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppSemanticColors.subtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Text(
        message,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildCenteredDropdownField({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      alignment: Alignment.center,
      style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Center(child: Text(item)),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) => items
          .map((item) => Center(child: Text(item)))
          .toList(),
      onChanged: onChanged,
      decoration: _inlineInputDecoration(hint),
    );
  }

  Widget _buildPrimaryUserJourneysCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Primary user journeys',
            subtitle: 'What users need to accomplish end-to-end.',
            action: TextButton.icon(
              onPressed: _addJourney,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add journey'),
            ),
          ),
          const SizedBox(height: 16),
          if (_journeys.isEmpty)
            _buildEmptyState('No journeys yet. Add the first critical flow.')
          else
            ..._journeys.map(_buildJourneyItem),
        ],
      ),
    );
  }

  Widget _buildJourneyItem(_JourneyItem journey) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: ValueKey('journey-title-${journey.id}'),
              initialValue: journey.title,
              decoration: _inlineInputDecoration('Journey title'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              onChanged: (value) {
                journey.title = value;
                _scheduleSave();
              },
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: ValueKey('journey-desc-${journey.id}'),
              initialValue: journey.description,
              minLines: 1,
              maxLines: null,
              decoration: _inlineInputDecoration('Describe the journey'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              onChanged: (value) {
                journey.description = value;
                _scheduleSave();
              },
            ),
          ],
        );

        final statusField = _buildCenteredDropdownField(
          value: _journeyStatusOptions.contains(journey.status)
              ? journey.status
              : _journeyStatusOptions.first,
          items: _journeyStatusOptions,
          onChanged: (value) {
            if (value == null) return;
            setState(() => journey.status = value);
            _scheduleSave();
          },
          hint: 'Status',
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppSemanticColors.subtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppSemanticColors.border),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: statusField),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() => _journeys
                                .removeWhere((item) => item.id == journey.id));
                            _scheduleSave();
                          },
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 12),
                    SizedBox(width: 160, child: statusField),
                    IconButton(
                      onPressed: () {
                        setState(() => _journeys
                            .removeWhere((item) => item.id == journey.id));
                        _scheduleSave();
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildInterfaceStructureCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Interface structure',
            subtitle: 'Core screens, flows, and the purpose of each view.',
            action: TextButton.icon(
              onPressed: _addInterface,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add area'),
            ),
          ),
          const SizedBox(height: 16),
          if (_interfaces.isEmpty)
            _buildEmptyState('No interfaces yet. Add the critical screens.')
          else
            ..._interfaces.map(_buildInterfaceRow),
        ],
      ),
    );
  }

  Widget _buildInterfaceRow(_InterfaceItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final areaField = TextFormField(
          key: ValueKey('interface-area-${item.id}'),
          initialValue: item.area,
          decoration: _inlineInputDecoration('Area'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          onChanged: (value) {
            item.area = value;
            _scheduleSave();
          },
        );
        final purposeField = TextFormField(
          key: ValueKey('interface-purpose-${item.id}'),
          initialValue: item.purpose,
          minLines: 1,
          maxLines: null,
          decoration: _inlineInputDecoration('Purpose'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          onChanged: (value) {
            item.purpose = value;
            _scheduleSave();
          },
        );
        final stateField = _buildCenteredDropdownField(
          value: _interfaceStateOptions.contains(item.state)
              ? item.state
              : _interfaceStateOptions.first,
          items: _interfaceStateOptions,
          onChanged: (value) {
            if (value == null) return;
            setState(() => item.state = value);
            _scheduleSave();
          },
          hint: 'State',
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppSemanticColors.subtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppSemanticColors.border),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    areaField,
                    const SizedBox(height: 8),
                    purposeField,
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: stateField),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() => _interfaces
                                .removeWhere((entry) => entry.id == item.id));
                            _scheduleSave();
                          },
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: areaField),
                    const SizedBox(width: 12),
                    Expanded(child: purposeField),
                    const SizedBox(width: 12),
                    SizedBox(width: 150, child: stateField),
                    IconButton(
                      onPressed: () {
                        setState(() => _interfaces
                            .removeWhere((entry) => entry.id == item.id));
                        _scheduleSave();
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDesignSystemElementsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Design system essentials',
            subtitle: 'Tokens, components, and states the build will rely on.',
          ),
          const SizedBox(height: 16),
          _buildSubsectionHeader(
            title: 'Core tokens',
            subtitle: 'Color, typography, spacing, and feedback states.',
            action: TextButton.icon(
              onPressed: _addCoreToken,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add token'),
            ),
          ),
          const SizedBox(height: 12),
          if (_coreTokens.isEmpty)
            _buildEmptyState('No tokens yet. Add the essential foundations.')
          else
            ..._coreTokens.map((e) => _buildDesignElementItem(e, list: _coreTokens)),
          const SizedBox(height: 20),
          _buildSubsectionHeader(
            title: 'Key components',
            subtitle: 'Reusable patterns required before development starts.',
            action: TextButton.icon(
              onPressed: _addKeyComponent,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add component'),
            ),
          ),
          const SizedBox(height: 12),
          if (_keyComponents.isEmpty)
            _buildEmptyState('No components yet. Add the reusable building blocks.')
          else
            ..._keyComponents.map((e) => _buildDesignElementItem(e, list: _keyComponents)),
        ],
      ),
    );
  }

  Widget _buildDesignElementItem(_DesignElement element, {required List<_DesignElement> list}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: ValueKey('element-title-${element.id}'),
              initialValue: element.title,
              decoration: _inlineInputDecoration('Element'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              onChanged: (value) {
                element.title = value;
                _scheduleSave();
              },
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: ValueKey('element-desc-${element.id}'),
              initialValue: element.description,
              minLines: 1,
              maxLines: null,
              decoration: _inlineInputDecoration('Description'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              onChanged: (value) {
                element.description = value;
                _scheduleSave();
              },
            ),
          ],
        );
        final statusField = _buildCenteredDropdownField(
          value: _elementStatusOptions.contains(element.status)
              ? element.status
              : _elementStatusOptions.first,
          items: _elementStatusOptions,
          onChanged: (value) {
            if (value == null) return;
            setState(() => element.status = value);
            _scheduleSave();
          },
          hint: 'Status',
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppSemanticColors.subtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppSemanticColors.border),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: statusField),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() => list
                                .removeWhere((entry) => entry.id == element.id));
                            _scheduleSave();
                          },
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 12),
                    SizedBox(width: 160, child: statusField),
                    IconButton(
                      onPressed: () {
                        setState(() => list
                            .removeWhere((entry) => entry.id == element.id));
                        _scheduleSave();
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // _buildBottomNavigation removed — replaced by the shared LaunchPhaseNavigation in the main build.
}

InputDecoration _inlineInputDecoration(String hint) {
  return InputDecoration(
    isDense: true,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
    ),
  );
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

class _JourneyItem {
  final String id;
  String title;
  String description;
  String status;

  _JourneyItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
      };

  static List<_JourneyItem> fromList(dynamic data) {
    if (data is! List) return [];
    final items = <_JourneyItem>[];
    for (final item in data) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      items.add(_JourneyItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Draft',
      ));
    }
    return items;
  }
}

class _InterfaceItem {
  final String id;
  String area;
  String purpose;
  String state;

  _InterfaceItem({
    required this.id,
    required this.area,
    required this.purpose,
    required this.state,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'area': area,
        'purpose': purpose,
        'state': state,
      };

  static List<_InterfaceItem> fromList(dynamic data) {
    if (data is! List) return [];
    final items = <_InterfaceItem>[];
    for (final item in data) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      items.add(_InterfaceItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        area: map['area']?.toString() ?? '',
        purpose: map['purpose']?.toString() ?? '',
        state: map['state']?.toString() ?? 'To define',
      ));
    }
    return items;
  }
}

class _DesignElement {
  final String id;
  String title;
  String description;
  String status;

  _DesignElement({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
      };

  static List<_DesignElement> fromList(dynamic data) {
    if (data is! List) return [];
    final items = <_DesignElement>[];
    for (final item in data) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      items.add(_DesignElement(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Draft',
      ));
    }
    return items;
  }
}
