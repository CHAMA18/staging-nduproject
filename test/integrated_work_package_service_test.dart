import 'package:flutter_test/flutter_test.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/integrated_work_package_service.dart';

void main() {
  group('WorkPackage integrated package fields', () {
    test('round trips package readiness, estimate basis, and procurement data',
        () {
      final package = WorkPackage(
        id: 'wp-1',
        wbsLevel2Id: 'civil',
        wbsLevel2Title: 'Civil works',
        sourceWbsLevel3Id: 'foundations',
        sourceWbsLevel3Title: 'Foundations',
        packageCode: 'CIV-FOUN-EWP',
        packageClassification: IntegratedWorkPackageService.engineeringEwp,
        linkedProcurementPackageIds: const ['proc-1'],
        deliverables: [
          PackageDeliverable(
            id: 'drawing-1',
            title: 'Foundation drawings',
            type: 'drawing',
            status: 'complete',
          ),
        ],
        readiness: PackageReadinessChecklist(
          requirementsTraced: true,
          drawingsComplete: true,
          specificationsComplete: true,
          billOfMaterialsComplete: true,
          designReviewComplete: true,
          ifcApproved: true,
        ),
        estimateBasis: PackageEstimateBasis(
          method: 'historical_data',
          sourceData: 'Comparable foundation package',
          assumptions: const ['Single civil crew'],
          confidenceLevel: 'medium',
        ),
        procurementBreakdown: PackageProcurementBreakdown(
          category: 'bulkMaterials',
          leadTimeDays: 21,
          activities: const ['rfq_rfp', 'delivery'],
        ),
        readinessWarnings: const ['Example warning'],
      );

      final parsed = WorkPackage.fromJson(package.toJson());

      expect(parsed.packageCode, 'CIV-FOUN-EWP');
      expect(parsed.packageClassification,
          IntegratedWorkPackageService.engineeringEwp);
      expect(parsed.sourceWbsLevel3Id, 'foundations');
      expect(parsed.linkedProcurementPackageIds, ['proc-1']);
      expect(parsed.deliverables.single.title, 'Foundation drawings');
      expect(parsed.readiness.ifcApproved, isTrue);
      expect(parsed.estimateBasis.hasMinimumBasis, isTrue);
      expect(parsed.procurementBreakdown.category, 'bulkMaterials');
      expect(parsed.readinessWarnings, ['Example warning']);
    });
  });

  group('IntegratedWorkPackageService', () {
    test('generates EWP, procurement, and CWP chains from Level 3 WBS nodes',
        () {
      final wbsTree = [
        WorkItem(
          id: 'facility',
          title: 'Facility',
          children: [
            WorkItem(
              id: 'civil',
              title: 'Civil works',
              children: [
                WorkItem(
                  id: 'foundations',
                  title: 'Foundation package',
                  description: 'Foundation construction scope',
                ),
              ],
            ),
          ],
        ),
      ];

      final packages =
          IntegratedWorkPackageService.generatePackageChainsFromWbs(
        wbsTree: wbsTree,
        methodology: 'Waterfall',
      );

      expect(packages, hasLength(3));
      expect(
        packages.map((package) => package.packageClassification),
        containsAll([
          IntegratedWorkPackageService.engineeringEwp,
          IntegratedWorkPackageService.procurementPackage,
          IntegratedWorkPackageService.constructionCwp,
        ]),
      );

      final ewp = packages.firstWhere((package) =>
          package.packageClassification ==
          IntegratedWorkPackageService.engineeringEwp);
      final procurement = packages.firstWhere((package) =>
          package.packageClassification ==
          IntegratedWorkPackageService.procurementPackage);
      final cwp = packages.firstWhere((package) =>
          package.packageClassification ==
          IntegratedWorkPackageService.constructionCwp);

      expect(ewp.sourceWbsLevel3Id, 'foundations');
      expect(ewp.wbsLevel2Id, 'civil');
      expect(ewp.linkedProcurementPackageIds, [procurement.id]);
      expect(procurement.linkedExecutionPackageIds, [cwp.id]);
      expect(cwp.linkedEngineeringPackageIds, [ewp.id]);
      expect(cwp.areaOrSystem, 'Civil works');
      expect(cwp.readinessWarnings, isNotEmpty);
    });

    test('generates agile iteration packages for agile methodology', () {
      final wbsTree = [
        WorkItem(
          id: 'platform',
          title: 'Platform',
          children: [
            WorkItem(
              id: 'app',
              title: 'Application',
              children: [
                WorkItem(
                  id: 'checkout',
                  title: 'Checkout flow',
                  description: 'Software implementation scope',
                ),
              ],
            ),
          ],
        ),
      ];

      final packages =
          IntegratedWorkPackageService.generatePackageChainsFromWbs(
        wbsTree: wbsTree,
        methodology: 'Agile',
      );

      expect(
        packages.map((package) => package.packageClassification),
        contains(IntegratedWorkPackageService.agileIterationPackage),
      );
      expect(
        packages.last.title,
        contains('Agile Iteration Package'),
      );
    });

    test('readiness validation warns instead of blocking incomplete packages',
        () {
      final warnings = IntegratedWorkPackageService.validateReadiness(
        WorkPackage(
          id: 'iwp-1',
          packageClassification:
              IntegratedWorkPackageService.implementationWorkPackage,
          sourceWbsLevel3Id: 'config',
          wbsLevel2Id: 'system',
          estimateBasis: PackageEstimateBasis(
            method: 'expert_judgment',
            sourceData: 'Team estimate',
            assumptions: const ['Two iterations'],
          ),
        ),
      );

      expect(
          warnings, contains('Execution owner or contract is not confirmed.'));
      expect(warnings, contains('Execution resources are not assigned.'));
    });

    test('generates integrated schedule network activities from packages', () {
      final packages =
          IntegratedWorkPackageService.generatePackageChainsFromWbs(
        wbsTree: [
          WorkItem(
            id: 'facility',
            title: 'Facility',
            children: [
              WorkItem(
                id: 'civil',
                title: 'Civil works',
                children: [
                  WorkItem(
                    id: 'foundations',
                    title: 'Foundation package',
                    description: 'Foundation construction scope',
                  ),
                ],
              ),
            ],
          ),
        ],
        methodology: 'Waterfall',
      );

      final activities =
          IntegratedWorkPackageService.generateScheduleActivitiesFromPackages(
        packages: packages,
      );

      final ewp = packages.firstWhere((package) =>
          package.packageClassification ==
          IntegratedWorkPackageService.engineeringEwp);
      final procurement = packages.firstWhere((package) =>
          package.packageClassification ==
          IntegratedWorkPackageService.procurementPackage);
      final cwp = packages.firstWhere((package) =>
          package.packageClassification ==
          IntegratedWorkPackageService.constructionCwp);

      final ewpActivity =
          activities.firstWhere((activity) => activity.id == ewp.id);
      final procurementActivity =
          activities.firstWhere((activity) => activity.id == procurement.id);
      final cwpActivity =
          activities.firstWhere((activity) => activity.id == cwp.id);

      expect(activities, hasLength(3));
      expect(ewpActivity.predecessorIds, isEmpty);
      expect(procurementActivity.predecessorIds, [ewp.id]);
      expect(cwpActivity.predecessorIds, containsAll([ewp.id, procurement.id]));
      expect(cwpActivity.workPackageId, cwp.id);
      expect(cwpActivity.workPackageType, 'construction');
      expect(cwpActivity.estimatingBasis, contains('Method: expert_judgment'));
    });

    test('skips schedule activities for packages already represented', () {
      final package = WorkPackage(
        id: 'existing-ewp',
        title: 'Existing EWP',
        packageClassification: IntegratedWorkPackageService.engineeringEwp,
      );

      final activities =
          IntegratedWorkPackageService.generateScheduleActivitiesFromPackages(
        packages: [package],
        existingActivities: [
          ScheduleActivity(
            id: 'activity-1',
            workPackageId: 'existing-ewp',
          ),
        ],
      );

      expect(activities, isEmpty);
    });

    test('carries contract and vendor references into generated activities',
        () {
      final activity =
          IntegratedWorkPackageService.generateScheduleActivitiesFromPackages(
        packages: [
          WorkPackage(
            id: 'proc-1',
            title: 'Procurement Package',
            packageClassification:
                IntegratedWorkPackageService.procurementPackage,
            type: 'procurement',
            phase: 'execution',
            contractIds: const ['contract-42'],
            vendorIds: const ['vendor-acme'],
            estimateBasis: PackageEstimateBasis(
              method: 'historical_data',
              sourceData: 'Prior package',
              assumptions: const ['Lead time benchmark'],
            ),
          ),
        ],
      ).single;

      expect(activity.contractId, 'contract-42');
      expect(activity.vendorId, 'vendor-acme');
      expect(activity.workPackageType, 'procurement');
    });
  });
}
