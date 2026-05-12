import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/screens/specialized_design_screen.dart';
import 'package:ndu_project/screens/staff_team_screen.dart';
import 'package:ndu_project/services/activity_log_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/models/user_role.dart';
import 'package:ndu_project/providers/user_role_provider.dart';
import 'package:ndu_project/services/design_phase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// firebase_auth removed - unused

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Design Deliverables — World-Class CRUD Page
// Aligned with PMI PMBOK 7th Ed., ISO/IEC/IEEE 15288:2023, PRINCE2 2017,
// SAFe 6.0, and AIA Document E202 design deliverable conventions.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class DesignDeliverablesScreen extends StatefulWidget {
  const DesignDeliverablesScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DesignDeliverablesScreen()),
    );
  }

  @override
  State<DesignDeliverablesScreen> createState() =>
      _DesignDeliverablesScreenState();
}

class _DesignDeliverablesScreenState extends State<DesignDeliverablesScreen> {
  DesignDeliverablesData _data = DesignDeliverablesData();
  bool _loading = false;
  String? _error;
  final _saveDebouncer = _Debouncer();
  bool _saving = false;

  // Filter state
  final Set<String> _selectedFilters = {'All deliverables'};

  // CRUD state for acceptance evidence
  List<_AcceptanceEvidenceRow> _acceptanceEvidence = [];
  // CRUD state for handoff governance
  List<_HandoffGovernanceRow> _handoffGovernance = [];
  // CRUD state for approval gates
  List<_ApprovalGateRow> _approvalGates = [];

  // Firestore tracking doc
  // _trackedProjectId removed - unused

  String get _currentProjectId {
    return ProjectDataHelper.getData(context).projectId ?? '';
  }

  bool get _canCreateDeliverables {
    final role = context.roleProvider;
    final projectId = _currentProjectId;
    return role.hasPermission(Permission.createContent) ||
        (projectId.isNotEmpty && role.canEditProject(projectId));
  }

  bool get _canEditDeliverables {
    final role = context.roleProvider;
    final projectId = _currentProjectId;
    return role.hasPermission(Permission.editAnyContent) ||
        (projectId.isNotEmpty && role.canEditProject(projectId));
  }

  bool get _canDeleteDeliverables {
    final role = context.roleProvider;
    final projectId = _currentProjectId;
    return role.hasPermission(Permission.deleteAnyContent) ||
        (projectId.isNotEmpty && role.canDeleteProject(projectId));
  }

  bool get _canUseDeliverablesAi {
    return context.roleProvider.hasPermission(Permission.useAiGeneration) &&
        (_canCreateDeliverables || _canEditDeliverables);
  }

