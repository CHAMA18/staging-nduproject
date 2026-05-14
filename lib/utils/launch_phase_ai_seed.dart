import 'package:flutter/material.dart';
import 'package:ndu_project/models/launch_phase_models.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/launch_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:provider/provider.dart';

/// Provides comprehensive cross-phase context building and AI generation
/// for all nine Launch Phase screens.
///
/// Phase Dependency Chain:
///   Initiation → Front End Planning → Planning → Design → Execution → LAUNCH
///
/// Each Launch screen inherits data context from ALL prior phases so that
/// AI-generated content reflects the full project history.
class LaunchPhaseAiSeed {
  const LaunchPhaseAiSeed._();

  // ────────────────────────────────────────────────────────────────
  // 1. Cross-phase context builder
  // ────────────────────────────────────────────────────────────────

  /// Builds a rich, phase-dependency-aware context string for AI generation.
  ///
  /// This method:
  ///  1. Starts with the base context from [ProjectDataHelper.buildExecutivePlanContext]
  ///     which already includes Initiation, FEP, Planning, Design, and Execution data.
  ///  2. Augments it with live Firestore data from Execution Phase entries
  ///     (staffing, contracts, vendors, budget, deliverables, scope tracking, risks).
  ///  3. Adds Planning Phase sprints and deliverables if available.
  ///  4. Appends the target [sectionLabel] so the AI knows which section to generate.
  static Future<String> buildFullPhaseDependencyContext(
    BuildContext context, {
    required String sectionLabel,
  }) async {
    final projectData = ProjectDataHelper.getData(context);
    final projectId = projectData.projectId;

    // Base context covers Initiation + FEP + Planning + Design + Execution
    var contextText = ProjectDataHelper.buildExecutivePlanContext(
      projectData,
      sectionLabel: sectionLabel,
    );
    if (contextText.trim().isEmpty) {
      contextText = ProjectDataHelper.buildProjectContextScan(
        projectData,
        sectionLabel: sectionLabel,
      );
    }
    if (contextText.trim().isEmpty) return '';

    if (projectId == null || projectId.isEmpty) return contextText;

    // Load cross-phase data from Firestore
    final staffing = await LaunchPhaseService.loadExecutionStaffing(projectId);
    final contracts =
        await LaunchPhaseService.loadExecutionContracts(projectId);
    final vendors = await LaunchPhaseService.loadExecutionVendors(projectId);
    final budgetRows = await LaunchPhaseService.loadBudgetRows(projectId);
    final deliverableRows =
        await LaunchPhaseService.loadDeliverableRows(projectId);
    final scopeTracking =
        await LaunchPhaseService.loadScopeTrackingItems(projectId);
    final riskSnapshot =
        await LaunchPhaseService.loadRiskTrackingSnapshot(projectId);
    final planningDeliverables =
        await LaunchPhaseService.loadPlanningDeliverables(projectId);
    final planningSprints =
        await LaunchPhaseService.loadPlanningSprints(projectId);
    final stakeholders =
        await LaunchPhaseService.loadCoreStakeholders(projectId);

    // Format each cross-phase summary
    final staffingSummary = staffing.isEmpty
        ? null
        : staffing
            .map((s) =>
                '- ${s.name} (${s.role}, status: ${s.releaseStatus})')
            .take(10)
            .join('\n');

    final contractsSummary = contracts.isEmpty
        ? null
        : contracts
            .map((c) =>
                '- ${c.contractName} (vendor: ${c.vendor}, value: ${c.value}, status: ${c.closeOutStatus})')
            .take(10)
            .join('\n');

    final vendorsSummary = vendors.isEmpty
        ? null
        : vendors
            .map((v) =>
                '- ${v.vendorName} (ref: ${v.contractRef}, status: ${v.accountStatus})')
            .take(10)
            .join('\n');

    final budgetSummary = budgetRows.isEmpty
        ? null
        : budgetRows
            .map((b) =>
                '- ${b['category'] ?? 'Unknown'}: planned ${b['plannedAmount'] ?? '0'}, actual ${b['actualAmount'] ?? '0'}')
            .take(10)
            .join('\n');

    final deliverablesSummary = deliverableRows.isEmpty
        ? null
        : deliverableRows
            .map((d) =>
                '- ${d['title'] ?? 'Untitled'} (status: ${d['status'] ?? 'Unknown'})')
            .take(10)
            .join('\n');

    final scopeSummary = scopeTracking.isEmpty
        ? null
        : scopeTracking
            .map(
                (s) => '- ${s.deliverable} (status: ${s.status})')
            .take(10)
            .join('\n');

    String? riskSummary;
    final riskItems = riskSnapshot['riskItems'];
    if (riskItems is List && riskItems.isNotEmpty) {
      riskSummary = riskItems
          .whereType<Map>()
          .take(8)
          .map((r) =>
              '- ${r['title'] ?? r['risk'] ?? 'Unknown'} (status: ${r['status'] ?? 'Unknown'}, owner: ${r['owner'] ?? 'Unassigned'})')
          .join('\n');
    }

    String? sprintsSummary;
    if (planningSprints.isNotEmpty) {
      sprintsSummary = planningSprints
          .map((s) =>
              '- Sprint ${s['sprintNumber'] ?? s['name'] ?? '?'}: ${s['goal'] ?? s['title'] ?? ''} (status: ${s['status'] ?? 'Unknown'})')
          .take(6)
          .join('\n');
    }

    String? stakeholdersSummary;
    if (stakeholders.isNotEmpty) {
      stakeholdersSummary = stakeholders
          .map((s) =>
              '- ${s['name'] ?? s['title'] ?? 'Stakeholder'} (${s['role'] ?? 'Role'})')
          .take(8)
            .join('\n');
    }

    // Build the augmented context
    contextText = ProjectDataHelper.buildLaunchPhaseContext(
      baseContext: contextText,
      sectionLabel: sectionLabel,
      staffingSummary: staffingSummary,
      contractsSummary: contractsSummary,
      vendorsSummary: vendorsSummary,
      budgetSummary: budgetSummary,
      deliverablesSummary: deliverablesSummary,
      scopeTrackingSummary: scopeSummary,
      riskTrackingSummary: riskSummary,
      sprintsSummary: sprintsSummary,
    );

    // Append planning deliverables and stakeholders if available
    final buf = StringBuffer(contextText);

    if (planningDeliverables.isNotEmpty) {
      buf.writeln();
      buf.writeln('Planning Phase Deliverables:');
      for (final d in planningDeliverables.take(6)) {
        buf.writeln(
            '- ${d['name'] ?? d['title'] ?? 'Deliverable'} (status: ${d['status'] ?? 'Unknown'})');
      }
    }

    if (stakeholdersSummary != null) {
      buf.writeln();
      buf.writeln('Core Stakeholders:');
      buf.writeln(stakeholdersSummary);
    }

    return buf.toString().trim();
  }

