// ignore_for_file: unused_element

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/models/user_role.dart';
import 'package:ndu_project/providers/user_role_provider.dart';
import 'package:ndu_project/screens/technical_alignment_screen.dart';
import 'package:ndu_project/screens/ui_ux_design_screen.dart';
import 'package:ndu_project/services/architecture_service.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Development Set Up — World-Class Overhaul
//
// Industry-standard Development Environment Setup page covering three
// methodology paradigms: Waterfall, Hybrid, and Agile. Content is based on
// PMI PMBOK 7th Ed., IEEE 830, ISO/IEC 12207, SAFe 6.0, Disciplined Agile
// Delivery (DAD), and Leffingwell's Agile Software Requirements.
// ─────────────────────────────────────────────────────────────────────────────

class DevelopmentSetUpScreen extends StatefulWidget {
  const DevelopmentSetUpScreen({super.key});

  @override
  State<DevelopmentSetUpScreen> createState() => _DevelopmentSetUpScreenState();
}

class _DevelopmentSetUpScreenState extends State<DevelopmentSetUpScreen> {
  // ── Methodology selection ──────────────────────────────────────────────
  String _selectedMethodology = 'Hybrid'; // Waterfall | Hybrid | Agile

  // ── Section-level status & summaries ───────────────────────────────────
  final TextEditingController _envSummaryController = TextEditingController();
  final TextEditingController _buildSummaryController = TextEditingController();
  final TextEditingController _toolingSummaryController =
      TextEditingController();
  final TextEditingController _qualitySummaryController =
      TextEditingController();
  final TextEditingController _securitySummaryController =
      TextEditingController();

  final List<_SetupChecklistItem> _envChecklist = [];
  final List<_SetupChecklistItem> _buildChecklist = [];
  final List<_SetupChecklistItem> _toolingChecklist = [];
  final List<_SetupChecklistItem> _qualityChecklist = [];
  final List<_SetupChecklistItem> _securityChecklist = [];

  final _Debouncer _saveDebounce = _Debouncer();

  bool _isLoading = false;
  bool _suspendSave = false;
  bool _registersExpanded = false;
  int _architectureNodeCount = 0;

  String _envStatus = 'Not started';
  String _buildStatus = 'Not started';
  String _toolingStatus = 'Not started';
  String _qualityStatus = 'Not started';
  String _securityStatus = 'Not started';

  final List<String> _sectionStatusOptions = const [
    'Not started',
    'In progress',
    'In review',
    'At risk',
    'Blocked',
    'Ready',
    'Approved'
  ];
  final List<String> _itemStatusOptions = const [
    'Not started',
    'In progress',
    'In review',
    'Blocked',
    'Ready',
    'Done',
    'Approved'
  ];

  String get _currentProjectId {
    final provider = ProjectDataInherited.maybeOf(context);
    return provider?.projectData.projectId ?? '';
  }

  bool get _canCreateSetup {
    final role = context.roleProvider;
    final projectId = _currentProjectId;
    return role.hasPermission(Permission.createContent) ||
        (projectId.isNotEmpty && role.canEditProject(projectId));
  }

  bool get _canEditSetup {
    final role = context.roleProvider;
    final projectId = _currentProjectId;
    return role.hasPermission(Permission.editAnyContent) ||
        (projectId.isNotEmpty && role.canEditProject(projectId));
  }

  bool get _canDeleteSetup {
    final role = context.roleProvider;
    final projectId = _currentProjectId;
    return role.hasPermission(Permission.deleteAnyContent) ||
        (projectId.isNotEmpty && role.canDeleteProject(projectId));
  }

