// ignore_for_file: unused_element

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/services/activity_log_service.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/screens/backend_design_screen.dart';
import 'package:ndu_project/screens/development_set_up_screen.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/utils/design_planning_document.dart';

class UiUxDesignScreen extends StatefulWidget {
  const UiUxDesignScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UiUxDesignScreen()),
    );
  }

  @override
  State<UiUxDesignScreen> createState() => _UiUxDesignScreenState();
}

class _UiUxDesignScreenState extends State<UiUxDesignScreen> {
  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;
  bool _didSeedDefaults = false;

  final Set<String> _selectedFilters = {'All items'};

  // User Journey Register
  List<_JourneyRow> _journeys = [];

  // Interface Architecture Register
  List<_InterfaceRow> _interfaces = [];

  // Design System Tokens Register
  List<_DesignTokenRow> _designTokens = [];

  // Usability & Accessibility Validation Register
  List<_UsabilityRow> _usabilityEntries = [];

  // Design Review Gates
  List<_ReviewGateRow> _reviewGates = [];

  static const List<String> _journeyStatusOptions = [
    'Mapped',
    'Draft',
    'Planned',
    'In progress',
    'Validated',
    'Deprecated',
  ];

  static const List<String> _interfaceStateOptions = [
    'Wireframe',
    'User flow map',
    'To define',
    'Prototype',
    'Final',
    'Deprecated',
  ];

  static const List<String> _tokenStatusOptions = [
    'Ready',
    'Draft',
    'In review',
    'Planned',
    'Deprecated',
  ];

  static const List<String> _usabilityStatusOptions = [
    'Pass',
    'Fail',
    'In progress',
    'Not tested',
    'Conditional',
  ];

