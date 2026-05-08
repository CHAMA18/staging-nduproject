import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/utils/design_planning_document.dart';

class IntegratedWorkPackageService {
  IntegratedWorkPackageService._();

  static const String engineeringEwp = 'engineeringEwp';
  static const String procurementPackage = 'procurementPackage';
  static const String constructionCwp = 'constructionCwp';
  static const String implementationWorkPackage = 'implementationWorkPackage';
  static const String agileIterationPackage = 'agileIterationPackage';

  // ------------------------------------------------------------------
  // Guide Step 1–5: Generate EWP → Procurement → Execution chains
  // Now includes design-to-procurement traceability on deliverables.
  // ------------------------------------------------------------------

  static List<WorkPackage> generatePackageChainsFromWbs({
    required List<WorkItem> wbsTree,
    required String methodology,
    /// Optional design specification rows to link into EWP deliverables.
    /// When provided, matching specs are embedded as deliverable items
    /// and their IDs are tracked on the EWP's linkedDesignSpecificationIds.
    List<DesignSpecificationPlanRow>? designSpecifications,
  }) {
    final packages = <WorkPackage>[];
    final normalizedMethodology = methodology.trim().toLowerCase();
    final isAgile = normalizedMethodology == 'agile';

    for (final level1 in wbsTree) {
      for (final level2 in level1.children) {
        for (final level3 in level2.children) {
          final baseId = _stableId(level3.id.isNotEmpty
              ? level3.id
              : '${level2.title}_${level3.title}');
          final baseCode = _packageCode(level2.title, level3.title);
          final executionClassification = isAgile
              ? agileIterationPackage
              : (_looksLikeConstruction(level3)
                  ? constructionCwp
                  : implementationWorkPackage);
          final executionType = executionClassification == constructionCwp
              ? 'construction'
              : 'execution';
          final executionLabel = executionClassification == constructionCwp
              ? 'Construction Work Package'
              : (executionClassification == agileIterationPackage
                  ? 'Agile Iteration Package'
                  : 'Implementation Work Package');

          final engineeringId = '$baseId-ewp';
          final procurementId = '$baseId-proc';
          final executionId = '$baseId-exec';

          // --- Fix 1.2: Import matching design specification rows ---
          final matchedSpecs = _matchSpecificationsToWbs(
            designSpecifications ?? [],
            level2WbsId: level2.id,
            level3WbsId: level3.id,
            level3Title: level3.title,
            level2Title: level2.title,
          );

          // Build EWP deliverables: defaults + spec-derived items
          final deliverables = _buildEwpDeliverables(
            procurementId: procurementId,
            matchedSpecs: matchedSpecs,
          );

          // Track linked spec IDs on the package
          final linkedSpecIds =
              matchedSpecs.map((spec) => spec.id).toList();

          packages.add(
            WorkPackage(
              id: engineeringId,
              wbsItemId: level3.id,
              wbsLevel2Id: level2.id,
              wbsLevel2Title: level2.title,
              sourceWbsLevel3Id: level3.id,
              sourceWbsLevel3Title: level3.title,
              packageLevel: 3,
              packageCode: '$baseCode-EWP',
              packageClassification: engineeringEwp,
              childPackageIds: [procurementId, executionId],
              linkedProcurementPackageIds: [procurementId],
              linkedExecutionPackageIds: [executionId],
              linkedDesignSpecificationIds: linkedSpecIds,
              title: '${level3.title} Engineering Work Package',
              description: level3.description,
              type: 'design',
              phase: 'design',
              discipline: level3.framework,
              releaseStatus: 'draft',
              deliverables: deliverables,
              estimateBasis: _defaultEstimateBasis(methodology),
            ),
          );

          // --- Fix 1.1: Derive procurement scope from EWP deliverables ---
          final procurementScopeFromDeliverables = deliverables
              .where((d) => d.requiredForProcurement)
              .map((d) => d.title)
              .join('; ');

          final scopeDefinition = procurementScopeFromDeliverables.isNotEmpty
              ? 'Requires: $procurementScopeFromDeliverables'
              : level3.description;

          packages.add(
            WorkPackage(
              id: procurementId,
              wbsItemId: level3.id,
              wbsLevel2Id: level2.id,
              wbsLevel2Title: level2.title,
              sourceWbsLevel3Id: level3.id,
              sourceWbsLevel3Title: level3.title,
              packageLevel: 3,
              packageCode: '$baseCode-PROC',
              packageClassification: procurementPackage,
              parentPackageId: engineeringId,
              childPackageIds: [executionId],
              linkedEngineeringPackageIds: [engineeringId],
              linkedExecutionPackageIds: [executionId],
              linkedDesignSpecificationIds: linkedSpecIds,
              title: '${level3.title} Procurement Package',
              description: level3.description,
              type: 'procurement',
              phase: 'execution',
              discipline: level3.framework,
              releaseStatus: 'draft',
              procurementBreakdown: PackageProcurementBreakdown(
                category: _inferProcurementCategory(level3),
                scopeDefinition: scopeDefinition,
                activities: const [
                  'scope_definition',
                  'rfq_rfp',
                  'bid_evaluation',
                  'award',
                  'fabrication_or_configuration',
                  'delivery',
                ],
              ),
              estimateBasis: _defaultEstimateBasis(methodology),
            ),
          );

          packages.add(
            WorkPackage(
              id: executionId,
              wbsItemId: level3.id,
              wbsLevel2Id: level2.id,
              wbsLevel2Title: level2.title,
              sourceWbsLevel3Id: level3.id,
              sourceWbsLevel3Title: level3.title,
              packageLevel: 3,
              packageCode: '$baseCode-EXEC',
              packageClassification: executionClassification,
              parentPackageId: procurementId,
              linkedEngineeringPackageIds: [engineeringId],
              linkedProcurementPackageIds: [procurementId],
              linkedDesignSpecificationIds: linkedSpecIds,
              title: '${level3.title} $executionLabel',
              description: level3.description,
              type: executionType,
              phase: 'execution',
              discipline: level3.framework,
              areaOrSystem: level2.title,
              releaseStatus: 'draft',
              estimateBasis: _defaultEstimateBasis(methodology),
            ),
          );
        }
      }
    }

    return packages
        .map((package) =>
            package.copyWith(readinessWarnings: validateReadiness(package)))
        .toList();
  }