  // ────────────────────────────────────────────────────────────────
  // 2. AI generation entry point
  // ────────────────────────────────────────────────────────────────

  /// Generates AI-populated entries for a Launch Phase screen, using
  /// the full cross-phase dependency context.
  ///
  /// Returns a map of section keys to lists of raw entry maps,
  /// each containing 'title', 'details', and 'status'.
  static Future<Map<String, List<Map<String, dynamic>>>> generateEntries({
    required BuildContext context,
    required String sectionLabel,
    required Map<String, String> sections,
    int itemsPerSection = 3,
  }) async {
    final contextText = await buildFullPhaseDependencyContext(
      context,
      sectionLabel: sectionLabel,
    );
    if (contextText.isEmpty) return {};

    return OpenAiServiceSecure().generateLaunchPhaseEntries(
      context: contextText,
      sections: sections,
      itemsPerSection: itemsPerSection,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // 3. Auto-populate helpers (data-driven, no AI call)
  // ────────────────────────────────────────────────────────────────

  /// Loads ALL cross-phase data from Firestore and returns a structured
  /// record that screens can use for deterministic auto-population
  /// (before or instead of AI generation).
  static Future<CrossPhaseData> loadCrossPhaseData(String projectId) async {
    return CrossPhaseData(
      staffing: await LaunchPhaseService.loadExecutionStaffing(projectId),
      contracts: await LaunchPhaseService.loadExecutionContracts(projectId),
      vendors: await LaunchPhaseService.loadExecutionVendors(projectId),
      budgetRows: await LaunchPhaseService.loadBudgetRows(projectId),
      deliverableRows:
          await LaunchPhaseService.loadDeliverableRows(projectId),
      scopeTracking:
          await LaunchPhaseService.loadScopeTrackingItems(projectId),
      riskSnapshot:
          await LaunchPhaseService.loadRiskTrackingSnapshot(projectId),
      planningDeliverables:
          await LaunchPhaseService.loadPlanningDeliverables(projectId),
      planningSprints:
          await LaunchPhaseService.loadPlanningSprints(projectId),
      stakeholders: await LaunchPhaseService.loadCoreStakeholders(projectId),
    );
  }
}

/// Immutable snapshot of cross-phase data used for deterministic
/// auto-population of Launch Phase screens.
class CrossPhaseData {
  final List<LaunchTeamMember> staffing;
  final List<LaunchContractItem> contracts;
  final List<LaunchVendorItem> vendors;
  final List<Map<String, dynamic>> budgetRows;
  final List<Map<String, dynamic>> deliverableRows;
  final List<LaunchScopeItem> scopeTracking;
  final Map<String, dynamic> riskSnapshot;
  final List<Map<String, dynamic>> planningDeliverables;
  final List<Map<String, dynamic>> planningSprints;
  final List<Map<String, String>> stakeholders;

  const CrossPhaseData({
    this.staffing = const [],
    this.contracts = const [],
    this.vendors = const [],
    this.budgetRows = const [],
    this.deliverableRows = const [],
    this.scopeTracking = const [],
    this.riskSnapshot = const {},
    this.planningDeliverables = const [],
    this.planningSprints = const [],
    this.stakeholders = const [],
  });

  // ── Budget helpers ──

  double get totalPlannedBudget => budgetRows.fold<double>(
        0,
        (sum, b) =>
            sum +
            (_parseNum(b['plannedAmount'])),
      );

  double get totalActualBudget => budgetRows.fold<double>(
        0,
        (sum, b) =>
            sum +
            (_parseNum(b['actualAmount'])),
      );

  double get budgetVariance => totalPlannedBudget - totalActualBudget;

  double get totalContractValue => contracts.fold<double>(
        0,
        (sum, c) => sum + _parseNum(c.value),
      );

  // ── Scope helpers ──

  int get completedDeliverables => deliverableRows.where((d) {
        final s = (d['status'] ?? '').toString().toLowerCase();
        return s == 'completed' || s == 'done' || s == 'verified';
      }).length;

  int get completedScopeItems => scopeTracking.where((s) {
        final st = s.status.toLowerCase();
        return st == 'verified' || st == 'completed' || st == 'done';
      }).length;

  int get totalScopeCount =>
      deliverableRows.length + scopeTracking.length;

  int get totalCompletedScope =>
      completedDeliverables + completedScopeItems;

  // ── Risk helpers ──

  List<Map<String, dynamic>> get openRiskItems {
    final items = riskSnapshot['riskItems'];
    if (items is! List) return [];
    return items
        .whereType<Map>()
        .map((r) => Map<String, dynamic>.from(r))
        .where((r) {
      final status = (r['status'] ?? '').toString().toLowerCase();
      return status != 'closed' &&
          status != 'resolved' &&
          status != 'mitigated';
    }).toList();
  }

  List<Map<String, dynamic>> get mitigationPlans {
    final plans = riskSnapshot['mitigationPlans'];
    if (plans is! List) return [];
    return plans
        .whereType<Map>()
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
  }

  // ── Utility ──

  static double _parseNum(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(
            v.toString().replaceAll(RegExp(r'[^\d.]'), '')) ??
        0;
  }
}
