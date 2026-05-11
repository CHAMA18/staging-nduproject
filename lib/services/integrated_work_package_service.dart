import 'package:ndu_project/models/project_data_model.dart';

class IntegratedWorkPackageService {
  IntegratedWorkPackageService._();

  static const String engineeringEwp = 'engineeringEwp';
  static const String procurementPackage = 'procurementPackage';
  static const String constructionCwp = 'constructionCwp';
  static const String implementationWorkPackage = 'implementationWorkPackage';
  static const String agileIterationPackage = 'agileIterationPackage';

  static List<WorkPackage> generatePackageChainsFromWbs({
    required List<WorkItem> wbsTree,
    required String methodology,
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
              title: '${level3.title} Engineering Work Package',
              description: level3.description,
              type: 'design',
              phase: 'design',
              discipline: level3.framework,
              releaseStatus: 'draft',
              deliverables: _defaultEngineeringDeliverables(),
              estimateBasis: _defaultEstimateBasis(methodology),
            ),
          );

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
              title: '${level3.title} Procurement Package',
              description: level3.description,
              type: 'procurement',
              phase: 'execution',
              discipline: level3.framework,
              releaseStatus: 'draft',
              procurementBreakdown: PackageProcurementBreakdown(
                category: _inferProcurementCategory(level3),
                scopeDefinition: level3.description,
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
    }

    return warnings;
  }

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
