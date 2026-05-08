// ignore_for_file: unused_element

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/models/project_data_model.dart';
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

class DevelopmentSetUpScreen extends StatefulWidget {
  const DevelopmentSetUpScreen({super.key});

  @override
  State<DevelopmentSetUpScreen> createState() => _DevelopmentSetUpScreenState();
}

class _DevelopmentSetUpScreenState extends State<DevelopmentSetUpScreen> {
  final TextEditingController _envSummaryController = TextEditingController();
  final TextEditingController _buildSummaryController = TextEditingController();
  final TextEditingController _toolingSummaryController =
      TextEditingController();

  final List<_SetupChecklistItem> _envChecklist = [];
  final List<_SetupChecklistItem> _buildChecklist = [];
  final List<_SetupChecklistItem> _toolingChecklist = [];

  final _Debouncer _saveDebounce = _Debouncer();

  bool _isLoading = false;
  bool _suspendSave = false;
  bool _registersExpanded = false;
  int _architectureNodeCount = 0;

  String _envStatus = 'Not started';
  String _buildStatus = 'Not started';
  String _toolingStatus = 'Not started';

  final List<String> _sectionStatusOptions = const [
    'Not started',
    'In progress',
    'At risk',
    'Ready'
  ];
  final List<String> _itemStatusOptions = const [
    'Not started',
    'In progress',
    'Blocked',
    'Done'
  ];

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
    _saveDebounce.dispose();
    super.dispose();
  }

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

  List<_SetupChecklistItem> _defaultEnvChecklist(ProjectDataModel projectData) {
    final owners = _ownerOptions(projectData);
    final hasTechContext = projectData.technologyInventory.isNotEmpty;
    final hasStakeholders = projectData.stakeholderEntries.isNotEmpty;
    return [
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-env-dev',
        title: 'Provision Dev workspace on AWS Server',
        owner: owners.first,
        targetDate: _nextDateLabel(2),
        status: hasTechContext ? 'Done' : 'In progress',
        notes: 'Access URL and seed credentials for the core delivery team.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-env-stage',
        title: 'Prepare staging handoff environment',
        owner: owners.length > 1 ? owners[1] : owners.first,
        targetDate: _nextDateLabel(4),
        status: projectData.designDeliverablesData.register.isNotEmpty
            ? 'In progress'
            : 'Not started',
        notes: 'Mirror integrations and configuration needed for smoke tests.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-env-site',
        title: 'Confirm physical site access, venue keys, and site fencing',
        owner: owners.length > 2 ? owners[2] : owners.first,
        targetDate: _nextDateLabel(5),
        status: hasStakeholders ? 'In progress' : 'Not started',
        notes:
            'Track physical access constraints alongside digital environments.',
      ),
    ];
  }

  List<_SetupChecklistItem> _defaultBuildChecklist(
      ProjectDataModel projectData) {
    final owners = _ownerOptions(projectData);
    return [
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-build-build',
        title: 'Configure build validation and artifact packaging',
        owner: owners.first,
        targetDate: _nextDateLabel(3),
        status: _architectureNodeCount > 0 ? 'In progress' : 'Not started',
        notes:
            'Ensure generated artifacts are consistent with design deliverables.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-build-test',
        title: 'Prepare smoke tests and mock scenario validation',
        owner: owners.length > 1 ? owners[1] : owners.first,
        targetDate: _nextDateLabel(4),
        status: projectData.planningRequirementItems.isNotEmpty
            ? 'In progress'
            : 'Not started',
        notes: 'Cover API endpoint fixtures and venue readiness scenarios.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-build-deploy',
        title: 'Define deploy promotion and rollback checkpoints',
        owner: owners.length > 2 ? owners[2] : owners.first,
        targetDate: _nextDateLabel(6),
        status: 'Not started',
        notes: 'Include approvals for both digital and physical releases.',
      ),
    ];
  }

  List<_SetupChecklistItem> _defaultToolingChecklist(
      ProjectDataModel projectData) {
    final owners = _ownerOptions(projectData);
    return [
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-tool-ide',
        title: 'IDE and Git Repo access',
        owner: owners.first,
        targetDate: _nextDateLabel(1),
        status: 'Done',
        notes:
            'Developer workspace access and repository permissions verified.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-tool-ci',
        title: 'Automation runner and package signing',
        owner: owners.length > 1 ? owners[1] : owners.first,
        targetDate: _nextDateLabel(3),
        status: 'In progress',
        notes: 'CI tokens, package registry, and deployment secrets staged.',
      ),
      _SetupChecklistItem(
        id: '${DateTime.now().microsecondsSinceEpoch}-tool-crane',
        title: 'Crane and site rigging availability',
        owner: owners.length > 2 ? owners[2] : owners.first,
        targetDate: _nextDateLabel(5),
        status: 'Not started',
        notes:
            'Physical tooling readiness tracked with the same governance standard.',
      ),
    ];
  }

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
    if (_envSummaryController.text.trim().isEmpty) {
      _envSummaryController.text =
          'Provision dev and staging access for ${_defaultProjectLabel(projectData)} and track physical site readiness in the same ledger.';
      changed = true;
    }
    if (_buildSummaryController.text.trim().isEmpty) {
      _buildSummaryController.text =
          'Prepare build, test, and deploy controls so the team can validate both software changes and site-facing readiness checks.';
      changed = true;
    }
    if (_toolingSummaryController.text.trim().isEmpty) {
      _toolingSummaryController.text =
          'Verify licensing, ownership, and operating readiness for software tooling and physical equipment.';
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

    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scheduleSave();
      });
    }
  }

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
      envSummary: _envSummaryController.text,
      buildSummary: _buildSummaryController.text,
      toolingSummary: _toolingSummaryController.text,
      envChecklist: _envChecklist,
      buildChecklist: _buildChecklist,
      toolingChecklist: _toolingChecklist,
      architectureNodeCount: _architectureNodeCount,
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
                  _buildReadinessHubHeader(
                    isMobile: isMobile,
                    projectData: projectData,
                    snapshot: snapshot,
                  ),
                  const SizedBox(height: 24),
                  _buildTopSection(snapshot, isMobile),
                  const SizedBox(height: 20),
                  _buildMiddleSection(snapshot, isMobile),
                  const SizedBox(height: 20),
                  _buildOperationalReadinessGrid(snapshot),
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

  Widget _buildReadinessHubHeader({
    required bool isMobile,
    required ProjectDataModel projectData,
    required _DevelopmentSetupSnapshot snapshot,
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
                      'Readiness & Environment Preparation',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Development Set Up for ${_defaultProjectLabel(projectData)}. This hub prepares digital workspaces, site access, tooling, automation, and proof-of-connectivity so execution can start without avoidable blockers.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.84),
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
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
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
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
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
                  'Provisioned Spaces', '${snapshot.provisionedSpaces}/3'),
              _buildMetricPill('Licensed Tools', '${snapshot.activeLicenses}'),
              _buildMetricPill('Channels Ready', '${snapshot.invitedChannels}'),
              _buildMetricPill('AI Signals', '${snapshot.aiSignalCount}'),
              _buildMetricPill(
                  'Architecture Nodes', '${snapshot.architectureNodeCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(_DevelopmentSetupSnapshot snapshot, bool isMobile) {
    return Column(
      children: [
        _buildEnvironmentProvisioningCard(snapshot),
        const SizedBox(height: 20),
        _buildRepositoryCard(snapshot),
      ],
    );
  }

  Widget _buildMiddleSection(
      _DevelopmentSetupSnapshot snapshot, bool isMobile) {
    return Column(
      children: [
        _buildToolingCard(snapshot),
        const SizedBox(height: 20),
        _buildPipelineCard(snapshot),
      ],
    );
  }

  Widget _buildOperationalReadinessGrid(_DevelopmentSetupSnapshot snapshot) {
    return Column(
      children: [
        _buildTestDataCard(snapshot),
        const SizedBox(height: 20),
        _buildChannelsCard(snapshot),
        const SizedBox(height: 20),
        _buildSecurityCard(snapshot),
      ],
    );
  }

  Widget _buildSmokeTestSection(_DevelopmentSetupSnapshot snapshot) {
    final resultColor = snapshot.smokePassed
        ? AppSemanticColors.success
        : const Color(0xFFDC2626);
    return _buildDashboardPanel(
      title: 'Hello World / Proof of Connectivity',
      subtitle:
          'Smoke-test status for basic workspace access and change movement before execution starts.',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: resultColor.withValues(alpha: 0.22)),
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
                        snapshot.smokePassed ? 'PASS' : 'FAIL',
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
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentProvisioningCard(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Environment & Workspace Provisioning',
      subtitle:
          'Prepare Dev, Staging, and Physical Site spaces with clear status and access references.',
      icon: Icons.grid_view_rounded,
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
              final columns = constraints.maxWidth >= 620 ? 3 : 1;
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
                        child: Container(
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
                                  Icon(environment.icon,
                                      color: const Color(0xFF0F172A), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      environment.title,
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
                              _buildStatusTag(
                                environment.status,
                                environment.status == 'Provisioned'
                                    ? AppSemanticColors.success
                                    : const Color(0xFFF59E0B),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                environment.note,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 14),
                              InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showAccessReference(
                                  environment.accessReference,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.link_outlined,
                                          size: 16, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          environment.accessLabel,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12.5,
                                            color: Color(0xFF2563EB),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
            label: 'Provisioning notes',
            controller: _envSummaryController,
            hintText:
                'Capture access URLs, site locations, provisioning dependencies, and readiness notes.',
          ),
        ],
      ),
    );
  }

  Widget _buildRepositoryCard(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Repository & Asset Structure',
      subtitle:
          'Visualize the repo shape, branching strategy, and access control around design assets.',
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

  Widget _buildToolingCard(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Tooling & Licensing Verification',
      subtitle:
          'Verify licenses and assigned users for software tools and physical equipment.',
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
            hintText:
                'Capture licensing caveats, provisioning blockers, and support contacts.',
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineCard(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'CI/CD & Automation Pipeline',
      subtitle:
          'Build, Test, and Deploy flow with readiness indicators for each node.',
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
                Expanded(
                    child: _buildPipelineStage(snapshot.pipelineStages[i])),
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

  Widget _buildTestDataCard(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Test Data & Mock Scenarios',
      subtitle:
          'Form-style view of seed data and scenario sources for execution readiness.',
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

  Widget _buildChannelsCard(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Communication & Collaboration Channels',
      subtitle:
          'Digital and field coordination channels with invite status and platform context.',
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
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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

  Widget _buildSecurityCard(_DevelopmentSetupSnapshot snapshot) {
    return _buildDashboardPanel(
      title: 'Security & Access Baseline',
      subtitle:
          'Shield and lock checks for digital access controls and site safeguards.',
      icon: Icons.shield_outlined,
      child: Column(
        children: snapshot.securityMeasures
            .map(
              (measure) => Container(
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
            )
            .toList(),
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

  Widget _buildMetricPill(String label, String value) {
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

  Widget _buildDarkBadge({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
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
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.22)),
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

  Widget _buildTag(
      {required String label,
      required Color background,
      required Color foreground}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                      onChanged: (value) =>
                          onUpdateItem(item.copyWith(title: value)),
                    ),
                    _TextCell(
                      value: item.owner,
                      fieldKey: '${item.id}_owner',
                      hintText: 'Owner',
                      onChanged: (value) =>
                          onUpdateItem(item.copyWith(owner: value)),
                    ),
                    _DateCell(
                      value: item.targetDate,
                      fieldKey: '${item.id}_date',
                      hintText: 'YYYY-MM-DD',
                      onChanged: (value) =>
                          onUpdateItem(item.copyWith(targetDate: value)),
                    ),
                    _DropdownCell(
                      value: item.status,
                      fieldKey: '${item.id}_status',
                      options: _itemStatusOptions,
                      onChanged: (value) =>
                          onUpdateItem(item.copyWith(status: value)),
                    ),
                    _TextCell(
                      value: item.notes,
                      fieldKey: '${item.id}_notes',
                      hintText: 'Notes',
                      onChanged: (value) =>
                          onUpdateItem(item.copyWith(notes: value)),
                    ),
                    _DeleteCell(
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
    required String envSummary,
    required String buildSummary,
    required String toolingSummary,
    required List<_SetupChecklistItem> envChecklist,
    required List<_SetupChecklistItem> buildChecklist,
    required List<_SetupChecklistItem> toolingChecklist,
    required int architectureNodeCount,
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
    ];

    final deliverableNames = projectData.designDeliverablesData.register
        .map((item) => item.name.trim())
        .where((name) => name.isNotEmpty)
        .take(2)
        .toList();
    final repoNodes = [
      _RepoNode(depth: 0, label: '$slug/', meta: 'root', isFolder: true),
      const _RepoNode(depth: 1, label: 'apps/', meta: '', isFolder: true),
      const _RepoNode(
          depth: 2,
          label: 'design-ui/',
          meta: 'Figma + components',
          isFolder: true),
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
      _RepoNode(
        depth: 1,
        label: 'README-setup.md',
        meta: deliverableNames.isNotEmpty
            ? deliverableNames.join(' | ')
            : 'workspace guide',
        isFolder: false,
      ),
    ];

    final branchingStrategy = buildChecklist.any((item) =>
            '${item.title} ${item.notes}'.toLowerCase().contains('release') ||
            '${item.title} ${item.notes}'.toLowerCase().contains('hotfix'))
        ? 'GitFlow'
        : 'Trunk + release branches';

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
      return projectData.planningRequirementItems.isNotEmpty
          ? 'Pending'
          : 'Pending';
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
        status: projectData.stakeholderEntries.isNotEmpty ? 'Seeded' : 'Empty',
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
        inviteStatus: projectData.designDeliverablesData.register.isNotEmpty
            ? 'Invited'
            : 'Pending Invite',
      ),
      _ChannelCard(
        name: 'Site-Safety',
        platform: 'Radio',
        icon: Icons.settings_input_antenna,
        inviteStatus:
            hasKeywords(envChecklist, const ['site', 'venue', 'safety']) ||
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
      color: displayText.isEmpty
          ? const Color(0xFF9CA3AF)
          : const Color(0xFF111827),
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