  static const List<String> _reviewGateStatusOptions = [
    'Pending',
    'In Review',
    'Approved',
    'Rejected',
    'Waived',
  ];

  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _journeys = _defaultJourneys();
    _interfaces = _defaultInterfaces();
    _designTokens = _defaultDesignTokens();
    _usabilityEntries = _defaultUsabilityEntries();
    _reviewGates = _defaultReviewGates();
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
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
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
      final journeys = _JourneyRow.fromList(data['journeys']);
      final interfaces = _InterfaceRow.fromList(data['interfaces']);
      final designTokens = _DesignTokenRow.fromList(data['designTokens']);
      final usabilityEntries = _UsabilityRow.fromList(data['usabilityEntries']);
      final reviewGates = _ReviewGateRow.fromList(data['reviewGates']);
      shouldSeedDefaults = data.isEmpty && !_didSeedDefaults;
      setState(() {
        if (shouldSeedDefaults) {
          _didSeedDefaults = true;
          final planningDoc = DesignPlanningDocument.fromProjectData(
            provider?.projectData ?? ProjectDataModel(),
          );
          _journeys = planningDoc.journeys.isEmpty
              ? _defaultJourneys()
              : planningDoc.journeys
                  .map((item) => _JourneyRow(
                        id: _newId(),
                        title: item.name,
                        description: item.purpose,
                        touchpoints: 'TBD',
                        owner: 'UX Lead',
                        priority: 'Medium',
                        status: item.status.isEmpty ? 'Planned' : item.status,
                      ))
                  .toList();
          _interfaces = planningDoc.interfaces.isEmpty
              ? _defaultInterfaces()
              : planningDoc.interfaces
                  .map((item) => _InterfaceRow(
                        id: _newId(),
                        area: item.name,
                        purpose: item.purpose,
                        fidelity: 'Low',
                        owner: 'UI Designer',
                        status: item.status.isEmpty ? 'To define' : item.status,
                      ))
                  .toList();
          _designTokens = _defaultDesignTokens();
          _usabilityEntries = _defaultUsabilityEntries();
          _reviewGates = _defaultReviewGates();
        } else {
          _journeys = data.containsKey('journeys') && journeys.isNotEmpty
              ? journeys
              : _defaultJourneys();
          _interfaces = data.containsKey('interfaces') && interfaces.isNotEmpty
              ? interfaces
              : _defaultInterfaces();
          _designTokens =
              data.containsKey('designTokens') && designTokens.isNotEmpty
                  ? designTokens
                  : _defaultDesignTokens();
          _usabilityEntries =
              data.containsKey('usabilityEntries') && usabilityEntries.isNotEmpty
                  ? usabilityEntries
                  : _defaultUsabilityEntries();
          _reviewGates =
              data.containsKey('reviewGates') && reviewGates.isNotEmpty
                  ? reviewGates
                  : _defaultReviewGates();
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
        'journeys': _journeys.map((e) => e.toMap()).toList(),
        'interfaces': _interfaces.map((e) => e.toMap()).toList(),
        'designTokens': _designTokens.map((e) => e.toMap()).toList(),
        'usabilityEntries': _usabilityEntries.map((e) => e.toMap()).toList(),
        'reviewGates': _reviewGates.map((e) => e.toMap()).toList(),
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
    }
  }

  // ─── Default Data ────────────────────────────────────────────────

  List<_JourneyRow> _defaultJourneys() {
    return [
      _JourneyRow(
        id: _newId(),
        title: 'User onboarding & first-time setup',
        description: 'Guided registration, profile creation, and preference configuration for new users entering the system for the first time.',
        touchpoints: '5 screens, 2 modals',
        owner: 'UX Lead',
        priority: 'Critical',
        status: 'Mapped',
      ),
      _JourneyRow(
        id: _newId(),
        title: 'Core task completion flow',
        description: 'Primary workflow from task initiation through data entry, validation, and successful completion with confirmation feedback.',
        touchpoints: '8 screens, 3 API calls',
        owner: 'Product Designer',
        priority: 'Critical',
        status: 'In progress',
      ),
      _JourneyRow(
        id: _newId(),
        title: 'Error recovery & support escalation',
        description: 'Error state handling, inline validation feedback, help documentation access, and escalation path to live support channels.',
        touchpoints: '4 screens, 1 modal',
        owner: 'UX Researcher',
        priority: 'High',
        status: 'Draft',
      ),
      _JourneyRow(
        id: _newId(),
        title: 'Dashboard navigation & data discovery',
        description: 'Entry point navigation, filter-based search, saved views, and contextual drill-down into detailed records and reports.',
        touchpoints: '6 screens',
        owner: 'UX Lead',
        priority: 'High',
        status: 'Planned',
      ),
      _JourneyRow(
        id: _newId(),
        title: 'Administrative configuration & settings',
        description: 'System settings, user role management, permission configuration, and organizational preference controls for admin users.',
        touchpoints: '7 screens, 2 confirmation dialogs',
        owner: 'Product Designer',
        priority: 'Medium',
        status: 'Planned',
      ),
    ];
  }

  List<_InterfaceRow> _defaultInterfaces() {
    return [
      _InterfaceRow(
        id: _newId(),
        area: 'Web application - Dashboard',
        purpose: 'Primary entry point displaying KPI summaries, recent activity, and navigation shortcuts for authenticated users.',
        fidelity: 'High',
        owner: 'UI Designer',
        status: 'Prototype',
      ),
      _InterfaceRow(
        id: _newId(),
        area: 'Mobile responsive - Task management',
        purpose: 'Touch-optimized task list with swipe actions, pull-to-refresh, and contextual bottom sheets for quick edits.',
        fidelity: 'Medium',
        owner: 'UI Designer',
        status: 'Wireframe',
      ),
      _InterfaceRow(
        id: _newId(),
        area: 'Authentication & authorization screens',
        purpose: 'Login, MFA verification, password reset, and session timeout handling with SSO integration points.',
        fidelity: 'High',
        owner: 'UX Lead',
        status: 'Prototype',
      ),
      _InterfaceRow(
        id: _newId(),
        area: 'Data visualization & reporting module',
        purpose: 'Interactive charts, exportable reports, date range selectors, and comparison views for analytical use cases.',
        fidelity: 'Low',
        owner: 'Product Designer',
        status: 'User flow map',
      ),
      _InterfaceRow(
        id: _newId(),
        area: 'Notification center & alert preferences',
        purpose: 'In-app notification feed, read/unread states, alert configuration, and channel preferences (email, push, in-app).',
        fidelity: 'Low',
        owner: 'UI Designer',
        status: 'To define',
      ),
    ];
  }

  List<_DesignTokenRow> _defaultDesignTokens() {
    return [
      _DesignTokenRow(
        id: _newId(),
        title: 'Color palette - Primary',
        description: 'Brand primary (#0F172A), secondary (#2563EB), accent (#F59E0B), surface (#F8FAFC) with usage rules for dark/light themes.',
        category: 'Colors',
        status: 'Ready',
        owner: 'Design Systems Lead',
      ),
      _DesignTokenRow(
        id: _newId(),
        title: 'Typography scale',
        description: 'Display (48/40/32), headings (24/20/18), body (16/14), caption (12/11). Inter for UI, Satoshi for display. Line heights and letter spacing defined.',
        category: 'Typography',
        status: 'Ready',
        owner: 'Design Systems Lead',
      ),
      _DesignTokenRow(
        id: _newId(),
        title: 'Spacing & grid system',
        description: '4px base unit, 8/12/16/24/32/48/64 spacing scale. 12-column grid with 24px gutters for responsive layouts.',
        category: 'Layout',
        status: 'Ready',
        owner: 'Design Systems Lead',
      ),
      _DesignTokenRow(
        id: _newId(),
        title: 'Elevation & shadow tokens',
        description: '5 elevation levels (0-4) with corresponding box shadows for cards, modals, dropdowns, and floating elements.',
        category: 'Effects',
        status: 'Draft',
        owner: 'UI Designer',
      ),
      _DesignTokenRow(
        id: _newId(),
        title: 'Interaction states & micro-animations',
        description: 'Hover, focus, active, disabled, loading, success, and error states with 200ms transition curves and motion guidelines.',
        category: 'Motion',
        status: 'Draft',
        owner: 'UX Lead',
      ),
      _DesignTokenRow(
        id: _newId(),
        title: 'Iconography system',
        description: '24px grid, 2px stroke, rounded caps. Material Symbols as base with custom overrides for domain-specific actions.',
        category: 'Iconography',
        status: 'In review',
        owner: 'UI Designer',
      ),
    ];
  }

  List<_UsabilityRow> _defaultUsabilityEntries() {
    return [
      _UsabilityRow(
        id: _newId(),
        criteria: 'WCAG 2.1 AA color contrast',
        description: 'All text and interactive elements must maintain minimum 4.5:1 contrast ratio against backgrounds in both light and dark themes.',
        standard: 'WCAG 2.1 AA',
        status: 'Pass',
        owner: 'QA Lead',
        notes: 'Automated check passed; manual verification pending for custom components',
      ),
      _UsabilityRow(
        id: _newId(),
        criteria: 'Keyboard navigation completeness',
        description: 'All interactive elements must be reachable and operable via keyboard alone, following logical tab order with visible focus indicators.',
        standard: 'WCAG 2.1 AA / Section 508',
        status: 'In progress',
        owner: 'UX Researcher',
        notes: 'Main flows covered; modal trap and dropdown keyboard support in progress',
      ),
      _UsabilityRow(
        id: _newId(),
        criteria: 'Screen reader compatibility',
        description: 'All content and interactive elements properly announced by VoiceOver (iOS) and TalkBack (Android) with meaningful labels and roles.',
        standard: 'WCAG 2.1 AA / ARIA',
        status: 'Not tested',
        owner: 'QA Lead',
        notes: 'Scheduled for next sprint after component library finalization',
      ),
      _UsabilityRow(
        id: _newId(),
        criteria: 'Touch target sizing (mobile)',
        description: 'All tappable elements minimum 44x44px with adequate spacing to prevent accidental activation on touch devices.',
        standard: 'WCAG 2.1 AA / iOS HIG / Material',
        status: 'Pass',
        owner: 'UI Designer',
        notes: 'Verified on iOS and Android reference devices',
      ),
      _UsabilityRow(
        id: _newId(),
        criteria: 'Task completion rate (core flow)',
        description: 'Minimum 85% of test participants must complete the primary task flow without assistance within expected time benchmarks.',
        standard: 'NNG Usability Benchmark',
        status: 'Not tested',
        owner: 'UX Researcher',
        notes: 'Unmoderated usability test scheduled for next design review cycle',
      ),
    ];
  }

  List<_ReviewGateRow> _defaultReviewGates() {
    return [
      _ReviewGateRow(
        id: _newId(),
        gate: 'Information Architecture Sign-off',
        description: 'Validate sitemap, navigation hierarchy, user flow maps, and content structure against business requirements and user research findings.',
        approver: 'Product Owner',
        department: 'Product',
        priority: 'Critical',
        status: 'Approved',
        targetDate: 'TBD',
      ),
      _ReviewGateRow(
        id: _newId(),
        gate: 'Wireframe & Low-Fidelity Review',
        description: 'Review wireframes for layout, information hierarchy, interaction patterns, and responsive breakpoint behavior before high-fidelity investment.',
        approver: 'UX Lead',
        department: 'Design',
        priority: 'Critical',
        status: 'In Review',
        targetDate: 'TBD',
      ),
      _ReviewGateRow(
        id: _newId(),
        gate: 'Design System Token Validation',
        description: 'Confirm design tokens (colors, typography, spacing, elevation) meet brand guidelines, accessibility standards, and cross-platform rendering requirements.',
        approver: 'Design Systems Lead',
        department: 'Design',
        priority: 'High',
        status: 'Pending',
        targetDate: 'TBD',
      ),
      _ReviewGateRow(
        id: _newId(),
        gate: 'High-Fidelity Prototype Approval',
        description: 'Review interactive prototypes against requirements, validate animations and transitions, confirm responsive behavior across target devices.',
        approver: 'Product Owner',
        department: 'Product',
        priority: 'High',
        status: 'Pending',
        targetDate: 'TBD',
      ),
      _ReviewGateRow(
        id: _newId(),
        gate: 'Accessibility Compliance Check',
        description: 'Verify WCAG 2.1 AA compliance across all interfaces, including color contrast, keyboard navigation, screen reader support, and touch targets.',
        approver: 'QA Lead',
        department: 'Quality',
        priority: 'Critical',
        status: 'Pending',
        targetDate: 'TBD',
      ),
      _ReviewGateRow(
        id: _newId(),
        gate: 'Design Handoff & Developer Acceptance',
        description: 'Final design handoff with annotated specs, asset exports, interaction documentation, and developer sign-off confirming build feasibility.',
        approver: 'Technical Lead',
        department: 'Engineering',
        priority: 'High',
        status: 'Not Started',
        targetDate: 'TBD',
      ),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'UI/UX Design',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(positioned: false),
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
                  if (_isLoading) const SizedBox(height: 16),
                  _buildHeader(isNarrow),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 20),
                  _buildStatsRow(isNarrow),
                  const SizedBox(height: 20),
                  _buildUXFrameworkGuide(),
                  const SizedBox(height: 24),
                  _buildJourneyRegister(),
                  const SizedBox(height: 20),
                  _buildInterfaceRegister(),
                  const SizedBox(height: 20),
                  _buildDesignTokenRegister(),
                  const SizedBox(height: 20),
                  _buildUsabilityRegister(),
                  const SizedBox(height: 20),
                  _buildReviewGatesPanel(),
                  const SizedBox(height: 24),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: Development Set Up',
                    nextLabel: 'Next: Backend Design',
                    onBack: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DevelopmentSetUpScreen())),
                    onNext: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BackendDesignScreen())),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────

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
            'EXPERIENCE DESIGN',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = isNarrow || constraints.maxWidth < 1040;
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'UI/UX Design',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
                SizedBox(height: 6),
                Text(
                  'Manage user journeys, interface architecture, design system tokens, and usability validation for the project. '
                  'Aligned with ISO 9241-210 Human-Centred Design, Nielsen Norman Group usability heuristics, '
                  'and WCAG 2.1 accessibility standards. This register ensures experience design decisions remain '
                  'traceable, testable, and reviewable throughout the design phase.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleBlock,
                  const SizedBox(height: 12),
                  _buildHeaderActions(),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 20),
                Flexible(child: _buildHeaderActions()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _actionButton(Icons.add, 'Add journey',
            onPressed: () => _showJourneyDialog()),
        _actionButton(Icons.upload_outlined, 'Import design tokens',
            onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Import design tokens from Figma or JSON is available from the Design System Tokens register.')),
          );
        }),
        _actionButton(Icons.description_outlined, 'Export spec',
            onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Export specification is queued. Use the registers while export tools are finalized.')),
          );
        }),
        _primaryButton('Start design review'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
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
        setState(() {
          _selectedFilters
            ..clear()
            ..add('Review pending');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Design review started. Filter set to items pending review.')),
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

  // ─── Filter Chips ────────────────────────────────────────────────

  Widget _buildFilterChips() {
    const filters = [
      'All items',
      'Journeys',
      'Interfaces',
      'Design system',
      'Validation',
      'Review pending',
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final selected = _selectedFilters.contains(filter);
        return ChoiceChip(
          label: Text(
            filter,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
          ),
          selected: selected,
          selectedColor: const Color(0xFF111827),
          backgroundColor: Colors.white,
          shape: StadiumBorder(
            side: BorderSide(color: const Color(0xFFE5E7EB)),
          ),
          onSelected: (value) {
            setState(() {
              if (value) {
                if (filter == 'All items') {
                  _selectedFilters
                    ..clear()
                    ..add(filter);
                } else {
                  _selectedFilters
                    ..remove('All items')
                    ..add(filter);
                }
              } else {
                _selectedFilters.remove(filter);
                if (_selectedFilters.isEmpty) {
                  _selectedFilters.add('All items');
                }
              }
            });
          },
        );
      }).toList(),
    );
  }

  bool get _showJourneys =>
      _selectedFilters.contains('All items') ||
      _selectedFilters.contains('Journeys');
  bool get _showInterfaces =>
      _selectedFilters.contains('All items') ||
      _selectedFilters.contains('Interfaces');
  bool get _showDesignTokens =>
      _selectedFilters.contains('All items') ||
      _selectedFilters.contains('Design system');
  bool get _showUsability =>
      _selectedFilters.contains('All items') ||
      _selectedFilters.contains('Validation');
  bool get _showReviewGates =>
      _selectedFilters.contains('All items') ||
      _selectedFilters.contains('Review pending');

  // ─── Stats Row ────────────────────────────────────────────────────

  Widget _buildStatsRow(bool isNarrow) {
    final journeyMapped =
        _journeys.where((j) => j.status == 'Mapped' || j.status == 'Validated').length;
    final interfaceFinal =
        _interfaces.where((i) => i.status == 'Final' || i.status == 'Prototype').length;
    final tokenReady =
        _designTokens.where((t) => t.status == 'Ready').length;
    final reviewPending =
        _reviewGates.where((g) => g.status == 'Pending' || g.status == 'In Review').length;

    final stats = [
      _StatCardData(
        '${_journeys.length}',
        'User Journeys',
        '$journeyMapped validated',
        const Color(0xFF0EA5E9),
      ),
      _StatCardData(
        '${_interfaces.length}',
        'Interfaces',
        '$interfaceFinal at prototype+',
        const Color(0xFF10B981),
      ),
      _StatCardData(
        '${_designTokens.length}',
        'Design Tokens',
        '$tokenReady ready',
        const Color(0xFFF97316),
      ),
      _StatCardData(
        '$reviewPending',
        'Pending Reviews',
        reviewPending > 0 ? 'Require attention' : 'All reviewed',
        const Color(0xFF6366F1),
      ),
    ];

    if (isNarrow) {
      return Column(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            SizedBox(width: double.infinity, child: _buildStatCard(stats[i])),
            if (i < stats.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          Expanded(child: _buildStatCard(stats[i])),
          if (i < stats.length - 1) const SizedBox(width: 12),
        ],
      ],
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

  // ─── UX Framework Guide ────────────────────────────────────────────

  Widget _buildUXFrameworkGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Experience design framework',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Grounded in ISO 9241-210 Human-Centred Design for Interactive Systems, '
            'Nielsen Norman Group usability heuristics, WCAG 2.1 accessibility guidelines, '
            'and Google Material Design 3 principles. Effective experience design ensures '
            'that user needs, task flows, and interaction patterns remain validated, consistent, '
            'and accessible across all touchpoints throughout the project lifecycle.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Column(
            children: [
              _buildGuideCard(
                Icons.route_outlined,
                'User Journey Mapping',
                'Define end-to-end user journeys from entry to task completion. Map touchpoints, '
                    'decision points, and emotional arcs. Validate journeys against user research '
                    'and business objectives before investing in interface design.',
                const Color(0xFF2563EB),
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                Icons.widgets_outlined,
                'Interface Architecture',
                'Structure screens, navigation patterns, and information hierarchy. Define '
                    'fidelity levels from wireframe to final prototype. Ensure consistent '
                    'interaction patterns across responsive breakpoints and platforms.',
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                Icons.palette_outlined,
                'Design System & Tokens',
                'Establish shared visual language through design tokens: colors, typography, '
                    'spacing, elevation, and motion. Tokens ensure consistency, enable '
                    'theme switching, and bridge the design-to-development handoff gap.',
                const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                Icons.accessibility_new_outlined,
                'Usability & Accessibility',
                'Validate interfaces against WCAG 2.1 AA, Section 508, and platform-specific '
                    'accessibility guidelines. Conduct usability testing with representative users. '
                    'Track compliance status and remediation actions systematically.',
                const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(IconData icon, String title, String description, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Panel Shell ────────────────────────────────────────────────

  Widget _buildPanelShell({
    required String title,
    required String subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
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
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          child,
        ],
      ),
    );
  }

  // ─── User Journey Register ──────────────────────────────────────

  Widget _buildJourneyRegister() {
    if (!_showJourneys) return const SizedBox.shrink();
    return _buildPanelShell(
      title: 'User journey register',
      subtitle: 'Track user journeys, touchpoints, owners, and validation status aligned with ISO 9241-210 human-centred design process.',
      trailing: OutlinedButton.icon(
        onPressed: () => _showJourneyDialog(),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add journey', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF475569),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: _journeys.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No journeys defined. Add a user journey to start tracking.', style: TextStyle(color: Color(0xFF64748B)))),
            )
          : Column(
              children: [
                _buildTableHeader([
                  _ColDef('JOURNEY', flex: 4),
                  _ColDef('TOUCHPOINTS', width: 130),
                  _ColDef('OWNER', width: 110),
                  _ColDef('PRIORITY', width: 90),
                  _ColDef('STATUS', width: 100),
                  _ColDef('', width: 60),
                ]),
                ...List.generate(_journeys.length, (i) {
                  final row = _journeys[i];
                  return _buildTableRow(
                    cells: [
                      _CellDef(Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                            const SizedBox(height: 2),
                            Text(row.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4)),
                          ],
                        ),
                      )),
                      _CellDef(SizedBox(width: 130, child: Text(row.touchpoints, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))))),
                      _CellDef(SizedBox(width: 110, child: Text(row.owner, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))))),
                      _CellDef(SizedBox(width: 90, child: _buildPriorityTag(row.priority))),
                      _CellDef(SizedBox(width: 100, child: _buildStatusTag(row.status))),
                      _CellDef(SizedBox(
                        width: 60,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showJourneyDialog(existing: row), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)), onPressed: () => _confirmDelete(() => _deleteJourney(row)), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          ],
                        ),
                      )),
                    ],
                    isLast: i == _journeys.length - 1,
                  );
                }),
              ],
            ),
    );
  }

  // ─── Interface Architecture Register ─────────────────────────────

  Widget _buildInterfaceRegister() {
    if (!_showInterfaces) return const SizedBox.shrink();
    return _buildPanelShell(
      title: 'Interface architecture register',
      subtitle: 'Track interface areas, fidelity levels, and design states aligned with progressive design maturity from wireframe to production.',
      trailing: OutlinedButton.icon(
        onPressed: () => _showInterfaceDialog(),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add interface', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF475569),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: _interfaces.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No interfaces defined. Add an interface area to start tracking.', style: TextStyle(color: Color(0xFF64748B)))),
            )
          : Column(
              children: [
                _buildTableHeader([
                  _ColDef('INTERFACE', flex: 4),
                  _ColDef('FIDELITY', width: 90),
                  _ColDef('OWNER', width: 110),
                  _ColDef('STATE', width: 110),
                  _ColDef('', width: 60),
                ]),
                ...List.generate(_interfaces.length, (i) {
                  final row = _interfaces[i];
                  return _buildTableRow(
                    cells: [
                      _CellDef(Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.area, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                            const SizedBox(height: 2),
                            Text(row.purpose, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4)),
                          ],
                        ),
                      )),
                      _CellDef(SizedBox(width: 90, child: _buildFidelityTag(row.fidelity))),
                      _CellDef(SizedBox(width: 110, child: Text(row.owner, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))))),
                      _CellDef(SizedBox(width: 110, child: _buildInterfaceStateTag(row.status))),
                      _CellDef(SizedBox(
                        width: 60,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showInterfaceDialog(existing: row), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)), onPressed: () => _confirmDelete(() => _deleteInterface(row)), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          ],
                        ),
                      )),
                    ],
                    isLast: i == _interfaces.length - 1,
                  );
                }),
              ],
            ),
    );
  }

  // ─── Design System Tokens Register ────────────────────────────────

  Widget _buildDesignTokenRegister() {
    if (!_showDesignTokens) return const SizedBox.shrink();
    return _buildPanelShell(
      title: 'Design system tokens register',
      subtitle: 'Track design tokens, categories, and readiness status to maintain visual consistency and enable efficient design-to-development handoff.',
      trailing: OutlinedButton.icon(
        onPressed: () => _showDesignTokenDialog(),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add token', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF475569),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: _designTokens.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No design tokens defined. Add a token to start tracking.', style: TextStyle(color: Color(0xFF64748B)))),
            )
          : Column(
              children: [
                _buildTableHeader([
                  _ColDef('TOKEN', flex: 4),
                  _ColDef('CATEGORY', width: 110),
                  _ColDef('OWNER', width: 130),
                  _ColDef('STATUS', width: 90),
                  _ColDef('', width: 60),
                ]),
                ...List.generate(_designTokens.length, (i) {
                  final row = _designTokens[i];
                  return _buildTableRow(
                    cells: [
                      _CellDef(Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                            const SizedBox(height: 2),
                            Text(row.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4)),
                          ],
                        ),
                      )),
                      _CellDef(SizedBox(width: 110, child: _buildCategoryTag(row.category))),
                      _CellDef(SizedBox(width: 130, child: Text(row.owner, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))))),
                      _CellDef(SizedBox(width: 90, child: _buildTokenStatusTag(row.status))),
                      _CellDef(SizedBox(
                        width: 60,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showDesignTokenDialog(existing: row), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)), onPressed: () => _confirmDelete(() => _deleteDesignToken(row)), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          ],
                        ),
                      )),
                    ],
                    isLast: i == _designTokens.length - 1,
                  );
                }),
              ],
            ),
    );
  }

  // ─── Usability & Accessibility Register ─────────────────────────

  Widget _buildUsabilityRegister() {
    if (!_showUsability) return const SizedBox.shrink();
    return _buildPanelShell(
      title: 'Usability & accessibility validation',
      subtitle: 'Track WCAG compliance, usability benchmarks, and accessibility testing status aligned with ISO 9241 and Section 508 requirements.',
      trailing: OutlinedButton.icon(
        onPressed: () => _showUsabilityDialog(),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add criteria', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF475569),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: _usabilityEntries.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No validation criteria defined. Add criteria to start tracking.', style: TextStyle(color: Color(0xFF64748B)))),
            )
          : Column(
              children: [
                _buildTableHeader([
                  _ColDef('CRITERIA', flex: 4),
                  _ColDef('STANDARD', width: 120),
                  _ColDef('OWNER', width: 100),
                  _ColDef('STATUS', width: 100),
                  _ColDef('', width: 60),
                ]),
                ...List.generate(_usabilityEntries.length, (i) {
                  final row = _usabilityEntries[i];
                  return _buildTableRow(
                    cells: [
                      _CellDef(Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.criteria, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                            const SizedBox(height: 2),
                            Text(row.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4)),
                          ],
                        ),
                      )),
                      _CellDef(SizedBox(width: 120, child: Text(row.standard, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))))),
                      _CellDef(SizedBox(width: 100, child: Text(row.owner, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))))),
                      _CellDef(SizedBox(width: 100, child: _buildUsabilityStatusTag(row.status))),
                      _CellDef(SizedBox(
                        width: 60,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showUsabilityDialog(existing: row), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)), onPressed: () => _confirmDelete(() => _deleteUsability(row)), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          ],
                        ),
                      )),
                    ],
                    isLast: i == _usabilityEntries.length - 1,
                  );
                }),
              ],
            ),
    );
  }

  // ─── Design Review Gates ────────────────────────────────────────

  Widget _buildReviewGatesPanel() {
    if (!_showReviewGates) return const SizedBox.shrink();
    return _buildPanelShell(
      title: 'Design review gates',
      subtitle: 'Approval checkpoints aligned with ISO 9241-210 design review cycles. Each gate must be cleared before proceeding to the next design maturity level.',
      trailing: OutlinedButton.icon(
        onPressed: () => _showReviewGateDialog(),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add gate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF475569),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: _reviewGates.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No review gates defined. Add a gate to start tracking design reviews.', style: TextStyle(color: Color(0xFF64748B)))),
            )
          : Column(
              children: [
                _buildTableHeader([
                  _ColDef('GATE', flex: 4),
                  _ColDef('APPROVER', width: 120),
                  _ColDef('PRIORITY', width: 80),
                  _ColDef('STATUS', width: 100),
                  _ColDef('', width: 60),
                ]),
                ...List.generate(_reviewGates.length, (i) {
                  final row = _reviewGates[i];
                  return _buildTableRow(
                    cells: [
                      _CellDef(Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.gate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                            const SizedBox(height: 2),
                            Text(row.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4)),
                          ],
                        ),
                      )),
                      _CellDef(SizedBox(width: 120, child: Text(row.approver, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))))),
                      _CellDef(SizedBox(width: 80, child: _buildPriorityTag(row.priority))),
                      _CellDef(SizedBox(width: 100, child: _buildReviewGateStatusTag(row.status))),
                      _CellDef(SizedBox(
                        width: 60,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 16), onPressed: () => _showReviewGateDialog(existing: row), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)), onPressed: () => _confirmDelete(() => _deleteReviewGate(row)), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          ],
                        ),
                      )),
                    ],
                    isLast: i == _reviewGates.length - 1,
                  );
                }),
              ],
            ),
    );
  }

  // ─── Table Building Helpers ────────────────────────────────────────

  Widget _buildTableHeader(List<_ColDef> columns) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
      child: Row(
        children: columns.map((col) {
          if (col.flex != null) {
            return Expanded(
              flex: col.flex!,
              child: Text(col.label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.8)),
            );
          }
          return SizedBox(
            width: col.width,
            child: Text(col.label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.8),
                textAlign: TextAlign.center),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableRow({required List<_CellDef> cells, required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cells.map((cell) => cell.child).toList(),
      ),
    );
  }

  // ─── Status / Tag Builders ──────────────────────────────────────

  Widget _buildPriorityTag(String priority) {
    Color color;
    switch (priority) {
      case 'Critical':
        color = const Color(0xFFEF4444);
        break;
      case 'High':
        color = const Color(0xFFF97316);
        break;
      case 'Medium':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(priority,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildStatusTag(String status) {
    Color color;
    switch (status) {
      case 'Mapped':
      case 'Validated':
        color = const Color(0xFF10B981);
        break;
      case 'In progress':
        color = const Color(0xFF0EA5E9);
        break;
      case 'Draft':
        color = const Color(0xFFF59E0B);
        break;
      case 'Deprecated':
        color = const Color(0xFF9CA3AF);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildFidelityTag(String fidelity) {
    Color color;
    switch (fidelity) {
      case 'High':
        color = const Color(0xFF10B981);
        break;
      case 'Medium':
        color = const Color(0xFF0EA5E9);
        break;
      case 'Low':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(fidelity,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildInterfaceStateTag(String state) {
    Color color;
    switch (state) {
      case 'Final':
        color = const Color(0xFF10B981);
        break;
      case 'Prototype':
        color = const Color(0xFF0EA5E9);
        break;
      case 'User flow map':
        color = const Color(0xFF8B5CF6);
        break;
      case 'Wireframe':
        color = const Color(0xFFF59E0B);
        break;
      case 'To define':
        color = const Color(0xFF9CA3AF);
        break;
      case 'Deprecated':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(state,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildCategoryTag(String category) {
    Color color;
    switch (category) {
      case 'Colors':
        color = const Color(0xFF8B5CF6);
        break;
      case 'Typography':
        color = const Color(0xFF2563EB);
        break;
      case 'Layout':
        color = const Color(0xFF10B981);
        break;
      case 'Effects':
        color = const Color(0xFFF59E0B);
        break;
      case 'Motion':
        color = const Color(0xFF0EA5E9);
        break;
      case 'Iconography':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(category,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildTokenStatusTag(String status) {
    Color color;
    switch (status) {
      case 'Ready':
        color = const Color(0xFF10B981);
        break;
      case 'In review':
        color = const Color(0xFF0EA5E9);
        break;
      case 'Draft':
        color = const Color(0xFFF59E0B);
        break;
      case 'Planned':
        color = const Color(0xFF8B5CF6);
        break;
      case 'Deprecated':
        color = const Color(0xFF9CA3AF);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildUsabilityStatusTag(String status) {
    Color color;
    switch (status) {
      case 'Pass':
        color = const Color(0xFF10B981);
        break;
      case 'Fail':
        color = const Color(0xFFEF4444);
        break;
      case 'In progress':
        color = const Color(0xFF0EA5E9);
        break;
      case 'Conditional':
        color = const Color(0xFFF59E0B);
        break;
      case 'Not tested':
        color = const Color(0xFF9CA3AF);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildReviewGateStatusTag(String status) {
    Color color;
    switch (status) {
      case 'Approved':
        color = const Color(0xFF10B981);
        break;
      case 'In Review':
        color = const Color(0xFF0EA5E9);
        break;
      case 'Pending':
        color = const Color(0xFFF59E0B);
        break;
      case 'Rejected':
        color = const Color(0xFFEF4444);
        break;
      case 'Waived':
        color = const Color(0xFF8B5CF6);
        break;
      case 'Not Started':
        color = const Color(0xFF9CA3AF);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // ─── CRUD Dialogs ─────────────────────────────────────────────────

  Future<void> _showJourneyDialog({_JourneyRow? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final touchpointsController = TextEditingController(text: existing?.touchpoints ?? '');
    final ownerController = TextEditingController(text: existing?.owner ?? '');
    String priority = existing?.priority ?? 'Medium';
    String status = existing?.status ?? 'Planned';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Add user journey' : 'Edit user journey'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Journey title', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: touchpointsController, decoration: const InputDecoration(labelText: 'Touchpoints', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: ownerController, decoration: const InputDecoration(labelText: 'Owner', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: priority,
                      items: ['Critical', 'High', 'Medium', 'Low'].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) { if (v != null) setModalState(() => priority = v); },
                      decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: status,
                      items: _journeyStatusOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) { if (v != null) setModalState(() => status = v); },
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    )),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(existing == null ? 'Add journey' : 'Save')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    setState(() {
      if (existing == null) {
        _journeys.add(_JourneyRow(id: _newId(), title: titleController.text.trim(), description: descController.text.trim(), touchpoints: touchpointsController.text.trim(), owner: ownerController.text.trim(), priority: priority, status: status));
      } else {
        existing.title = titleController.text.trim();
        existing.description = descController.text.trim();
        existing.touchpoints = touchpointsController.text.trim();
        existing.owner = ownerController.text.trim();
        existing.priority = priority;
        existing.status = status;
      }
    });
    _scheduleSave();
  }

  void _deleteJourney(_JourneyRow row) {
    setState(() => _journeys.removeWhere((j) => j.id == row.id));
    _scheduleSave();
  }

  Future<void> _showInterfaceDialog({_InterfaceRow? existing}) async {
    final areaController = TextEditingController(text: existing?.area ?? '');
    final purposeController = TextEditingController(text: existing?.purpose ?? '');
    final ownerController = TextEditingController(text: existing?.owner ?? '');
    String fidelity = existing?.fidelity ?? 'Low';
    String status = existing?.status ?? 'To define';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Add interface area' : 'Edit interface area'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: areaController, decoration: const InputDecoration(labelText: 'Area / screen name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: purposeController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Purpose', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: ownerController, decoration: const InputDecoration(labelText: 'Owner', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: fidelity,
                      items: ['High', 'Medium', 'Low'].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) { if (v != null) setModalState(() => fidelity = v); },
                      decoration: const InputDecoration(labelText: 'Fidelity', border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: status,
                      items: _interfaceStateOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) { if (v != null) setModalState(() => status = v); },
                      decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                    )),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(existing == null ? 'Add interface' : 'Save')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    setState(() {
      if (existing == null) {
        _interfaces.add(_InterfaceRow(id: _newId(), area: areaController.text.trim(), purpose: purposeController.text.trim(), owner: ownerController.text.trim(), fidelity: fidelity, status: status));
      } else {
        existing.area = areaController.text.trim();
        existing.purpose = purposeController.text.trim();
        existing.owner = ownerController.text.trim();
        existing.fidelity = fidelity;
        existing.status = status;
      }
    });
    _scheduleSave();
  }

  void _deleteInterface(_InterfaceRow row) {
    setState(() => _interfaces.removeWhere((i) => i.id == row.id));
    _scheduleSave();
  }

  Future<void> _showDesignTokenDialog({_DesignTokenRow? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final ownerController = TextEditingController(text: existing?.owner ?? '');
    String category = existing?.category ?? 'Colors';
    String status = existing?.status ?? 'Draft';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Add design token' : 'Edit design token'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Token name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Description / value', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: ownerController, decoration: const InputDecoration(labelText: 'Owner', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: category,
                      items: ['Colors', 'Typography', 'Layout', 'Effects', 'Motion', 'Iconography'].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) { if (v != null) setModalState(() => category = v); },
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: status,
                      items: _tokenStatusOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) { if (v != null) setModalState(() => status = v); },
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    )),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(existing == null ? 'Add token' : 'Save')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    setState(() {
      if (existing == null) {
        _designTokens.add(_DesignTokenRow(id: _newId(), title: titleController.text.trim(), description: descController.text.trim(), category: category, status: status, owner: ownerController.text.trim()));
      } else {
        existing.title = titleController.text.trim();
        existing.description = descController.text.trim();
        existing.category = category;
        existing.status = status;
        existing.owner = ownerController.text.trim();
      }
    });
    _scheduleSave();
  }

  void _deleteDesignToken(_DesignTokenRow row) {
    setState(() => _designTokens.removeWhere((t) => t.id == row.id));
    _scheduleSave();
  }

  Future<void> _showUsabilityDialog({_UsabilityRow? existing}) async {
    final criteriaController = TextEditingController(text: existing?.criteria ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final standardController = TextEditingController(text: existing?.standard ?? '');
    final ownerController = TextEditingController(text: existing?.owner ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String status = existing?.status ?? 'Not tested';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Add validation criteria' : 'Edit validation criteria'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: criteriaController, decoration: const InputDecoration(labelText: 'Criteria', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: standardController, decoration: const InputDecoration(labelText: 'Standard', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: status,
                      items: _usabilityStatusOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) { if (v != null) setModalState(() => status = v); },
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: ownerController, decoration: const InputDecoration(labelText: 'Owner', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: notesController, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(existing == null ? 'Add criteria' : 'Save')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    setState(() {
      if (existing == null) {
        _usabilityEntries.add(_UsabilityRow(id: _newId(), criteria: criteriaController.text.trim(), description: descController.text.trim(), standard: standardController.text.trim(), status: status, owner: ownerController.text.trim(), notes: notesController.text.trim()));
      } else {
        existing.criteria = criteriaController.text.trim();
        existing.description = descController.text.trim();
        existing.standard = standardController.text.trim();
        existing.status = status;
        existing.owner = ownerController.text.trim();
        existing.notes = notesController.text.trim();
      }
    });
    _scheduleSave();
  }

  void _deleteUsability(_UsabilityRow row) {
    setState(() => _usabilityEntries.removeWhere((u) => u.id == row.id));
    _scheduleSave();
  }

  Future<void> _showReviewGateDialog({_ReviewGateRow? existing}) async {
    final gateController = TextEditingController(text: existing?.gate ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final approverController = TextEditingController(text: existing?.approver ?? '');
    final deptController = TextEditingController(text: existing?.department ?? '');
    String priority = existing?.priority ?? 'High';
    String status = existing?.status ?? 'Pending';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Add review gate' : 'Edit review gate'),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: gateController, decoration: const InputDecoration(labelText: 'Gate name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: descController, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: approverController, decoration: const InputDecoration(labelText: 'Approver', border: OutlineInputBorder()))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: deptController, decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: DropdownButtonFormField<String>(
                      value: priority,
                      items: ['Critical', 'High', 'Medium', 'Low'].map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) { if (v != null) setModalState(() => priority = v); },
                      decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: DropdownButtonFormField<String>(
                      value: status,
                      items: _reviewGateStatusOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                      onChanged: (v) { if (v != null) setModalState(() => status = v); },
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    )),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(existing == null ? 'Add gate' : 'Save')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    setState(() {
      if (existing == null) {
        _reviewGates.add(_ReviewGateRow(id: _newId(), gate: gateController.text.trim(), description: descController.text.trim(), approver: approverController.text.trim(), department: deptController.text.trim(), priority: priority, status: status, targetDate: 'TBD'));
      } else {
        existing.gate = gateController.text.trim();
        existing.description = descController.text.trim();
        existing.approver = approverController.text.trim();
        existing.department = deptController.text.trim();
        existing.priority = priority;
        existing.status = status;
      }
    });
    _scheduleSave();
  }

  void _deleteReviewGate(_ReviewGateRow row) {
    setState(() => _reviewGates.removeWhere((g) => g.id == row.id));
    _scheduleSave();
  }

  void _confirmDelete(VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () { Navigator.of(ctx).pop(); onDelete(); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Data Models ──────────────────────────────────────────────────────

class _JourneyRow {
  String id;
  String title;
  String description;
  String touchpoints;
  String owner;
  String priority;
  String status;

  _JourneyRow({
    required this.id,
    required this.title,
    required this.description,
    required this.touchpoints,
    required this.owner,
    required this.priority,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'title': title, 'description': description,
        'touchpoints': touchpoints, 'owner': owner,
        'priority': priority, 'status': status,
      };

  static List<_JourneyRow> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return _JourneyRow(
        id: m['id'] ?? '', title: m['title'] ?? '',
        description: m['description'] ?? '', touchpoints: m['touchpoints'] ?? '',
        owner: m['owner'] ?? '', priority: m['priority'] ?? 'Medium',
        status: m['status'] ?? 'Planned',
      );
    }).toList();
  }
}

class _InterfaceRow {
  String id;
  String area;
  String purpose;
  String fidelity;
  String owner;
  String status;

  _InterfaceRow({
    required this.id, required this.area, required this.purpose,
    required this.fidelity, required this.owner, required this.status,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'area': area, 'purpose': purpose,
        'fidelity': fidelity, 'owner': owner, 'status': status,
      };

  static List<_InterfaceRow> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return _InterfaceRow(
        id: m['id'] ?? '', area: m['area'] ?? '',
        purpose: m['purpose'] ?? '', fidelity: m['fidelity'] ?? 'Low',
        owner: m['owner'] ?? '', status: m['status'] ?? 'To define',
      );
    }).toList();
  }
}

class _DesignTokenRow {
  String id;
  String title;
  String description;
  String category;
  String status;
  String owner;

  _DesignTokenRow({
    required this.id, required this.title, required this.description,
    required this.category, required this.status, required this.owner,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'title': title, 'description': description,
        'category': category, 'status': status, 'owner': owner,
      };

  static List<_DesignTokenRow> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return _DesignTokenRow(
        id: m['id'] ?? '', title: m['title'] ?? '',
        description: m['description'] ?? '', category: m['category'] ?? 'Colors',
        status: m['status'] ?? 'Draft', owner: m['owner'] ?? '',
      );
    }).toList();
  }
}

class _UsabilityRow {
  String id;
  String criteria;
  String description;
  String standard;
  String status;
  String owner;
  String notes;

  _UsabilityRow({
    required this.id, required this.criteria, required this.description,
    required this.standard, required this.status, required this.owner,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'criteria': criteria, 'description': description,
        'standard': standard, 'status': status, 'owner': owner, 'notes': notes,
      };

  static List<_UsabilityRow> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return _UsabilityRow(
        id: m['id'] ?? '', criteria: m['criteria'] ?? '',
        description: m['description'] ?? '', standard: m['standard'] ?? '',
        status: m['status'] ?? 'Not tested', owner: m['owner'] ?? '',
        notes: m['notes'] ?? '',
      );
    }).toList();
  }
}

class _ReviewGateRow {
  String id;
  String gate;
  String description;
  String approver;
  String department;
  String priority;
  String status;
  String targetDate;

  _ReviewGateRow({
    required this.id, required this.gate, required this.description,
    required this.approver, required this.department, required this.priority,
    required this.status, required this.targetDate,
  });

  Map<String, dynamic> toMap() => {
        'id': id, 'gate': gate, 'description': description,
        'approver': approver, 'department': department,
        'priority': priority, 'status': status, 'targetDate': targetDate,
      };

  static List<_ReviewGateRow> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return _ReviewGateRow(
        id: m['id'] ?? '', gate: m['gate'] ?? '',
        description: m['description'] ?? '', approver: m['approver'] ?? '',
        department: m['department'] ?? '', priority: m['priority'] ?? 'High',
        status: m['status'] ?? 'Pending', targetDate: m['targetDate'] ?? 'TBD',
      );
    }).toList();
  }
}

// ─── Utility Classes ──────────────────────────────────────────────────

class _StatCardData {
  final String value;
  final String label;
  final String supporting;
  final Color color;
  _StatCardData(this.value, this.label, this.supporting, this.color);
}

class _ColDef {
  final String label;
  final int? flex;
  final double? width;
  _ColDef(this.label, {this.flex, this.width});
}

class _CellDef {
  final Widget child;
  _CellDef(this.child);
}

class _Debouncer {
  Timer? _timer;
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 600), action);
  }
  void dispose() => _timer?.cancel();
}
