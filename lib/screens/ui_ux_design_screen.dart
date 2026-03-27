// ignore_for_file: unused_element

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/services/activity_log_service.dart';
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
  bool _registersExpanded = false;
  int _selectedGalleryTab = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final projectId = provider?.projectData.projectId;
      if (projectId != null && projectId.isNotEmpty) {
        await ProjectNavigationService.instance.saveLastPage(
          projectId,
          'ui-ux-design',
        );
      }
      await _loadFromFirestore();
    });
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
      await ActivityLogService.instance.logActivity(
        projectId: projectId,
        phase: 'Design Phase',
        page: 'UI/UX Design',
        action: 'Updated UI/UX design data',
      );
    } catch (error) {
      debugPrint('UI/UX design save error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save UI/UX Design changes right now. Please try again.',
          ),
        ),
      );
    }
  }

  List<_JourneyItem> _defaultJourneys() {
    return [
      _JourneyItem(
        id: _newId(),
        title: 'Mobile app guest check-in',
        description:
            'From QR scan to ticket validation and the first in-app confirmation state.',
        status: 'Mapped',
      ),
      _JourneyItem(
        id: _newId(),
        title: 'Stage-to-foyer wayfinding',
        description:
            'Physical pathfinding from entry signage to the activation zone and support desk.',
        status: 'Draft',
      ),
      _JourneyItem(
        id: _newId(),
        title: 'Support, refunds, and access recovery',
        description:
            'Error states, fallback assistance, and escalation paths across app and venue touchpoints.',
        status: 'Planned',
      ),
    ];
  }

  List<_InterfaceItem> _defaultInterfaces() {
    return [
      _InterfaceItem(
        id: _newId(),
        area: 'Mobile guest app',
        purpose:
            'Core event app screens for schedule viewing, check-in, and live support.',
        state: 'Prototype',
      ),
      _InterfaceItem(
        id: _newId(),
        area: 'Roll-up banner system',
        purpose:
            'Marketing and wayfinding graphics for event entry, sponsor zone, and registration.',
        state: 'User flow map',
      ),
      _InterfaceItem(
        id: _newId(),
        area: 'Venue floor plan',
        purpose:
            'Spatial layout and circulation guidance for booths, stage access, and seating.',
        state: 'Wireframe',
      ),
    ];
  }

  List<_DesignElement> _defaultCoreTokens() {
    return [
      _DesignElement(
        id: _newId(),
        title: 'Color palette',
        description: '#0F172A, #2563EB, #F59E0B, #F8FAFC and usage rules.',
        status: 'Ready',
      ),
      _DesignElement(
        id: _newId(),
        title: 'Typography scale',
        description: 'Display, body, caption, and signage headline samples.',
        status: 'Ready',
      ),
      _DesignElement(
        id: _newId(),
        title: 'Interactions & feedback',
        description:
            'Loading, success, warning, hover, and environmental cue states.',
        status: 'Draft',
      ),
    ];
  }

  List<_DesignElement> _defaultKeyComponents() {
    return [
      _DesignElement(
        id: _newId(),
        title: 'Primary CTA and filter chips',
        description:
            'Core mobile and desktop interaction controls for ticketing and discovery.',
        status: 'Ready',
      ),
      _DesignElement(
        id: _newId(),
        title: 'Event banner module',
        description:
            'Roll-up banner lockup with headline, sponsor strip, and QR call-to-action.',
        status: 'In review',
      ),
      _DesignElement(
        id: _newId(),
        title: 'Floor plan legend',
        description:
            'Visual key for stage, seating, emergency routes, and premium zones.',
        status: 'Draft',
      ),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _addJourney() {
    _openJourneyDialog();
  }

  void _addInterface() {
    _openInterfaceDialog();
  }

  void _addCoreToken() {
    _openDesignElementDialog(
      list: _coreTokens,
      actionLabel: 'design token',
    );
  }

  void _addKeyComponent() {
    _openDesignElementDialog(
      list: _keyComponents,
      actionLabel: 'key component',
    );
  }

  Future<void> _openJourneyDialog({_JourneyItem? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    String status = existing?.status ?? _journeyStatusOptions.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Add journey' : 'Edit journey'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Journey title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Journey description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: _journeyStatusOptions
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
              child: Text(existing == null ? 'Add journey' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;

    setState(() {
      if (existing == null) {
        _journeys.add(_JourneyItem(
          id: _newId(),
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          status: status,
        ));
      } else {
        existing
          ..title = titleController.text.trim()
          ..description = descriptionController.text.trim()
          ..status = status;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null ? 'Added journey row' : 'Edited journey row',
      details: {'itemId': existing?.id},
    );
  }

  Future<void> _openInterfaceDialog({_InterfaceItem? existing}) async {
    final areaController = TextEditingController(text: existing?.area ?? '');
    final purposeController =
        TextEditingController(text: existing?.purpose ?? '');
    String state = existing?.state ?? _interfaceStateOptions.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(
              existing == null ? 'Add interface area' : 'Edit interface area'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: areaController,
                  decoration: const InputDecoration(
                    labelText: 'Area / screen / asset',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Purpose',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: state,
                  items: _interfaceStateOptions
                      .map((option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => state = value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'State',
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
              child: Text(existing == null ? 'Add area' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;

    setState(() {
      if (existing == null) {
        _interfaces.add(_InterfaceItem(
          id: _newId(),
          area: areaController.text.trim(),
          purpose: purposeController.text.trim(),
          state: state,
        ));
      } else {
        existing
          ..area = areaController.text.trim()
          ..purpose = purposeController.text.trim()
          ..state = state;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null ? 'Added interface row' : 'Edited interface row',
      details: {'itemId': existing?.id},
    );
  }

  Future<void> _openDesignElementDialog({
    required List<_DesignElement> list,
    required String actionLabel,
    _DesignElement? existing,
  }) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    String status = existing?.status ?? _elementStatusOptions.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title:
              Text(existing == null ? 'Add $actionLabel' : 'Edit $actionLabel'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText:
                        '${actionLabel[0].toUpperCase()}${actionLabel.substring(1)} title',
                    border: const OutlineInputBorder(),
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
                  initialValue: status,
                  items: _elementStatusOptions
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
              child: Text(existing == null ? 'Add item' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;

    setState(() {
      if (existing == null) {
        list.add(_DesignElement(
          id: _newId(),
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          status: status,
        ));
      } else {
        existing
          ..title = titleController.text.trim()
          ..description = descriptionController.text.trim()
          ..status = status;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null ? 'Added $actionLabel row' : 'Edited $actionLabel row',
      details: {'itemId': existing?.id},
    );
  }

  void _logActivity(String action, {Map<String, dynamic>? details}) {
    final projectId =
        ProjectDataInherited.maybeOf(context)?.projectData.projectId?.trim() ??
            '';
    if (projectId.isEmpty) return;
    unawaited(
      ActivityLogService.instance.logActivity(
        projectId: projectId,
        phase: 'Design Phase',
        page: 'UI/UX Design',
        action: action,
        details: details,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);
    final provider = ProjectDataInherited.maybeOf(context);
    final projectData = provider?.projectData ?? ProjectDataModel();
    final snapshot = _UiUxDashboardSnapshot.from(
      projectData: projectData,
      notes: _notesController.text,
      journeys: _journeys,
      interfaces: _interfaces,
      coreTokens: _coreTokens,
      keyComponents: _keyComponents,
      selectedGalleryTab: _selectedGalleryTab,
    );

    return ResponsiveScaffold(
      activeItemLabel: 'UI/UX Design',
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'UI/UX Design',
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
                  _buildExperienceHubHeader(
                    isMobile: isMobile,
                    projectData: projectData,
                    snapshot: snapshot,
                  ),
                  const SizedBox(height: 24),
                  _buildTopSection(snapshot, isMobile),
                  const SizedBox(height: 20),
                  _buildGalleryAndInteractionSection(snapshot, isMobile),
                  const SizedBox(height: 20),
                  _buildValidationGrid(snapshot),
                  const SizedBox(height: 20),
                  _buildDetailedRegistersPanel(),
                  const SizedBox(height: 32),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: Development Set Up',
                    nextLabel: 'Next: Backend Design',
                    onBack: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DevelopmentSetUpScreen(),
                      ),
                    ),
                    onNext: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const BackendDesignScreen()),
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

  void _setGalleryTab(int index) {
    if (_selectedGalleryTab == index) return;
    setState(() => _selectedGalleryTab = index);
  }

  Widget _buildExperienceHubHeader({
    required bool isMobile,
    required ProjectDataModel projectData,
    required _UiUxDashboardSnapshot snapshot,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF183153),
            Color(0xFF0F766E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Experience & Visual Design',
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'UI/UX Design for ${projectData.projectName.trim().isNotEmpty ? projectData.projectName.trim() : 'the current design package'}. This hub balances digital interfaces, event graphics, floor plans, motion, accessibility, and handoff-ready specifications.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.5,
            ),
          ),
          if (_notesController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _notesController.text.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroMetricPill(
                  'Gallery Assets', '${snapshot.galleryItems.length}'),
              _buildHeroMetricPill('Flows', '${snapshot.flowNodes.length}'),
              _buildHeroMetricPill(
                  'Motion Specs', '${snapshot.motionItems.length}'),
              _buildHeroMetricPill(
                  'Handoff Files', '${snapshot.handoffItems.length}'),
              _buildHeroMetricPill('AI Signals', '${snapshot.aiSignalCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(_UiUxDashboardSnapshot snapshot, bool isMobile) {
    return Column(
      children: [
        _buildInformationArchitectureCard(snapshot),
        const SizedBox(height: 20),
        _buildStyleGuideCard(snapshot),
      ],
    );
  }

  Widget _buildGalleryAndInteractionSection(
      _UiUxDashboardSnapshot snapshot, bool isMobile) {
    return Column(
      children: [
        _buildGalleryCard(snapshot),
        const SizedBox(height: 20),
        _buildInteractionCard(snapshot),
      ],
    );
  }

  Widget _buildValidationGrid(_UiUxDashboardSnapshot snapshot) {
    return Column(
      children: [
        _buildUsabilityCard(snapshot),
        const SizedBox(height: 20),
        _buildAccessibilityCard(snapshot),
        const SizedBox(height: 20),
        _buildHandoffCard(snapshot),
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
            'Edit the source brief, flows, interfaces, and design-system items behind the dashboard.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          children: [
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
          ],
        ),
      ),
    );
  }

  Widget _buildInformationArchitectureCard(_UiUxDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Information Architecture & Flow',
      subtitle:
          'Mini sitemap and journey progression with drafting and validation signals.',
      icon: Icons.account_tree_outlined,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            for (int i = 0; i < snapshot.flowNodes.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: snapshot.flowNodes[i].status == 'Validated'
                              ? AppSemanticColors.success
                              : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (i != snapshot.flowNodes.length - 1)
                        Container(
                          width: 2,
                          height: 48,
                          color: const Color(0xFFCBD5E1),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                snapshot.flowNodes[i].title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            _buildStatusTag(
                              snapshot.flowNodes[i].status,
                              snapshot.flowNodes[i].status == 'Validated'
                                  ? AppSemanticColors.success
                                  : const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          snapshot.flowNodes[i].detail,
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStyleGuideCard(_UiUxDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Design System & Style Guide',
      subtitle:
          'Color swatches, typography samples, and component previews for a shared visual language.',
      icon: Icons.style_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Color Palettes',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: snapshot.colorSwatches
                .map((swatch) => _buildColorSwatch(swatch))
                .toList(),
          ),
          const SizedBox(height: 18),
          const Text(
            'Typography',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: snapshot.typographySamples
                .map(
                  (sample) => Container(
                    width: double.infinity,
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
                            sample.preview,
                            style: TextStyle(
                              fontSize: sample.fontSize,
                              fontWeight: sample.weight,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Text(
                          sample.label,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Components',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: snapshot.componentPreviews
                .map(
                  (component) => FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${component.label} is available in the design-system handoff set.',
                          ),
                          backgroundColor: const Color(0xFF0F172A),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: component.color,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(component.label),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPanel({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
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
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF0F172A)),
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
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildGalleryCard(_UiUxDashboardSnapshot snapshot) {
    const tabs = [
      'Wireframes & Lo-Fi Concepts',
      'Visual Design & Hi-Fi Mockups',
    ];
    final visibleItems = snapshot.galleryItems
        .where((item) => item.tabIndex == _selectedGalleryTab)
        .toList();

    return _buildDashboardPanel(
      title: 'The Gallery',
      subtitle:
          'Responsive concept wall mixing software screens, event graphics, and physical planning assets.',
      icon: Icons.collections_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              tabs.length,
              (index) => ChoiceChip(
                label: Text(tabs[index]),
                selected: _selectedGalleryTab == index,
                onSelected: (_) => _setGalleryTab(index),
              ),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 14.0;
              final columns = constraints.maxWidth >= 1080
                  ? 3
                  : constraints.maxWidth >= 620
                      ? 2
                      : 1;
              final width = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: visibleItems
                    .map((item) => SizedBox(
                          width: width,
                          child: _buildGalleryTile(item),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionCard(_UiUxDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Interaction & Motion Design',
      subtitle:
          'Triggers and motion specs for digital interactions and physical experience cues.',
      icon: Icons.play_circle_outline,
      child: Column(
        children: snapshot.motionItems
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
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Trigger: ${item.trigger}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Specs: ${item.specs}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
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

  Widget _buildUsabilityCard(_UiUxDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Usability Testing & Validation',
      subtitle:
          'Testing log covering walkthroughs, experiments, and physical-space review findings.',
      icon: Icons.fact_check_outlined,
      child: Column(
        children: snapshot.testingItems
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
                            item.method,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        _buildStatusTag(item.status, item.statusColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.finding,
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

  Widget _buildAccessibilityCard(_UiUxDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Accessibility & Inclusivity',
      subtitle:
          'Digital compliance and physical accessibility checks presented with pass/fail signals.',
      icon: Icons.checklist_rtl_outlined,
      child: Column(
        children: snapshot.accessibilityItems
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
                    Icon(
                      item.passed
                          ? Icons.check_circle_outline
                          : Icons.highlight_off,
                      size: 22,
                      color: item.passed
                          ? AppSemanticColors.success
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    _buildStatusTag(
                      item.passed ? 'Pass' : 'Fail',
                      item.passed
                          ? AppSemanticColors.success
                          : const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildHandoffCard(_UiUxDashboardSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Asset Handoff & Specifications',
      subtitle:
          'Design assets, redlines, dimensions, and recipients for development and print handoff.',
      icon: Icons.inventory_2_outlined,
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
                  flex: 4,
                  child: Text(
                    'Asset Name',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Specs',
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
                    'Recipient',
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
          for (int i = 0; i < snapshot.handoffItems.length; i++) ...[
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
                    flex: 4,
                    child: Text(
                      snapshot.handoffItems[i].name,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      snapshot.handoffItems[i].specs,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      snapshot.handoffItems[i].recipient,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != snapshot.handoffItems.length - 1)
              const SizedBox(height: 10),
          ],
        ],
      ),
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

  Widget _buildStatusTag(String label, Color color) {
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

  Widget _buildColorSwatch(_ColorSwatchSpec swatch) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: swatch.color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            swatch.label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            swatch.hex,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryTile(_GalleryItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 188,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.colors,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Center(child: _buildGalleryPreview(item)),
              ),
              Positioned(
                top: 12,
                left: 12,
                child:
                    _buildStatusTag(item.contextLabel, const Color(0xFF0F172A)),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _buildStatusTag(
                  item.feedbackStatus,
                  item.feedbackStatus == 'Approved'
                      ? AppSemanticColors.success
                      : item.feedbackStatus == 'Needs Review'
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
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
    );
  }

  Widget _buildGalleryPreview(_GalleryItem item) {
    switch (item.previewType) {
      case _PreviewType.mobile:
        return Container(
          width: 96,
          height: 156,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x330F172A)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  height: 16,
                  width: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 10),
                ...List.generate(
                  3,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    height: 18,
                    decoration: BoxDecoration(
                      color: index.isEven
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case _PreviewType.desktop:
        return Container(
          width: 182,
          height: 118,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x330F172A)),
          ),
          child: Column(
            children: [
              Container(
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          children: List.generate(
                            4,
                            (index) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              height: 14,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? const Color(0xFFDBEAFE)
                                    : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case _PreviewType.banner:
        return Container(
          width: 92,
          height: 158,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x330F172A)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case _PreviewType.floorPlan:
        return Container(
          width: 182,
          height: 126,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x330F172A)),
          ),
          child: CustomPaint(
            painter: _FloorPlanPainter(),
            child: const SizedBox.expand(),
          ),
        );
    }
  }

  // Legacy register editors remain below and now feed the dashboard above.

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
      selectedItemBuilder: (context) =>
          items.map((item) => Center(child: Text(item))).toList(),
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
                          onPressed: () =>
                              _openJourneyDialog(existing: journey),
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: Color(0xFF2563EB)),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _journeys
                                .removeWhere((item) => item.id == journey.id));
                            _scheduleSave();
                            _logActivity(
                              'Deleted journey row',
                              details: {'itemId': journey.id},
                            );
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
                      onPressed: () => _openJourneyDialog(existing: journey),
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: Color(0xFF2563EB)),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _journeys
                            .removeWhere((item) => item.id == journey.id));
                        _scheduleSave();
                        _logActivity(
                          'Deleted journey row',
                          details: {'itemId': journey.id},
                        );
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
                          onPressed: () => _openInterfaceDialog(existing: item),
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: Color(0xFF2563EB)),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _interfaces
                                .removeWhere((entry) => entry.id == item.id));
                            _scheduleSave();
                            _logActivity(
                              'Deleted interface row',
                              details: {'itemId': item.id},
                            );
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
                      onPressed: () => _openInterfaceDialog(existing: item),
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: Color(0xFF2563EB)),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _interfaces
                            .removeWhere((entry) => entry.id == item.id));
                        _scheduleSave();
                        _logActivity(
                          'Deleted interface row',
                          details: {'itemId': item.id},
                        );
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
            ..._coreTokens
                .map((e) => _buildDesignElementItem(e, list: _coreTokens)),
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
            _buildEmptyState(
                'No components yet. Add the reusable building blocks.')
          else
            ..._keyComponents
                .map((e) => _buildDesignElementItem(e, list: _keyComponents)),
        ],
      ),
    );
  }

  Widget _buildDesignElementItem(_DesignElement element,
      {required List<_DesignElement> list}) {
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
                          onPressed: () => _openDesignElementDialog(
                            list: list,
                            actionLabel: identical(list, _coreTokens)
                                ? 'design token'
                                : 'key component',
                            existing: element,
                          ),
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: Color(0xFF2563EB)),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => list.removeWhere(
                                (entry) => entry.id == element.id));
                            _scheduleSave();
                            _logActivity(
                              'Deleted design system row',
                              details: {'itemId': element.id},
                            );
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
                      onPressed: () => _openDesignElementDialog(
                        list: list,
                        actionLabel: identical(list, _coreTokens)
                            ? 'design token'
                            : 'key component',
                        existing: element,
                      ),
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: Color(0xFF2563EB)),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => list
                            .removeWhere((entry) => entry.id == element.id));
                        _scheduleSave();
                        _logActivity(
                          'Deleted design system row',
                          details: {'itemId': element.id},
                        );
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

class _UiUxDashboardSnapshot {
  const _UiUxDashboardSnapshot({
    required this.flowNodes,
    required this.colorSwatches,
    required this.typographySamples,
    required this.componentPreviews,
    required this.galleryItems,
    required this.motionItems,
    required this.testingItems,
    required this.accessibilityItems,
    required this.handoffItems,
    required this.aiSignalCount,
  });

  final List<_FlowNode> flowNodes;
  final List<_ColorSwatchSpec> colorSwatches;
  final List<_TypographySample> typographySamples;
  final List<_ComponentPreview> componentPreviews;
  final List<_GalleryItem> galleryItems;
  final List<_MotionItem> motionItems;
  final List<_TestingItem> testingItems;
  final List<_AccessibilityItem> accessibilityItems;
  final List<_HandoffItem> handoffItems;
  final int aiSignalCount;

  int get validatedFlowCount =>
      flowNodes.where((node) => node.status == 'Validated').length;

  factory _UiUxDashboardSnapshot.from({
    required ProjectDataModel projectData,
    required String notes,
    required List<_JourneyItem> journeys,
    required List<_InterfaceItem> interfaces,
    required List<_DesignElement> coreTokens,
    required List<_DesignElement> keyComponents,
    required int selectedGalleryTab,
  }) {
    final trimmedNotes = notes.trim();
    final journeyItems =
        journeys.where((item) => item.title.trim().isNotEmpty).toList();
    final interfaceItems =
        interfaces.where((item) => item.area.trim().isNotEmpty).toList();
    final deliverables = projectData.designDeliverablesData.register;
    final teamMembers = projectData.teamMembers
        .where((member) => member.name.trim().isNotEmpty)
        .toList();

    final flowNodes = <_FlowNode>[
      ...journeyItems.take(3).map(
            (journey) => _FlowNode(
              title: journey.title,
              detail: journey.description.isNotEmpty
                  ? journey.description
                  : 'Critical user journey to validate before build.',
              status: journey.status == 'Mapped' ? 'Validated' : 'Drafting',
            ),
          ),
      ...interfaceItems.take(1).map(
            (item) => _FlowNode(
              title: item.area,
              detail: item.purpose.isNotEmpty
                  ? item.purpose
                  : 'Interface area awaiting deeper structure definition.',
              status: (item.state == 'Final' || item.state == 'Prototype')
                  ? 'Validated'
                  : 'Drafting',
            ),
          ),
    ];

    if (flowNodes.isEmpty) {
      flowNodes.addAll(const [
        _FlowNode(
          title: 'Discover',
          detail: 'Entry point into the product or event journey.',
          status: 'Drafting',
        ),
        _FlowNode(
          title: 'Engage',
          detail: 'Core touchpoint and task completion path.',
          status: 'Validated',
        ),
        _FlowNode(
          title: 'Support',
          detail: 'Fallback, help, and accessibility flow.',
          status: 'Drafting',
        ),
      ]);
    }

    final colorSwatches = [
      const _ColorSwatchSpec('Primary', '#0F172A', Color(0xFF0F172A)),
      const _ColorSwatchSpec('Accent', '#2563EB', Color(0xFF2563EB)),
      const _ColorSwatchSpec('Signal', '#F59E0B', Color(0xFFF59E0B)),
      const _ColorSwatchSpec('Canvas', '#F8FAFC', Color(0xFFF8FAFC)),
    ];

    if (trimmedNotes.contains('#')) {
      final noteHex = RegExp(r'#([A-Fa-f0-9]{6})').firstMatch(trimmedNotes);
      if (noteHex != null) {
        final raw = noteHex.group(1);
        if (raw != null) {
          final parsed = int.tryParse(raw, radix: 16);
          if (parsed != null) {
            colorSwatches[3] = _ColorSwatchSpec(
              'Brief Accent',
              '#$raw',
              Color(0xFF000000 | parsed),
            );
          }
        }
      }
    }

    final typographySamples = const [
      _TypographySample(
        'Display / 32',
        'Event Experience',
        28,
        FontWeight.w800,
      ),
      _TypographySample(
        'Body / 14',
        'Comfortable reading for UI and print.',
        14,
        FontWeight.w500,
      ),
      _TypographySample(
        'Caption / 12',
        'Timings, labels, and redline notes.',
        12,
        FontWeight.w600,
      ),
    ];

    final previewColors = [
      const Color(0xFF2563EB),
      const Color(0xFF0F766E),
      const Color(0xFFF59E0B),
      const Color(0xFF1D4ED8),
    ];
    final componentSource = keyComponents
        .where((element) => element.title.trim().isNotEmpty)
        .take(4)
        .toList();
    final componentPreviews = componentSource.isNotEmpty
        ? List.generate(
            componentSource.length,
            (index) => _ComponentPreview(
              componentSource[index].title,
              previewColors[index % previewColors.length],
            ),
          )
        : const [
            _ComponentPreview('CTA Button', Color(0xFF2563EB)),
            _ComponentPreview('Filter Chip', Color(0xFF0F766E)),
            _ComponentPreview('Banner Module', Color(0xFFF59E0B)),
          ];

    String feedbackFromState(String state) {
      switch (state) {
        case 'Final':
          return 'Approved';
        case 'Prototype':
          return 'Feedback Applied';
        default:
          return 'Needs Review';
      }
    }

    final galleryItems = <_GalleryItem>[
      _GalleryItem(
        tabIndex: 0,
        title: interfaceItems.isNotEmpty
            ? interfaceItems.first.area
            : 'Mobile app journey map',
        subtitle:
            'Low-fidelity flow for task progression, hierarchy, and error recovery.',
        contextLabel: 'Mobile',
        feedbackStatus: interfaceItems.isNotEmpty
            ? feedbackFromState(interfaceItems.first.state)
            : 'Needs Review',
        previewType: _PreviewType.mobile,
        colors: const [Color(0xFFE0F2FE), Color(0xFFDBEAFE)],
      ),
      const _GalleryItem(
        tabIndex: 0,
        title: 'Operations dashboard wireframe',
        subtitle:
            'Desktop status board for schedule, ticketing, and support visibility.',
        contextLabel: 'Desktop',
        feedbackStatus: 'Feedback Applied',
        previewType: _PreviewType.desktop,
        colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
      ),
      const _GalleryItem(
        tabIndex: 0,
        title: 'Roll-up banner concept',
        subtitle: 'Lo-fi sponsor and wayfinding banner composition.',
        contextLabel: 'Roll-up Banner',
        feedbackStatus: 'Needs Review',
        previewType: _PreviewType.banner,
        colors: [Color(0xFFFFFBEB), Color(0xFFFDE68A)],
      ),
      const _GalleryItem(
        tabIndex: 0,
        title: 'Floor plan circulation study',
        subtitle:
            'Layout concept for stage adjacency, queues, and seating zones.',
        contextLabel: 'Floor Plan',
        feedbackStatus: 'Needs Review',
        previewType: _PreviewType.floorPlan,
        colors: [Color(0xFFECFEFF), Color(0xFFCFFAFE)],
      ),
      const _GalleryItem(
        tabIndex: 1,
        title: 'Guest app hi-fi mockups',
        subtitle:
            'Final visual treatment for check-in, schedule, and live updates.',
        contextLabel: 'Mobile',
        feedbackStatus: 'Approved',
        previewType: _PreviewType.mobile,
        colors: [Color(0xFFBFDBFE), Color(0xFF93C5FD)],
      ),
      const _GalleryItem(
        tabIndex: 1,
        title: 'Admin experience visual design',
        subtitle:
            'High-fidelity desktop panel with status, queues, and escalation controls.',
        contextLabel: 'Desktop',
        feedbackStatus: 'Feedback Applied',
        previewType: _PreviewType.desktop,
        colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
      ),
      const _GalleryItem(
        tabIndex: 1,
        title: 'Sponsor banner artwork',
        subtitle:
            'Brand-aligned print asset for foyer signage and photo moments.',
        contextLabel: 'Roll-up Banner',
        feedbackStatus: 'Approved',
        previewType: _PreviewType.banner,
        colors: [Color(0xFFFDE68A), Color(0xFFFCD34D)],
      ),
      const _GalleryItem(
        tabIndex: 1,
        title: 'Venue floor plan final pack',
        subtitle:
            'Spatial legend, paths, and activation zones ready for operations handoff.',
        contextLabel: 'Floor Plan',
        feedbackStatus: 'Feedback Applied',
        previewType: _PreviewType.floorPlan,
        colors: [Color(0xFFA7F3D0), Color(0xFF99F6E4)],
      ),
    ];

    final motionItems = const [
      _MotionItem(
        'Button Hover',
        'Pointer hover',
        '120ms ease-out / 8% scale lift',
      ),
      _MotionItem(
        'Drawer Transition',
        'Menu open',
        '220ms slide with fade',
      ),
      _MotionItem(
        'Stage Lighting',
        'Show cue or keynote intro',
        '350ms fade / 1.8s wash',
      ),
      _MotionItem(
        'Banner Reveal',
        'Registration open moment',
        '400ms slide-up / 80ms stagger',
      ),
    ];

    final testingItems = [
      _TestingItem(
        'Walkthrough',
        journeyItems.isNotEmpty
            ? 'The ${journeyItems.first.title.toLowerCase()} path reads clearly, but secondary actions still need hierarchy tuning.'
            : 'Primary task completion is readable, but secondary actions need clearer hierarchy.',
        'Recorded',
        AppSemanticColors.success,
      ),
      const _TestingItem(
        'A/B Test',
        'Desktop navigation labels performed better when grouped by goal rather than team function.',
        'In Review',
        Color(0xFFF59E0B),
      ),
      const _TestingItem(
        'Venue Walkthrough',
        'Wayfinding artwork needs stronger contrast at long viewing distances near the foyer.',
        'Action Required',
        Color(0xFFDC2626),
      ),
    ];

    final accessibilityItems = [
      _AccessibilityItem(
        'Color Contrast',
        coreTokens.any((item) => item.title.toLowerCase().contains('color')),
      ),
      _AccessibilityItem('Keyboard Focus', componentSource.isNotEmpty),
      _AccessibilityItem('Screen Reader Labels', journeyItems.isNotEmpty),
      _AccessibilityItem(
        'Wheelchair Access',
        interfaceItems.any(
          (item) =>
              item.area.toLowerCase().contains('floor') ||
              item.area.toLowerCase().contains('venue'),
        ),
      ),
      _AccessibilityItem(
        'Signage Readability',
        interfaceItems.any(
          (item) =>
              item.area.toLowerCase().contains('banner') ||
              item.purpose.toLowerCase().contains('wayfinding'),
        ),
      ),
    ];

    String recipientFor(String name) {
      final lower = name.toLowerCase();
      if (lower.contains('banner') || lower.contains('print')) return 'Printer';
      if (lower.contains('floor') || lower.contains('venue')) {
        return 'Venue Ops';
      }
      return 'Developer';
    }

    String specsFor(String name) {
      final lower = name.toLowerCase();
      if (lower.contains('banner')) return '850x2000mm / Print-ready PDF';
      if (lower.contains('floor')) return 'A1 plan / legend + callouts';
      if (lower.contains('desktop')) return 'Redlines / 1440px grid';
      return 'Redlines / responsive specs';
    }

    final handoffItems = deliverables.isNotEmpty
        ? deliverables.take(4).map((item) {
            final name = item.name.isNotEmpty ? item.name : 'UI asset package';
            return _HandoffItem(name, specsFor(name), recipientFor(name));
          }).toList()
        : [
            const _HandoffItem(
              'Guest app screen set',
              'Redlines / responsive specs',
              'Developer',
            ),
            const _HandoffItem(
              'Sponsor roll-up banner',
              '850x2000mm / Print-ready PDF',
              'Printer',
            ),
            const _HandoffItem(
              'Venue floor plan pack',
              'A1 plan / legend + callouts',
              'Venue Ops',
            ),
          ];

    final aiSignalCount =
        projectData.aiUsageCounts.values.fold<int>(0, (total, value) {
              return total + value;
            }) +
            projectData.aiRecommendations.length +
            projectData.aiIntegrations.length +
            (trimmedNotes.isNotEmpty ? 1 : 0) +
            (selectedGalleryTab == 1 ? 1 : 0) +
            teamMembers.length;

    return _UiUxDashboardSnapshot(
      flowNodes: flowNodes,
      colorSwatches: colorSwatches,
      typographySamples: typographySamples,
      componentPreviews: componentPreviews,
      galleryItems: galleryItems,
      motionItems: motionItems,
      testingItems: testingItems,
      accessibilityItems: accessibilityItems,
      handoffItems: handoffItems,
      aiSignalCount: aiSignalCount,
    );
  }
}

class _FlowNode {
  const _FlowNode({
    required this.title,
    required this.detail,
    required this.status,
  });

  final String title;
  final String detail;
  final String status;
}

class _ColorSwatchSpec {
  const _ColorSwatchSpec(this.label, this.hex, this.color);

  final String label;
  final String hex;
  final Color color;
}

class _TypographySample {
  const _TypographySample(
    this.label,
    this.preview,
    this.fontSize,
    this.weight,
  );

  final String label;
  final String preview;
  final double fontSize;
  final FontWeight weight;
}

class _ComponentPreview {
  const _ComponentPreview(this.label, this.color);

  final String label;
  final Color color;
}

enum _PreviewType { mobile, desktop, banner, floorPlan }

class _GalleryItem {
  const _GalleryItem({
    required this.tabIndex,
    required this.title,
    required this.subtitle,
    required this.contextLabel,
    required this.feedbackStatus,
    required this.previewType,
    required this.colors,
  });

  final int tabIndex;
  final String title;
  final String subtitle;
  final String contextLabel;
  final String feedbackStatus;
  final _PreviewType previewType;
  final List<Color> colors;
}

class _MotionItem {
  const _MotionItem(this.label, this.trigger, this.specs);

  final String label;
  final String trigger;
  final String specs;
}

class _TestingItem {
  const _TestingItem(this.method, this.finding, this.status, this.statusColor);

  final String method;
  final String finding;
  final String status;
  final Color statusColor;
}

class _AccessibilityItem {
  const _AccessibilityItem(this.label, this.passed);

  final String label;
  final bool passed;
}

class _HandoffItem {
  const _HandoffItem(this.name, this.specs, this.recipient);

  final String name;
  final String specs;
  final String recipient;
}

class _FloorPlanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final routePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 3;
    final zonePaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    final highlightPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, zonePaint);
    canvas.drawRRect(rect, borderPaint);

    final boothRect =
        Rect.fromLTWH(24, 24, size.width * 0.28, size.height * 0.24);
    final stageRect = Rect.fromLTWH(
      size.width * 0.62,
      24,
      size.width * 0.18,
      size.height * 0.18,
    );
    final seatingRect = Rect.fromLTWH(
      size.width * 0.46,
      size.height * 0.52,
      size.width * 0.28,
      size.height * 0.2,
    );
    canvas.drawRect(boothRect, highlightPaint);
    canvas.drawRect(stageRect, highlightPaint);
    canvas.drawRect(seatingRect, highlightPaint);
    canvas.drawRect(boothRect, borderPaint);
    canvas.drawRect(stageRect, borderPaint);
    canvas.drawRect(seatingRect, borderPaint);

    canvas.drawLine(
      Offset(size.width * 0.16, size.height * 0.82),
      Offset(size.width * 0.84, size.height * 0.82),
      routePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.82),
      Offset(size.width * 0.38, size.height * 0.28),
      routePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.28),
      Offset(size.width * 0.62, size.height * 0.28),
      routePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
