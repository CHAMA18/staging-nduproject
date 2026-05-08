import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/activity_log_service.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TechnicalDevelopmentScreen extends StatefulWidget {
  const TechnicalDevelopmentScreen({super.key});

  @override
  State<TechnicalDevelopmentScreen> createState() =>
      _TechnicalDevelopmentScreenState();
}

class _TechnicalDevelopmentScreenState
    extends State<TechnicalDevelopmentScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _approachController = TextEditingController();
  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;
  bool _didSeedDefaults = false;
  bool _registersExpanded = false;
  Map<String, dynamic>? _engineeringContext;
  Map<String, dynamic>? _backendDesignContext;

  // Build strategy chips data
  List<_ChipItem> _standardsChips = [];

  // Workstreams data
  List<_WorkstreamItem> _workstreams = [];

  // Readiness checklist items
  List<_ReadinessItem> _readinessItems = [];

  static const List<String> _workstreamStatusOptions = [
    'Team staffed',
    'Backlog ready',
    'Depends on vendor access',
    'In planning',
    'At risk',
    'Blocked',
  ];

  static const List<String> _readinessStatusOptions = [
    'Ready',
    'In review',
    'Partially ready',
    'Draft',
    'Blocked',
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

  @override
  void initState() {
    super.initState();
    _standardsChips = _defaultStandards();
    _workstreams = _defaultWorkstreams();
    _readinessItems = _defaultReadinessItems();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final projectId = provider?.projectData.projectId;
      if (projectId != null && projectId.isNotEmpty) {
        await ProjectNavigationService.instance.saveLastPage(
          projectId,
          'technical_development',
        );
      }
      await _loadFromFirestore();
    });
    _notesController.addListener(_scheduleSave);
    _approachController.addListener(_scheduleSave);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _approachController.dispose();
    _saveDebouncer.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> _docFor(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('design_phase_sections')
        .doc('technical_development');
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
      final docFuture = _docFor(projectId).get();
      final engineeringFuture = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('design_phase_sections')
          .doc('engineering_design')
          .get();
      final backendFuture = FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('design_phase_sections')
          .doc('backend_design')
          .get();
      final results =
          await Future.wait<DocumentSnapshot<Map<String, dynamic>>>([
        docFuture,
        engineeringFuture,
        backendFuture,
      ]);
      final doc = results[0];
      final engineeringDoc = results[1];
      final backendDoc = results[2];
      final data = doc.data() ?? {};
      shouldSeedDefaults = data.isEmpty && !_didSeedDefaults;
      _suspendSave = true;
      if (!mounted) return;
      setState(() {
        _engineeringContext = engineeringDoc.data();
        _backendDesignContext = backendDoc.data();
        final chips = _ChipItem.fromList(data['standardsChips']);
        final workstreams = _WorkstreamItem.fromList(data['workstreams']);
        final readiness = _ReadinessItem.fromList(data['readinessItems']);
        if (shouldSeedDefaults) {
          _didSeedDefaults = true;
          _notesController.text =
              'Production readiness now covers software build packs, fabrication packages, integration proving, mock venue rehearsals, and release controls before tools integration begins.';
          _approachController.text =
              'Run mixed software and physical workstreams in parallel, freeze interfaces early, validate prototypes before procurement, and push only after quality, safety, and rollback checks are complete.';
          _standardsChips = _defaultStandards();
          _workstreams = _defaultWorkstreams();
          _readinessItems = _defaultReadinessItems();
        } else {
          _notesController.text = data['notes']?.toString() ?? '';
          _approachController.text = data['approach']?.toString() ?? '';
          _standardsChips = chips.isEmpty ? _defaultStandards() : chips;
          _workstreams =
              workstreams.isEmpty ? _defaultWorkstreams() : workstreams;
          _readinessItems =
              readiness.isEmpty ? _defaultReadinessItems() : readiness;
        }
      });
    } catch (error) {
      debugPrint('Technical development load error: $error');
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
        'approach': _approachController.text.trim(),
        'standardsChips': _standardsChips.map((e) => e.toMap()).toList(),
        'workstreams': _workstreams.map((e) => e.toMap()).toList(),
        'readinessItems': _readinessItems.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await ActivityLogService.instance.logActivity(
        projectId: projectId,
        phase: 'Design Phase',
        page: 'Technical Development',
        action: 'Updated Technical Development data',
      );
    } catch (error) {
      debugPrint('Technical development save error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save Technical Development changes right now. Please try again.',
          ),
        ),
      );
    }
  }

  List<_ChipItem> _defaultStandards() {
    return [
      _ChipItem(id: _newId(), label: 'Coding guidelines signed off'),
      _ChipItem(id: _newId(), label: 'Fabrication tolerances locked'),
      _ChipItem(id: _newId(), label: 'Interface freeze before sprint cut-off'),
      _ChipItem(
        id: _newId(),
        label: 'Safety protocols cleared for site assembly',
      ),
    ];
  }

  List<_WorkstreamItem> _defaultWorkstreams() {
    return [
      _WorkstreamItem(
        id: _newId(),
        title: 'Login Module',
        subtitle: 'Auth flows, session guardrails, and code review readiness',
        status: 'Team staffed',
      ),
      _WorkstreamItem(
        id: _newId(),
        title: 'Main Stage Fabrication',
        subtitle:
            'Deck framing, material sign-off, and installation sequencing',
        status: 'Backlog ready',
      ),
      _WorkstreamItem(
        id: _newId(),
        title: 'API and Lighting Integration',
        subtitle: 'Platform endpoints, control triggers, and interface proving',
        status: 'Depends on vendor access',
      ),
      _WorkstreamItem(
        id: _newId(),
        title: 'Release and Site Assembly',
        subtitle: 'Staging cut-over, mock run, and handover playbook',
        status: 'In planning',
      ),
    ];
  }

  List<_ReadinessItem> _defaultReadinessItems() {
    return [
      _ReadinessItem(
        id: _newId(),
        title: 'API contracts and ticket scanner mappings frozen',
        owner: 'Backend lead',
        status: 'Ready',
      ),
      _ReadinessItem(
        id: _newId(),
        title: 'Load sign-off for stage truss and rigging package',
        owner: 'Structural engineer',
        status: 'In review',
      ),
      _ReadinessItem(
        id: _newId(),
        title: 'Staging environment and mock venue access available',
        owner: 'DevOps',
        status: 'Partially ready',
      ),
      _ReadinessItem(
        id: _newId(),
        title: 'Go-live runbook, rollback path, and radio comms plan drafted',
        owner: 'Release manager',
        status: 'Draft',
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
        page: 'Technical Development',
        action: action,
        details: details,
      ),
    );
  }

  _TechnicalDevelopmentDashboardSnapshot _snapshotFor(ProjectDataModel data) {
    return _TechnicalDevelopmentDashboardSnapshot.from(
      projectData: data,
      engineeringContext: _engineeringContext,
      backendDesignContext: _backendDesignContext,
      notes: _notesController.text.trim(),
      approach: _approachController.text.trim(),
      standardsChips: _standardsChips,
      workstreams: _workstreams,
      readinessItems: _readinessItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);
    final sectionGap = AppBreakpoints.sectionGap(context);
    final provider = ProjectDataInherited.maybeOf(context);
    final projectData = provider?.projectData ?? ProjectDataModel();
    final snapshot = _snapshotFor(projectData);

    return ResponsiveScaffold(
      activeItemLabel: 'Technical Development',
      floatingActionButton: const KazAiChatBubble(positioned: false),
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Technical Development',
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
                  if (_isLoading) const SizedBox(height: 16),
                  _buildProductionHubHeader(
                    isMobile: isMobile,
                    snapshot: snapshot,
                  ),
                  SizedBox(height: sectionGap),
                  _buildWorkflowCard(snapshot),
                  SizedBox(height: sectionGap),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildComponentBuildRegister(snapshot),
                      SizedBox(height: sectionGap),
                      _buildValidationPanel(snapshot),
                    ],
                  ),
                  SizedBox(height: sectionGap),
                  _buildGovernanceGrid(snapshot),
                  SizedBox(height: sectionGap),
                  _buildDetailedRegistersSection(),
                  SizedBox(height: sectionGap),
                  _buildBottomNavigation(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionHubHeader({
    required bool isMobile,
    required _TechnicalDevelopmentDashboardSnapshot snapshot,
  }) {
    final metrics = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildHeroMetric(
          label: 'Build Register',
          value: '${snapshot.buildRegister.length}',
          icon: Icons.handyman_rounded,
          color: LightModeColors.accent,
        ),
        _buildHeroMetric(
          label: 'Delivered',
          value: '${snapshot.deliveredCount}',
          icon: Icons.check_circle_rounded,
          color: AppSemanticColors.success,
        ),
        _buildHeroMetric(
          label: 'Interfaces Ready',
          value: '${snapshot.connectedCount}',
          icon: Icons.link_rounded,
          color: const Color(0xFF38BDF8),
        ),
        _buildHeroMetric(
          label: 'Open Issues',
          value: '${snapshot.issueItems.length}',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF97316),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1220),
            Color(0xFF132238),
            Color(0xFF1E293B),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Text(
                  'DESIGN PHASE | TECHNICAL DEVELOPMENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (snapshot.aiSignalCount > 0)
                _buildHeroMetric(
                  label: 'AI Context Signals',
                  value: '${snapshot.aiSignalCount}',
                  icon: Icons.auto_awesome_rounded,
                  color: AppSemanticColors.ai,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Production & Prototyping Hub',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Translate the approved design into real build packages, prototype proofs, and go-live controls for ${snapshot.projectLabel}.',
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _exportDevelopmentSummary,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export summary'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Production & Prototyping Hub',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Translate the approved design into real build packages, prototype proofs, and go-live controls for ${snapshot.projectLabel}.',
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _exportDevelopmentSummary,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Export summary'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 22),
          metrics,
        ],
      ),
    );
  }

  Widget _buildHeroMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 28 : 36,
            height: compact ? 28 : 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: compact ? 16 : 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowCard(_TechnicalDevelopmentDashboardSnapshot snapshot) {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.timeline_rounded,
            title: 'Development Roadmap & Workflow',
            subtitle:
                'Production phases, sprint sequencing, and progress against the build runway.',
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int index = 0;
                    index < snapshot.workflowStages.length;
                    index++) ...[
                  _buildWorkflowStage(snapshot.workflowStages[index]),
                  if (index != snapshot.workflowStages.length - 1)
                    Container(
                      width: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStage(_WorkflowStageItem item) {
    final progressColor = item.progress >= 0.8
        ? AppSemanticColors.success
        : item.progress >= 0.45
            ? AppSemanticColors.warning
            : const Color(0xFF38BDF8);
    return Container(
      width: 230,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                item.label,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const Spacer(),
              _buildToneBadge(item.percentLabel, color: progressColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.note,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentBuildRegister(
    _TechnicalDevelopmentDashboardSnapshot snapshot,
  ) {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.precision_manufacturing_rounded,
            title: 'Component Build Register',
            subtitle:
                'Track deliverables in motion across software modules, fabrication packages, and site build items.',
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 760),
              child: Column(
                children: [
                  _buildTableHeaderRow(),
                  const SizedBox(height: 8),
                  ...snapshot.buildRegister.asMap().entries.map(
                        (entry) => _buildBuildRegisterRow(
                          entry.value,
                          index: entry.key,
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

  Widget _buildTableHeaderRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 320,
            child: Text(
              'Component Name',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: Text(
              'Owner',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Text(
              'Status',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildRegisterRow(
    _BuildRegisterRow row, {
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _looksPhysical('${row.name} ${row.detail}')
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _looksPhysical('${row.name} ${row.detail}')
                        ? Icons.build_circle_rounded
                        : Icons.play_circle_fill_rounded,
                    color: _looksPhysical('${row.name} ${row.detail}')
                        ? const Color(0xFFD97706)
                        : const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        row.detail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildToneBadge(
                        row.contextLabel,
                        color: _looksPhysical(row.contextLabel)
                            ? const Color(0xFFD97706)
                            : const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 180,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Text(
                    _initials(row.owner),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.owner,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 160,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildToneBadge(
                row.status,
                color: _toneForStatus(row.status),
                icon: row.status == 'Delivered'
                    ? Icons.check_circle_rounded
                    : row.status == 'In Production'
                        ? Icons.sync_rounded
                        : Icons.play_arrow_rounded,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationPanel(
      _TechnicalDevelopmentDashboardSnapshot snapshot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIntegrationCard(snapshot),
        const SizedBox(height: 16),
        _buildPrototypeGalleryCard(snapshot),
      ],
    );
  }

  Widget _buildIntegrationCard(
      _TechnicalDevelopmentDashboardSnapshot snapshot) {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.link_rounded,
            title: 'Integration & Interface Realization',
            subtitle:
                'Live connection checks between build components, services, and physical systems.',
          ),
          const SizedBox(height: 16),
          ...snapshot.integrations.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppSemanticColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color:
                          _toneForStatus(item.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.link_rounded,
                      size: 18,
                      color: _toneForStatus(item.status),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.detail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildToneBadge(item.status,
                      color: _toneForStatus(item.status)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrototypeGalleryCard(
    _TechnicalDevelopmentDashboardSnapshot snapshot,
  ) {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.play_circle_outline_rounded,
            title: 'Prototyping & Proof of Concept',
            subtitle:
                'Validated concepts across wireframes, mockups, fabrication tests, and site rehearsals.',
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.prototypeItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.82,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final item = snapshot.prototypeItems[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppSemanticColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: _buildPrototypePreview(item),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: _buildToneBadge(
                                item.contextLabel,
                                color: _looksPhysical(item.contextLabel)
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: _buildToneBadge(
                                item.outcome,
                                color: _toneForStatus(item.outcome),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.caption,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrototypePreview(_PrototypeCardItem item) {
    switch (item.previewType) {
      case _PrototypePreviewType.appScreen:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE0F2FE), Color(0xFFDBEAFE)],
            ),
          ),
          child: Center(
            child: Container(
              width: 72,
              height: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    4,
                    (index) => Container(
                      height: 8,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case _PrototypePreviewType.wireframe:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: List.generate(
                5,
                (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF94A3B8)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF94A3B8)),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 6,
                                margin:
                                    const EdgeInsets.only(right: 18, bottom: 6),
                                color: const Color(0xFFCBD5E1),
                              ),
                              Container(
                                height: 6,
                                margin:
                                    const EdgeInsets.only(right: 30, bottom: 6),
                                color: const Color(0xFFE2E8F0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      case _PrototypePreviewType.stageMockup:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E293B), Color(0xFF475569)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 18,
                right: 18,
                bottom: 24,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned(
                left: 28,
                right: 28,
                bottom: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    3,
                    (index) => Container(
                      width: 28,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case _PrototypePreviewType.siteAssembly:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFBEB), Color(0xFFFDE68A)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF92400E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Positioned(
                left: 34,
                bottom: 36,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    color: Color(0xFFD97706),
                    size: 26,
                  ),
                ),
              ),
              Positioned(
                right: 24,
                top: 24,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.rule_rounded,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildGovernanceGrid(
    _TechnicalDevelopmentDashboardSnapshot snapshot,
  ) {
    return Column(
      children: [
        _buildIssueTrackerCard(snapshot),
        const SizedBox(height: 16),
        _buildQualityCodeCard(snapshot),
        const SizedBox(height: 16),
        _buildDocumentationCard(snapshot),
        const SizedBox(height: 16),
        _buildReleasePreparationCard(snapshot),
      ],
    );
  }

  Widget _buildIssueTrackerCard(
      _TechnicalDevelopmentDashboardSnapshot snapshot) {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.bug_report_outlined,
            title: 'Defect & Issue Tracker',
            subtitle:
                'Current build blockers, production exceptions, and technical rework items.',
          ),
          const SizedBox(height: 16),
          ...snapshot.issueItems.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppSemanticColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    item.severity == 'Critical'
                        ? Icons.priority_high_rounded
                        : Icons.report_problem_outlined,
                    color: _toneForStatus(item.severity),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildToneBadge(
                              item.severity,
                              color: _toneForStatus(item.severity),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.detail,
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
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCodeCard(
      _TechnicalDevelopmentDashboardSnapshot snapshot) {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.checklist_rounded,
            title: 'Technical Standards & Quality Code',
            subtitle:
                'Active quality gates spanning software conventions and physical execution controls.',
          ),
          const SizedBox(height: 16),
          ...snapshot.qualityStandards.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppSemanticColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    item.status == 'Active'
                        ? Icons.check_circle_rounded
                        : Icons.pending_actions_rounded,
                    size: 18,
                    color: _toneForStatus(item.status),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildToneBadge(item.status,
                      color: _toneForStatus(item.status)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentationCard(
    _TechnicalDevelopmentDashboardSnapshot snapshot,
  ) {
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.menu_book_rounded,
            title: 'Documentation & Technical Guides',
            subtitle:
                'Reference packs, manuals, and implementation guides for build teams and vendors.',
          ),
          const SizedBox(height: 16),
          ...snapshot.guideDocuments.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppSemanticColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      size: 18,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
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
                  const SizedBox(width: 8),
                  _buildToneBadge(
                    item.versionStatus,
                    color: _toneForStatus(item.versionStatus),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleasePreparationCard(
    _TechnicalDevelopmentDashboardSnapshot snapshot,
  ) {
    final allReady = snapshot.releaseChecklist
        .every((item) => item.status.toLowerCase() == 'ready');
    final readyCount = snapshot.releaseReadyCount;
    return _dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.fact_check_rounded,
            title: 'Deployment & Release Preparation',
            subtitle:
                'Go-live control pack with target gate, final QA checks, and handover readiness.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Go-live target',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.releaseTarget,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.releaseCountdown,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildToneBadge(
                  allReady
                      ? 'Pass'
                      : readyCount >= 2
                          ? 'Watch'
                          : 'At Risk',
                  color: allReady
                      ? AppSemanticColors.success
                      : readyCount >= 2
                          ? AppSemanticColors.warning
                          : const Color(0xFFDC2626),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...snapshot.releaseChecklist.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppSemanticColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: item.status == 'Ready'
                          ? AppSemanticColors.success
                          : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: item.status == 'Ready'
                            ? AppSemanticColors.success
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: item.status == 'Ready'
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildToneBadge(
                    item.status,
                    color: _toneForStatus(item.status),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRegistersSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () =>
                setState(() => _registersExpanded = !_registersExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detailed Registers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep editing the underlying delivery approach, workstreams, and readiness items that feed the dashboard.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _registersExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF475569),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Column(
                children: [
                  _buildBuildStrategyCard(),
                  const SizedBox(height: 16),
                  _buildWorkstreamsCard(),
                  const SizedBox(height: 16),
                  _buildReadinessChecklistCard(),
                ],
              ),
            ),
            crossFadeState: _registersExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDevelopmentSummary() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final snapshot = _snapshotFor(provider?.projectData ?? ProjectDataModel());
    final doc = pw.Document();

    final standards = _standardsChips
        .map((chip) => chip.label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
    final workstreams = _workstreams
        .map((item) {
          final title = item.title.trim();
          final subtitle = item.subtitle.trim();
          final status = item.status.trim();
          if (title.isEmpty && subtitle.isEmpty && status.isEmpty) return '';
          final base = subtitle.isEmpty ? title : '$title - $subtitle';
          return status.isEmpty ? base : '$base (Status: $status)';
        })
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final readiness = _readinessItems
        .map((item) {
          final title = item.title.trim();
          final owner = item.owner.trim();
          final status = item.status.trim();
          if (title.isEmpty && owner.isEmpty && status.isEmpty) return '';
          final meta = [
            if (owner.isNotEmpty) 'Owner: $owner',
            if (status.isNotEmpty) 'Status: $status',
          ].join(' | ');
          return meta.isEmpty ? title : '$title ($meta)';
        })
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final buildRows = snapshot.buildRegister
        .map((item) => '${item.name} - ${item.owner} (${item.status})')
        .toList();
    final integrations = snapshot.integrations
        .map((item) => '${item.label} (${item.status}) - ${item.detail}')
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Technical Development Summary',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          _pdfTextBlock('Project', snapshot.projectLabel),
          _pdfTextBlock('Build approach', _approachController.text.trim()),
          _pdfTextBlock('Notes', _notesController.text.trim()),
          _pdfSection('Standards & quality code', standards),
          _pdfSection('Development roadmap & workflow', workstreams),
          _pdfSection('Component build register', buildRows),
          _pdfSection('Integration realization', integrations),
          _pdfSection('Readiness & release checklist', readiness),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'technical-development-summary.pdf',
    );
  }

  pw.Widget _pdfTextBlock(String title, String content) {
    final normalized = content.trim().isEmpty ? 'No entries.' : content.trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
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
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
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

  Widget _dashboardCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppSemanticColors.border),
          ),
          child: Icon(icon, color: const Color(0xFF0F172A), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
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
    );
  }

  Widget _buildToneBadge(
    String label, {
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _toneForStatus(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('delivered') ||
        normalized.contains('validated') ||
        normalized.contains('connected') ||
        normalized.contains('ready') ||
        normalized.contains('current') ||
        normalized.contains('active') ||
        normalized.contains('pass')) {
      return AppSemanticColors.success;
    }
    if (normalized.contains('critical') ||
        normalized.contains('blocked') ||
        normalized.contains('fail') ||
        normalized.contains('rework') ||
        normalized.contains('risk')) {
      return const Color(0xFFDC2626);
    }
    if (normalized.contains('progress') ||
        normalized.contains('production') ||
        normalized.contains('pending') ||
        normalized.contains('review') ||
        normalized.contains('watch') ||
        normalized.contains('major') ||
        normalized.contains('updating')) {
      return AppSemanticColors.warning;
    }
    return const Color(0xFF2563EB);
  }

  Widget _buildBuildStrategyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Build strategy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'How the team will structure development, fabrication, and release control.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Text(
            'Approach',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _approachController,
            minLines: 1,
            maxLines: null,
            decoration: InputDecoration(
              hintText:
                  'Describe the delivery approach, prototype loops, and release gates.',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppSemanticColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppSemanticColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 16),
          Text(
            'Standards & constraints',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._standardsChips.map(_buildEditableChip),
              _addChipButton(onTap: _addStandardChip),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Notes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            minLines: 3,
            maxLines: null,
            decoration: InputDecoration(
              hintText:
                  'Capture build decisions, fabrication notes, environment assumptions, and release dependencies.',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppSemanticColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppSemanticColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableChip(_ChipItem chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            child: TextFormField(
              key: ValueKey('chip-${chip.id}'),
              initialValue: chip.label,
              decoration: const InputDecoration(
                  border: InputBorder.none, isDense: true),
              onChanged: (value) =>
                  _updateStandardChip(chip.copyWith(label: value)),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              minLines: 1,
              maxLines: null,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 16, color: Color(0xFF2563EB)),
            onPressed: () => _openStandardsChipDialog(existing: chip),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
            onPressed: () => _deleteStandardChip(chip.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _addChipButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add, size: 14),
            SizedBox(width: 6),
            Text('Add',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkstreamsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Workstreams & ownership',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Who builds what, and how it aligns to design',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ..._workstreams.map((item) => _buildWorkstreamItem(item)),
          TextButton.icon(
            onPressed: _addWorkstream,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add workstream'),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkstreamItem(_WorkstreamItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: ValueKey('workstream-title-${item.id}'),
                  initialValue: item.title,
                  decoration: const InputDecoration(
                      border: InputBorder.none, isDense: true),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  minLines: 1,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  onChanged: (value) =>
                      _updateWorkstream(item.copyWith(title: value)),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  key: ValueKey('workstream-subtitle-${item.id}'),
                  initialValue: item.subtitle,
                  decoration: InputDecoration(
                    hintText: 'Describe scope',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  minLines: 1,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  onChanged: (value) =>
                      _updateWorkstream(item.copyWith(subtitle: value)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusBadge(item),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: Color(0xFF2563EB)),
            onPressed: () => _openWorkstreamDialog(existing: item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Color(0xFFEF4444)),
            onPressed: () => _deleteWorkstream(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(_WorkstreamItem item) {
    final status = item.status;
    Color bgColor;
    Color dotColor;
    Color textColor;

    if (status.toLowerCase().contains('ready') ||
        status.toLowerCase().contains('staffed')) {
      bgColor = Colors.green[50]!;
      dotColor = Colors.green;
      textColor = Colors.green[700]!;
    } else if (status.toLowerCase().contains('depends') ||
        status.toLowerCase().contains('blocked')) {
      bgColor = Colors.orange[50]!;
      dotColor = Colors.orange;
      textColor = Colors.orange[700]!;
    } else {
      bgColor = Colors.yellow[50]!;
      dotColor = Colors.yellow[700]!;
      textColor = Colors.yellow[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _workstreamStatusOptions.contains(status)
                  ? status
                  : _workstreamStatusOptions.first,
              items: _workstreamStatusOptions
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option,
                            style: TextStyle(
                                fontSize: 11,
                                color: textColor,
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateWorkstream(item.copyWith(status: value));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Readiness checklist',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Confirm we can safely start development',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ..._readinessItems.map((item) => _buildReadinessItem(item)),
          TextButton.icon(
            onPressed: _addReadinessItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add checklist item'),
          ),
          const SizedBox(height: 16),
          // Export button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exportDevelopmentSummary,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export development readiness summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessItem(_ReadinessItem item) {
    final ownerOptions = _ownerOptions(currentValue: item.owner);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey('readiness-title-${item.id}'),
              initialValue: item.title,
              decoration: const InputDecoration(
                  border: InputBorder.none, isDense: true),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              minLines: 1,
              maxLines: null,
              textAlign: TextAlign.center,
              onChanged: (value) =>
                  _updateReadinessItem(item.copyWith(title: value)),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  initialValue: ownerOptions.contains(item.owner.trim())
                      ? item.owner.trim()
                      : ownerOptions.first,
                  items: ownerOptions
                      .map((owner) => DropdownMenuItem(
                            value: owner,
                            child: Center(
                              child: Text(
                                owner,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _updateReadinessItem(item.copyWith(owner: value));
                  },
                  decoration: const InputDecoration(
                      border: InputBorder.none, isDense: true),
                  isExpanded: true,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 140,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _readinessStatusOptions.contains(item.status)
                        ? item.status
                        : _readinessStatusOptions.first,
                    items: _readinessStatusOptions
                        .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]))))
                        .toList(),
                    onChanged: (value) => _updateReadinessItem(item.copyWith(
                        status: value ?? _readinessStatusOptions.first)),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: Color(0xFF2563EB)),
            onPressed: () => _openReadinessItemDialog(existing: item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Color(0xFFEF4444)),
            onPressed: () => _deleteReadinessItem(item.id),
          ),
        ],
      ),
    );
  }

  void _addStandardChip() {
    _openStandardsChipDialog();
  }

  void _updateStandardChip(_ChipItem chip) {
    final index = _standardsChips.indexWhere((item) => item.id == chip.id);
    if (index == -1) return;
    setState(() => _standardsChips[index] = chip);
    _scheduleSave();
  }

  void _deleteStandardChip(String id) {
    setState(() => _standardsChips.removeWhere((item) => item.id == id));
    _scheduleSave();
    _logActivity('Deleted standards chip', details: {'itemId': id});
  }

  void _addWorkstream() {
    _openWorkstreamDialog();
  }

  void _updateWorkstream(_WorkstreamItem item) {
    final index = _workstreams.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _workstreams[index] = item);
    _scheduleSave();
  }

  void _deleteWorkstream(String id) {
    setState(() => _workstreams.removeWhere((item) => item.id == id));
    _scheduleSave();
    _logActivity('Deleted workstream row', details: {'itemId': id});
  }

  void _addReadinessItem() {
    _openReadinessItemDialog();
  }

  void _updateReadinessItem(_ReadinessItem item) {
    final index = _readinessItems.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _readinessItems[index] = item);
    _scheduleSave();
  }

  void _deleteReadinessItem(String id) {
    setState(() => _readinessItems.removeWhere((item) => item.id == id));
    _scheduleSave();
    _logActivity('Deleted readiness row', details: {'itemId': id});
  }

  Future<void> _openStandardsChipDialog({_ChipItem? existing}) async {
    final controller = TextEditingController(text: existing?.label ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null
            ? 'Add quality standard'
            : 'Edit quality standard'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Standard / quality code',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(existing == null ? 'Add standard' : 'Save changes'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final item =
        _ChipItem(id: existing?.id ?? _newId(), label: controller.text.trim());
    setState(() {
      if (existing == null) {
        _standardsChips.add(item);
      } else {
        final index =
            _standardsChips.indexWhere((entry) => entry.id == existing.id);
        if (index != -1) _standardsChips[index] = item;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null ? 'Added standards chip' : 'Edited standards chip',
      details: {'itemId': item.id},
    );
  }

  Future<void> _openWorkstreamDialog({_WorkstreamItem? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final subtitleController =
        TextEditingController(text: existing?.subtitle ?? '');
    String status = existing?.status ?? _workstreamStatusOptions.first;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Add workstream' : 'Edit workstream'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Workstream',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subtitleController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Scope / notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: _workstreamStatusOptions
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
              child: Text(existing == null ? 'Add workstream' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final item = _WorkstreamItem(
      id: existing?.id ?? _newId(),
      title: titleController.text.trim(),
      subtitle: subtitleController.text.trim(),
      status: status,
    );
    setState(() {
      if (existing == null) {
        _workstreams.add(item);
      } else {
        final index =
            _workstreams.indexWhere((entry) => entry.id == existing.id);
        if (index != -1) _workstreams[index] = item;
      }
    });
    _scheduleSave();
    _logActivity(
      existing == null ? 'Added workstream row' : 'Edited workstream row',
      details: {'itemId': item.id},
    );
  }

  Future<void> _openReadinessItemDialog({_ReadinessItem? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    String owner =
        existing?.owner ?? _ownerOptions(currentValue: existing?.owner).first;
    String status = existing?.status ?? _readinessStatusOptions.first;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(
              existing == null ? 'Add checklist item' : 'Edit checklist item'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Checklist item',
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  items: _readinessStatusOptions
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
              child: Text(
                  existing == null ? 'Add checklist item' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final item = _ReadinessItem(
      id: existing?.id ?? _newId(),
      title: titleController.text.trim(),
      owner: owner,
      status: status,
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

  Widget _buildBottomNavigation(bool isMobile) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Design phase | Technical Development',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/${AppRoutes.engineeringDesign}'),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back: Engineering Design'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.push('/${AppRoutes.toolsIntegration}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Next: Tools Integration'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Tip text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lock the first build slices, prove the key interfaces, and finish the release runbook before you hand off to tools integration.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          Column(
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.go('/${AppRoutes.engineeringDesign}'),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back: Engineering Design'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Design phase | Technical Development',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () =>
                        context.push('/${AppRoutes.toolsIntegration}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Next: Tools Integration'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Tip text
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use this hub to prove feasibility in the real world: working interfaces, production-ready documents, and a clean release checklist matter more than extra design polish here.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class _WorkstreamItem {
  final String id;
  final String title;
  final String subtitle;
  final String status;

  _WorkstreamItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  _WorkstreamItem copyWith({String? title, String? subtitle, String? status}) {
    return _WorkstreamItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'status': status,
      };

  static List<_WorkstreamItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _WorkstreamItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
        status: map['status']?.toString() ?? 'In planning',
      );
    }).toList();
  }
}

class _ReadinessItem {
  final String id;
  final String title;
  final String owner;
  final String status;

  _ReadinessItem({
    required this.id,
    required this.title,
    required this.owner,
    required this.status,
  });

  _ReadinessItem copyWith({String? title, String? owner, String? status}) {
    return _ReadinessItem(
      id: id,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'owner': owner,
        'status': status,
      };

  static List<_ReadinessItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ReadinessItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Draft',
      );
    }).toList();
  }
}

class _ChipItem {
  final String id;
  final String label;

  _ChipItem({required this.id, required this.label});

  _ChipItem copyWith({String? label}) =>
      _ChipItem(id: id, label: label ?? this.label);

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
      };

  static List<_ChipItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ChipItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
      );
    }).toList();
  }
}

class _TechnicalDevelopmentDashboardSnapshot {
  const _TechnicalDevelopmentDashboardSnapshot({
    required this.projectLabel,
    required this.workflowStages,
    required this.buildRegister,
    required this.integrations,
    required this.prototypeItems,
    required this.issueItems,
    required this.qualityStandards,
    required this.guideDocuments,
    required this.releaseChecklist,
    required this.releaseTarget,
    required this.releaseCountdown,
    required this.aiSignalCount,
  });

  final String projectLabel;
  final List<_WorkflowStageItem> workflowStages;
  final List<_BuildRegisterRow> buildRegister;
  final List<_IntegrationItem> integrations;
  final List<_PrototypeCardItem> prototypeItems;
  final List<_IssueItem> issueItems;
  final List<_QualityStandardItem> qualityStandards;
  final List<_GuideDocumentItem> guideDocuments;
  final List<_ReleaseChecklistItem> releaseChecklist;
  final String releaseTarget;
  final String releaseCountdown;
  final int aiSignalCount;

  int get deliveredCount =>
      buildRegister.where((item) => item.status == 'Delivered').length;
  int get connectedCount =>
      integrations.where((item) => item.status == 'Connected').length;
  int get releaseReadyCount => releaseChecklist
      .where((item) => item.status.toLowerCase() == 'ready')
      .length;

  factory _TechnicalDevelopmentDashboardSnapshot.from({
    required ProjectDataModel projectData,
    required Map<String, dynamic>? engineeringContext,
    required Map<String, dynamic>? backendDesignContext,
    required String notes,
    required String approach,
    required List<_ChipItem> standardsChips,
    required List<_WorkstreamItem> workstreams,
    required List<_ReadinessItem> readinessItems,
  }) {
    final projectLabel = projectData.projectName.trim().isNotEmpty
        ? projectData.projectName.trim()
        : 'the current production package';
    final engineeringComponents =
        _mapList(engineeringContext?['components']).take(6).toList();
    final engineeringReadiness =
        _mapList(engineeringContext?['readinessItems']).take(6).toList();
    final backendArchitecture = Map<String, dynamic>.from(
      backendDesignContext?['architecture'] as Map? ?? const {},
    );
    final backendFlows = _mapList(backendArchitecture['dataFlows']);
    final backendDocuments = _mapList(backendArchitecture['documents']);
    final deliverables = projectData.designDeliverablesData.register;
    final pipeline = projectData.designDeliverablesData.pipeline;
    final dependencyHints = projectData.designDeliverablesData.dependencies;

    final workflowStages = <_WorkflowStageItem>[];
    for (final entry in pipeline.take(4).toList().asMap().entries) {
      final item = entry.value;
      final label = 'PHASE ${(entry.key + 1).toString().padLeft(2, '0')}';
      final title =
          item.label.trim().isNotEmpty ? item.label.trim() : 'Build phase';
      final status =
          item.status.trim().isNotEmpty ? item.status.trim() : 'In progress';
      workflowStages.add(
        _WorkflowStageItem(
          label: label,
          title: title,
          note: status,
          progress: _progressForStatus(status),
        ),
      );
    }
    if (workflowStages.isEmpty) {
      for (final entry in workstreams.take(4).toList().asMap().entries) {
        final item = entry.value;
        workflowStages.add(
          _WorkflowStageItem(
            label: 'SPRINT ${(entry.key + 1).toString().padLeft(2, '0')}',
            title: item.title.trim().isNotEmpty
                ? item.title.trim()
                : 'Technical build slice',
            note: item.subtitle.trim().isNotEmpty
                ? item.subtitle.trim()
                : item.status.trim(),
            progress: _progressForStatus(item.status),
          ),
        );
      }
    }
    if (workflowStages.isEmpty) {
      workflowStages.addAll(const [
        _WorkflowStageItem(
          label: 'SPRINT 01',
          title: 'Foundation Build',
          note: 'Auth, environments, and fabrication prep',
          progress: 0.35,
        ),
        _WorkflowStageItem(
          label: 'SPRINT 02',
          title: 'Integration Realization',
          note: 'API handshakes, control systems, and vendor proving',
          progress: 0.58,
        ),
        _WorkflowStageItem(
          label: 'SPRINT 03',
          title: 'Prototype Validation',
          note: 'Mockups, dry-runs, and rework closure',
          progress: 0.72,
        ),
        _WorkflowStageItem(
          label: 'SPRINT 04',
          title: 'Release Readiness',
          note: 'Go-live pack, assembly sequencing, and QA gate',
          progress: 0.82,
        ),
      ]);
    }

    final buildRegister = <_BuildRegisterRow>[];
    for (final deliverable in deliverables.take(4)) {
      final name = deliverable.name.trim();
      if (name.isEmpty) continue;
      buildRegister.add(
        _BuildRegisterRow(
          name: name,
          owner: deliverable.owner.trim().isNotEmpty
              ? deliverable.owner.trim()
              : _ownerFromTeam(projectData.teamMembers, buildRegister.length),
          status: _buildStatusFromText(deliverable.status),
          contextLabel: _contextLabelFor(name, deliverable.risk),
          detail: deliverable.risk.trim().isNotEmpty
              ? deliverable.risk.trim()
              : 'Scheduled build package moving through production controls.',
        ),
      );
    }
    for (final component in engineeringComponents) {
      final name = component['name']?.toString().trim() ?? '';
      if (name.isEmpty ||
          buildRegister
              .any((row) => row.name.toLowerCase() == name.toLowerCase())) {
        continue;
      }
      final detail = component['responsibility']?.toString().trim() ??
          'Engineering detail package in motion.';
      buildRegister.add(
        _BuildRegisterRow(
          name: name,
          owner: _ownerForComponent(
            name,
            projectData.teamMembers,
            engineeringReadiness,
            buildRegister.length,
          ),
          status:
              _buildStatusFromText(component['statusLabel']?.toString() ?? ''),
          contextLabel: _contextLabelFor(name, detail),
          detail:
              detail.isNotEmpty ? detail : 'Component build is being prepared.',
        ),
      );
      if (buildRegister.length >= 6) break;
    }
    for (final item in workstreams) {
      final name = item.title.trim();
      if (name.isEmpty ||
          buildRegister
              .any((row) => row.name.toLowerCase() == name.toLowerCase())) {
        continue;
      }
      buildRegister.add(
        _BuildRegisterRow(
          name: name,
          owner: _ownerFromTeam(projectData.teamMembers, buildRegister.length),
          status: _buildStatusFromText(item.status),
          contextLabel: _contextLabelFor(name, item.subtitle),
          detail: item.subtitle.trim().isNotEmpty
              ? item.subtitle.trim()
              : 'Workstream execution path is being prepared.',
        ),
      );
      if (buildRegister.length >= 6) break;
    }
    if (!buildRegister
        .any((row) => _looksSoftware('${row.name} ${row.detail}'))) {
      buildRegister.insert(
        0,
        const _BuildRegisterRow(
          name: 'Login Module',
          owner: 'Software lead',
          status: 'In Progress',
          contextLabel: 'Software Build',
          detail:
              'Credential flow, API contract wiring, and release guardrails.',
        ),
      );
    }
    if (!buildRegister
        .any((row) => _looksPhysical('${row.name} ${row.detail}'))) {
      buildRegister.add(
        const _BuildRegisterRow(
          name: 'Main Stage',
          owner: 'Production manager',
          status: 'In Production',
          contextLabel: 'Site Fabrication',
          detail: 'Structural framing, decking, and on-site assembly package.',
        ),
      );
    }

    final integrations = <_IntegrationItem>[];
    for (final flow in backendFlows.take(5)) {
      final source = flow['source']?.toString().trim() ?? '';
      final destination = flow['destination']?.toString().trim() ?? '';
      if (source.isEmpty || destination.isEmpty) continue;
      final detail = flow['notes']?.toString().trim();
      integrations.add(
        _IntegrationItem(
          label: '$source to $destination',
          detail: detail != null && detail.isNotEmpty
              ? detail
              : 'Protocol: ${flow['protocol']?.toString().trim().isNotEmpty == true ? flow['protocol'] : 'Manual handoff'}',
          status: _integrationStatusFromText(
            detail ?? flow['protocol']?.toString() ?? '',
          ),
        ),
      );
    }
    for (final hint in dependencyHints.take(4)) {
      final label = hint.trim();
      if (label.isEmpty ||
          integrations.any(
            (item) => item.label.toLowerCase().contains(label.toLowerCase()),
          )) {
        continue;
      }
      integrations.add(
        _IntegrationItem(
          label: label,
          detail: 'Dependency from the deliverables register awaiting proof.',
          status: 'Pending',
        ),
      );
      if (integrations.length >= 4) break;
    }
    if (!integrations
        .any((item) => _looksSoftware('${item.label} ${item.detail}'))) {
      integrations.insert(
        0,
        const _IntegrationItem(
          label: 'API to DB',
          detail: 'Auth and content payloads proving against staging data.',
          status: 'Connected',
        ),
      );
    }
    if (!integrations
        .any((item) => _looksPhysical('${item.label} ${item.detail}'))) {
      integrations.add(
        const _IntegrationItem(
          label: 'Stage to Lighting',
          detail: 'Control trigger and power handoff still being validated.',
          status: 'Pending',
        ),
      );
    }

    final prototypeItems = <_PrototypeCardItem>[
      for (final row in buildRegister.take(4))
        _PrototypeCardItem(
          title: row.name,
          contextLabel: _prototypeContextLabel(row.contextLabel, row.name),
          caption: row.detail,
          outcome: row.status == 'Delivered' ? 'Validated' : 'Needs Rework',
          previewType: _prototypeTypeFor('${row.name} ${row.contextLabel}'),
        ),
    ];
    if (!prototypeItems.any((item) => _looksSoftware(item.contextLabel))) {
      prototypeItems.insert(
        0,
        const _PrototypeCardItem(
          title: 'Mobile App Screen',
          contextLabel: 'Mobile App',
          caption:
              'Interactive checkout wireframe and credential handoff proof.',
          outcome: 'Validated',
          previewType: _PrototypePreviewType.appScreen,
        ),
      );
    }
    if (!prototypeItems.any((item) => _looksPhysical(item.contextLabel))) {
      prototypeItems.add(
        const _PrototypeCardItem(
          title: 'Floor Plan Mockup',
          contextLabel: 'Site Assembly',
          caption:
              'Main stage access paths and fabrication clearances under review.',
          outcome: 'Needs Rework',
          previewType: _PrototypePreviewType.siteAssembly,
        ),
      );
    }

    final issueItems = <_IssueItem>[];
    for (final item in workstreams.where((w) {
      final status = w.status.toLowerCase();
      return status.contains('risk') ||
          status.contains('blocked') ||
          status.contains('depends');
    })) {
      issueItems.add(
        _IssueItem(
          title:
              item.title.trim().isNotEmpty ? item.title.trim() : 'Build issue',
          detail: item.subtitle.trim().isNotEmpty
              ? item.subtitle.trim()
              : 'Active workstream exception requires resolution.',
          severity: item.status.toLowerCase().contains('blocked')
              ? 'Critical'
              : 'Major',
        ),
      );
      if (issueItems.length >= 4) break;
    }
    for (final solutionRisk in projectData.solutionRisks) {
      for (final risk in solutionRisk.risks) {
        final value = risk.trim();
        if (value.isEmpty) continue;
        issueItems.add(
          _IssueItem(
            title: solutionRisk.solutionTitle.trim().isNotEmpty
                ? solutionRisk.solutionTitle.trim()
                : 'Project risk',
            detail: value,
            severity: _severityForText(value),
          ),
        );
        if (issueItems.length >= 4) break;
      }
      if (issueItems.length >= 4) break;
    }
    if (issueItems.isEmpty) {
      issueItems.addAll(const [
        _IssueItem(
          title: 'Code Review Queue',
          detail:
              'Auth and integration branches need final sign-off before merge.',
          severity: 'Major',
        ),
        _IssueItem(
          title: 'Fabrication Tolerance Clash',
          detail:
              'Stage deck edge detailing still conflicts with lighting cable path.',
          severity: 'Critical',
        ),
      ]);
    }

    final qualityStandards = <_QualityStandardItem>[];
    for (final chip in standardsChips.take(5)) {
      final label = chip.label.trim();
      if (label.isEmpty) continue;
      qualityStandards.add(
        _QualityStandardItem(
          label: label,
          status: _qualityStatusFromText(label, notes, approach),
        ),
      );
    }
    if (!qualityStandards.any((item) => _looksSoftware(item.label))) {
      qualityStandards.insert(
        0,
        const _QualityStandardItem(
          label: 'Coding Guidelines',
          status: 'Active',
        ),
      );
    }
    if (!qualityStandards.any((item) => _looksPhysical(item.label))) {
      qualityStandards.add(
        const _QualityStandardItem(
          label: 'Safety Protocols',
          status: 'Active',
        ),
      );
    }

    final guideDocuments = <_GuideDocumentItem>[];
    for (final document in backendDocuments.take(4)) {
      final title = document['title']?.toString().trim() ?? '';
      if (title.isEmpty) continue;
      guideDocuments.add(
        _GuideDocumentItem(
          name: title,
          specification: document['location']?.toString().trim().isNotEmpty ==
                  true
              ? document['location'].toString().trim()
              : (document['description']?.toString().trim().isNotEmpty == true
                  ? document['description'].toString().trim()
                  : 'Reference pack for production teams.'),
          versionStatus:
              _documentStatusFromText(document['status']?.toString() ?? ''),
        ),
      );
    }
    if (!guideDocuments
        .any((item) => _looksSoftware('${item.name} ${item.specification}'))) {
      guideDocuments.insert(
        0,
        const _GuideDocumentItem(
          name: 'API Docs',
          specification:
              'Endpoint contract, payload examples, and auth sequence.',
          versionStatus: 'Current',
        ),
      );
    }
    if (!guideDocuments
        .any((item) => _looksPhysical('${item.name} ${item.specification}'))) {
      guideDocuments.add(
        const _GuideDocumentItem(
          name: 'Assembly Guide',
          specification:
              'Main stage setup order, fixings, and site safety checks.',
          versionStatus: 'Updating',
        ),
      );
    }

    final releaseChecklist = <_ReleaseChecklistItem>[];
    for (final item in readinessItems.take(5)) {
      final label = item.title.trim();
      if (label.isEmpty) continue;
      releaseChecklist.add(
        _ReleaseChecklistItem(
          label: label,
          status: item.status.trim().isNotEmpty ? item.status.trim() : 'Draft',
        ),
      );
    }
    if (releaseChecklist.isEmpty) {
      releaseChecklist.addAll(const [
        _ReleaseChecklistItem(label: 'Access environment', status: 'Ready'),
        _ReleaseChecklistItem(
          label: 'Push and extract changes',
          status: 'In review',
        ),
        _ReleaseChecklistItem(
          label: 'Main stage assembly rehearsal',
          status: 'Draft',
        ),
      ]);
    }

    final milestoneWithDate = projectData.keyMilestones.firstWhere(
      (milestone) => milestone.dueDate.trim().isNotEmpty,
      orElse: () => Milestone(),
    );
    final releaseTarget = milestoneWithDate.dueDate.trim().isNotEmpty
        ? milestoneWithDate.dueDate.trim()
        : projectData.keyMilestones
            .map((item) => item.name.trim())
            .firstWhere((name) => name.isNotEmpty, orElse: () => 'Date TBD');
    final releaseCountdown = _countdownLabelFor(milestoneWithDate.dueDate);

    final aiSignalCount = projectData.aiUsageCounts.values.fold<int>(
          0,
          (total, value) => total + value,
        ) +
        projectData.aiIntegrations.length +
        projectData.aiRecommendations.length;

    return _TechnicalDevelopmentDashboardSnapshot(
      projectLabel: projectLabel,
      workflowStages: workflowStages,
      buildRegister: buildRegister.take(6).toList(),
      integrations: integrations.take(4).toList(),
      prototypeItems: prototypeItems.take(4).toList(),
      issueItems: issueItems.take(4).toList(),
      qualityStandards: qualityStandards.take(5).toList(),
      guideDocuments: guideDocuments.take(4).toList(),
      releaseChecklist: releaseChecklist.take(4).toList(),
      releaseTarget: releaseTarget,
      releaseCountdown: releaseCountdown,
      aiSignalCount: aiSignalCount,
    );
  }
}

class _WorkflowStageItem {
  const _WorkflowStageItem({
    required this.label,
    required this.title,
    required this.note,
    required this.progress,
  });

  final String label;
  final String title;
  final String note;
  final double progress;

  String get percentLabel => '${(progress * 100).round()}%';
}

class _BuildRegisterRow {
  const _BuildRegisterRow({
    required this.name,
    required this.owner,
    required this.status,
    required this.contextLabel,
    required this.detail,
  });

  final String name;
  final String owner;
  final String status;
  final String contextLabel;
  final String detail;
}

class _IntegrationItem {
  const _IntegrationItem({
    required this.label,
    required this.detail,
    required this.status,
  });

  final String label;
  final String detail;
  final String status;
}

class _PrototypeCardItem {
  const _PrototypeCardItem({
    required this.title,
    required this.contextLabel,
    required this.caption,
    required this.outcome,
    required this.previewType,
  });

  final String title;
  final String contextLabel;
  final String caption;
  final String outcome;
  final _PrototypePreviewType previewType;
}

enum _PrototypePreviewType {
  appScreen,
  wireframe,
  stageMockup,
  siteAssembly,
}

class _IssueItem {
  const _IssueItem({
    required this.title,
    required this.detail,
    required this.severity,
  });

  final String title;
  final String detail;
  final String severity;
}

class _QualityStandardItem {
  const _QualityStandardItem({
    required this.label,
    required this.status,
  });

  final String label;
  final String status;
}

class _GuideDocumentItem {
  const _GuideDocumentItem({
    required this.name,
    required this.specification,
    required this.versionStatus,
  });

  final String name;
  final String specification;
  final String versionStatus;
}

class _ReleaseChecklistItem {
  const _ReleaseChecklistItem({
    required this.label,
    required this.status,
  });

  final String label;
  final String status;
}

List<Map<String, dynamic>> _mapList(dynamic data) {
  if (data is! List) return const [];
  return data
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

bool _looksSoftware(String value) {
  final text = value.toLowerCase();
  return text.contains('api') ||
      text.contains('app') ||
      text.contains('ui') ||
      text.contains('ux') ||
      text.contains('module') ||
      text.contains('screen') ||
      text.contains('auth') ||
      text.contains('code') ||
      text.contains('db') ||
      text.contains('server') ||
      text.contains('endpoint');
}

bool _looksPhysical(String value) {
  final text = value.toLowerCase();
  return text.contains('stage') ||
      text.contains('site') ||
      text.contains('floor') ||
      text.contains('fabrication') ||
      text.contains('lighting') ||
      text.contains('rigging') ||
      text.contains('hall') ||
      text.contains('venue') ||
      text.contains('assembly') ||
      text.contains('truss') ||
      text.contains('hvac');
}

double _progressForStatus(String value) {
  final text = value.toLowerCase();
  if (text.contains('approved') ||
      text.contains('done') ||
      text.contains('ready')) {
    return 0.9;
  }
  if (text.contains('review') || text.contains('production')) return 0.7;
  if (text.contains('staffed') || text.contains('backlog')) return 0.55;
  if (text.contains('depends') || text.contains('planning')) return 0.42;
  if (text.contains('blocked') || text.contains('risk')) return 0.22;
  return 0.38;
}

String _buildStatusFromText(String value) {
  final text = value.toLowerCase();
  if (text.contains('approved') ||
      text.contains('done') ||
      text.contains('delivered') ||
      text.contains('ready') ||
      text.contains('complete') ||
      text.contains('live')) {
    return 'Delivered';
  }
  if (text.contains('review') ||
      text.contains('production') ||
      text.contains('depends') ||
      text.contains('planning') ||
      text.contains('risk')) {
    return 'In Production';
  }
  return 'In Progress';
}

String _integrationStatusFromText(String value) {
  final text = value.toLowerCase();
  if (text.contains('pending') ||
      text.contains('manual') ||
      text.contains('blocked') ||
      text.contains('review')) {
    return 'Pending';
  }
  return 'Connected';
}

String _qualityStatusFromText(String label, String notes, String approach) {
  final combined = '$notes $approach'.toLowerCase();
  final keyword = label.toLowerCase();
  if (combined.contains(keyword.split(' ').first)) return 'Active';
  return label.toLowerCase().contains('safety') ||
          label.toLowerCase().contains('coding')
      ? 'Active'
      : 'Pending';
}

String _documentStatusFromText(String value) {
  final text = value.toLowerCase();
  if (text.contains('approved') || text.contains('live')) return 'Current';
  if (text.contains('review') || text.contains('draft')) return 'Updating';
  return 'Draft';
}

String _contextLabelFor(String name, String detail) {
  final combined = '$name $detail';
  if (_looksPhysical(combined)) return 'Site Fabrication';
  if (_looksSoftware(combined)) return 'Software Build';
  return 'Mixed Build';
}

String _prototypeContextLabel(String current, String name) {
  if (_looksPhysical('$current $name')) return 'Site Assembly';
  if (_looksSoftware('$current $name')) return 'Mobile App';
  return 'Prototype';
}

_PrototypePreviewType _prototypeTypeFor(String value) {
  final text = value.toLowerCase();
  if (text.contains('wire') || text.contains('flow')) {
    return _PrototypePreviewType.wireframe;
  }
  if (_looksPhysical(value) && text.contains('stage')) {
    return _PrototypePreviewType.stageMockup;
  }
  if (_looksPhysical(value)) return _PrototypePreviewType.siteAssembly;
  return _PrototypePreviewType.appScreen;
}

String _ownerFromTeam(List<TeamMember> members, int index) {
  if (members.isEmpty) return 'Owner';
  final member = members[index % members.length];
  if (member.name.trim().isNotEmpty) return member.name.trim();
  if (member.email.trim().isNotEmpty) return member.email.trim();
  if (member.role.trim().isNotEmpty) return member.role.trim();
  return 'Owner';
}

String _ownerForComponent(
  String componentName,
  List<TeamMember> members,
  List<Map<String, dynamic>> readiness,
  int index,
) {
  final lowerName = componentName.toLowerCase();
  for (final item in readiness) {
    final title = item['title']?.toString().toLowerCase() ?? '';
    final owner = item['owner']?.toString().trim() ?? '';
    if (owner.isEmpty) continue;
    final keywords = componentName
        .split(' ')
        .map((part) => part.toLowerCase())
        .where((part) => part.length > 3);
    if (keywords.any(title.contains) || title.contains(lowerName)) {
      return owner;
    }
  }
  return _ownerFromTeam(members, index);
}

String _severityForText(String value) {
  final text = value.toLowerCase();
  if (text.contains('critical') ||
      text.contains('safety') ||
      text.contains('fire') ||
      text.contains('blocked') ||
      text.contains('security')) {
    return 'Critical';
  }
  return 'Major';
}

String _countdownLabelFor(String dueDate) {
  final parsed = _tryParseLooseDate(dueDate.trim());
  if (parsed == null) return 'Countdown unavailable - schedule pending';
  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);
  final startOfTarget = DateTime(parsed.year, parsed.month, parsed.day);
  final difference = startOfTarget.difference(startOfToday).inDays;
  if (difference > 0) return 'D-$difference to release window';
  if (difference == 0) return 'Release window is today';
  return '${difference.abs()} days past target window';
}

DateTime? _tryParseLooseDate(String value) {
  if (value.isEmpty) return null;
  final direct = DateTime.tryParse(value);
  if (direct != null) return direct;
  final slashMatch = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);
  if (slashMatch != null) {
    final day = int.parse(slashMatch.group(1)!);
    final month = int.parse(slashMatch.group(2)!);
    final year = int.parse(slashMatch.group(3)!);
    return DateTime(year, month, day);
  }
  return null;
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'OW';
  if (parts.length == 1) {
    final word = parts.first;
    return word.substring(0, word.length < 2 ? word.length : 2).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
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
