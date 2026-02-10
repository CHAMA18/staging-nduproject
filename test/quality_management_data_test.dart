import 'package:flutter_test/flutter_test.dart';
import 'package:ndu_project/models/project_data_model.dart';

void main() {
  group('QualityManagementData migration', () {
    test('derives objectives/workflow controls from legacy fields', () {
      final legacy = {
        'qualityPlan': 'Legacy quality plan',
        'targets': [
          {
            'id': 't-1',
            'name': 'Defect leakage',
            'metric': 'Leakage rate',
            'target': '<5%',
            'current': '8%',
            'status': 2,
          }
        ],
        'qaTechniques': [
          {
            'id': 'qa-1',
            'name': 'Peer Review',
            'description': 'Review major outputs',
            'frequency': 'Weekly',
            'standards': 'ISO 9001',
          }
        ],
        'qcTechniques': [
          {
            'id': 'qc-1',
            'name': 'Inspection',
            'description': 'Inspect completed artifacts',
            'frequency': 'Bi-weekly',
          }
        ],
      };

      final parsed = QualityManagementData.fromJson(legacy);

      expect(parsed.qualityPlan, 'Legacy quality plan');
      expect(parsed.objectives, hasLength(1));
      expect(parsed.objectives.first.title, 'Defect leakage');
      expect(parsed.objectives.first.successMetric, 'Leakage rate');
      expect(parsed.objectives.first.status, 'Off Track');

      expect(parsed.workflowControls, hasLength(2));
      expect(
        parsed.workflowControls
            .where((entry) => entry.type == QualityWorkflowType.qa)
            .length,
        1,
      );
      expect(
        parsed.workflowControls
            .where((entry) => entry.type == QualityWorkflowType.qc)
            .length,
        1,
      );

      expect(parsed.dashboardConfig.targetTimeToResolutionDays, 15);
      expect(parsed.computedSnapshot, isNull);
    });

    test('normalizes task/audit/corrective enum strings from json', () {
      final raw = {
        'qaTaskLog': [
          {
            'id': 'task-1',
            'task': 'Check requirements matrix',
            'percentComplete': '60%',
            'responsible': 'QA Lead',
            'startDate': '2026-01-01',
            'endDate': '2026-01-02',
            'durationDays': '1',
            'status': 'in Progress',
            'priority': 'CRITICAL',
            'comments': '',
            'resolvedDate': '',
          }
        ],
        'auditPlan': [
          {
            'id': 'audit-1',
            'title': 'Gate audit',
            'scope': 'Scope',
            'plannedDate': '2026-01-03',
            'completedDate': '2026-01-04',
            'owner': 'Auditor',
            'result': 'FAILED',
            'findings': '',
            'notes': '',
          }
        ],
        'correctiveActions': [
          {
            'id': 'ca-1',
            'auditEntryId': 'audit-1',
            'title': 'Fix traceability gaps',
            'rootCause': 'Requirements not linked',
            'action': 'Backfill trace matrix links',
            'owner': 'PM',
            'dueDate': '2026-01-15',
            'status': 'in-progress',
            'createdAt': '2026-01-05',
            'closedAt': '',
            'verificationNotes': '',
          }
        ],
      };

      final parsed = QualityManagementData.fromJson(raw);

      expect(parsed.qaTaskLog, hasLength(1));
      expect(parsed.qaTaskLog.first.status, QualityTaskStatus.inProgress);
      expect(parsed.qaTaskLog.first.priority, QualityTaskPriority.critical);
      expect(parsed.qaTaskLog.first.percentComplete, 60);

      expect(parsed.auditPlan, hasLength(1));
      expect(parsed.auditPlan.first.result, AuditResultStatus.fail);

      expect(parsed.correctiveActions, hasLength(1));
      expect(
        parsed.correctiveActions.first.status,
        CorrectiveActionStatus.inProgress,
      );
    });
  });
}