  void _showPermissionSnackBar(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You do not have permission to $action.'),
        backgroundColor: const Color(0xFFB91C1C),
      ),
    );
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _dedupeTextList(Iterable<String> values) {
    final seen = <String>{};
    final deduped = <String>[];
    for (final value in values) {
      final normalized = _normalize(value);
      if (normalized.isEmpty) continue;
      if (seen.add(normalized)) deduped.add(value.trim());
    }
    return deduped;
  }

  List<DesignDeliverablePipelineItem> _dedupePipeline(
      Iterable<DesignDeliverablePipelineItem> items) {
    final seen = <String>{};
    final deduped = <DesignDeliverablePipelineItem>[];
    for (final item in items) {
      final key = '${_normalize(item.label)}|${_normalize(item.status)}';
      if (key == '|') continue;
      if (seen.add(key)) deduped.add(item);
    }
    return deduped;
  }

  List<DesignDeliverableRegisterItem> _dedupeRegister(
      Iterable<DesignDeliverableRegisterItem> items) {
    final seen = <String>{};
    final deduped = <DesignDeliverableRegisterItem>[];
    for (final item in items) {
      final key =
          '${_normalize(item.name)}|${_normalize(item.owner)}|${_normalize(item.status)}|${_normalize(item.due)}|${_normalize(item.risk)}';
      if (key == '||||') continue;
      if (seen.add(key)) deduped.add(item);
    }
    return deduped;
  }

  DesignDeliverablesData _dedupeData(DesignDeliverablesData data) {
    return data.copyWith(
      pipeline: _dedupePipeline(data.pipeline),
      approvals: _dedupeTextList(data.approvals),
      register: _dedupeRegister(data.register),
      dependencies: _dedupeTextList(data.dependencies),
      handoffChecklist: _dedupeTextList(data.handoffChecklist),
    );
  }

  @override
  void initState() {
    super.initState();
    _acceptanceEvidence = _defaultAcceptanceEvidence();
    _handoffGovernance = _defaultHandoffGovernance();
    _approvalGates = _defaultApprovalGates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> _trackingDoc(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('design_phase_sections')
        .doc('deliverables_tracking');
  }

  Future<void> _loadData() async {
    final projectData = ProjectDataHelper.getData(context);
    final projectId = projectData.projectId;
    if (projectId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load main deliverables data
      var loaded =
          await DesignPhaseService.instance.loadDesignDeliverables(projectId);

      if (!mounted) return;

      if (loaded == null) {
        final existing = projectData.designDeliverablesData;
        if (!existing.isEmpty) {
          loaded = existing;
          if (_canCreateDeliverables || _canEditDeliverables) {
            _updateData(loaded, saveImmediate: true);
          } else {
            _applyData(loaded);
          }
        }
      }

      if (loaded == null || loaded.isEmpty) {
        await _generateFromAi(silentFallback: true);
      } else {
        _applyData(loaded);
        setState(() => _loading = false);
      }

      // Load tracking data (acceptance evidence, handoff governance, approval gates)
      await _loadTrackingData(projectId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load data: $e';
        });
      }
    }
  }

  Future<void> _loadTrackingData(String projectId) async {
    try {
      final doc = await _trackingDoc(projectId).get();
      final data = doc.data() ?? {};
      if (!mounted) return;

      final aeData = data['acceptanceEvidence'] as List?;
      final hgData = data['handoffGovernance'] as List?;
      final agData = data['approvalGates'] as List?;

      setState(() {
        if (aeData != null && aeData.isNotEmpty) {
          _acceptanceEvidence = aeData
              .whereType<Map>()
              .map((e) =>
                  _AcceptanceEvidenceRow.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
        if (hgData != null && hgData.isNotEmpty) {
          _handoffGovernance = hgData
              .whereType<Map>()
              .map((e) =>
                  _HandoffGovernanceRow.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
        if (agData != null && agData.isNotEmpty) {
          _approvalGates = agData
              .whereType<Map>()
              .map(
                  (e) => _ApprovalGateRow.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
      });
    } catch (e) {
      debugPrint('Load tracking data error: $e');
    }
  }

  Future<void> _saveTrackingData() async {
    final projectId = _currentProjectId;
    if (projectId.isEmpty) return;
    try {
      await _trackingDoc(projectId).set({
        'acceptanceEvidence':
            _acceptanceEvidence.map((e) => e.toMap()).toList(),
        'handoffGovernance': _handoffGovernance.map((e) => e.toMap()).toList(),
        'approvalGates': _approvalGates.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Save tracking data error: $e');
    }
  }

  Future<void> _generateFromAi({bool silentFallback = false}) async {
    if (!_canUseDeliverablesAi) {
      final fallback = _defaultDesignDeliverablesData(
        ProjectDataHelper.getData(context),
      );
      _applyData(fallback);
      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
      if (!silentFallback) {
        _showPermissionSnackBar('generate design deliverables content');
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = ProjectDataHelper.getData(context);
      final contextText = ProjectDataHelper.buildFepContext(data,
          sectionLabel: 'Design Deliverables');
      final generated = await OpenAiServiceSecure()
          .generateDesignDeliverables(context: contextText);

      if (!mounted) return;

      _updateData(generated, saveImmediate: true);
      ProjectDataHelper.getProvider(context).updateField(
        (current) => current.copyWith(designDeliverablesData: generated),
      );

      await _logActivity(
        'Generated Design Deliverables with AI',
        details: {
          'pipelineCount': generated.pipeline.length,
          'registerCount': generated.register.length,
          'approvalCount': generated.approvals.length,
        },
      );

      setState(() {
        _applyData(generated);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to generate content. Please try again later.';
        _data = DesignDeliverablesData();
      });
    }
  }

  void _updateData(DesignDeliverablesData data, {bool saveImmediate = false}) {
    if (!_canCreateDeliverables && !_canEditDeliverables) {
      _showPermissionSnackBar('modify design deliverables');
      return;
    }
    final deduped = _dedupeData(data);
    final computed = _computeMetrics(deduped.register);
    final nextData = deduped.copyWith(metrics: computed);
    setState(() => _data = nextData);

    ProjectDataHelper.getProvider(context).updateField(
      (current) => current.copyWith(designDeliverablesData: nextData),
    );

    if (saveImmediate) {
      _saveNow();
    } else {
      _scheduleSave();
    }
  }

  void _applyData(DesignDeliverablesData data) {
    final deduped = _dedupeData(data);
    final computed = _computeMetrics(deduped.register);
    setState(() => _data = deduped.copyWith(metrics: computed));
  }

  DesignDeliverablesMetrics _computeMetrics(
      List<DesignDeliverableRegisterItem> rows) {
    int active = 0;
    int inReview = 0;
    int approved = 0;
    int atRisk = 0;
    for (final row in rows) {
      final status = row.status.trim().toLowerCase();
      final risk = row.risk.trim().toLowerCase();
      if (status == 'in review') {
        inReview++;
      } else if (status == 'approved') {
        approved++;
      } else if (status == 'in progress' || status == 'pending') {
        active++;
      }
      if (risk == 'high') {
        atRisk++;
      }
    }
    return DesignDeliverablesMetrics(
      active: active,
      inReview: inReview,
      approved: approved,
      atRisk: atRisk,
    );
  }

  DesignDeliverablesData _defaultDesignDeliverablesData(
    ProjectDataModel projectData,
  ) {
    final projectLabel = projectData.projectName.trim().isNotEmpty
        ? projectData.projectName.trim()
        : 'Current Design Package';
    final owner = projectData.teamMembers.isNotEmpty
        ? projectData.teamMembers.first.name.trim().isNotEmpty
            ? projectData.teamMembers.first.name.trim()
            : projectData.teamMembers.first.role.trim()
        : 'Design Lead';

    final register = [
      DesignDeliverableRegisterItem(
        name: 'DD-001 Requirements Traceability & Acceptance Matrix',
        owner: owner.isEmpty ? 'Business Analyst' : owner,
        status: 'In progress',
        due: 'Gate 1',
        risk: 'Medium',
      ),
      const DesignDeliverableRegisterItem(
        name: 'DD-002 Architecture Decision Pack & Solution Intent',
        owner: 'Architecture',
        status: 'In review',
        due: 'Gate 1',
        risk: 'Medium',
      ),
      const DesignDeliverableRegisterItem(
        name: 'DD-003 UX Flow, Wireframe, Prototype & Accessibility Evidence',
        owner: 'UX Lead',
        status: 'Pending',
        due: 'Sprint / Phase Review',
        risk: 'Low',
      ),
      const DesignDeliverableRegisterItem(
        name: 'DD-004 Interface, Data, Security & NFR Design Specification',
        owner: 'Engineering',
        status: 'Pending',
        due: 'Build Readiness',
        risk: 'High',
      ),
      const DesignDeliverableRegisterItem(
        name: 'DD-005 Release Handoff, Runbook & Operational Acceptance Pack',
        owner: 'DevOps / Ops',
        status: 'Pending',
        due: 'Transition Gate',
        risk: 'Medium',
      ),
    ];

    return DesignDeliverablesData(
      pipeline: const [
        DesignDeliverablePipelineItem(
          label: 'Scope baseline and design inputs verified',
          status: 'In progress',
        ),
        DesignDeliverablePipelineItem(
          label: 'Design package authored with traceable acceptance criteria',
          status: 'Pending',
        ),
        DesignDeliverablePipelineItem(
          label: 'Peer review, quality review, and stakeholder approval',
          status: 'Pending',
        ),
        DesignDeliverablePipelineItem(
          label: 'Handoff package baselined for build or next increment',
          status: 'Pending',
        ),
      ],
      approvals: [
        'Waterfall gate: sponsor and design authority approve verified deliverables before build authorization.',
        'Hybrid gate: phase baseline is approved while iterative design slices remain traceable to release increments.',
        'Agile gate: each design increment satisfies Definition of Done, acceptance criteria, and sprint review evidence.',
        'Scaled agile gate: solution intent, NFRs, dependencies, and enabler work are synchronized across teams.',
      ],
      register: register,
      dependencies: [
        'Requirements baseline, backlog priorities, and acceptance criteria must be current for $projectLabel.',
        'Architecture decisions, interface contracts, data ownership, and NFR budgets must be confirmed.',
        'Reviewers, approvers, design system assets, test evidence, and operational owners must be assigned.',
      ],
      handoffChecklist: const [
        'Deliverable is unique, versioned, traceable, and linked to source requirement or backlog item.',
        'Acceptance criteria, verification method, reviewer, approver, and evidence location are recorded.',
        'Quality, accessibility, security, data, integration, and operational impacts have been reviewed.',
        'Open issues, waivers, assumptions, and change-control decisions are captured before handoff.',
      ],
    );
  }

  void _scheduleSave() {
    _saveDebouncer.run(() async {
      if (!mounted) return;
      await _saveNow();
    });
  }

  Future<void> _saveNow() async {
    if (_saving) return;
    if (!_canCreateDeliverables && !_canEditDeliverables) return;
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null) return;

    setState(() => _saving = true);

    try {
      await DesignPhaseService.instance
          .saveDesignDeliverables(projectId, _data);
      await _logActivity(
        'Updated Design Deliverables data',
        details: {
          'pipelineCount': _data.pipeline.length,
          'registerCount': _data.register.length,
          'dependencyCount': _data.dependencies.length,
        },
      );

      if (!mounted) return;
      setState(() {
        _saving = false;
        // saved successfully
      });
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save Design Deliverables right now.'),
          ),
        );
      }
    }
  }

  Future<void> _logActivity(
    String action, {
    Map<String, dynamic>? details,
  }) async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) return;
    await ActivityLogService.instance.logActivity(
      projectId: projectId,
      phase: 'Design Phase',
      page: 'Design Deliverables',
      action: action,
      details: details,
    );
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  // ── Default data generators ──────────────────────────────────────────────

  List<_AcceptanceEvidenceRow> _defaultAcceptanceEvidence() {
    return [
      _AcceptanceEvidenceRow(
        id: _newId(),
        evidenceArea: 'Scope And Traceability',
        whatMustBeCaptured:
            'Requirement, backlog item, business rule, NFR, interface, and out-of-scope link for every material deliverable.',
        verificationMethod: 'Traceability review and gap scan.',
        approvalOwner: 'BA / Product Owner',
        riskIfMissing:
            'Unclear scope, acceptance disputes, rework, and unplanned change requests.',
      ),
      _AcceptanceEvidenceRow(
        id: _newId(),
        evidenceArea: 'Acceptance Criteria',
        whatMustBeCaptured:
            'Specific pass/fail conditions, quality thresholds, accessibility expectations, and stakeholder acceptance rules.',
        verificationMethod:
            'Inspection, walkthrough, test mapping, or acceptance-test review.',
        approvalOwner: 'Sponsor / Product Owner',
        riskIfMissing:
            'Subjective approval decisions and late disagreement on what Done means.',
      ),
      _AcceptanceEvidenceRow(
        id: _newId(),
        evidenceArea: 'Version And Configuration',
        whatMustBeCaptured:
            'Version, source link, file location, owner, baseline date, change reason, and superseded artefact history.',
        verificationMethod: 'Configuration audit and repository review.',
        approvalOwner: 'Design Manager',
        riskIfMissing:
            'Wrong version used for build, procurement, vendor handoff, or approval.',
      ),
      _AcceptanceEvidenceRow(
        id: _newId(),
        evidenceArea: 'Quality And Compliance',
        whatMustBeCaptured:
            'Design standards, accessibility, security, privacy, safety, regulatory, brand, and design-system conformance evidence.',
        verificationMethod:
            'Quality review, standards checklist, and exception/waiver review.',
        approvalOwner: 'Quality / Compliance',
        riskIfMissing: 'Non-compliance, defects, blocked approvals, and operational risk.',
      ),
      _AcceptanceEvidenceRow(
        id: _newId(),
        evidenceArea: 'Operational Handoff',
        whatMustBeCaptured:
            'Build notes, runbook impact, support owner, training need, unresolved issues, assumptions, and transition sign-off.',
        verificationMethod: 'Handoff review and operational acceptance test.',
        approvalOwner: 'Operations Lead',
        riskIfMissing:
            'Deliverable cannot be built, supported, maintained, or transitioned cleanly.',
      ),
    ];
  }

  List<_HandoffGovernanceRow> _defaultHandoffGovernance() {
    return [
      _HandoffGovernanceRow(
        id: _newId(),
        control: 'Definition Of Done',
        industryStandardPractice:
            'Design artefacts are reviewed, versioned, accessible, traceable, testable, and accepted against explicit quality criteria.',
        waterfallEvidence: 'Validated deliverable package and formal sign-off.',
        agileHybridEvidence:
            'DoD checklist, story acceptance, and sprint review evidence.',
        decision: 'Required',
      ),
      _HandoffGovernanceRow(
        id: _newId(),
        control: 'Solution Intent',
        industryStandardPractice:
            'Current and intended behaviour, design decisions, standards, models, NFRs, and tests are stored in a shared knowledge repository.',
        waterfallEvidence:
            'Design baseline and controlled specification set.',
        agileHybridEvidence:
            'Solution intent, ADRs, enabler backlog, and system demo evidence.',
        decision: 'Required',
      ),
      _HandoffGovernanceRow(
        id: _newId(),
        control: 'Change Control',
        industryStandardPractice:
            'Material deliverable changes have impact analysis across scope, schedule, cost, risk, architecture, procurement, and operations.',
        waterfallEvidence: 'Change request and CCB decision.',
        agileHybridEvidence:
            'Backlog change, dependency board update, and release impact note.',
        decision: 'Required',
      ),
      _HandoffGovernanceRow(
        id: _newId(),
        control: 'Handoff Readiness',
        industryStandardPractice:
            'Engineering, vendors, QA, security, and operations can consume the artefacts without undocumented assumptions.',
        waterfallEvidence:
            'Transition checklist and receiving-team acceptance.',
        agileHybridEvidence:
            'Build-readiness review, support story, and implementation notes.',
        decision: 'Conditional',
      ),
    ];
  }

  List<_ApprovalGateRow> _defaultApprovalGates() {
    return [
      _ApprovalGateRow(
        id: _newId(),
        gate: 'Design Authority Review',
        description:
            'Verify design intent, traceability to requirements, architectural soundness, and NFR compliance',
        approver: 'Design Authority',
        priority: 'Critical',
        status: 'In Review',
        targetDate: 'TBD',
      ),
      _ApprovalGateRow(
        id: _newId(),
        gate: 'Stakeholder Acceptance',
        description:
            'Confirm deliverables meet acceptance criteria, business rules, and stakeholder expectations',
        approver: 'Project Sponsor',
        priority: 'Critical',
        status: 'Pending',
        targetDate: 'TBD',
      ),
      _ApprovalGateRow(
        id: _newId(),
        gate: 'Quality & Compliance Sign-off',
        description:
            'Validate quality standards, accessibility, security, privacy, and regulatory conformance',
        approver: 'Quality Manager',
        priority: 'High',
        status: 'Pending',
        targetDate: 'TBD',
      ),
      _ApprovalGateRow(
        id: _newId(),
        gate: 'Technical Feasibility Gate',
        description:
            'Confirm design is buildable, testable, supportable, and operationally viable within constraints',
        approver: 'Technical Lead',
        priority: 'High',
        status: 'Not Started',
        targetDate: 'TBD',
      ),
      _ApprovalGateRow(
        id: _newId(),
        gate: 'Configuration & Version Control',
        description:
            'Verify all artefacts are versioned, baselined, and stored in controlled repositories with audit trail',
        approver: 'Design Manager',
        priority: 'High',
        status: 'Not Started',
        targetDate: 'TBD',
      ),
      _ApprovalGateRow(
        id: _newId(),
        gate: 'Executive Authorization',
        description:
            'Final approval from executive sponsor for build authorization and resource commitment',
        approver: 'Executive Sponsor',
        priority: 'Medium',
        status: 'Not Started',
        targetDate: 'TBD',
      ),
    ];
  }

  // ── Filter logic ──────────────────────────────────────────────────────

  List<DesignDeliverableRegisterItem> get _filteredRegister {
    if (_selectedFilters.contains('All deliverables')) return _data.register;
    return _data.register.where((r) {
      final status = r.status.trim().toLowerCase();
      final risk = r.risk.trim().toLowerCase();
      if (_selectedFilters.contains('In progress') &&
          (status == 'in progress' || status == 'pending')) {
        return true;
      }
      if (_selectedFilters.contains('In review') && status == 'in review') {
        return true;
      }
      if (_selectedFilters.contains('Approved') && status == 'approved') {
        return true;
      }
      if (_selectedFilters.contains('At risk') && risk == 'high') {
        return true;
      }
      return false;
    }).toList();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // BUILD
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @override
  Widget build(BuildContext context) {
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Design Deliverables',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(positioned: false),
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Design Deliverables',
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
                  if (_loading) const LinearProgressIndicator(minHeight: 2),
                  if (_loading) const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 20),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildFrameworkGuide(),
                  const SizedBox(height: 24),
                  _buildDeliverableRegister(),
                  const SizedBox(height: 20),
                  _buildAcceptanceEvidencePanel(),
                  const SizedBox(height: 20),
                  _buildHandoffGovernancePanel(),
                  const SizedBox(height: 20),
                  _buildApprovalGatesPanel(),
                  const SizedBox(height: 20),
                  _buildPipelinePanel(),
                  const SizedBox(height: 20),
                  _buildDependenciesPanel(),
                  const SizedBox(height: 24),
                  LaunchPhaseNavigation(
                    backLabel: 'Back: Specialized Design',
                    nextLabel: 'Next: Staff Team',
                    onBack: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const SpecializedDesignScreen()),
                    ),
                    onNext: () => StaffTeamScreen.open(context),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HEADER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'DELIVERABLE CONTROL',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1040;
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Design Deliverables',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
                SizedBox(height: 6),
                Text(
                  'Track deliverable authoring, acceptance evidence, approval gates, and handoff readiness across the design lifecycle. '
                  'Aligned with PMI PMBOK 7th Ed. Deliverables and Quality processes, ISO/IEC/IEEE 15288:2023 design output controls, '
                  'and PRINCE2 Managing Product Delivery. This register ensures every design artefact is traceable, verified, '
                  'and approved before build authorization.',
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
        _actionButton(Icons.add, 'Add deliverable',
            onPressed: () => _showAddDeliverableDialog()),
        _actionButton(Icons.description_outlined, 'Export register',
            onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Export register is queued. Use the register table while export tools are finalized.')),
          );
        }),
        _primaryButton('Start review'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label,
      {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _primaryButton(String label) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _selectedFilters
            ..clear()
            ..add('In review');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Review started. Filter set to deliverables in review.')),
        );
      },
      icon: const Icon(Icons.play_arrow, size: 18),
      label: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FILTER CHIPS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildFilterChips() {
    const filters = [
      'All deliverables',
      'In progress',
      'In review',
      'Approved',
      'At risk'
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
                if (filter == 'All deliverables') {
                  _selectedFilters
                    ..clear()
                    ..add(filter);
                } else {
                  _selectedFilters
                    ..remove('All deliverables')
                    ..add(filter);
                }
              } else {
                _selectedFilters.remove(filter);
                if (_selectedFilters.isEmpty) {
                  _selectedFilters.add('All deliverables');
                }
              }
            });
          },
        );
      }).toList(),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // STATS ROW
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildStatsRow() {
    final m = _data.metrics;
    final total = _data.register.length;
    final stats = [
      _StatCardData(
          'Active Deliverables', '${m.active}', '$total total', const Color(0xFF0EA5E9)),
      _StatCardData(
          'Total Items', '$total', 'All statuses', const Color(0xFF10B981)),
      _StatCardData(
          'In Review', '${m.inReview}', 'Awaiting approval', const Color(0xFFF97316)),
      _StatCardData(
          'At Risk', '${m.atRisk}',
          m.atRisk > 0 ? 'Require attention' : 'All stable', const Color(0xFF6366F1)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          return Column(
            children: [
              for (int i = 0; i < stats.length; i++) ...[
                SizedBox(
                    width: double.infinity, child: _buildStatCard(stats[i])),
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
      },
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FRAMEWORK GUIDE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildFrameworkGuide() {
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
            'Deliverable control framework',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Grounded in PMI PMBOK 7th Ed. Deliverables (4.3) and Quality (4.4) performance domains, '
            'ISO/IEC/IEEE 15288:2023 design output verification, and PRINCE2 Managing Product Delivery. '
            'Effective deliverable tracking ensures that scope, acceptance, version control, and handoff '
            'evidence remain visible and actionable throughout the design lifecycle.',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
                height: 1.5),
          ),
          const SizedBox(height: 18),
          Column(
            children: [
              _buildGuideCard(
                Icons.account_tree_outlined,
                'Deliverable Lifecycle',
                'Draft \u2192 Review \u2192 Approved \u2192 Baselined \u2192 Handed Off. '
                'Track every deliverable from authoring through acceptance with version control at each transition. '
                'Set review milestones at 90/60/30-day intervals aligned to phase gates.',
                const Color(0xFF2563EB),
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                Icons.fact_check_outlined,
                'Acceptance & Verification',
                'Every deliverable needs explicit acceptance criteria, verification method, and evidence of compliance '
                'before approval is granted. Map each artefact to its source requirement and maintain a traceability '
                'matrix that survives design iterations.',
                const Color(0xFF10B981),
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                Icons.swap_horiz_outlined,
                'Handoff & Transition',
                'Deliverables must be build-ready, supportable, and consumable by receiving teams without '
                'undocumented assumptions or gaps. Use handoff checklists, build-readiness reviews, and operational '
                'acceptance tests to ensure clean transitions.',
                const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 12),
              _buildGuideCard(
                Icons.verified_user_outlined,
                'Quality & Compliance',
                'Design standards, accessibility, security, privacy, safety, and regulatory conformance must be '
                'evidenced and reviewed before handoff. Non-compliance at this stage propagates defects into build, '
                'test, and production environments at exponentially higher remediation cost.',
                const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(
      IconData icon, String title, String description, Color color) {
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DELIVERABLE REGISTER PANEL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildDeliverableRegister() {
    final filtered = _filteredRegister;
    return _PanelShell(
      title: 'Deliverable register',
      subtitle:
          'Track design artefacts, owners, status, and readiness gates',
      trailing: _actionButton(Icons.add, 'Add deliverable',
          onPressed: () => _showAddDeliverableDialog()),
      child: Column(
        children: [
          // Table header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('DELIVERABLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8))),
                SizedBox(width: 100, child: Text('OWNER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8), textAlign: TextAlign.center)),
                SizedBox(width: 100, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8), textAlign: TextAlign.center)),
                SizedBox(width: 100, child: Text('DUE/GATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8), textAlign: TextAlign.center)),
                SizedBox(width: 80, child: Text('RISK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8), textAlign: TextAlign.center)),
                SizedBox(width: 80, child: Text('', style: TextStyle(fontSize: 10))),
              ],
            ),
          ),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        color: Color(0xFF9CA3AF), size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'No deliverables found. Add deliverables to start tracking.',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(filtered.length, (index) {
              final row = filtered[index];
              final actualIndex = _data.register.indexOf(row);
              return _DeliverableRegisterRow(
                row: row,
                onEdit: () => _showEditDeliverableDialog(row, actualIndex),
                onDelete: () => _confirmDeleteDeliverable(actualIndex),
                showDivider: index != filtered.length - 1,
              );
            }),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ACCEPTANCE EVIDENCE PANEL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildAcceptanceEvidencePanel() {
    return _PanelShell(
      title: 'Acceptance evidence matrix',
      subtitle:
          'Standard for proving each deliverable is complete, reviewable, and ready for handoff',
      trailing: _actionButton(Icons.add, 'Add evidence',
          onPressed: () => _showAcceptanceEvidenceEditor()),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('EVIDENCE AREA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8))),
                Expanded(flex: 3, child: Text('WHAT MUST BE CAPTURED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8))),
                Expanded(flex: 2, child: Text('VERIFICATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8))),
                SizedBox(width: 110, child: Text('OWNER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8), textAlign: TextAlign.center)),
                SizedBox(width: 80, child: Text('', style: TextStyle(fontSize: 10))),
              ],
            ),
          ),
          if (_acceptanceEvidence.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No acceptance evidence rows defined.',
                  style: TextStyle(color: Color(0xFF6B7280))),
            )
          else
            ...List.generate(_acceptanceEvidence.length, (index) {
              final row = _acceptanceEvidence[index];
              return _AcceptanceEvidenceDisplayRow(
                row: row,
                onEdit: () =>
                    _showAcceptanceEvidenceEditor(entry: row, index: index),
                onDelete: () => _confirmDeleteAcceptanceEvidence(index),
                showDivider: index != _acceptanceEvidence.length - 1,
              );
            }),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // HANDOFF GOVERNANCE PANEL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildHandoffGovernancePanel() {
    return _PanelShell(
      title: 'Handoff governance',
      subtitle:
          'Controls that keep deliverables usable by engineering, vendors, approvers, and operations',
      trailing: _actionButton(Icons.add, 'Add control',
          onPressed: () => _showHandoffGovernanceEditor()),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('CONTROL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8))),
                Expanded(flex: 3, child: Text('INDUSTRY STANDARD PRACTICE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8))),
                Expanded(flex: 2, child: Text('WATERFALL EVIDENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8))),
                Expanded(flex: 2, child: Text('AGILE/HYBRID EVIDENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8))),
                SizedBox(width: 90, child: Text('DECISION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8), textAlign: TextAlign.center)),
                SizedBox(width: 80, child: Text('', style: TextStyle(fontSize: 10))),
              ],
            ),
          ),
          if (_handoffGovernance.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No handoff governance rows defined.',
                  style: TextStyle(color: Color(0xFF6B7280))),
            )
          else
            ...List.generate(_handoffGovernance.length, (index) {
              final row = _handoffGovernance[index];
              return _HandoffGovernanceDisplayRow(
                row: row,
                onEdit: () =>
                    _showHandoffGovernanceEditor(entry: row, index: index),
                onDelete: () => _confirmDeleteHandoffGovernance(index),
                showDivider: index != _handoffGovernance.length - 1,
              );
            }),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // APPROVAL GATES PANEL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildApprovalGatesPanel() {
    return _PanelShell(
      title: 'Approval gate readiness',
      subtitle:
          'Design approval gates aligned with PMI PMBOK Quality and PRINCE2 Controlling a Stage processes',
      trailing: _actionButton(Icons.add, 'Add gate',
          onPressed: () => _showApprovalGateEditor()),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('GATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8))),
                Expanded(flex: 3, child: Text('DESCRIPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8))),
                SizedBox(width: 120, child: Text('APPROVER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8), textAlign: TextAlign.center)),
                SizedBox(width: 90, child: Text('PRIORITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8), textAlign: TextAlign.center)),
                SizedBox(width: 100, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8), textAlign: TextAlign.center)),
                SizedBox(width: 80, child: Text('', style: TextStyle(fontSize: 10))),
              ],
            ),
          ),
          if (_approvalGates.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No approval gates defined.',
                  style: TextStyle(color: Color(0xFF6B7280))),
            )
          else
            ...List.generate(_approvalGates.length, (index) {
              final row = _approvalGates[index];
              return _ApprovalGateDisplayRow(
                row: row,
                onEdit: () =>
                    _showApprovalGateEditor(entry: row, index: index),
                onDelete: () => _confirmDeleteApprovalGate(index),
                showDivider: index != _approvalGates.length - 1,
              );
            }),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PIPELINE PANEL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildPipelinePanel() {
    return _PanelShell(
      title: 'Deliverable pipeline',
      subtitle:
          'Progress across design stages from scope verification through handoff',
      trailing: _actionButton(Icons.add, 'Add stage',
          onPressed: _showAddPipelineItemDialog),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
            child: const Row(
              children: [
                Expanded(flex: 5, child: Text('STAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8))),
                SizedBox(width: 120, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 0.8), textAlign: TextAlign.center)),
                SizedBox(width: 80, child: Text('', style: TextStyle(fontSize: 10))),
              ],
            ),
          ),
          if (_data.pipeline.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No pipeline stages defined.',
                  style: TextStyle(color: Color(0xFF6B7280))),
            )
          else
            ...List.generate(_data.pipeline.length, (index) {
              final item = _data.pipeline[index];
              return _PipelineDisplayRow(
                item: item,
                onEdit: () => _showEditPipelineDialog(item, index),
                onDelete: () {
                  final next = [..._data.pipeline]..removeAt(index);
                  _updateData(_data.copyWith(pipeline: next));
                },
                showDivider: index != _data.pipeline.length - 1,
              );
            }),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DEPENDENCIES PANEL
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Widget _buildDependenciesPanel() {
    return _PanelShell(
      title: 'Dependencies & prerequisites',
      subtitle: 'Items that must be resolved before deliverables can advance',
      trailing: _actionButton(Icons.add, 'Add dependency', onPressed: () {
        _updateData(
            _data.copyWith(dependencies: [..._data.dependencies, '']));
      }),
      child: Column(
        children: [
          if (_data.dependencies.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No dependencies captured yet.',
                  style: TextStyle(color: Color(0xFF6B7280))),
            )
          else
            ..._data.dependencies.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.circle,
                        size: 8, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('dep-${entry.key}'),
                        initialValue: entry.value,
                        enabled: _canEditDeliverables,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'Add dependency',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF374151)),
                        onChanged: (value) {
                          final next = [..._data.dependencies];
                          next[entry.key] = value;
                          _updateData(
                              _data.copyWith(dependencies: next));
                        },
                      ),
                    ),
                    if (_canDeleteDeliverables)
                      IconButton(
                        onPressed: () {
                          final next = [..._data.dependencies]
                            ..removeAt(entry.key);
                          _updateData(
                              _data.copyWith(dependencies: next));
                        },
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Color(0xFFEF4444)),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DIALOGS — Deliverable Register
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _showAddDeliverableDialog() {
    _showDeliverableDialog(null, -1);
  }

  void _showEditDeliverableDialog(
      DesignDeliverableRegisterItem row, int index) {
    _showDeliverableDialog(row, index);
  }

  void _showDeliverableDialog(
      DesignDeliverableRegisterItem? existing, int editIndex) {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final dueCtl = TextEditingController(text: existing?.due ?? '');
    String owner = existing?.owner ?? 'Design Lead';
    String status = existing?.status ?? 'In progress';
    String risk = existing?.risk ?? 'Medium';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: Text(editIndex >= 0 ? 'Edit Deliverable' : 'Add Deliverable'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtl,
                      decoration:
                          const InputDecoration(labelText: 'Deliverable name'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: owner,
                      items: const [
                        DropdownMenuItem(value: 'Design Lead', child: Text('Design Lead')),
                        DropdownMenuItem(value: 'Architecture', child: Text('Architecture')),
                        DropdownMenuItem(value: 'UX Lead', child: Text('UX Lead')),
                        DropdownMenuItem(value: 'Engineering', child: Text('Engineering')),
                        DropdownMenuItem(value: 'DevOps / Ops', child: Text('DevOps / Ops')),
                        DropdownMenuItem(value: 'Business Analyst', child: Text('Business Analyst')),
                      ],
                      onChanged: (v) => setModalState(() => owner = v ?? owner),
                      decoration: const InputDecoration(labelText: 'Owner'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(value: 'In progress', child: Text('In progress')),
                        DropdownMenuItem(value: 'In review', child: Text('In review')),
                        DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                      ],
                      onChanged: (v) => setModalState(() => status = v ?? status),
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: dueCtl,
                      decoration:
                          const InputDecoration(labelText: 'Due / Gate'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: risk,
                      items: const [
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                      ],
                      onChanged: (v) => setModalState(() => risk = v ?? risk),
                      decoration: const InputDecoration(labelText: 'Risk'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final item = DesignDeliverableRegisterItem(
                      name: nameCtl.text.trim(),
                      owner: owner,
                      status: status,
                      due: dueCtl.text.trim(),
                      risk: risk,
                    );
                    final register = [..._data.register];
                    if (editIndex >= 0) {
                      register[editIndex] = item;
                    } else {
                      register.add(item);
                    }
                    _updateData(_data.copyWith(register: register));
                    Navigator.pop(ctx);
                  },
                  child: Text(editIndex >= 0 ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteDeliverable(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Deliverable'),
        content: const Text(
            'Are you sure you want to remove this deliverable from the register?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              final register = [..._data.register]..removeAt(index);
              _updateData(_data.copyWith(register: register));
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DIALOGS — Acceptance Evidence
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _showAcceptanceEvidenceEditor(
      {_AcceptanceEvidenceRow? entry, int? index}) {
    final areaCtl =
        TextEditingController(text: entry?.evidenceArea ?? '');
    final whatCtl =
        TextEditingController(text: entry?.whatMustBeCaptured ?? '');
    final verCtl =
        TextEditingController(text: entry?.verificationMethod ?? '');
    final ownCtl =
        TextEditingController(text: entry?.approvalOwner ?? '');
    final riskCtl =
        TextEditingController(text: entry?.riskIfMissing ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(index != null ? 'Edit Evidence Row' : 'Add Evidence Row'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: areaCtl,
                    decoration: const InputDecoration(labelText: 'Evidence Area')),
                const SizedBox(height: 12),
                TextField(
                    controller: whatCtl,
                    decoration: const InputDecoration(labelText: 'What Must Be Captured'),
                    maxLines: 2),
                const SizedBox(height: 12),
                TextField(
                    controller: verCtl,
                    decoration: const InputDecoration(labelText: 'Verification Method')),
                const SizedBox(height: 12),
                TextField(
                    controller: ownCtl,
                    decoration: const InputDecoration(labelText: 'Approval Owner')),
                const SizedBox(height: 12),
                TextField(
                    controller: riskCtl,
                    decoration: const InputDecoration(labelText: 'Risk If Missing'),
                    maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final row = _AcceptanceEvidenceRow(
                  id: entry?.id ?? _newId(),
                  evidenceArea: areaCtl.text.trim(),
                  whatMustBeCaptured: whatCtl.text.trim(),
                  verificationMethod: verCtl.text.trim(),
                  approvalOwner: ownCtl.text.trim(),
                  riskIfMissing: riskCtl.text.trim(),
                );
                setState(() {
                  if (index != null) {
                    _acceptanceEvidence[index] = row;
                  } else {
                    _acceptanceEvidence.add(row);
                  }
                });
                _saveTrackingData();
                Navigator.pop(ctx);
              },
              child: Text(index != null ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAcceptanceEvidence(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Evidence Row'),
        content: const Text('Remove this acceptance evidence row?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              setState(() => _acceptanceEvidence.removeAt(index));
              _saveTrackingData();
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DIALOGS — Handoff Governance
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _showHandoffGovernanceEditor(
      {_HandoffGovernanceRow? entry, int? index}) {
    final ctrlCtl = TextEditingController(text: entry?.control ?? '');
    final pracCtl =
        TextEditingController(text: entry?.industryStandardPractice ?? '');
    final wfCtl =
        TextEditingController(text: entry?.waterfallEvidence ?? '');
    final agileCtl =
        TextEditingController(text: entry?.agileHybridEvidence ?? '');
    String decision = entry?.decision ?? 'Required';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: Text(index != null ? 'Edit Control' : 'Add Control'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: ctrlCtl,
                        decoration: const InputDecoration(labelText: 'Control')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: pracCtl,
                        decoration: const InputDecoration(
                            labelText: 'Industry Standard Practice'),
                        maxLines: 2),
                    const SizedBox(height: 12),
                    TextField(
                        controller: wfCtl,
                        decoration: const InputDecoration(
                            labelText: 'Waterfall Evidence')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: agileCtl,
                        decoration: const InputDecoration(
                            labelText: 'Agile/Hybrid Evidence')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: decision,
                      items: const [
                        DropdownMenuItem(value: 'Required', child: Text('Required')),
                        DropdownMenuItem(value: 'Conditional', child: Text('Conditional')),
                        DropdownMenuItem(value: 'Optional', child: Text('Optional')),
                      ],
                      onChanged: (v) =>
                          setModalState(() => decision = v ?? decision),
                      decoration: const InputDecoration(labelText: 'Decision'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final row = _HandoffGovernanceRow(
                      id: entry?.id ?? _newId(),
                      control: ctrlCtl.text.trim(),
                      industryStandardPractice: pracCtl.text.trim(),
                      waterfallEvidence: wfCtl.text.trim(),
                      agileHybridEvidence: agileCtl.text.trim(),
                      decision: decision,
                    );
                    setState(() {
                      if (index != null) {
                        _handoffGovernance[index] = row;
                      } else {
                        _handoffGovernance.add(row);
                      }
                    });
                    _saveTrackingData();
                    Navigator.pop(ctx);
                  },
                  child: Text(index != null ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteHandoffGovernance(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Control'),
        content: const Text('Remove this handoff governance control?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              setState(() => _handoffGovernance.removeAt(index));
              _saveTrackingData();
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DIALOGS — Approval Gates
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _showApprovalGateEditor(
      {_ApprovalGateRow? entry, int? index}) {
    final gateCtl = TextEditingController(text: entry?.gate ?? '');
    final descCtl = TextEditingController(text: entry?.description ?? '');
    final apprCtl = TextEditingController(text: entry?.approver ?? '');
    String priority = entry?.priority ?? 'High';
    String status = entry?.status ?? 'Pending';
    final dateCtl = TextEditingController(text: entry?.targetDate ?? 'TBD');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: Text(index != null ? 'Edit Gate' : 'Add Gate'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: gateCtl,
                        decoration: const InputDecoration(labelText: 'Gate')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: descCtl,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 2),
                    const SizedBox(height: 12),
                    TextField(
                        controller: apprCtl,
                        decoration: const InputDecoration(labelText: 'Approver')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priority,
                      items: const [
                        DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                      ],
                      onChanged: (v) =>
                          setModalState(() => priority = v ?? priority),
                      decoration: const InputDecoration(labelText: 'Priority'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(value: 'Not Started', child: Text('Not Started')),
                        DropdownMenuItem(value: 'In Review', child: Text('In Review')),
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                        DropdownMenuItem(value: 'Blocked', child: Text('Blocked')),
                      ],
                      onChanged: (v) =>
                          setModalState(() => status = v ?? status),
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: dateCtl,
                        decoration: const InputDecoration(labelText: 'Target Date')),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final row = _ApprovalGateRow(
                      id: entry?.id ?? _newId(),
                      gate: gateCtl.text.trim(),
                      description: descCtl.text.trim(),
                      approver: apprCtl.text.trim(),
                      priority: priority,
                      status: status,
                      targetDate: dateCtl.text.trim(),
                    );
                    setState(() {
                      if (index != null) {
                        _approvalGates[index] = row;
                      } else {
                        _approvalGates.add(row);
                      }
                    });
                    _saveTrackingData();
                    Navigator.pop(ctx);
                  },
                  child: Text(index != null ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteApprovalGate(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Gate'),
        content: const Text('Remove this approval gate?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              setState(() => _approvalGates.removeAt(index));
              _saveTrackingData();
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DIALOGS — Pipeline
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  void _showAddPipelineItemDialog() {
    if (!_canCreateDeliverables) {
      _showPermissionSnackBar('add pipeline items');
      return;
    }
    final labelCtl = TextEditingController();
    String status = 'In progress';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: const Text('Add Pipeline Stage'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: labelCtl,
                        decoration: const InputDecoration(
                            labelText: 'Stage or deliverable')),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(value: 'In progress', child: Text('In progress')),
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'In review', child: Text('In review')),
                        DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                      ],
                      onChanged: (v) =>
                          setModalState(() => status = v ?? status),
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final label = labelCtl.text.trim();
                    if (label.isEmpty) return;
                    _updateData(_data.copyWith(
                        pipeline: [
                          ..._data.pipeline,
                          DesignDeliverablePipelineItem(
                              label: label, status: status)
                        ]));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditPipelineDialog(
      DesignDeliverablePipelineItem item, int index) {
    final labelCtl = TextEditingController(text: item.label);
    String status = item.status;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              title: const Text('Edit Pipeline Stage'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: labelCtl,
                        decoration: const InputDecoration(
                            labelText: 'Stage or deliverable')),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      items: const [
                        DropdownMenuItem(value: 'In progress', child: Text('In progress')),
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'In review', child: Text('In review')),
                        DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                      ],
                      onChanged: (v) =>
                          setModalState(() => status = v ?? status),
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final pipeline = [..._data.pipeline];
                    pipeline[index] = DesignDeliverablePipelineItem(
                        label: labelCtl.text.trim(), status: status);
                    _updateData(_data.copyWith(pipeline: pipeline));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DATA CLASSES
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);
  final String label;
  final String value;
  final String supporting;
  final Color color;
}

class _AcceptanceEvidenceRow {
  _AcceptanceEvidenceRow({
    required this.id,
    this.evidenceArea = '',
    this.whatMustBeCaptured = '',
    this.verificationMethod = '',
    this.approvalOwner = '',
    this.riskIfMissing = '',
  });
  final String id;
  String evidenceArea;
  String whatMustBeCaptured;
  String verificationMethod;
  String approvalOwner;
  String riskIfMissing;

  Map<String, dynamic> toMap() => {
        'id': id,
        'evidenceArea': evidenceArea,
        'whatMustBeCaptured': whatMustBeCaptured,
        'verificationMethod': verificationMethod,
        'approvalOwner': approvalOwner,
        'riskIfMissing': riskIfMissing,
      };

  static _AcceptanceEvidenceRow fromMap(Map<String, dynamic> m) =>
      _AcceptanceEvidenceRow(
        id: m['id'] ?? '',
        evidenceArea: m['evidenceArea'] ?? '',
        whatMustBeCaptured: m['whatMustBeCaptured'] ?? '',
        verificationMethod: m['verificationMethod'] ?? '',
        approvalOwner: m['approvalOwner'] ?? '',
        riskIfMissing: m['riskIfMissing'] ?? '',
      );
}

class _HandoffGovernanceRow {
  _HandoffGovernanceRow({
    required this.id,
    this.control = '',
    this.industryStandardPractice = '',
    this.waterfallEvidence = '',
    this.agileHybridEvidence = '',
    this.decision = 'Required',
  });
  final String id;
  String control;
  String industryStandardPractice;
  String waterfallEvidence;
  String agileHybridEvidence;
  String decision;

  Map<String, dynamic> toMap() => {
        'id': id,
        'control': control,
        'industryStandardPractice': industryStandardPractice,
        'waterfallEvidence': waterfallEvidence,
        'agileHybridEvidence': agileHybridEvidence,
        'decision': decision,
      };

  static _HandoffGovernanceRow fromMap(Map<String, dynamic> m) =>
      _HandoffGovernanceRow(
        id: m['id'] ?? '',
        control: m['control'] ?? '',
        industryStandardPractice: m['industryStandardPractice'] ?? '',
        waterfallEvidence: m['waterfallEvidence'] ?? '',
        agileHybridEvidence: m['agileHybridEvidence'] ?? '',
        decision: m['decision'] ?? 'Required',
      );
}

class _ApprovalGateRow {
  _ApprovalGateRow({
    required this.id,
    this.gate = '',
    this.description = '',
    this.approver = '',
    this.priority = 'High',
    this.status = 'Pending',
    this.targetDate = 'TBD',
  });
  final String id;
  String gate;
  String description;
  String approver;
  String priority;
  String status;
  String targetDate;

  Map<String, dynamic> toMap() => {
        'id': id,
        'gate': gate,
        'description': description,
        'approver': approver,
        'priority': priority,
        'status': status,
        'targetDate': targetDate,
      };

  static _ApprovalGateRow fromMap(Map<String, dynamic> m) => _ApprovalGateRow(
        id: m['id'] ?? '',
        gate: m['gate'] ?? '',
        description: m['description'] ?? '',
        approver: m['approver'] ?? '',
        priority: m['priority'] ?? 'High',
        status: m['status'] ?? 'Pending',
        targetDate: m['targetDate'] ?? 'TBD',
      );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PANEL SHELL WIDGET
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827))),
                      const SizedBox(height: 6),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                              height: 1.45)),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
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
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DISPLAY ROW WIDGETS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return const Color(0xFF10B981);
    case 'in review':
      return const Color(0xFFF59E0B);
    case 'in progress':
      return const Color(0xFF2563EB);
    case 'not started':
      return const Color(0xFF9CA3AF);
    case 'blocked':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF64748B);
  }
}

Color _riskColor(String risk) {
  switch (risk.toLowerCase()) {
    case 'high':
      return const Color(0xFFEF4444);
    case 'medium':
      return const Color(0xFFF59E0B);
    case 'low':
      return const Color(0xFF10B981);
    default:
      return const Color(0xFF64748B);
  }
}

Color _priorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'critical':
      return const Color(0xFFEF4444);
    case 'high':
      return const Color(0xFFF97316);
    case 'medium':
      return const Color(0xFFF59E0B);
    case 'low':
      return const Color(0xFF10B981);
    default:
      return const Color(0xFF64748B);
  }
}

Widget _statusBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );
}

class _DeliverableRegisterRow extends StatelessWidget {
  const _DeliverableRegisterRow({
    required this.row,
    required this.onEdit,
    required this.onDelete,
    required this.showDivider,
  });
  final DesignDeliverableRegisterItem row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(row.name,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: 100,
                child: Text(row.owner,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center),
              ),
              SizedBox(
                  width: 100,
                  child: Center(
                      child: _statusBadge(row.status, _statusColor(row.status)))),
              SizedBox(
                width: 100,
                child: Text(row.due,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center),
              ),
              SizedBox(
                  width: 80,
                  child: Center(
                      child: _statusBadge(row.risk, _riskColor(row.risk)))),
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: Color(0xFF64748B)),
                        visualDensity: VisualDensity.compact),
                    IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Color(0xFFEF4444)),
                        visualDensity: VisualDensity.compact),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
      ],
    );
  }
}

class _AcceptanceEvidenceDisplayRow extends StatelessWidget {
  const _AcceptanceEvidenceDisplayRow({
    required this.row,
    required this.onEdit,
    required this.onDelete,
    required this.showDivider,
  });
  final _AcceptanceEvidenceRow row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(row.evidenceArea,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
              ),
              Expanded(
                flex: 3,
                child: Text(row.whatMustBeCaptured,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF4B5563), height: 1.45)),
              ),
              Expanded(
                flex: 2,
                child: Text(row.verificationMethod,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF4B5563), height: 1.45)),
              ),
              SizedBox(
                width: 110,
                child: Text(row.approvalOwner,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center),
              ),
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: Color(0xFF64748B)),
                        visualDensity: VisualDensity.compact),
                    IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Color(0xFFEF4444)),
                        visualDensity: VisualDensity.compact),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
      ],
    );
  }
}

class _HandoffGovernanceDisplayRow extends StatelessWidget {
  const _HandoffGovernanceDisplayRow({
    required this.row,
    required this.onEdit,
    required this.onDelete,
    required this.showDivider,
  });
  final _HandoffGovernanceRow row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(row.control,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
              ),
              Expanded(
                flex: 3,
                child: Text(row.industryStandardPractice,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF4B5563), height: 1.45)),
              ),
              Expanded(
                flex: 2,
                child: Text(row.waterfallEvidence,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF4B5563), height: 1.45)),
              ),
              Expanded(
                flex: 2,
                child: Text(row.agileHybridEvidence,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF4B5563), height: 1.45)),
              ),
              SizedBox(
                  width: 90,
                  child: Center(
                      child: _statusBadge(
                          row.decision,
                          row.decision == 'Required'
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFF59E0B)))),
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: Color(0xFF64748B)),
                        visualDensity: VisualDensity.compact),
                    IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Color(0xFFEF4444)),
                        visualDensity: VisualDensity.compact),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
      ],
    );
  }
}

