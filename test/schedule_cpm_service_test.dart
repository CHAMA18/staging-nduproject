import 'package:flutter_test/flutter_test.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/schedule_cpm_service.dart';

void main() {
  group('ScheduleCpmService', () {
    test('calculates critical path and float across parallel paths', () {
      final result = ScheduleCpmService.calculate(
        projectStart: DateTime(2026, 1, 1),
        activities: [
          ScheduleActivity(id: 'a', title: 'A', durationDays: 5),
          ScheduleActivity(
            id: 'b',
            title: 'B',
            durationDays: 3,
            predecessorIds: const ['a'],
          ),
          ScheduleActivity(
            id: 'c',
            title: 'C',
            durationDays: 7,
            predecessorIds: const ['a'],
          ),
          ScheduleActivity(
            id: 'd',
            title: 'D',
            durationDays: 2,
            predecessorIds: const ['b', 'c'],
          ),
        ],
      );

      expect(result.projectDurationDays, 14);
      expect(result.criticalPathIds, containsAll(['a', 'c', 'd']));
      expect(result.activitiesById['a']!.totalFloat, 0);
      expect(result.activitiesById['b']!.totalFloat, 4);
      expect(result.activitiesById['c']!.totalFloat, 0);
      expect(result.activitiesById['d']!.totalFloat, 0);
      expect(result.activitiesById['d']!.earlyStartOffsetDays, 12);
    });

    test('combines predecessorIds and dependencyIds', () {
      final result = ScheduleCpmService.calculate(
        projectStart: DateTime(2026, 1, 1),
        activities: [
          ScheduleActivity(id: 'design', durationDays: 2),
          ScheduleActivity(id: 'permit', durationDays: 5),
          ScheduleActivity(
            id: 'install',
            durationDays: 3,
            predecessorIds: const ['design'],
            dependencyIds: const ['permit'],
          ),
        ],
      );

      expect(result.activitiesById['install']!.dependencyIds,
          containsAll(['design', 'permit']));
      expect(result.activitiesById['install']!.earlyStartOffsetDays, 5);
      expect(result.projectDurationDays, 8);
    });

    test('applies computed dates, float, and critical path to activities', () {
      final applied = ScheduleCpmService.applyToActivities(
        projectStart: DateTime(2026, 1, 1),
        activities: [
          ScheduleActivity(id: 'a', durationDays: 5),
          ScheduleActivity(
            id: 'b',
            durationDays: 3,
            predecessorIds: const ['a'],
          ),
        ],
      );

      final a = applied.firstWhere((activity) => activity.id == 'a');
      final b = applied.firstWhere((activity) => activity.id == 'b');

      expect(a.startDate, '2026-01-01');
      expect(a.dueDate, '2026-01-05');
      expect(a.isCriticalPath, isTrue);
      expect(a.totalFloat, 0);
      expect(b.startDate, '2026-01-06');
      expect(b.dueDate, '2026-01-08');
      expect(b.isCriticalPath, isTrue);
      expect(b.dependencyIds, ['a']);
    });

    test('reports missing dependencies without throwing', () {
      final result = ScheduleCpmService.calculate(
        projectStart: DateTime(2026, 1, 1),
        activities: [
          ScheduleActivity(
            id: 'a',
            durationDays: 1,
            predecessorIds: const ['missing'],
          ),
        ],
      );

      expect(result.diagnostics, hasLength(1));
      expect(
          result.diagnostics.single.type, CpmDiagnosticType.missingDependency);
      expect(result.activitiesById['a']!.earlyStartOffsetDays, 0);
    });

    test('reports circular dependencies without throwing', () {
      final result = ScheduleCpmService.calculate(
        projectStart: DateTime(2026, 1, 1),
        activities: [
          ScheduleActivity(
            id: 'a',
            durationDays: 1,
            predecessorIds: const ['b'],
          ),
          ScheduleActivity(
            id: 'b',
            durationDays: 1,
            predecessorIds: const ['a'],
          ),
        ],
      );

      expect(
        result.diagnostics.map((diagnostic) => diagnostic.type),
        contains(CpmDiagnosticType.cycle),
      );
      expect(result.activitiesById.keys, containsAll(['a', 'b']));
    });
  });
}
