import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/providers/app_content_provider.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/schedule_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Schedule timeline list tab renders without exceptions',
      (tester) async {
    final provider = ProjectDataProvider();
    provider.updateProjectData(
      ProjectDataModel(
        projectName: 'Schedule Smoke',
        wbsTree: const [],
        scheduleActivities: [
          ScheduleActivity(
            id: 'task-1',
            wbsId: '1.1',
            title: 'Foundation setup',
            durationDays: 10,
            status: 'pending',
            priority: 'high',
            assignee: 'Alice',
            progress: 0.35,
            startDate: '2026-04-01',
            dueDate: '2026-04-10',
            estimatedHours: 80,
            estimatingBasis: 'Crew productivity from prior civil works.',
          ),
          ScheduleActivity(
            id: 'task-2',
            wbsId: '1.2',
            title: 'API integration',
            durationDays: 15,
            predecessorIds: const ['task-1'],
            status: 'in_progress',
            priority: 'critical',
            assignee: 'Bob',
            progress: 0.55,
            startDate: '2026-04-11',
            dueDate: '2026-04-25',
            estimatedHours: 120,
          ),
        ],
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProjectDataProvider>.value(value: provider),
          ChangeNotifierProvider<AppContentProvider>(
            create: (_) => AppContentProvider(),
          ),
        ],
        child: MaterialApp(
          home: ProjectDataInherited(
            provider: provider,
            child: const ScheduleScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'List View'));
    await tester.pumpAndSettle();

    expect(find.text('Task Name'), findsOneWidget);
    expect(find.text('Estimate Basis'), findsOneWidget);
    expect(
        find.text('Crew productivity from prior civil works.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Schedule validation surfaces baseline and milestone sections',
      (tester) async {
    final provider = ProjectDataProvider();
    provider.updateProjectData(
      ProjectDataModel(
        projectName: 'Schedule Validation',
        keyMilestones: [
          Milestone(
            name: 'Execution Start',
            dueDate: '2026-04-02',
          ),
          Milestone(
            name: 'Commissioning Start',
            dueDate: '',
          ),
        ],
        scheduleActivities: [
          ScheduleActivity(
            id: 'task-1',
            wbsId: '1.1',
            title: 'Execution Start',
            durationDays: 6,
            status: 'pending',
            priority: 'high',
            assignee: 'Alice',
            progress: 0.2,
            startDate: '2026-04-03',
            dueDate: '2026-04-08',
            estimatedHours: 48,
            estimatingBasis: 'Historical execution rate.',
            isMilestone: true,
          ),
        ],
        scheduleBaselineActivities: [
          ScheduleActivity(
            id: 'task-1',
            wbsId: '1.1',
            title: 'Execution Start',
            durationDays: 4,
            status: 'pending',
            priority: 'high',
            assignee: 'Alice',
            progress: 0,
            startDate: '2026-04-01',
            dueDate: '2026-04-04',
            estimatedHours: 32,
            estimatingBasis: 'Baseline estimate.',
          ),
        ],
        scheduleBaselineDate: '2026-04-01T00:00:00.000',
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProjectDataProvider>.value(value: provider),
          ChangeNotifierProvider<AppContentProvider>(
            create: (_) => AppContentProvider(),
          ),
        ],
        child: MaterialApp(
          home: ProjectDataInherited(
            provider: provider,
            child: const ScheduleScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Validate').first);
    await tester.pumpAndSettle();

    expect(find.text('Schedule Validation'), findsOneWidget);
    expect(find.text('Baseline Variance'), findsWidgets);
    expect(find.text('Milestone Coverage'), findsOneWidget);
    expect(find.text('Commissioning Start'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Schedule milestone sync derives key milestones from network',
      (tester) async {
    final provider = ProjectDataProvider();
    provider.updateProjectData(
      ProjectDataModel(
        projectName: 'Milestone Sync',
        workPackages: [
          WorkPackage(
            id: 'ewp-1',
            title: 'Civil Engineering Work Package',
            packageClassification: 'engineeringEwp',
            type: 'design',
            phase: 'design',
            plannedEnd: '2026-04-10',
          ),
          WorkPackage(
            id: 'proc-1',
            title: 'Civil Procurement Package',
            packageClassification: 'procurementPackage',
            type: 'procurement',
            phase: 'execution',
            procurementBreakdown: PackageProcurementBreakdown(
              awardDate: '2026-04-12',
              deliveryDate: '2026-04-20',
            ),
          ),
          WorkPackage(
            id: 'cwp-1',
            title: 'Civil Construction Work Package',
            packageClassification: 'constructionCwp',
            type: 'construction',
            phase: 'execution',
            plannedEnd: '2026-05-05',
          ),
        ],
        scheduleActivities: [
          ScheduleActivity(
            id: 'launch-1',
            title: 'Commissioning Handover',
            phase: 'launch',
            startDate: '2026-05-06',
            dueDate: '2026-05-10',
          ),
        ],
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1440, 1024));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProjectDataProvider>.value(value: provider),
          ChangeNotifierProvider<AppContentProvider>(
            create: (_) => AppContentProvider(),
          ),
        ],
        child: MaterialApp(
          home: ProjectDataInherited(
            provider: provider,
            child: const ScheduleScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sync Milestones').first);
    await tester.pumpAndSettle();

    final milestoneNames =
        provider.projectData.keyMilestones.map((m) => m.name).toList();
    expect(milestoneNames, contains('Design Complete'));
    expect(milestoneNames, contains('Contract Awarded'));
    expect(milestoneNames, contains('Equipment Delivered'));
    expect(milestoneNames, contains('Construction Complete'));
    expect(milestoneNames, contains('Commissioning Start'));
  });
}