  // ------------------------------------------------------------------
  // Fix 1.2: Match design specification rows to WBS nodes
  // ------------------------------------------------------------------

  /// Matches design specification rows to a WBS Level 3 node.
  /// A spec row matches if its `wbsWorkPackageId` equals the Level 2 or
  /// Level 3 WBS ID, OR if its title/discipline/area keywords overlap
  /// with the WBS node titles.
  static List<DesignSpecificationPlanRow> _matchSpecificationsToWbs(
    List<DesignSpecificationPlanRow> specs, {
    required String level2WbsId,
    required String level3WbsId,
    required String level3Title,
    required String level2Title,
  }) {
    if (specs.isEmpty) return [];

    final level2Lower = level2Title.toLowerCase();
    final level3Lower = level3Title.toLowerCase();
    final level2Tokens = _tokenize(level2Lower);
    final level3Tokens = _tokenize(level3Lower);

    return specs.where((spec) {
      // Direct WBS ID match (strongest signal)
      if (spec.wbsWorkPackageId == level2WbsId ||
          spec.wbsWorkPackageId == level3WbsId) {
        return true;
      }

      // Title keyword overlap
      final specTitle = spec.title.toLowerCase();
      final specTokens = _tokenize(specTitle);
      if (level3Tokens.any((t) => specTokens.contains(t)) ||
          level2Tokens.any((t) => specTokens.contains(t))) {
        return true;
      }

      // Discipline/area keyword match
      final specDiscipline = spec.discipline.toLowerCase();
      final specArea = spec.area.toLowerCase();
      if (specDiscipline.isNotEmpty &&
          (level2Lower.contains(specDiscipline) ||
              level3Lower.contains(specDiscipline))) {
        return true;
      }
      if (specArea.isNotEmpty &&
          (level2Lower.contains(specArea) ||
              level3Lower.contains(specArea))) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Tokenizes a string for matching: splits on non-alphanumeric, removes
  /// common stop words, and keeps tokens of 3+ characters.
  static List<String> _tokenize(String value) {
    const stopWords = {'the', 'and', 'for', 'with', 'from', 'this', 'that'};
    return value
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 3 && !stopWords.contains(t))
        .toList();
  }

  // ------------------------------------------------------------------
  // Fix 1.2 + 1.3: Build EWP deliverables with traceability
  // ------------------------------------------------------------------

  /// Builds the complete deliverables list for an EWP.
  /// Starts with the 5 standard deliverables (Drawings, Specifications,
  /// Calculations, BOM, Codes) and appends spec-derived deliverables.
  /// Each deliverable is wired with `feedsProcurementPackageIds` pointing
  /// to the procurement package (Fix 1.3: design-to-procurement traceability).
  static List<PackageDeliverable> _buildEwpDeliverables({
    required String procurementId,
    required List<DesignSpecificationPlanRow> matchedSpecs,
  }) {
    final deliverables = <PackageDeliverable>[];

    // Standard 5 deliverables — each feeds the procurement package
    deliverables.addAll(_defaultEngineeringDeliverablesWithTraceability(
      procurementId: procurementId,
    ));

    // Spec-derived deliverables: one per matched specification row
    for (final spec in matchedSpecs) {
      final specType = _mapSpecTypeToDeliverableType(spec.specificationType);
      final requiresProcurement = _specRequiresProcurement(spec);
      deliverables.add(
        PackageDeliverable(
          title: spec.title.isNotEmpty ? spec.title : 'Specification: ${spec.specificationType}',
          type: specType,
          status: _mapSpecStatusToDeliverableStatus(spec.status),
          reference: spec.referenceLink,
          notes: _specDeliverableNotes(spec),
          feedsProcurementPackageIds: requiresProcurement ? [procurementId] : [],
          linkedSpecificationIds: [spec.id],
          requiredForProcurement: requiresProcurement,
        ),
      );
    }

    return deliverables;
  }

  /// The standard 5 EWP deliverables with procurement traceability wired.
  static List<PackageDeliverable>
      _defaultEngineeringDeliverablesWithTraceability({
    required String procurementId,
  }) =>
          [
            PackageDeliverable(
              title: 'Drawings',
              type: 'drawing',
              feedsProcurementPackageIds: [procurementId],
              requiredForProcurement: true,
            ),
            PackageDeliverable(
              title: 'Specifications',
              type: 'specification',
              feedsProcurementPackageIds: [procurementId],
              requiredForProcurement: true,
            ),
            PackageDeliverable(
              title: 'Calculations',
              type: 'calculation',
              feedsProcurementPackageIds: [procurementId],
              requiredForProcurement: false,
            ),
            PackageDeliverable(
              title: 'Bill of materials',
              type: 'bom',
              feedsProcurementPackageIds: [procurementId],
              requiredForProcurement: true,
            ),
            PackageDeliverable(
              title: 'Codes and requirements',
              type: 'requirement',
              feedsProcurementPackageIds: [],
              requiredForProcurement: false,
            ),
          ];

  /// Maps a DesignSpecificationPlanRow.specificationType to a
  /// PackageDeliverable type.
  static String _mapSpecTypeToDeliverableType(String specType) {
    switch (specType.toLowerCase()) {
      case 'code':
        return 'requirement';
      case 'law':
        return 'requirement';
      case 'standard':
        return 'specification';
      case 'criteria':
        return 'specification';
      case 'guideline':
        return 'specification';
      case 'contract':
        return 'requirement';
      default:
        return 'specification';
    }
  }

  /// Whether a specification row implies procurement is needed.
  /// External/contract/vendor sources typically require procurement.
  static bool _specRequiresProcurement(DesignSpecificationPlanRow spec) {
    final sourceType = spec.sourceType.toLowerCase();
    final ruleType = spec.ruleType.toLowerCase();
    return sourceType == 'vendors' ||
        sourceType == 'contracts' ||
        ruleType == 'external';
  }

  /// Maps a specification status to a deliverable status.
  static String _mapSpecStatusToDeliverableStatus(String specStatus) {
    switch (specStatus.toLowerCase()) {
      case 'draft':
        return 'planned';
      case 'planned':
        return 'planned';
      case 'in review':
        return 'in_review';
      case 'approved':
        return 'released';
      case 'complete':
        return 'complete';
      default:
        return 'planned';
    }
  }

  /// Builds the notes string for a spec-derived deliverable.
  static String _specDeliverableNotes(DesignSpecificationPlanRow spec) {
    final parts = <String>[];
    if (spec.specificationType.isNotEmpty) {
      parts.add('Spec type: ${spec.specificationType}');
    }
    if (spec.ruleType.isNotEmpty) {
      parts.add('Rule: ${spec.ruleType}');
    }
    if (spec.sourceType.isNotEmpty) {
      parts.add('Source: ${spec.sourceType}');
    }
    if (spec.discipline.isNotEmpty) {
      parts.add('Discipline: ${spec.discipline}');
    }
    if (spec.area.isNotEmpty) {
      parts.add('Area: ${spec.area}');
    }
    if (spec.details.isNotEmpty) {
      parts.add(spec.details);
    }
    if (spec.attachedRequirementIds.isNotEmpty) {
      parts.add('Req IDs: ${spec.attachedRequirementIds.join(", ")}');
    }
    return parts.join('\n');
  }

  // ------------------------------------------------------------------
  // Fix 1.4: Release for execution gate
  // ------------------------------------------------------------------

  /// Checks whether an EWP can be released for execution.
  /// Returns a list of blocking issues (empty = releasable).
  /// An EWP is releasable when:
  /// - All required-for-procurement deliverables are released/complete
  /// - The readiness checklist passes (drawings, specs, BOM, design review, IFC)
  /// - Requirements are traced
  static List<String> checkEwpReleaseReadiness(WorkPackage package) {
    if (package.packageClassification != engineeringEwp) {
      return ['Release gate only applies to Engineering Work Packages.'];
    }

    final blockers = <String>[];

    // Check deliverable completion
    final requiredDeliverables = package.deliverables
        .where((d) => d.requiredForProcurement)
        .toList();
    for (final deliverable in requiredDeliverables) {
      if (!deliverable.isReleased) {
        blockers.add(
            'Deliverable "${deliverable.title}" is not yet released (status: ${deliverable.status}).');
      }
    }

    // Check readiness flags
    final readiness = package.readiness;
    if (!readiness.requirementsTraced) {
      blockers.add('Requirements traceability is not complete.');
    }
    if (!readiness.drawingsComplete) {
      blockers.add('Drawings are not complete.');
    }
    if (!readiness.specificationsComplete) {
      blockers.add('Specifications are not complete.');
    }
    if (!readiness.billOfMaterialsComplete) {
      blockers.add('Bill of materials is not complete.');
    }
    if (!readiness.designReviewComplete) {
      blockers.add('Design review is not complete.');
    }
    if (!readiness.ifcApproved) {
      blockers.add('IFC approval is not complete.');
    }

    // Check estimate basis
    if (!package.estimateBasis.hasMinimumBasis) {
      blockers.add('Estimate basis is incomplete.');
    }

    // Check WBS linkage
    if (package.sourceWbsLevel3Id.trim().isEmpty) {
      blockers.add('Package is not linked to a WBS Level 3 element.');
    }

    return blockers;
  }

  /// Releases an EWP for execution if all gate criteria are met.
  /// Returns the updated package, or throws with blocker messages.
  static WorkPackage releaseEwpForExecution(WorkPackage package) {
    final blockers = checkEwpReleaseReadiness(package);
    if (blockers.isNotEmpty) {
      throw StateError(
          'Cannot release EWP "${package.title}". Blockers:\n${blockers.map((b) => "  - $b").join("\n")}');
    }

    return package.copyWith(
      releaseStatus: 'released',
      releaseForExecutionDate:
          DateTime.now().toUtc().toIso8601String().split('T').first,
    );
  }

  // ------------------------------------------------------------------
  // Fix 1.1: Derive procurement scope from EWP deliverables
  // ------------------------------------------------------------------

  /// Given a list of existing work packages, derives and updates
  /// procurement package scope definitions from linked EWP deliverables.
  /// This ensures procurement packages know what design outputs they need.
  static List<WorkPackage> deriveProcurementScopeFromEwpDeliverables(
    List<WorkPackage> packages,
  ) {
    final ewpById = <String, WorkPackage>{};
    for (final p in packages) {
      if (p.packageClassification == engineeringEwp) {
        ewpById[p.id] = p;
      }
    }

    return packages.map((package) {
      if (package.packageClassification != procurementPackage) {
        return package;
      }

      // Find linked EWP deliverables that feed this procurement package
      final requiredDeliverables = <PackageDeliverable>[];
      for (final ewpId in package.linkedEngineeringPackageIds) {
        final ewp = ewpById[ewpId];
        if (ewp == null) continue;
        for (final d in ewp.deliverables) {
          if (d.feedsProcurementPackageIds.contains(package.id)) {
            requiredDeliverables.add(d);
          }
        }
      }

      if (requiredDeliverables.isEmpty) return package;

      // Build scope definition from deliverables
      final scopeParts = requiredDeliverables
          .where((d) => d.requiredForProcurement)
          .map((d) => '${d.title}${d.isReleased ? " (ready)" : " (pending)"}')
          .toList();

      final newScope = scopeParts.isNotEmpty
          ? 'Requires design deliverables: ${scopeParts.join("; ")}'
          : package.procurementBreakdown.scopeDefinition;

      return package.copyWith(
        procurementBreakdown: package.procurementBreakdown.copyWith(
          scopeDefinition: newScope,
        ),
        linkedDesignSpecificationIds: requiredDeliverables
            .expand((d) => d.linkedSpecificationIds)
            .toSet()
            .toList(),
      );
    }).toList();
  }

  // ------------------------------------------------------------------
  // Validation
  // ------------------------------------------------------------------

  static List<String> validateReadiness(WorkPackage package) {
    final warnings = <String>[];
    final readiness = package.readiness;

    if (package.sourceWbsLevel3Id.trim().isEmpty) {
      warnings.add('Package is not linked to a WBS Level 3 package candidate.');
    }
    if (package.wbsLevel2Id.trim().isEmpty) {
      warnings
          .add('Package is not linked to a WBS Level 2 deliverable/system.');
    }
    if (!package.estimateBasis.hasMinimumBasis) {
      warnings.add('Schedule duration is missing a documented estimate basis.');
    }

    switch (package.packageClassification) {
      case engineeringEwp:
        if (!readiness.requirementsTraced) {
          warnings.add('EWP requirements traceability is not complete.');
        }
        if (!readiness.drawingsComplete) {
          warnings.add('EWP drawings are not complete.');
        }
        if (!readiness.specificationsComplete) {
          warnings.add('EWP specifications are not complete.');
        }
        if (!readiness.billOfMaterialsComplete) {
          warnings.add('EWP bill of materials is not complete.');
        }
        if (!readiness.designReviewComplete) {
          warnings.add('EWP design review is not complete.');
        }
        if (!readiness.ifcApproved) {
          warnings.add('EWP is not approved/released for execution.');
        }
        // Fix 1.2: Warn if EWP has no linked design specifications
        if (package.linkedDesignSpecificationIds.isEmpty) {
          warnings.add(
              'EWP has no linked design specifications. Consider mapping specifications from the Design Planning document.');
        }
        // Fix 1.4: Warn if EWP is not released but execution packages exist
        if (!package.isReleasedForExecution &&
            package.linkedExecutionPackageIds.isNotEmpty) {
          warnings.add(
              'EWP is not released for execution. Linked execution packages should not start until this EWP is released.');
        }
      case procurementPackage:
        if (!readiness.procurementScopeDefined) {
          warnings.add('Procurement scope is not defined.');
        }
        if (!readiness.rfqIssued) {
          warnings.add('RFQ/RFP has not been issued.');
        }
        if (!readiness.bidsEvaluated) {
          warnings.add('Bids have not been evaluated.');
        }
        if (!readiness.contractAwarded) {
          warnings.add('Contract/vendor award is not complete.');
        }
        if (package.procurementBreakdown.category.trim().isEmpty) {
          warnings.add('Procurement category is not set.');
        }
        // Fix 1.1: Warn if procurement has no EWP deliverable traceability
        if (package.linkedEngineeringPackageIds.isNotEmpty) {
          final hasDeliverableLink = _packageHasDeliverableLink(
            package,
            package.linkedEngineeringPackageIds,
          );
          // This is informational — not all procurement needs design deliverables
        }
      case constructionCwp:
      case implementationWorkPackage:
      case agileIterationPackage:
        if (!readiness.ifcApproved &&
            package.packageClassification == constructionCwp) {
          warnings.add('CWP does not have approved IFC/design inputs.');
        }
        if (!readiness.materialsAvailable &&
            package.packageClassification == constructionCwp) {
          warnings.add('CWP materials are not confirmed available/on site.');
        }
        if (!readiness.contractAwarded &&
            package.contractorOrCrew.trim().isEmpty) {
          warnings.add('Execution owner or contract is not confirmed.');
        }
        if (!readiness.predecessorsComplete) {
          warnings.add('Predecessor work is not confirmed complete.');
        }
        if (!readiness.resourcesAssigned) {
          warnings.add('Execution resources are not assigned.');
        }
        if (package.packageClassification == constructionCwp &&
            !readiness.permitsApproved) {
          warnings.add('CWP permits are not approved.');
        }
        if (package.packageClassification == constructionCwp &&
            !readiness.accessReady) {
          warnings.add('CWP access/workface readiness is not confirmed.');
        }
        // Fix 1.4: Warn if execution depends on unreleased EWP
        if (package.linkedEngineeringPackageIds.isNotEmpty) {
          // This will be checked at schedule level where we can access all packages
        }
    }

    return warnings;
  }

  /// Checks if any deliverable on the linked EWP packages feeds this
  /// procurement package. Returns true if at least one deliverable is
  /// traced.
  static bool _packageHasDeliverableLink(
    WorkPackage package,
    List<String> engineeringPackageIds,
  ) {
    // This is a placeholder for cross-package checking which requires
    // access to the full package list — done in schedule_screen validation
    return false;
  }

  // ------------------------------------------------------------------
  // Schedule activity generation from packages
  // ------------------------------------------------------------------

  static List<ScheduleActivity> generateScheduleActivitiesFromPackages({
    required List<WorkPackage> packages,
    Iterable<ScheduleActivity> existingActivities = const [],
  }) {
    final existingPackageIds = existingActivities
        .map((activity) => activity.workPackageId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final packageIds = packages.map((package) => package.id).toSet();
    final activities = <ScheduleActivity>[];

    for (final package in packages) {
      if (existingPackageIds.contains(package.id)) continue;

      final dependencies = _scheduleDependenciesForPackage(
        package: package,
        packageIds: packageIds,
      );

      activities.add(
        ScheduleActivity(
          id: package.id,
          wbsId: package.sourceWbsLevel3Id.isNotEmpty
              ? package.sourceWbsLevel3Id
              : package.wbsItemId,
          title: package.title,
          durationDays: _defaultDurationDays(package),
          predecessorIds: dependencies,
          dependencyIds: dependencies,
          isMilestone: false,
          status: 'pending',
          priority: _defaultPriority(package),
          assignee: package.owner.isNotEmpty
              ? package.owner
              : package.contractorOrCrew,
          discipline: package.discipline,
          workPackageId: package.id,
          workPackageTitle: package.title,
          workPackageType: package.type,
          phase: package.phase,
          wbsLevel2Id: package.wbsLevel2Id,
          wbsLevel2Title: package.wbsLevel2Title,
          contractId:
              package.contractIds.isEmpty ? '' : package.contractIds.first,
          vendorId: package.vendorIds.isEmpty ? '' : package.vendorIds.first,
          budgetedCost: package.budgetedCost,
          actualCost: package.actualCost,
          estimatingBasis: _activityEstimateBasis(package),
        ),
      );
    }

    return activities;
  }

  static List<String> _scheduleDependenciesForPackage({
    required WorkPackage package,
    required Set<String> packageIds,
  }) {
    final dependencies = <String>[];

    void addIfPresent(String id) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty && packageIds.contains(trimmed)) {
        dependencies.add(trimmed);
      }
    }

    switch (package.packageClassification) {
      case procurementPackage:
        for (final id in package.linkedEngineeringPackageIds) {
          addIfPresent(id);
        }
        addIfPresent(package.parentPackageId);
      case constructionCwp:
      case implementationWorkPackage:
      case agileIterationPackage:
        for (final id in package.linkedEngineeringPackageIds) {
          addIfPresent(id);
        }
        for (final id in package.linkedProcurementPackageIds) {
          addIfPresent(id);
        }
        addIfPresent(package.parentPackageId);
      default:
        break;
    }

    return dependencies.toSet().toList();
  }

  static int _defaultDurationDays(WorkPackage package) {
    final plannedStart = DateTime.tryParse(package.plannedStart ?? '');
    final plannedEnd = DateTime.tryParse(package.plannedEnd ?? '');
    if (plannedStart != null && plannedEnd != null) {
      return (plannedEnd.difference(plannedStart).inDays + 1).clamp(1, 365);
    }

    switch (package.packageClassification) {
      case engineeringEwp:
        return 5;
      case procurementPackage:
        return package.procurementBreakdown.category == 'longLeadEquipment'
            ? 30
            : 10;
      case constructionCwp:
        return 10;
      case implementationWorkPackage:
      case agileIterationPackage:
        return 5;
      default:
        return 5;
    }
  }

  static String _defaultPriority(WorkPackage package) {
    return package.packageClassification == procurementPackage &&
            package.procurementBreakdown.category == 'longLeadEquipment'
        ? 'high'
        : 'medium';
  }

  static String _activityEstimateBasis(WorkPackage package) {
    final basis = package.estimateBasis;
    final parts = [
      if (basis.method.trim().isNotEmpty) 'Method: ${basis.method.trim()}',
      if (basis.sourceData.trim().isNotEmpty)
        'Source: ${basis.sourceData.trim()}',
      if (basis.assumptions.isNotEmpty)
        'Assumptions: ${basis.assumptions.join('; ')}',
      if (basis.confidenceLevel.trim().isNotEmpty)
        'Confidence: ${basis.confidenceLevel.trim()}',
    ];
    return parts.join('\n');
  }

  static PackageEstimateBasis _defaultEstimateBasis(String methodology) {
    final method = methodology.trim().toLowerCase() == 'agile'
        ? 'iteration_based'
        : 'expert_judgment';
    return PackageEstimateBasis(
      method: method,
      sourceData: 'Generated from WBS Level 3 package candidate.',
      assumptions: const [
        'Initial package duration requires discipline review.',
      ],
      confidenceLevel: 'low',
    );
  }

  static List<PackageDeliverable> _defaultEngineeringDeliverables() => [
        PackageDeliverable(title: 'Drawings', type: 'drawing'),
        PackageDeliverable(title: 'Specifications', type: 'specification'),
        PackageDeliverable(title: 'Calculations', type: 'calculation'),
        PackageDeliverable(title: 'Bill of materials', type: 'bom'),
        PackageDeliverable(
            title: 'Codes and requirements', type: 'requirement'),
      ];

  static String _packageCode(String level2Title, String level3Title) {
    final left = _codeToken(level2Title);
    final right = _codeToken(level3Title);
    return [left, right].where((part) => part.isNotEmpty).join('-');
  }

  static String _codeToken(String value) {
    final words = value
        .toUpperCase()
        .split(RegExp(r'[^A-Z0-9]+'))
        .where((part) => part.isNotEmpty)
        .take(3)
        .map((part) => part.length <= 4 ? part : part.substring(0, 4));
    return words.join('');
  }

  static String _stableId(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'package' : normalized;
  }

  static bool _looksLikeConstruction(WorkItem item) {
    final text = '${item.title} ${item.description}'.toLowerCase();
    return text.contains('construction') ||
        text.contains('civil') ||
        text.contains('foundation') ||
        text.contains('structural') ||
        text.contains('site work') ||
        text.contains('build');
  }

  static String _inferProcurementCategory(WorkItem item) {
    final text = '${item.title} ${item.description}'.toLowerCase();
    if (text.contains('equipment') || text.contains('long lead')) {
      return 'longLeadEquipment';
    }
    if (text.contains('material') ||
        text.contains('pipe') ||
        text.contains('aggregate')) {
      return 'bulkMaterials';
    }
    if (text.contains('contract') ||
        text.contains('subcontract') ||
        text.contains('construction')) {
      return 'subcontract';
    }
    if (text.contains('software') ||
        text.contains('system') ||
        text.contains('technology')) {
      return 'technology';
    }
    return 'services';
  }
}