  void _showPermissionSnackBar(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You do not have permission to $action.'),
        backgroundColor: const Color(0xFFB91C1C),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _envSummaryController.addListener(_scheduleSave);
    _buildSummaryController.addListener(_scheduleSave);
    _toolingSummaryController.addListener(_scheduleSave);
    _qualitySummaryController.addListener(_scheduleSave);
    _securitySummaryController.addListener(_scheduleSave);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final projectId = provider?.projectData.projectId;
      if (projectId != null && projectId.isNotEmpty) {
        await ProjectNavigationService.instance
            .saveLastPage(projectId, 'development-set-up');
      }
      await _loadFromFirestore();
    });
  }

  @override
  void dispose() {
    _envSummaryController.dispose();
    _buildSummaryController.dispose();
    _toolingSummaryController.dispose();
    _qualitySummaryController.dispose();
    _securitySummaryController.dispose();
    _saveDebounce.dispose();
    super.dispose();
  }

  // ── Helper methods ─────────────────────────────────────────────────────

  List<String> _ownerOptions(ProjectDataModel projectData) {
    final names = <String>{
      ...projectData.teamMembers
          .map((member) => member.name.trim())
          .where((name) => name.isNotEmpty),
    };
    if (projectData.charterProjectManagerName.trim().isNotEmpty) {
      names.add(projectData.charterProjectManagerName.trim());
    }
    if (projectData.charterProjectSponsorName.trim().isNotEmpty) {
      names.add(projectData.charterProjectSponsorName.trim());
    }
    if (names.isEmpty) {
      names.addAll(const ['Dev Lead', 'Platform Owner', 'Site Ops']);
    }
    return names.toList()..sort();
  }

  String _nextDateLabel(int offsetDays) {
    final date = DateTime.now().add(Duration(days: offsetDays));
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _defaultProjectLabel(ProjectDataModel projectData) {
    final name = projectData.projectName.trim();
    return name.isNotEmpty ? name : 'Current Design Package';
  }

  // ── Default checklist items (methodology-aware) ────────────────────────

  List<_SetupChecklistItem> _defaultEnvChecklist(ProjectDataModel pd) {
    final owners = _ownerOptions(pd);
    final isWaterfall = _selectedMethodology == 'Waterfall';
    final isAgile = _selectedMethodology == 'Agile';
    return [
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-env-dev',
        title: isWaterfall
            ? 'Provision complete Development environment with full stack'
            : isAgile
                ? 'Provision minimal viable Dev environment for Sprint 1'
                : 'Provision Dev workspace on AWS Server',
        owner: owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 5 : isAgile ? 1 : 2),
        status: pd.technologyInventory.isNotEmpty ? 'Done' : 'In progress',
        notes: isWaterfall
            ? 'Waterfall requires all environments fully provisioned before any development phase begins (PMBOK 7th Ed., Section 4.2).'
            : isAgile
                ? 'Agile favours a minimal environment that evolves with each sprint; start with just enough to code and test.'
                : 'Access URL and seed credentials for the core delivery team.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-env-stage',
        title: isWaterfall
            ? 'Provision Staging environment mirroring Production'
            : isAgile
                ? 'Set up lightweight staging for continuous demo'
                : 'Prepare staging handoff environment',
        owner: owners.length > 1 ? owners[1] : owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 7 : isAgile ? 3 : 4),
        status: pd.designDeliverablesData.register.isNotEmpty
            ? 'In progress'
            : 'Not started',
        notes: isWaterfall
            ? 'Staging must be an exact mirror of production for validation before the single deployment window.'
            : isAgile
                ? 'Agile teams deploy to staging every sprint; it should be lightweight and automated.'
                : 'Mirror integrations and configuration needed for smoke tests.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-env-site',
        title: isWaterfall
            ? 'Complete site infrastructure and facility readiness'
            : isAgile
                ? 'Confirm basic site access for iteration zero'
                : 'Confirm physical site access, venue keys, and site fencing',
        owner: owners.length > 2 ? owners[2] : owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 10 : isAgile ? 2 : 5),
        status: pd.stakeholderEntries.isNotEmpty
            ? 'In progress'
            : 'Not started',
        notes: isWaterfall
            ? 'All physical infrastructure must be signed off before development start per phase-gate governance.'
            : isAgile
                ? 'Just-in-time site access for early iterations; refine as scope clarifies.'
                : 'Track physical access constraints alongside digital environments.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-env-prod',
        title: isWaterfall
            ? 'Provision Production environment with full HA/DR'
            : isAgile
                ? 'Define Production deployment target and rollback strategy'
                : 'Configure Production environment with promotion gates',
        owner: owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 12 : isAgile ? 5 : 7),
        status: 'Not started',
        notes: isWaterfall
            ? 'Production must be ready before system integration testing begins.'
            : isAgile
                ? 'Agile favours continuous deployment to production; start with automated rollback capability.'
                : 'Production environment with controlled promotion from staging.',
      ),
    ];
  }

  List<_SetupChecklistItem> _defaultBuildChecklist(ProjectDataModel pd) {
    final owners = _ownerOptions(pd);
    final isWaterfall = _selectedMethodology == 'Waterfall';
    final isAgile = _selectedMethodology == 'Agile';
    return [
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-build-ci',
        title: isWaterfall
            ? 'Configure complete CI pipeline with all quality gates'
            : isAgile
                ? 'Set up basic CI with fast feedback loop'
                : 'Configure build validation and artifact packaging',
        owner: owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 4 : isAgile ? 1 : 3),
        status: _architectureNodeCount > 0 ? 'In progress' : 'Not started',
        notes: isWaterfall
            ? 'Full CI pipeline with code analysis, unit tests, integration tests, and compliance checks before merge.'
            : isAgile
                ? 'Fast CI (under 10 min) with unit tests and linting; add integration tests incrementally.'
                : 'Ensure generated artifacts are consistent with design deliverables.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-build-cd',
        title: isWaterfall
            ? 'Define CD pipeline with phase-gate approvals'
            : isAgile
                ? 'Set up continuous deployment to staging'
                : 'Prepare smoke tests and mock scenario validation',
        owner: owners.length > 1 ? owners[1] : owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 6 : isAgile ? 2 : 4),
        status: pd.planningRequirementItems.isNotEmpty
            ? 'In progress'
            : 'Not started',
        notes: isWaterfall
            ? 'CD must enforce formal sign-off gates aligned with waterfall phase transitions.'
            : isAgile
                ? 'Automated deployment to staging on every green build; production follows sprint review approval.'
                : 'Cover API endpoint fixtures and venue readiness scenarios.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-build-rollback',
        title: isWaterfall
            ? 'Establish rollback procedures with change control board'
            : isAgile
                ? 'Implement feature flags and automated rollback'
                : 'Define deploy promotion and rollback checkpoints',
        owner: owners.length > 2 ? owners[2] : owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 8 : isAgile ? 3 : 6),
        status: 'Not started',
        notes: isWaterfall
            ? 'Rollback requires CCB approval; document rollback criteria per deliverable.'
            : isAgile
                ? 'Feature flags allow instant rollback without redeployment; essential for continuous delivery.'
                : 'Include approvals for both digital and physical releases.',
      ),
    ];
  }

  List<_SetupChecklistItem> _defaultToolingChecklist(ProjectDataModel pd) {
    final owners = _ownerOptions(pd);
    final isWaterfall = _selectedMethodology == 'Waterfall';
    final isAgile = _selectedMethodology == 'Agile';
    return [
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-tool-ide',
        title: isWaterfall
            ? 'Standardize IDE and enforce coding standards across team'
            : isAgile
                ? 'Set up IDE with shared extensions and linting'
                : 'IDE and Git Repo access',
        owner: owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 3 : isAgile ? 1 : 1),
        status: 'Done',
        notes: isWaterfall
            ? 'All team members must use the same IDE configuration to ensure consistency per coding standards.'
            : isAgile
                ? 'Agile teams self-organize around tooling; shared linting ensures code consistency.'
                : 'Developer workspace access and repository permissions verified.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-tool-ci',
        title: isWaterfall
            ? 'Procure and configure all project management and ALM tools'
            : isAgile
                ? 'Set up agile board (Jira/Azure DevOps) with initial backlog'
                : 'Automation runner and package signing',
        owner: owners.length > 1 ? owners[1] : owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 4 : isAgile ? 1 : 3),
        status: 'In progress',
        notes: isWaterfall
            ? 'Full ALM suite: requirements management, traceability matrix, test management, and defect tracking.'
            : isAgile
                ? 'Agile board with product backlog, sprint board, and burndown chart; minimal setup for sprint 1.'
                : 'CI tokens, package registry, and deployment secrets staged.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-tool-equip',
        title: isWaterfall
            ? 'Complete equipment procurement and calibration'
            : isAgile
                ? 'Confirm essential equipment availability for first sprint'
                : 'Crane and site rigging availability',
        owner: owners.length > 2 ? owners[2] : owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 8 : isAgile ? 3 : 5),
        status: 'Not started',
        notes: isWaterfall
            ? 'All physical equipment must be procured, calibrated, and documented before construction/development phase.'
            : isAgile
                ? 'Just-enough equipment for the current sprint scope; expand as backlog items demand.'
                : 'Physical tooling readiness tracked with the same governance standard.',
      ),
    ];
  }

  List<_SetupChecklistItem> _defaultQualityChecklist(ProjectDataModel pd) {
    final owners = _ownerOptions(pd);
    final isWaterfall = _selectedMethodology == 'Waterfall';
    final isAgile = _selectedMethodology == 'Agile';
    return [
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-q-dor',
        title: isWaterfall
            ? 'Define phase entry and exit criteria'
            : isAgile
                ? 'Establish Definition of Ready (DoR) for backlog items'
                : 'Define quality gate criteria for each phase',
        owner: owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 3 : isAgile ? 1 : 2),
        status: 'In progress',
        notes: isWaterfall
            ? 'Each phase has formal entry/exit criteria with required sign-offs per PMBOK quality management.'
            : isAgile
                ? 'DoR ensures backlog items are sufficiently refined before sprint planning; team-owned.'
                : 'Quality gates combine phase-gate rigor with sprint-level flexibility.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-q-dod',
        title: isWaterfall
            ? 'Establish acceptance criteria and test strategy'
            : isAgile
                ? 'Establish Definition of Done (DoD) for sprint increments'
                : 'Define acceptance criteria with dual governance',
        owner: owners.length > 1 ? owners[1] : owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 4 : isAgile ? 1 : 3),
        status: 'Not started',
        notes: isWaterfall
            ? 'Formal test strategy document covering unit, integration, system, and UAT phases.'
            : isAgile
                ? 'DoD is team-agreed, includes code review, test coverage, documentation; evolves over sprints.'
                : 'Acceptance criteria per deliverable; DoD per sprint increment.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-q-review',
        title: isWaterfall
            ? 'Configure formal review and approval workflows'
            : isAgile
                ? 'Set up sprint review and retrospective cadence'
                : 'Configure review gates and sprint ceremonies',
        owner: owners.length > 2 ? owners[2] : owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 5 : isAgile ? 2 : 4),
        status: 'Not started',
        notes: isWaterfall
            ? 'Peer reviews, technical reviews, and management reviews at each phase boundary.'
            : isAgile
                ? 'Sprint review for stakeholder feedback; retrospective for continuous improvement.'
                : 'Phase-gate reviews for infrastructure; sprint reviews for feature delivery.',
      ),
    ];
  }

  List<_SetupChecklistItem> _defaultSecurityChecklist(ProjectDataModel pd) {
    final owners = _ownerOptions(pd);
    final isWaterfall = _selectedMethodology == 'Waterfall';
    final isAgile = _selectedMethodology == 'Agile';
    return [
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-sec-access',
        title: isWaterfall
            ? 'Complete RBAC matrix and access control provisioning'
            : isAgile
                ? 'Set up basic team access and SSH key management'
                : 'Configure role-based access with escalation paths',
        owner: owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 5 : isAgile ? 1 : 3),
        status: 'In progress',
        notes: isWaterfall
            ? 'Full role-based access control matrix covering all environments before development starts.'
            : isAgile
                ? 'Start with team-level access; refine roles as the team self-organizes.'
                : 'Formal RBAC for infrastructure; flexible team access for development.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-sec-compliance',
        title: isWaterfall
            ? 'Complete security and compliance audit baseline'
            : isAgile
                ? 'Set up automated security scanning in CI pipeline'
                : 'Conduct compliance gap assessment and CI security scan',
        owner: owners.length > 1 ? owners[1] : owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 6 : isAgile ? 2 : 4),
        status: 'Not started',
        notes: isWaterfall
            ? 'Full security audit (OWASP, NIST) and compliance baseline established before coding begins.'
            : isAgile
                ? 'Shift-left security: SAST/DAST in CI pipeline from sprint 1.'
                : 'Compliance baseline upfront (waterfall); iterative security hardening (agile).',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-sec-secrets',
        title: isWaterfall
            ? 'Establish secrets management and key rotation policy'
            : isAgile
                ? 'Configure secrets manager for CI/CD pipelines'
                : 'Set up secrets management with rotation schedule',
        owner: owners.length > 2 ? owners[2] : owners.first,
        targetDate: _nextDateLabel(isWaterfall ? 6 : isAgile ? 2 : 4),
        status: 'Not started',
        notes: isWaterfall
            ? 'All secrets, API keys, and certificates managed through vault with documented rotation policy.'
            : isAgile
                ? 'Secrets in environment variables or vault; never in code; automated rotation.'
                : 'Central secrets management with policy-driven rotation.',
      ),
    ];
  }

  // ── Seed defaults ──────────────────────────────────────────────────────

  void _seedDefaultsIfNeeded(ProjectDataModel projectData) {
    var changed = false;

    if (_envChecklist.isEmpty) {
      _envChecklist.addAll(_defaultEnvChecklist(projectData));
      changed = true;
    }
    if (_buildChecklist.isEmpty) {
      _buildChecklist.addAll(_defaultBuildChecklist(projectData));
      changed = true;
    }
    if (_toolingChecklist.isEmpty) {
      _toolingChecklist.addAll(_defaultToolingChecklist(projectData));
      changed = true;
    }
    if (_qualityChecklist.isEmpty) {
      _qualityChecklist.addAll(_defaultQualityChecklist(projectData));
      changed = true;
    }
    if (_securityChecklist.isEmpty) {
      _securityChecklist.addAll(_defaultSecurityChecklist(projectData));
      changed = true;
    }
    if (_envSummaryController.text.trim().isEmpty) {
      _envSummaryController.text =
          'Prepare development, integration, staging, production, and field workspaces for ${_defaultProjectLabel(projectData)} with access control, configuration parity, test data, observability, and evidence for the selected delivery model.';
      changed = true;
    }
    if (_buildSummaryController.text.trim().isEmpty) {
      _buildSummaryController.text =
          'Establish the end-to-end path from source control to release: build, test, security scan, artifact management, deployment, approval, rollback, and operational monitoring.';
      changed = true;
    }
    if (_toolingSummaryController.text.trim().isEmpty) {
      _toolingSummaryController.text =
          'Verify licensing, ownership, and operating readiness for software tooling and physical equipment.';
      changed = true;
    }
    if (_qualitySummaryController.text.trim().isEmpty) {
      _qualitySummaryController.text =
          'Establish quality gates, Definition of Ready/Done, and review cadences appropriate for the chosen methodology.';
      changed = true;
    }
    if (_securitySummaryController.text.trim().isEmpty) {
      _securitySummaryController.text =
          'Configure access controls, compliance baselines, and secrets management before development begins.';
      changed = true;
    }
    if (_envStatus == 'Not started') {
      _envStatus = 'In progress';
      changed = true;
    }
    if (_buildStatus == 'Not started') {
      _buildStatus = 'In progress';
      changed = true;
    }
    if (_toolingStatus == 'Not started') {
      _toolingStatus = 'In progress';
      changed = true;
    }
    if (_qualityStatus == 'Not started') {
      _qualityStatus = 'In progress';
      changed = true;
    }
    if (_securityStatus == 'Not started') {
      _securityStatus = 'In progress';
      changed = true;
    }

    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleSave();
      });
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void _navigateToTechnicalAlignment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TechnicalAlignmentScreen()),
    );
  }

  void _navigateToUiUxDesign() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UiUxDesignScreen()),
    );
  }

  void _showAccessReference(String reference) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reference),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);
    final provider = ProjectDataInherited.maybeOf(context);
    final projectData = provider?.projectData ?? ProjectDataModel();
    final snapshot = _DevelopmentSetupSnapshot.from(
      projectData: projectData,
      envStatus: _envStatus,
      buildStatus: _buildStatus,
      toolingStatus: _toolingStatus,
      qualityStatus: _qualityStatus,
      securityStatus: _securityStatus,
      envSummary: _envSummaryController.text,
      buildSummary: _buildSummaryController.text,
      toolingSummary: _toolingSummaryController.text,
      qualitySummary: _qualitySummaryController.text,
      securitySummary: _securitySummaryController.text,
      envChecklist: _envChecklist,
      buildChecklist: _buildChecklist,
      toolingChecklist: _toolingChecklist,
      qualityChecklist: _qualityChecklist,
      securityChecklist: _securityChecklist,
      architectureNodeCount: _architectureNodeCount,
      methodology: _selectedMethodology,
    );

    return ResponsiveScaffold(
      activeItemLabel: 'Development Set Up',
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Development Set Up',
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
                  _buildHeroHeader(isMobile: isMobile, snapshot: snapshot),
                  const SizedBox(height: 24),
                  _buildMethodologySelector(snapshot),
                  const SizedBox(height: 24),
                  _buildMethodologyComparisonTable(snapshot),
                  const SizedBox(height: 24),
                  _buildEnvironmentSection(snapshot, isMobile),
                  const SizedBox(height: 20),
                  _buildPipelineSection(snapshot, isMobile),
                  const SizedBox(height: 20),
                  _buildToolingSection(snapshot),
                  const SizedBox(height: 20),
                  _buildQualityGatesSection(snapshot),
                  const SizedBox(height: 20),
                  _buildSecuritySection(snapshot),
                  const SizedBox(height: 20),
                  _buildRepositorySection(snapshot),
                  const SizedBox(height: 20),
                  _buildTestDataSection(snapshot),
                  const SizedBox(height: 20),
                  _buildChannelsSection(snapshot),
                  const SizedBox(height: 20),
                  _buildSmokeTestSection(snapshot),
                  const SizedBox(height: 20),
                  _buildDetailedRegistersPanel(),
                  const SizedBox(height: 32),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: Technical Alignment',
                    nextLabel: 'Next: UI/UX Design',
                    onBack: _navigateToTechnicalAlignment,
                    onNext: _navigateToUiUxDesign,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HERO HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroHeader({
    required bool isMobile,
    required _DevelopmentSetupSnapshot snapshot,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF102A43),
            Color(0xFF1E3A5F),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 760;
              final titleBlock = Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Development Environment Setup',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prepare environments, tooling, pipelines, quality gates, and security baselines so execution can start without blockers. Content aligns with PMI PMBOK 7th Ed., ISO/IEC 12207, and SAFe 6.0 standards for $_selectedMethodology methodology.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.84),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
              final badge = _buildDarkBadge(
                label: snapshot.smokePassed
                    ? 'Smoke Test Pass'
                    : 'Readiness In Progress',
                icon: snapshot.smokePassed
                    ? Icons.verified_outlined
                    : Icons.pending_actions_outlined,
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.14),
                            ),
                          ),
                          child: const Icon(
                            Icons.settings_suggest_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        titleBlock,
                      ],
                    ),
                    const SizedBox(height: 14),
                    badge,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                    child: const Icon(
                      Icons.settings_suggest_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  titleBlock,
                  const SizedBox(width: 16),
                  badge,
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricPill(
                  'Provisioned Spaces', '${snapshot.provisionedSpaces}/4'),
              _buildMetricPill('Licensed Tools', '${snapshot.activeLicenses}'),
              _buildMetricPill('Channels Ready', '${snapshot.invitedChannels}'),
              _buildMetricPill(
                  'Readiness Gates', '${_setupReadinessGates.length}'),
              _buildMetricPill(
                  'Architecture Nodes', '${snapshot.architectureNodeCount}'),
              _buildMetricPill(
                  'Methodology', _selectedMethodology, highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // METHODOLOGY SELECTOR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMethodologySelector(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Development Methodology',
      subtitle:
          'Select the delivery methodology to tailor setup requirements. Each methodology dictates different environment provisioning, quality gates, and tooling expectations per industry standards.',
      icon: Icons.account_tree_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 700;
              if (isNarrow) {
                return Column(
                  children: [
                    _buildMethodologyCard(
                      'Waterfall',
                      'Sequential, phase-gated delivery. All environments and tooling must be fully provisioned before development begins. Best for fixed-scope, regulatory-heavy projects.',
                      Icons.timeline,
                      const Color(0xFF2563EB),
                    ),
                    const SizedBox(height: 12),
                    _buildMethodologyCard(
                      'Hybrid',
                      'Combines waterfall rigour for infrastructure with agile flexibility for feature delivery. Core environments upfront; development evolves iteratively.',
                      Icons.merge_type_outlined,
                      const Color(0xFF7C3AED),
                    ),
                    const SizedBox(height: 12),
                    _buildMethodologyCard(
                      'Agile',
                      'Iterative, incremental delivery. Minimal viable environment for Sprint 1; tooling and infrastructure evolve with each iteration. Best for adaptive scope.',
                      Icons.autorenew_outlined,
                      const Color(0xFF16A34A),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: _buildMethodologyCard(
                      'Waterfall',
                      'Sequential, phase-gated delivery. All environments and tooling must be fully provisioned before development begins. Best for fixed-scope, regulatory-heavy projects.',
                      Icons.timeline,
                      const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMethodologyCard(
                      'Hybrid',
                      'Combines waterfall rigour for infrastructure with agile flexibility for feature delivery. Core environments upfront; development evolves iteratively.',
                      Icons.merge_type_outlined,
                      const Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMethodologyCard(
                      'Agile',
                      'Iterative, incremental delivery. Minimal viable environment for Sprint 1; tooling and infrastructure evolve with each iteration. Best for adaptive scope.',
                      Icons.autorenew_outlined,
                      const Color(0xFF16A34A),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMethodologyCard(
      String label, String description, IconData icon, Color color) {
    final isSelected = _selectedMethodology == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethodology = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.22)),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? color : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // METHODOLOGY COMPARISON TABLE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMethodologyComparisonTable(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Methodology Comparison Matrix',
      subtitle:
          'Industry-standard comparison of Development Setup requirements across Waterfall, Hybrid, and Agile methodologies. Based on PMBOK 7th Ed., ISO/IEC 12207, and SAFe 6.0 frameworks.',
      icon: Icons.compare_arrows_outlined,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildComparisonHeader(),
              const SizedBox(height: 8),
              _buildComparisonRow(
                dimension: 'Environment Provisioning',
                waterfall: 'Complete all environments before development starts',
                hybrid: 'Core environments upfront; dev env evolves',
                agile: 'Minimal viable environment for Sprint 1',
                wfColor: AppSemanticColors.info,
                hColor: const Color(0xFF7C3AED),
                agColor: AppSemanticColors.success,
              ),
              _buildComparisonRow(
                dimension: 'CI/CD Pipeline',
                waterfall: 'Full pipeline with phase-gate approvals',
                hybrid: 'Basic CI upfront; CD matures iteratively',
                agile: 'Fast CI from day 1; CD per sprint',
                wfColor: AppSemanticColors.info,
                hColor: const Color(0xFF7C3AED),
                agColor: AppSemanticColors.success,
              ),
              _buildComparisonRow(
                dimension: 'Tooling & Licensing',
                waterfall: 'All tools licensed and configured upfront',
                hybrid: 'Critical tools first; others staged',
                agile: 'Essential tools for Sprint 1; expand as needed',
                wfColor: AppSemanticColors.info,
                hColor: const Color(0xFF7C3AED),
                agColor: AppSemanticColors.success,
              ),
              _buildComparisonRow(
                dimension: 'Quality Gates',
                waterfall: 'Phase entry/exit criteria with formal sign-off',
                hybrid: 'Phase gates for infra; DoD for features',
                agile: 'Definition of Ready and Definition of Done',
                wfColor: AppSemanticColors.info,
                hColor: const Color(0xFF7C3AED),
                agColor: AppSemanticColors.success,
              ),
              _buildComparisonRow(
                dimension: 'Security & Compliance',
                waterfall: 'Full security audit before development',
                hybrid: 'Compliance baseline upfront; iterative hardening',
                agile: 'Shift-left security in CI pipeline',
                wfColor: AppSemanticColors.info,
                hColor: const Color(0xFF7C3AED),
                agColor: AppSemanticColors.success,
              ),
              _buildComparisonRow(
                dimension: 'Branching Strategy',
                waterfall: 'Strict branching per phase (release branches)',
                hybrid: 'GitFlow with release trains',
                agile: 'Trunk-based with feature flags',
                wfColor: AppSemanticColors.info,
                hColor: const Color(0xFF7C3AED),
                agColor: AppSemanticColors.success,
              ),
              _buildComparisonRow(
                dimension: 'Test Data Strategy',
                waterfall: 'Complete test data prepared before SIT',
                hybrid: 'Core test data upfront; scenario data per sprint',
                agile: 'Test data generated per sprint from fixtures',
                wfColor: AppSemanticColors.info,
                hColor: const Color(0xFF7C3AED),
                agColor: AppSemanticColors.success,
              ),
              _buildComparisonRow(
                dimension: 'Rollback Approach',
                waterfall: 'CCB-approved rollback with documented criteria',
                hybrid: 'Formal rollback for infra; feature flags for code',
                agile: 'Automated rollback with feature flags and canary',
                wfColor: AppSemanticColors.info,
                hColor: const Color(0xFF7C3AED),
                agColor: AppSemanticColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 180,
            child: Text(
              'DIMENSION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 0.7,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'WATERFALL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
                letterSpacing: 0.7,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'HYBRID',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7C3AED),
                letterSpacing: 0.7,
              ),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'AGILE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF16A34A),
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow({
    required String dimension,
    required String waterfall,
    required String hybrid,
    required String agile,
    required Color wfColor,
    required Color hColor,
    required Color agColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              dimension,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: wfColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: wfColor.withOpacity(0.15)),
              ),
              child: Text(
                waterfall,
                style: TextStyle(
                  fontSize: 12.5,
                  color: const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: hColor.withOpacity(0.15)),
              ),
              child: Text(
                hybrid,
                style: TextStyle(
                  fontSize: 12.5,
                  color: const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: agColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: agColor.withOpacity(0.15)),
              ),
              child: Text(
                agile,
                style: TextStyle(
                  fontSize: 12.5,
                  color: const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ENVIRONMENT & INFRASTRUCTURE SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildEnvironmentSection(
      _DevelopmentSetupSnapshot snapshot, bool isMobile) {
    return _buildDashboardPanel(
      title: 'Environment & Infrastructure Provisioning',
      subtitle:
          'Prepare Dev, Staging, Production, and Physical Site spaces with clear status and access references. ${_selectedMethodology == 'Waterfall' ? 'All environments must be fully provisioned before development begins.' : _selectedMethodology == 'Agile' ? 'Minimal viable environment for Sprint 1; evolve iteratively.' : 'Core environments upfront; dev environment evolves with iterations.'}',
      icon: Icons.dns_outlined,
      trailing: _buildStatusDropdown(_envStatus, (value) {
        setState(() => _envStatus = value);
        _scheduleSave();
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 12.0;
              final columns = constraints.maxWidth >= 620 ? 2 : 1;
              if (constraints.maxWidth >= 900) columns == 2; // keep 2-col
              final width = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: snapshot.environments
                    .map(
                      (environment) => SizedBox(
                        width: width,
                        child: _buildEnvironmentCard(environment),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          _LabeledTextArea(
            label: 'Provisioning notes',
            controller: _envSummaryController,
            hintText:
                'Capture access URLs, site locations, provisioning dependencies, and readiness notes.',
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard(_EnvironmentCard env) {
    final statusColor =
        env.status == 'Provisioned' ? AppSemanticColors.success : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(env.icon, color: const Color(0xFF0F172A), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  env.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatusTag(env.status, statusColor),
          const SizedBox(height: 12),
          Text(
            env.note,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showAccessReference(env.accessReference),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.link_outlined,
                      size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      env.accessLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12.5,
                        color: Color(0xFF2563EB),
                        decoration: TextDecoration.underline,
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
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CI/CD & AUTOMATION PIPELINE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPipelineSection(
      _DevelopmentSetupSnapshot snapshot, bool isMobile) {
    return _buildDashboardPanel(
      title: 'CI/CD & Automation Pipeline',
      subtitle:
          'Build, Test, and Deploy flow with readiness indicators. ${_selectedMethodology == 'Waterfall' ? 'Full pipeline with phase-gate approvals required before development.' : _selectedMethodology == 'Agile' ? 'Fast feedback CI from Sprint 1; CD matures per iteration.' : 'Basic CI upfront; CD gates mature iteratively.'}',
      icon: Icons.play_circle_outline,
      trailing: _buildStatusDropdown(_buildStatus, (value) {
        setState(() => _buildStatus = value);
        _scheduleSave();
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (int i = 0; i < snapshot.pipelineStages.length; i++) ...[
                Expanded(child: _buildPipelineStage(snapshot.pipelineStages[i])),
                if (i != snapshot.pipelineStages.length - 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 36),
                      child: Row(
                        children: const [
                          Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                          SizedBox(width: 8),
                          Icon(Icons.play_arrow_rounded,
                              size: 20, color: Color(0xFF94A3B8)),
                          SizedBox(width: 8),
                          Expanded(child: Divider(color: Color(0xFFCBD5E1))),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          _LabeledTextArea(
            label: 'Pipeline notes',
            controller: _buildSummaryController,
            hintText:
                'Document gating checks, promotion strategy, approvals, and rollback coverage.',
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStage(_PipelineStage stage) {
    final color = stage.status == 'Ready'
        ? AppSemanticColors.success
        : stage.status == 'Pending'
            ? const Color(0xFFF59E0B)
            : stage.status == 'Blocked'
                ? const Color(0xFFDC2626)
                : const Color(0xFF2563EB);
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.22)),
          ),
          child: Icon(stage.icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          stage.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        _buildStatusTag(stage.status, color),
        const SizedBox(height: 8),
        Text(
          stage.detail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TOOLING & LICENSING
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildToolingSection(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Development Tools & Technology Stack',
      subtitle:
          'Verify licenses and assigned users for software tools and physical equipment. ${_selectedMethodology == 'Waterfall' ? 'All tools must be licensed and configured before development begins.' : _selectedMethodology == 'Agile' ? 'Essential tools for Sprint 1; expand toolchain as needed.' : 'Critical tools first; remaining tools staged per delivery phase.'}',
      icon: Icons.handyman_outlined,
      trailing: _buildStatusDropdown(_toolingStatus, (value) {
        setState(() => _toolingStatus = value);
        _scheduleSave();
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Tool Name',
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
                    'License Status',
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
                    'Assigned User',
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
          for (int i = 0; i < snapshot.toolRecords.length; i++) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                      snapshot.toolRecords[i].toolName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildStatusTag(
                      snapshot.toolRecords[i].licenseStatus,
                      snapshot.toolRecords[i].licenseStatus == 'Active'
                          ? AppSemanticColors.success
                          : const Color(0xFFDC2626),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      snapshot.toolRecords[i].assignedUser,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i != snapshot.toolRecords.length - 1)
              const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          _LabeledTextArea(
            label: 'Tooling notes',
            controller: _toolingSummaryController,
            enabled: _canEditSetup || _canCreateSetup,
            hintText:
                'Capture licensing caveats, provisioning blockers, and support contacts.',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // QUALITY GATES & DEFINITION OF READY/DONE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildQualityGatesSection(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Quality Gates & Definition of Ready/Done',
      subtitle:
          '${_selectedMethodology == 'Waterfall' ? 'Phase entry/exit criteria with formal sign-off per PMBOK quality management (Section 8.2).' : _selectedMethodology == 'Agile' ? 'Team-owned Definition of Ready (DoR) and Definition of Done (DoD) for sprint increments.' : 'Phase gates for infrastructure deliverables; DoR/DoD for feature delivery.'}',
      icon: Icons.fact_check_outlined,
      trailing: _buildStatusDropdown(_qualityStatus, (value) {
        setState(() => _qualityStatus = value);
        _scheduleSave();
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedMethodology == 'Waterfall' ||
              _selectedMethodology == 'Hybrid')
            _buildQualityGateTable(
              title: 'Phase Gate Criteria',
              rows: [
                _QualityGateRow(
                  phase: 'Requirements',
                  entry: 'Project charter approved, stakeholders identified',
                  exit: 'SRS signed off, traceability matrix complete',
                  owner: 'Project Manager',
                ),
                _QualityGateRow(
                  phase: 'Design',
                  entry: 'SRS approved, architecture reviewed',
                  exit: 'Design documents reviewed and baselined',
                  owner: 'Solution Architect',
                ),
                _QualityGateRow(
                  phase: 'Development',
                  entry: 'Design baselined, environment provisioned',
                  exit: 'Unit tests pass, code review complete',
                  owner: 'Dev Lead',
                ),
                _QualityGateRow(
                  phase: 'Testing',
                  entry: 'Code frozen, test data prepared',
                  exit: 'All test cases pass, UAT sign-off',
                  owner: 'QA Lead',
                ),
                _QualityGateRow(
                  phase: 'Deployment',
                  entry: 'UAT approved, deployment plan reviewed',
                  exit: 'System live, hypercare complete',
                  owner: 'Release Manager',
                ),
              ],
            ),
          if (_selectedMethodology == 'Agile' ||
              _selectedMethodology == 'Hybrid') ...[
            if (_selectedMethodology == 'Hybrid')
              const SizedBox(height: 20),
            _buildDoRDoDTable(),
          ],
          const SizedBox(height: 16),
          _LabeledTextArea(
            label: 'Quality notes',
            controller: _qualitySummaryController,
            hintText:
                'Document quality gate criteria, DoR/DoD agreements, and review cadences.',
          ),
        ],
      ),
    );
  }

  Widget _buildQualityGateTable({
    required String title,
    required List<_QualityGateRow> rows,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 700),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 120,
                        child: Text('PHASE',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                                letterSpacing: 0.7)),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('ENTRY CRITERIA',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                                letterSpacing: 0.7)),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('EXIT CRITERIA',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                                letterSpacing: 0.7)),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 130,
                        child: Text('GATE OWNER',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                                letterSpacing: 0.7)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < rows.length; i++) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? Colors.white
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(rows[i].phase,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(rows[i].entry,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF475569),
                                  height: 1.45)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(rows[i].exit,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF475569),
                                  height: 1.45)),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 130,
                          child: Text(rows[i].owner,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A))),
                        ),
                      ],
                    ),
                  ),
                  if (i != rows.length - 1) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoRDoDTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Definition of Ready (DoR) & Definition of Done (DoD)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 600),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 140,
                        child: Text('CRITERIA TYPE',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                                letterSpacing: 0.7)),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('CRITERIA',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                                letterSpacing: 0.7)),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 100,
                        child: Text('ENFORCED',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                                letterSpacing: 0.7)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildDoRDoDRow(
                  type: 'DoR',
                  criteria:
                      'User story has clear acceptance criteria and is estimated by the team',
                  enforced: 'Sprint Planning',
                ),
                _buildDoRDoDRow(
                  type: 'DoR',
                  criteria:
                      'Dependencies identified and resolved or escalated before sprint start',
                  enforced: 'Sprint Planning',
                ),
                _buildDoRDoDRow(
                  type: 'DoR',
                  criteria:
                      'UX mockups or design references available for UI stories',
                  enforced: 'Sprint Planning',
                ),
                _buildDoRDoDRow(
                  type: 'DoD',
                  criteria:
                      'Code reviewed by at least one peer; all unit tests passing',
                  enforced: 'Sprint Review',
                ),
                _buildDoRDoDRow(
                  type: 'DoD',
                  criteria:
                      'Integration tests pass; no critical or high-severity defects open',
                  enforced: 'Sprint Review',
                ),
                _buildDoRDoDRow(
                  type: 'DoD',
                  criteria:
                      'Feature deployed to staging and demonstrated in sprint review',
                  enforced: 'Sprint Review',
                ),
                _buildDoRDoDRow(
                  type: 'DoD',
                  criteria:
                      'Documentation updated; release notes entry created',
                  enforced: 'Sprint Review',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoRDoDRow({
    required String type,
    required String criteria,
    required String enforced,
  }) {
    final isDoR = type == 'DoR';
    final typeColor = isDoR ? const Color(0xFF2563EB) : AppSemanticColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: _buildStatusTag(type, typeColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              criteria,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF475569),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              enforced,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECURITY & COMPLIANCE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSecuritySection(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Security & Compliance Baseline',
      subtitle:
          '${_selectedMethodology == 'Waterfall' ? 'Full security audit and compliance baseline required before development begins (OWASP, NIST SP 800-53).' : _selectedMethodology == 'Agile' ? 'Shift-left security: SAST/DAST integrated in CI pipeline from Sprint 1.' : 'Compliance baseline upfront (waterfall-style); iterative security hardening per sprint (agile-style).'}',
      icon: Icons.shield_outlined,
      trailing: _buildStatusDropdown(_securityStatus, (value) {
        setState(() => _securityStatus = value);
        _scheduleSave();
      }),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security measures as cards
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = 12.0;
              final columns = constraints.maxWidth >= 600 ? 2 : 1;
              final width = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: snapshot.securityMeasures
                    .map(
                      (measure) => SizedBox(
                        width: width,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                measure.icon,
                                size: 18,
                                color: const Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  measure.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              _buildStatusTag(
                                measure.status,
                                measure.status == 'Ready'
                                    ? AppSemanticColors.success
                                    : const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          _LabeledTextArea(
            label: 'Security notes',
            controller: _securitySummaryController,
            hintText:
                'Document access controls, compliance gaps, secrets management, and remediation plans.',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REPOSITORY & ASSET STRUCTURE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRepositorySection(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Version Control & Repository Structure',
      subtitle:
          'Visualize the repo shape, branching strategy, and access control around design assets. ${_selectedMethodology == 'Waterfall' ? 'Strict branching per phase with release branches.' : _selectedMethodology == 'Agile' ? 'Trunk-based development with feature flags for continuous integration.' : 'GitFlow with release trains for structured delivery.'}',
      icon: Icons.folder_copy_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStatusTag(
                snapshot.branchingStrategy,
                const Color(0xFF2563EB),
              ),
              _buildStatusTag(
                '${snapshot.architectureNodeCount} architecture nodes',
                const Color(0xFF0F766E),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final node in snapshot.repoNodes) ...[
                  Padding(
                    padding: EdgeInsets.only(left: node.depth * 18.0),
                    child: Row(
                      children: [
                        Icon(
                          node.isFolder
                              ? Icons.folder_open_outlined
                              : Icons.description_outlined,
                          size: 16,
                          color: node.isFolder
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            node.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: node.depth == 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: const Color(0xFF0F172A),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        if (node.meta.isNotEmpty)
                          Text(
                            node.meta,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (node != snapshot.repoNodes.last)
                    const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Access Control',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: snapshot.accessMembers
                      .map((member) => _buildAvatarChip(member))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEST DATA & MOCK SCENARIOS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTestDataSection(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Test Data & Mock Scenarios',
      subtitle:
          '${_selectedMethodology == 'Waterfall' ? 'Complete test data and expected results prepared before System Integration Testing.' : _selectedMethodology == 'Agile' ? 'Test data generated per sprint from fixtures and factories; evolves with each iteration.' : 'Core test data upfront; scenario data added per sprint.'}',
      icon: Icons.dataset_outlined,
      child: Column(
        children: snapshot.scenarios
            .map(
              (scenario) => Container(
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
                    _buildFieldRow('Data Type', scenario.dataType),
                    const SizedBox(height: 8),
                    _buildFieldRow('Source', scenario.source),
                    const SizedBox(height: 10),
                    _buildStatusTag(
                      scenario.status,
                      scenario.status == 'Seeded'
                          ? AppSemanticColors.success
                          : const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMMUNICATION & COLLABORATION CHANNELS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildChannelsSection(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Communication & Collaboration Channels',
      subtitle:
          'Digital and field coordination channels with invite status. ${_selectedMethodology == 'Waterfall' ? 'Formal communication plan with scheduled reviews and escalation paths.' : _selectedMethodology == 'Agile' ? 'Daily standups, sprint reviews, and retrospectives for continuous alignment.' : 'Formal reviews for phase gates; agile ceremonies for feature delivery.'}',
      icon: Icons.forum_outlined,
      child: Column(
        children: snapshot.channels
            .map(
              (channel) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(
                        channel.icon,
                        size: 18,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel.name,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            channel.platform,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusTag(
                      channel.inviteStatus,
                      channel.inviteStatus == 'Invited'
                          ? AppSemanticColors.success
                          : const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SMOKE TEST / GO-NO-GO
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSmokeTestSection(_DevelopmentSetupSnapshot snapshot) {
    final resultColor = snapshot.smokePassed
        ? AppSemanticColors.success
        : const Color(0xFFDC2626);
    return _buildDashboardPanel(
      title: 'Go / No-Go Readiness Verification',
      subtitle:
          'Smoke-test status for basic workspace access, pipeline movement, and security baseline before execution starts.',
      icon: Icons.play_circle_outline,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 880;
                final resultCard = Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: resultColor.withOpacity(0.22)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Final Result',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        snapshot.smokePassed ? 'GO' : 'NO-GO',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: resultColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                );

                if (stacked) {
                  return Column(
                    children: [
                      for (int i = 0; i < snapshot.smokeChecks.length; i++) ...[
                        _buildSmokeCheck(snapshot.smokeChecks[i]),
                        const SizedBox(height: 12),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: resultCard,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    for (int i = 0; i < snapshot.smokeChecks.length; i++) ...[
                      Expanded(
                          child: _buildSmokeCheck(snapshot.smokeChecks[i])),
                      if (i != snapshot.smokeChecks.length - 1)
                        const SizedBox(width: 14),
                    ],
                    const SizedBox(width: 14),
                    resultCard,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmokeCheck(_SmokeCheck check) {
    final color =
        check.passed ? AppSemanticColors.success : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(
            check.passed ? Icons.check_circle : Icons.cancel_outlined,
            size: 28,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  check.detail,
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
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DETAILED REGISTERS (EXPANDABLE)
  // ══════════════════════════════════════════════════════════════════════════

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
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
            'Edit the source checklists and notes feeding the readiness dashboard.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
          children: [
            _buildSetupSection(
              icon: Icons.storage_outlined,
              title: 'Environments & Access',
              subtitle:
                  'Confirm where the system runs and who can access what.',
              helperText:
                  'Document environments, access provisioning, and seed data readiness.',
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
              helperText:
                  'Capture CI/CD steps, gating checks, and promotion approvals.',
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
              helperText:
                  'List tools, owners, onboarding steps, and support contacts.',
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
            const SizedBox(height: 20),
            _buildSetupSection(
              icon: Icons.fact_check_outlined,
              title: 'Quality Gates & DoR/DoD',
              subtitle: 'Define readiness and completion criteria.',
              helperText:
                  'Document quality gates, Definition of Ready, and Definition of Done.',
              status: _qualityStatus,
              onStatusChanged: (value) {
                setState(() => _qualityStatus = value);
                _scheduleSave();
              },
              summaryController: _qualitySummaryController,
              items: _qualityChecklist,
              onAddItem: _addQualityChecklistItem,
              onUpdateItem: _updateQualityChecklistItem,
              onDeleteItem: _deleteQualityChecklistItem,
            ),
            const SizedBox(height: 20),
            _buildSetupSection(
              icon: Icons.shield_outlined,
              title: 'Security & Compliance',
              subtitle: 'Configure access controls and compliance baselines.',
              helperText:
                  'Document RBAC, secrets management, compliance gaps, and remediation.',
              status: _securityStatus,
              onStatusChanged: (value) {
                setState(() => _securityStatus = value);
                _scheduleSave();
              },
              summaryController: _securitySummaryController,
              items: _securityChecklist,
              onAddItem: _addSecurityChecklistItem,
              onUpdateItem: _updateSecurityChecklistItem,
              onDeleteItem: _deleteSecurityChecklistItem,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED UI BUILDERS
  // ══════════════════════════════════════════════════════════════════════════

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

  Widget _buildMetricPill(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFFC812).withOpacity(0.20)
            : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight
              ? const Color(0xFFFFC812).withOpacity(0.35)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? const Color(0xFFFFC812)
                  : Colors.white.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: highlight ? Colors.white : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkBadge({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
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

  Widget _buildAvatarChip(String name) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF0F172A),
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
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
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
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
            enabled: _canEditSetup || _canCreateSetup,
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
                  child: Text(option,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ))
            .toList(),
        onChanged: _canEditSetup
            ? (value) {
                if (value != null) onChanged(value);
              }
            : null,
        decoration: InputDecoration(
          labelText: 'Status',
          labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          filled: true,
          fillColor: color.withOpacity(0.12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color.withOpacity(0.5)),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              child: Text('Readiness checklist',
                  style:
                      TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            TextButton.icon(
              onPressed: _canCreateSetup ? onAddItem : null,
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
                      enabled: _canEditSetup,
                      onChanged: (value) =>
                          onUpdateItem(item.copyWith(title: value)),
                    ),
                    _TextCell(
                      value: item.owner,
                      fieldKey: '${item.id}_owner',
                      hintText: 'Owner',
                      enabled: _canEditSetup,
                      onChanged: (value) =>
                          onUpdateItem(item.copyWith(owner: value)),
                    ),
                    _DateCell(
                      value: item.targetDate,
                      fieldKey: '${item.id}_date',
                      hintText: 'YYYY-MM-DD',
                      enabled: _canEditSetup,
                      onChanged: (value) =>
                          onUpdateItem(item.copyWith(targetDate: value)),
                    ),
                    _DropdownCell(
                      value: item.status,
                      fieldKey: '${item.id}_status',
                      options: _itemStatusOptions,
                      enabled: _canEditSetup,
                      onChanged: (value) =>
                          onUpdateItem(item.copyWith(status: value)),
                    ),
                    _TextCell(
                      value: item.notes,
                      fieldKey: '${item.id}_notes',
                      hintText: 'Notes',
                      enabled: _canEditSetup,
                      onChanged: (value) =>
                          onUpdateItem(item.copyWith(notes: value)),
                    ),
                    _DeleteCell(
                      enabled: _canDeleteSetup,
                      onPressed: () async {
                        final confirmed =
                            await _confirmDelete('checklist item');
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

  // ── Checklist CRUD ─────────────────────────────────────────────────────

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
    final index =
        _toolingChecklist.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _toolingChecklist[index] = updated);
    _scheduleSave();
  }

  void _deleteToolingChecklistItem(String id) {
    setState(() => _toolingChecklist.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addQualityChecklistItem() {
    setState(() => _qualityChecklist.add(_SetupChecklistItem.empty()));
    _scheduleSave();
  }

  void _updateQualityChecklistItem(_SetupChecklistItem updated) {
    final index =
        _qualityChecklist.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _qualityChecklist[index] = updated);
    _scheduleSave();
  }

  void _deleteQualityChecklistItem(String id) {
    setState(() => _qualityChecklist.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addSecurityChecklistItem() {
    setState(() => _securityChecklist.add(_SetupChecklistItem.empty()));
    _scheduleSave();
  }

  void _updateSecurityChecklistItem(_SetupChecklistItem updated) {
    final index =
        _securityChecklist.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;
    setState(() => _securityChecklist[index] = updated);
    _scheduleSave();
  }

  void _deleteSecurityChecklistItem(String id) {
    setState(() => _securityChecklist.removeWhere((item) => item.id == id));
    _scheduleSave();
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

  // ── Firestore persistence ──────────────────────────────────────────────

  String? _projectId() => ProjectDataHelper.getData(context).projectId;

  Future<void> _loadFromFirestore() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    final provider = ProjectDataInherited.maybeOf(context);
    final projectData = provider?.projectData ?? ProjectDataModel();
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('design_phase_sections')
            .doc('development_set_up')
            .get(),
        ArchitectureService.load(projectId),
      ]);
      final doc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final architectureData = results[1] as Map<String, dynamic>?;
      final data = doc.data() ?? {};
      final env = Map<String, dynamic>.from(data['environmentsAccess'] ?? {});
      final build = Map<String, dynamic>.from(data['buildDeployment'] ?? {});
      final tooling = Map<String, dynamic>.from(data['toolingOwnership'] ?? {});
      final quality = Map<String, dynamic>.from(data['qualityGates'] ?? {});
      final security = Map<String, dynamic>.from(data['securityBaseline'] ?? {});

      _suspendSave = true;
      _envSummaryController.text = env['summary']?.toString() ?? '';
      _buildSummaryController.text = build['summary']?.toString() ?? '';
      _toolingSummaryController.text = tooling['summary']?.toString() ?? '';
      _qualitySummaryController.text = quality['summary']?.toString() ?? '';
      _securitySummaryController.text = security['summary']?.toString() ?? '';
      _envStatus = _normalizeStatus(env['status']?.toString());
      _buildStatus = _normalizeStatus(build['status']?.toString());
      _toolingStatus = _normalizeStatus(tooling['status']?.toString());
      _qualityStatus = _normalizeStatus(quality['status']?.toString());
      _securityStatus = _normalizeStatus(security['status']?.toString());
      _selectedMethodology = data['methodology']?.toString() ?? 'Hybrid';
      _suspendSave = false;

      final envItems = _SetupChecklistItem.fromList(env['checklist']);
      final buildItems = _SetupChecklistItem.fromList(build['checklist']);
      final toolingItems = _SetupChecklistItem.fromList(tooling['checklist']);
      final qualityItems = _SetupChecklistItem.fromList(quality['checklist']);
      final securityItems =
          _SetupChecklistItem.fromList(security['checklist']);

      if (!mounted) return;
      setState(() {
        _architectureNodeCount =
            (architectureData?['nodes'] as List?)?.length ?? 0;
        _envChecklist
          ..clear()
          ..addAll(envItems);
        _buildChecklist
          ..clear()
          ..addAll(buildItems);
        _toolingChecklist
          ..clear()
          ..addAll(toolingItems);
        _qualityChecklist
          ..clear()
          ..addAll(qualityItems);
        _securityChecklist
          ..clear()
          ..addAll(securityItems);
        _seedDefaultsIfNeeded(projectData);
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
      'methodology': _selectedMethodology,
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
      'qualityGates': {
        'summary': _qualitySummaryController.text.trim(),
        'status': _qualityStatus,
        'checklist': _qualityChecklist.map((item) => item.toJson()).toList(),
      },
      'securityBaseline': {
        'summary': _securitySummaryController.text.trim(),
        'status': _securityStatus,
        'checklist': _securityChecklist.map((item) => item.toJson()).toList(),
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
}

// ════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ════════════════════════════════════════════════════════════════════════════

class _QualityGateRow {
  const _QualityGateRow({
    required this.phase,
    required this.entry,
    required this.exit,
    required this.owner,
  });
  final String phase;
  final String entry;
  final String exit;
  final String owner;
}

class _DevelopmentSetupSnapshot {
  const _DevelopmentSetupSnapshot({
    required this.environments,
    required this.repoNodes,
    required this.branchingStrategy,
    required this.accessMembers,
    required this.toolRecords,
    required this.pipelineStages,
    required this.scenarios,
    required this.channels,
    required this.securityMeasures,
    required this.smokeChecks,
    required this.smokePassed,
    required this.aiSignalCount,
    required this.architectureNodeCount,
  });

  final List<_EnvironmentCard> environments;
  final List<_RepoNode> repoNodes;
  final String branchingStrategy;
  final List<String> accessMembers;
  final List<_ToolRecord> toolRecords;
  final List<_PipelineStage> pipelineStages;
  final List<_ScenarioCard> scenarios;
  final List<_ChannelCard> channels;
  final List<_SecurityMeasure> securityMeasures;
  final List<_SmokeCheck> smokeChecks;
  final bool smokePassed;
  final int aiSignalCount;
  final int architectureNodeCount;

  int get provisionedSpaces => environments
      .where((environment) => environment.status == 'Provisioned')
      .length;
  int get activeLicenses =>
      toolRecords.where((tool) => tool.licenseStatus == 'Active').length;
  int get invitedChannels =>
      channels.where((channel) => channel.inviteStatus == 'Invited').length;

  factory _DevelopmentSetupSnapshot.from({
    required ProjectDataModel projectData,
    required String envStatus,
    required String buildStatus,
    required String toolingStatus,
    required String qualityStatus,
    required String securityStatus,
    required String envSummary,
    required String buildSummary,
    required String toolingSummary,
    required String qualitySummary,
    required String securitySummary,
    required List<_SetupChecklistItem> envChecklist,
    required List<_SetupChecklistItem> buildChecklist,
    required List<_SetupChecklistItem> toolingChecklist,
    required List<_SetupChecklistItem> qualityChecklist,
    required List<_SetupChecklistItem> securityChecklist,
    required int architectureNodeCount,
    required String methodology,
  }) {
    bool done(String status) => status.toLowerCase() == 'done';
    bool inProgress(String status) => status.toLowerCase() == 'in progress';
    bool blocked(String status) => status.toLowerCase() == 'blocked';
    bool hasKeywords(
        Iterable<_SetupChecklistItem> items, List<String> keywords) {
      for (final item in items) {
        final haystack = '${item.title} ${item.notes}'.toLowerCase();
        if (keywords.any(haystack.contains)) return true;
      }
      return false;
    }

    String firstUrl(String text) {
      final match = RegExp(r'https?://\S+').firstMatch(text);
      return match?.group(0) ?? '';
    }

    String slugify(String input) {
      final cleaned = input
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'-{2,}'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      return cleaned.isEmpty ? 'project' : cleaned;
    }

    final projectLabel = projectData.projectName.trim().isNotEmpty
        ? projectData.projectName.trim()
        : 'design-package';
    final slug = slugify(projectLabel);
    final owners = <String>{
      ...projectData.teamMembers
          .map((member) => member.name.trim())
          .where((name) => name.isNotEmpty),
      if (projectData.charterProjectManagerName.trim().isNotEmpty)
        projectData.charterProjectManagerName.trim(),
      if (projectData.charterProjectSponsorName.trim().isNotEmpty)
        projectData.charterProjectSponsorName.trim(),
    }.toList();
    if (owners.isEmpty) {
      owners.addAll(const ['Dev Lead', 'Platform Owner', 'Site Ops']);
    }

    final devProvisioned = envStatus == 'Ready' ||
        envChecklist.any((item) => done(item.status)) ||
        projectData.technologyInventory.isNotEmpty;
    final stagingProvisioned = buildStatus == 'Ready' ||
        buildChecklist.any((item) => done(item.status)) ||
        projectData.designDeliverablesData.register.isNotEmpty;
    final siteProvisioned = hasKeywords(
          [...envChecklist, ...toolingChecklist],
          const ['site', 'venue', 'keys', 'fencing', 'compound'],
        ) &&
        [...envChecklist, ...toolingChecklist].any((item) => done(item.status));
    final prodProvisioned = envStatus == 'Ready' && buildStatus == 'Ready';

    final environments = [
      _EnvironmentCard(
        title: 'Dev',
        status: devProvisioned ? 'Provisioned' : 'Pending',
        accessLabel: firstUrl(envSummary).isNotEmpty
            ? firstUrl(envSummary)
            : 'https://dev-$slug.workspace.local',
        accessReference: firstUrl(envSummary).isNotEmpty
            ? 'Access URL: ${firstUrl(envSummary)}'
            : 'Access URL: https://dev-$slug.workspace.local',
        note:
            'Workspace for day-one integration, fixtures, and branch testing.',
        icon: Icons.developer_board_outlined,
      ),
      _EnvironmentCard(
        title: 'Staging',
        status: stagingProvisioned ? 'Provisioned' : 'Pending',
        accessLabel: firstUrl(buildSummary).isNotEmpty
            ? firstUrl(buildSummary)
            : 'https://staging-$slug.workspace.local',
        accessReference: firstUrl(buildSummary).isNotEmpty
            ? 'Access URL: ${firstUrl(buildSummary)}'
            : 'Access URL: https://staging-$slug.workspace.local',
        note:
            'Promotion target for smoke tests and approval-ready package validation.',
        icon: Icons.cloud_done_outlined,
      ),
      _EnvironmentCard(
        title: 'Physical Site',
        status: siteProvisioned ? 'Provisioned' : 'Pending',
        accessLabel: 'Venue Keys / Site Office',
        accessReference: 'Location: Venue Keys Cabinet / Main Site Office',
        note: 'Field access, site fencing, keys, and physical setup controls.',
        icon: Icons.location_city_outlined,
      ),
      _EnvironmentCard(
        title: 'Production',
        status: prodProvisioned ? 'Provisioned' : 'Pending',
        accessLabel: 'Production Deployment Target',
        accessReference: 'Production environment with HA/DR configuration',
        note:
            'Controlled deployment target with rollback capability and monitoring.',
        icon: Icons.rocket_launch_outlined,
      ),
    ];

    final deliverableNames = projectData.designDeliverablesData.register
        .map((item) => item.name.trim())
        .where((name) => name.isNotEmpty)
        .take(2)
        .toList();

    // Methodology-aware repo structure
    final isAgile = methodology == 'Agile';
    final isWaterfall = methodology == 'Waterfall';
    final repoNodes = [
      _RepoNode(depth: 0, label: '$slug/', meta: 'root', isFolder: true),
      const _RepoNode(depth: 1, label: 'apps/', meta: '', isFolder: true),
      _RepoNode(
        depth: 2,
        label: 'design-ui/',
        meta: isAgile ? 'components + stories' : 'Figma + components',
        isFolder: true,
      ),
      const _RepoNode(
          depth: 2,
          label: 'mock-scenarios/',
          meta: 'seed data',
          isFolder: true),
      const _RepoNode(depth: 1, label: 'services/', meta: '', isFolder: true),
      const _RepoNode(
          depth: 2, label: 'backend-contracts/', meta: 'APIs', isFolder: true),
      const _RepoNode(depth: 1, label: 'sites/', meta: '', isFolder: true),
      const _RepoNode(
          depth: 2,
          label: 'physical-readiness/',
          meta: 'venue access',
          isFolder: true),
      if (isAgile)
        const _RepoNode(
          depth: 2,
          label: 'feature-flags/',
          meta: 'toggle config',
          isFolder: true,
        ),
      if (isWaterfall)
        const _RepoNode(
          depth: 2,
          label: 'release-candidates/',
          meta: 'RC builds',
          isFolder: true,
        ),
      _RepoNode(
        depth: 1,
        label: 'README-setup.md',
        meta: deliverableNames.isNotEmpty
            ? deliverableNames.join(' | ')
            : 'workspace guide',
        isFolder: false,
      ),
    ];

    final branchingStrategy = isWaterfall
        ? 'Strict branching per phase'
        : isAgile
            ? 'Trunk-based + feature flags'
            : buildChecklist.any((item) =>
                    '${item.title} ${item.notes}'.toLowerCase().contains('release') ||
                    '${item.title} ${item.notes}'.toLowerCase().contains('hotfix'))
                ? 'GitFlow'
                : 'GitFlow with release trains';

    final toolRecords = <_ToolRecord>[
      _ToolRecord(
        toolName: 'IDE',
        licenseStatus: blocked(toolingStatus) || toolingStatus == 'At risk'
            ? 'Expired'
            : 'Active',
        assignedUser: owners.first,
      ),
      _ToolRecord(
        toolName: 'Git Repo',
        licenseStatus: owners.isNotEmpty ? 'Active' : 'Expired',
        assignedUser: owners.length > 1 ? owners[1] : owners.first,
      ),
      _ToolRecord(
        toolName: 'AWS Server',
        licenseStatus: devProvisioned ? 'Active' : 'Expired',
        assignedUser: owners.length > 1 ? owners[1] : owners.first,
      ),
      _ToolRecord(
        toolName: isWaterfall ? 'ALM Suite' : isAgile ? 'Agile Board' : 'Project Tracker',
        licenseStatus: qualityStatus == 'Ready' || qualityStatus == 'In progress'
            ? 'Active'
            : 'Expired',
        assignedUser: owners.first,
      ),
      _ToolRecord(
        toolName: 'Crane',
        licenseStatus: siteProvisioned ? 'Active' : 'Expired',
        assignedUser: owners.length > 2 ? owners[2] : owners.first,
      ),
    ];

    String buildStageStatus() {
      if (buildStatus == 'Ready') return 'Ready';
      if (buildStatus == 'At risk' ||
          buildChecklist.any((item) => blocked(item.status))) {
        return 'Blocked';
      }
      if (buildStatus == 'In progress' ||
          buildChecklist.any((item) => inProgress(item.status))) {
        return 'Running';
      }
      return 'Pending';
    }

    String testStageStatus() {
      if (projectData.planningRequirementItems.isNotEmpty &&
          (buildStatus == 'Ready' || buildStatus == 'In progress')) {
        return 'Running';
      }
      return 'Pending';
    }

    String deployStageStatus() {
      if (devProvisioned && stagingProvisioned && buildStatus == 'Ready') {
        return 'Ready';
      }
      if (buildStatus == 'At risk') return 'Blocked';
      return 'Pending';
    }

    final pipelineStages = [
      _PipelineStage(
        label: 'Build',
        status: buildStageStatus(),
        detail: 'Compile workspace and package artifacts.',
        icon: Icons.play_arrow_rounded,
      ),
      _PipelineStage(
        label: 'Test',
        status: testStageStatus(),
        detail: 'Run smoke tests and scenario checks.',
        icon: Icons.science_outlined,
      ),
      _PipelineStage(
        label: 'Deploy',
        status: deployStageStatus(),
        detail: 'Promote approved changes and site updates.',
        icon: Icons.rocket_launch_outlined,
      ),
    ];

    final scenarios = [
      _ScenarioCard(
        dataType: 'API payload fixtures',
        source: projectData.planningRequirementItems.isNotEmpty
            ? 'Planning requirement register'
            : 'Backend contract draft',
        status: projectData.planningRequirementItems.isNotEmpty
            ? 'Seeded'
            : 'Empty',
      ),
      _ScenarioCard(
        dataType: 'Venue access roster',
        source: projectData.stakeholderEntries.isNotEmpty
            ? 'Stakeholder and site ops list'
            : 'Site operations brief',
        status:
            projectData.stakeholderEntries.isNotEmpty ? 'Seeded' : 'Empty',
      ),
      _ScenarioCard(
        dataType: 'UI smoke personas',
        source: projectData.teamMembers.isNotEmpty
            ? 'Delivery team and review roles'
            : 'Project roles matrix',
        status: projectData.teamMembers.isNotEmpty ? 'Seeded' : 'Empty',
      ),
    ];

    final channels = [
      _ChannelCard(
        name: 'Dev-Backend',
        platform: 'Slack',
        icon: Icons.chat_bubble_outline,
        inviteStatus: owners.isNotEmpty ? 'Invited' : 'Pending Invite',
      ),
      _ChannelCard(
        name: 'Design-QA',
        platform: 'Teams',
        icon: Icons.groups_2_outlined,
        inviteStatus:
            projectData.designDeliverablesData.register.isNotEmpty
                ? 'Invited'
                : 'Pending Invite',
      ),
      _ChannelCard(
        name: 'Site-Safety',
        platform: 'Radio',
        icon: Icons.settings_input_antenna,
        inviteStatus: hasKeywords(envChecklist,
                    const ['site', 'venue', 'safety']) ||
                hasKeywords(
                    toolingChecklist, const ['crane', 'rigging', 'site'])
            ? 'Invited'
            : 'Pending Invite',
      ),
    ];

    final securityMeasures = [
      _SecurityMeasure(
        label: 'SSL Certs',
        status: devProvisioned ? 'Ready' : 'Pending',
        icon: Icons.shield_outlined,
      ),
      _SecurityMeasure(
        label: 'Repo Permissions',
        status: owners.isNotEmpty ? 'Ready' : 'Pending',
        icon: Icons.lock_outline,
      ),
      _SecurityMeasure(
        label: 'Site Fencing',
        status: hasKeywords(envChecklist, const ['fencing', 'site', 'venue'])
            ? 'Ready'
            : 'Pending',
        icon: Icons.gpp_good_outlined,
      ),
      _SecurityMeasure(
        label: 'Venue Keys',
        status: hasKeywords(envChecklist, const ['keys', 'access', 'site'])
            ? 'Ready'
            : 'Pending',
        icon: Icons.key_outlined,
      ),
      _SecurityMeasure(
        label: 'Secrets Manager',
        status: securityStatus == 'Ready' ? 'Ready' : 'Pending',
        icon: Icons.vpn_key_outlined,
      ),
      _SecurityMeasure(
        label: 'RBAC Matrix',
        status: securityStatus == 'Ready' || securityStatus == 'In progress'
            ? 'Ready'
            : 'Pending',
        icon: Icons.admin_panel_settings_outlined,
      ),
    ];

    final smokeChecks = [
      _SmokeCheck(
        label: 'Access Environment',
        passed: devProvisioned || stagingProvisioned || siteProvisioned,
        detail: devProvisioned
            ? 'Workspace access has been provisioned for at least one environment.'
            : 'Environment access is still pending provisioning.',
      ),
      _SmokeCheck(
        label: 'Push/Extract Changes',
        passed: buildChecklist.isNotEmpty ||
            architectureNodeCount > 0 ||
            projectData.designDeliverablesData.register.isNotEmpty,
        detail: buildChecklist.isNotEmpty
            ? 'Pipeline and artifact movement controls are defined.'
            : 'No movement workflow is ready yet.',
      ),
      _SmokeCheck(
        label: 'Security Baseline',
        passed: securityStatus == 'Ready' || securityMeasures.any((m) => m.status == 'Ready'),
        detail: securityStatus == 'Ready'
            ? 'Security baseline is established and verified.'
            : 'Security baseline checks are still pending.',
      ),
    ];

    final smokePassed = smokeChecks.every((check) => check.passed);
    final aiSignalCount = projectData.aiUsageCounts.values.fold<int>(
          0,
          (total, value) => total + value,
        ) +
        projectData.aiRecommendations.length +
        projectData.aiIntegrations.length;

    return _DevelopmentSetupSnapshot(
      environments: environments,
      repoNodes: repoNodes,
      branchingStrategy: branchingStrategy,
      accessMembers: owners.take(4).toList(),
      toolRecords: toolRecords,
      pipelineStages: pipelineStages,
      scenarios: scenarios,
      channels: channels,
      securityMeasures: securityMeasures,
      smokeChecks: smokeChecks,
      smokePassed: smokePassed,
      aiSignalCount: aiSignalCount,
      architectureNodeCount: architectureNodeCount,
    );
  }
}

class _EnvironmentCard {
  const _EnvironmentCard({
    required this.title,
    required this.status,
    required this.accessLabel,
    required this.accessReference,
    required this.note,
    required this.icon,
  });

  final String title;
  final String status;
  final String accessLabel;
  final String accessReference;
  final String note;
  final IconData icon;
}

class _RepoNode {
  const _RepoNode({
    required this.depth,
    required this.label,
    required this.meta,
    required this.isFolder,
  });

  final int depth;
  final String label;
  final String meta;
  final bool isFolder;
}

class _ToolRecord {
  const _ToolRecord({
    required this.toolName,
    required this.licenseStatus,
    required this.assignedUser,
  });

  final String toolName;
  final String licenseStatus;
  final String assignedUser;
}

class _PipelineStage {
  const _PipelineStage({
    required this.label,
    required this.status,
    required this.detail,
    required this.icon,
  });

  final String label;
  final String status;
  final String detail;
  final IconData icon;
}

class _ScenarioCard {
  const _ScenarioCard({
    required this.dataType,
    required this.source,
    required this.status,
  });

  final String dataType;
  final String source;
  final String status;
}

class _ChannelCard {
  const _ChannelCard({
    required this.name,
    required this.platform,
    required this.icon,
    required this.inviteStatus,
  });

  final String name;
  final String platform;
  final IconData icon;
  final String inviteStatus;
}

class _SecurityMeasure {
  const _SecurityMeasure({
    required this.label,
    required this.status,
    required this.icon,
  });

  final String label;
  final String status;
  final IconData icon;
}

class _SmokeCheck {
  const _SmokeCheck({
    required this.label,
    required this.passed,
    required this.detail,
  });

  final String label;
  final bool passed;
  final String detail;
}

class _ReadOnlyColumn {
  const _ReadOnlyColumn(this.label, this.width);

  final String label;
  final double width;
}

class _DeliveryModelSetupStandard {
  const _DeliveryModelSetupStandard({
    required this.model,
    required this.emphasis,
    required this.evidence,
    required this.cadence,
    required this.exitCriteria,
  });

  final String model;
  final String emphasis;
  final String evidence;
  final String cadence;
  final String exitCriteria;
}

class _SetupReadinessGate {
  const _SetupReadinessGate({
    required this.gate,
    required this.standard,
    required this.evidence,
    required this.owner,
    required this.decision,
  });

  final String gate;
  final String standard;
  final String evidence;
  final String owner;
  final String decision;
}

class _DevSecOpsControl {
  const _DevSecOpsControl({
    required this.area,
    required this.requirement,
    required this.evidence,
    required this.risk,
  });

  final String area;
  final String requirement;
  final String evidence;
  final String risk;
}

class _SetupEvidenceRow {
  const _SetupEvidenceRow({
    required this.object,
    required this.why,
    required this.metric,
    required this.waterfallEvidence,
    required this.agileEvidence,
  });

  final String object;
  final String why;
  final String metric;
  final String waterfallEvidence;
  final String agileEvidence;
}

const List<_DeliveryModelSetupStandard> _deliveryModelSetupStandards = [
  _DeliveryModelSetupStandard(
    model: 'Waterfall / Predictive',
    emphasis:
        'Controlled baseline before build starts; strong audit trail and signed stage-gate evidence.',
    evidence:
        'Environment plan, approved toolchain, access matrix, configuration baseline, test strategy, deployment plan, rollback plan, support handover, and acceptance gate checklist.',
    cadence:
        'Formal setup review before design/build gate and controlled changes through change authority.',
    exitCriteria:
        'All mandatory environments, access, tools, test data, and release controls approved before implementation begins.',
  ),
  _DeliveryModelSetupStandard(
    model: 'Hybrid',
    emphasis:
        'Formal governance around phase boundaries with iterative setup for incremental product delivery.',
    evidence:
        'Rolling-wave environment plan, integrated backlog links, release train calendar, dependency board, setup risk log, change-control path, and increment readiness checklist.',
    cadence:
        'Gate reviews at phase boundaries plus sprint/release readiness checks inside each phase.',
    exitCriteria:
        'Governance artefacts are controlled while teams can build, test, demo, and release approved increments.',
  ),
  _DeliveryModelSetupStandard(
    model: 'Scrum',
    emphasis:
        'Team can create a usable Increment that meets Definition of Done every Sprint.',
    evidence:
        'Repository access, local run instructions, Definition of Done quality gates, product backlog links, CI checks, test data, demo environment, and release checklist.',
    cadence:
        'Validated before sprint planning and inspected through daily build health, sprint review, and retrospective improvements.',
    exitCriteria:
        'Ready backlog items can be built, integrated, tested, reviewed, and potentially released without hidden setup blockers.',
  ),
  _DeliveryModelSetupStandard(
    model: 'Kanban / Flow',
    emphasis:
        'Stable service policies, pull criteria, WIP limits, fast feedback, and operational visibility.',
    evidence:
        'Intake policy, workflow states, service classes, WIP limits, environment ownership, deployment policy, blocker aging view, and incident channel.',
    cadence:
        'Continuous readiness monitored through flow metrics, blocker reviews, replenishment, and service delivery reviews.',
    exitCriteria:
        'Work items can enter flow only when setup evidence, owner, risk class, and release path are explicit.',
  ),
  _DeliveryModelSetupStandard(
    model: 'Scaled Agile / Portfolio',
    emphasis:
        'Shared platform readiness, cross-team dependency ownership, and integrated release governance.',
    evidence:
        'Platform environment map, architecture runway, shared Definition of Done, program board, enabler backlog, integration cadence, SLOs, and release train readiness.',
    cadence:
        'Program increment readiness, system demos, dependency syncs, inspect-and-adapt, and release management reviews.',
    exitCriteria:
        'Teams share a deployable baseline, dependencies are owned, and the platform can absorb committed features.',
  ),
];

const List<_SetupReadinessGate> _setupReadinessGates = [
  _SetupReadinessGate(
    gate: 'People And Access',
    standard:
        'Every contributor has the correct repository, environment, collaboration, service desk, and field access using least privilege.',
    evidence:
        'Access matrix, role-to-permission map, MFA status, onboarding checklist, vendor access record, and emergency access owner.',
    owner: 'Delivery Lead',
    decision: 'Conditional',
  ),
  _SetupReadinessGate(
    gate: 'Environment Parity',
    standard:
        'Development, integration, staging, production, and physical/field environments are named, owned, configured, observable, and recoverable.',
    evidence:
        'Environment register, configuration source of truth, secrets inventory, endpoint list, smoke test result, and rollback route.',
    owner: 'Platform Owner',
    decision: 'Conditional',
  ),
  _SetupReadinessGate(
    gate: 'Source And Artifact Control',
    standard:
        'All code, scripts, infrastructure definitions, configuration, database changes, and release artefacts are versioned and traceable.',
    evidence:
        'Repository policy, branch strategy, code review rules, artifact registry, tagging convention, and provenance record.',
    owner: 'Engineering Lead',
    decision: 'Ready',
  ),
  _SetupReadinessGate(
    gate: 'Quality And Security Gates',
    standard:
        'Automated checks provide fast feedback on build health, tests, vulnerabilities, secrets, dependencies, accessibility, performance, and compliance.',
    evidence:
        'Pipeline logs, quality thresholds, SAST/SCA/secrets scans, test reports, acceptance evidence, and waiver workflow.',
    owner: 'QA / Security',
    decision: 'Conditional',
  ),
  _SetupReadinessGate(
    gate: 'Release And Operations',
    standard:
        'Promotion, approvals, rollback, incident response, monitoring, support ownership, and handover are rehearsed before execution begins.',
    evidence:
        'Release checklist, deployment runbook, monitoring dashboard, alert routes, support rota, known-error log, and operational acceptance sign-off.',
    owner: 'DevOps / Ops',
    decision: 'At risk',
  ),
];

const List<_DevSecOpsControl> _devSecOpsControls = [
  _DevSecOpsControl(
    area: 'Version Control',
    requirement:
        'Use source control for application code, infrastructure, configuration, database changes, scripts, test assets, and release documentation.',
    evidence:
        'Repository list, branch protections, pull request policy, signed commits/tags, and CODEOWNERS or reviewer rules.',
    risk:
        'Untraceable changes, undocumented releases, configuration drift, and inability to reproduce builds.',
  ),
  _DevSecOpsControl(
    area: 'Continuous Integration',
    requirement:
        'Maintain fast, repeatable builds that run on every meaningful change and keep the mainline deployable.',
    evidence:
        'Build pipeline, test suite, dependency cache, build status badges, failure alerts, and agreed fix-forward/revert policy.',
    risk:
        'Late integration failures, unstable releases, hidden defects, and long stabilization phases.',
  ),
  _DevSecOpsControl(
    area: 'Security By Design',
    requirement:
        'Integrate security requirements, threat considerations, dependency checks, secrets detection, and vulnerability response into setup.',
    evidence:
        'Threat model, SAST/SCA/secrets scan output, secure coding standard, vulnerability triage route, and exception/waiver record.',
    risk:
        'Vulnerabilities become release blockers or production incidents rather than managed engineering work.',
  ),
  _DevSecOpsControl(
    area: 'Test Data Management',
    requirement:
        'Provide representative, privacy-safe, resettable test data and mocks that do not constrain automated validation.',
    evidence:
        'Seed scripts, data dictionary, masking rules, synthetic data set, refresh process, and contract/mocking service.',
    risk:
        'Manual testing bottlenecks, privacy exposure, unreliable tests, and poor coverage of real workflows.',
  ),
  _DevSecOpsControl(
    area: 'Observability',
    requirement:
        'Instrument logs, metrics, traces, SLOs, alert routes, and dashboards before teams depend on the environment.',
    evidence:
        'Monitoring dashboard, alert rules, telemetry schema, runbook links, sample incident, and service health checks.',
    risk:
        'Teams cannot diagnose setup issues, release failures, performance regressions, or service-impacting incidents.',
  ),
  _DevSecOpsControl(
    area: 'Release Automation',
    requirement:
        'Automate deployable artifact promotion while preserving approvals, segregation of duties, rollback, and audit evidence.',
    evidence:
        'Deployment pipeline, approval gates, environment promotion rules, rollback test, release notes, and deployment audit log.',
    risk:
        'Manual release errors, slow recovery, inconsistent environments, and weak governance evidence.',
  ),
];

const List<_SetupEvidenceRow> _setupEvidenceRows = [
  _SetupEvidenceRow(
    object: 'Environment Register',
    why:
        'Creates one source of truth for where development, testing, staging, production, and field work occurs.',
    metric: 'Provisioning lead time; environment availability; drift findings.',
    waterfallEvidence: 'Environment management plan and stage-gate approval.',
    agileEvidence:
        'Team setup board, environment owner tags, and sprint readiness check.',
  ),
  _SetupEvidenceRow(
    object: 'Pipeline Health',
    why:
        'Shows whether code can move from commit to validated artifact without manual heroics.',
    metric:
        'Build duration, test pass rate, lead time for change, failed deployment recovery time.',
    waterfallEvidence: 'Build verification report and test readiness sign-off.',
    agileEvidence:
        'CI dashboard, Definition of Done gate, and deployment readiness signal.',
  ),
  _SetupEvidenceRow(
    object: 'Security And Compliance Baseline',
    why:
        'Prevents security, privacy, and compliance obligations from being discovered late in delivery.',
    metric:
        'Critical vulnerability count, waiver age, scan coverage, secrets findings.',
    waterfallEvidence:
        'Security control checklist, approval memo, and risk acceptance log.',
    agileEvidence:
        'Security acceptance criteria, automated scans, and backlog remediation items.',
  ),
  _SetupEvidenceRow(
    object: 'Operational Readiness',
    why:
        'Confirms that released work can be monitored, supported, recovered, and handed over.',
    metric:
        'Alert coverage, runbook coverage, incident response time, support acceptance defects.',
    waterfallEvidence: 'Operational acceptance test and handover sign-off.',
    agileEvidence:
        'Runbook story, support review, release checklist, and production telemetry review.',
  ),
  _SetupEvidenceRow(
    object: 'Flow And Governance',
    why:
        'Balances agility with control by making work intake, approvals, WIP, dependencies, and changes visible.',
    metric:
        'Cycle time, blocker age, WIP, change approval latency, dependency aging.',
    waterfallEvidence:
        'Integrated master schedule, change log, and dependency register.',
    agileEvidence:
        'Kanban board, program board, dependency sync, and retrospective improvement actions.',
  ),
];

class _LabeledTextArea extends StatelessWidget {
  const _LabeledTextArea({
    required this.label,
    required this.controller,
    required this.hintText,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool enabled;

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
          enabled: enabled,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                        letterSpacing: 0,
                        color: Color(0xFF6B7280)),
                  ),
                ))
            .toList(),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth =
            columns.fold<double>(0, (total, col) => total + col.width);
        final minWidth = constraints.maxWidth > totalWidth
            ? constraints.maxWidth
            : totalWidth;
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? Colors.white
                          : const Color(0xFFF9FAFB),
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
        (index) =>
            SizedBox(width: columns[index].width, child: cells[index]),
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
    this.enabled = true,
  });

  final String value;
  final String fieldKey;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(fieldKey),
      initialValue: value,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hintText,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
    this.enabled = true,
  });

  final String value;
  final String fieldKey;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final displayText = value.trim();
    final textStyle = TextStyle(
      fontSize: 12,
      color: displayText.isEmpty
          ? const Color(0xFF9CA3AF)
          : const Color(0xFF111827),
    );

    return InkWell(
      key: ValueKey(fieldKey),
      borderRadius: BorderRadius.circular(8),
      onTap: enabled
          ? () async {
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
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.calendar_today_outlined,
              size: 16, color: Color(0xFF6B7280)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
    this.enabled = true,
  });

  final String value;
  final String fieldKey;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final resolved = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<String>(
      key: ValueKey(fieldKey),
      initialValue: resolved,
      items: options
          .map((option) =>
              DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: enabled
          ? (value) {
              if (value != null) onChanged(value);
            }
          : null,
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      style: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
    );
  }
}

class _DeleteCell extends StatelessWidget {
  const _DeleteCell({required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
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
        id: data['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
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
