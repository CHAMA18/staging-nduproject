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

    await tester.tap(find.widgetWithText(ChoiceChip, 'List'));
    await tester.pumpAndSettle();

    expect(find.text('Task Name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