class _ApprovalGateDisplayRow extends StatelessWidget {
  const _ApprovalGateDisplayRow({
    required this.row,
    required this.onEdit,
    required this.onDelete,
    required this.showDivider,
  });
  final _ApprovalGateRow row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(row.gate,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
              ),
              Expanded(
                flex: 3,
                child: Text(row.description,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF4B5563), height: 1.45)),
              ),
              SizedBox(
                width: 120,
                child: Text(row.approver,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280)),
                    textAlign: TextAlign.center),
              ),
              SizedBox(
                  width: 90,
                  child: Center(
                      child: _statusBadge(
                          row.priority, _priorityColor(row.priority)))),
              SizedBox(
                  width: 100,
                  child: Center(
                      child: _statusBadge(
                          row.status, _statusColor(row.status)))),
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: Color(0xFF64748B)),
                        visualDensity: VisualDensity.compact),
                    IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Color(0xFFEF4444)),
                        visualDensity: VisualDensity.compact),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
      ],
    );
  }
}

class _PipelineDisplayRow extends StatelessWidget {
  const _PipelineDisplayRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.showDivider,
  });
  final DesignDeliverablePipelineItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(item.label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827))),
              ),
              SizedBox(
                  width: 120,
                  child: Center(
                      child: _statusBadge(
                          item.status, _statusColor(item.status)))),
              SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: Color(0xFF64748B)),
                        visualDensity: VisualDensity.compact),
                    IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Color(0xFFEF4444)),
                        visualDensity: VisualDensity.compact),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// DEBOUNCER
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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
