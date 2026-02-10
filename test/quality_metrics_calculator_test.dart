import 'package:flutter_test/flutter_test.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/utils/quality_metrics_calculator.dart';

void main() {
  group('QualityMetricsCalculator', () {
    test('computes KPI snapshot from QA/QC logs, audits, and config', () {
      final quality = QualityManagementData.empty().copyWith(
        dashboardConfig: const QualityDashboardConfig(
          targetTimeToResolutionDays: 12,
          allowManualMetricsOverride: true,
          maxTrendPoints: 12,
        ),
        qaTaskLog: [
          QualityTaskEntry(
            id: 'qa-1',
            task: 'Peer review requirement pack',
            percentComplete: 100,
            responsible: 'QA Lead',
            startDate: '2026-01-01',
            endDate: '2026-01-05',
            durationDays: 4,
            status: QualityTaskStatus.complete,
            priority: QualityTaskPriority.minimal,
            comments: '',
            resolvedDate: '2026-01-05',
          ),
        ],
        qcTaskLog: [
          QualityTaskEntry(
            id: 'qc-1',
            task: 'Inspect acceptance criteria coverage',
            percentComplete: 100,
            responsible: 'QC Lead',
            startDate: '2026-01-10',
            endDate: '2026-01-15',
            durationDays: null,
            status: QualityTaskStatus.complete,
            priority: QualityTaskPriority.moderate,
            comments: '',
            resolvedDate: '2026-01-15',
          ),
          QualityTaskEntry(
            id: 'qc-2',
            task: 'Control-check traceability',
            percentComplete: 20,
            responsible: 'QC Lead',
            startDate: '2026-02-03',
            endDate: '2026-02-07',
            durationDays: null,
            status: QualityTaskStatus.blocked,
            priority: QualityTaskPriority.critical,
            comments: '',
            resolvedDate: null,
          ),
        ],
        auditPlan: [
          QualityAuditEntry(
            id: 'a-1',
            title: 'Phase gate audit',
            scope: 'Gate quality controls',
            plannedDate: '2026-02-01',
            completedDate: '2026-02-06',
            owner: 'QA Manager',
            result: AuditResultStatus.fail,
            findings: 'Missing sign-off evidence',
            notes: '',
          ),
          QualityAuditEntry(
            id: 'a-2',
            title: 'Documentation audit',
            scope: 'Procedure docs',
            plannedDate: '2026-02-20',
            completedDate: '',
            owner: 'QA Manager',
            result: AuditResultStatus.pending,
            findings: '',
            notes: '',
          ),
        ],
      );

      final snapshot = QualityMetricsCalculator.computeSnapshot(
        quality,
        now: DateTime(2026, 2, 10),
      );

      expect(snapshot.averageTimeToResolutionDays, 4.5);
      expect(snapshot.targetTimeToResolutionDays, 12);
      expect(snapshot.averageTaskCompletionPercent, closeTo(73.33, 0.001));
      expect(snapshot.plannedAuditsCompletionPercent, 50);

      expect(snapshot.statusTallies['complete'], 2);
      expect(snapshot.statusTallies['blocked'], 1);
      expect(snapshot.priorityTallies['minimal'], 1);
      expect(snapshot.priorityTallies['moderate'], 1);
      expect(snapshot.priorityTallies['critical'], 1);

      expect(snapshot.defectTrendData, hasLength(6));
      expect(snapshot.satisfactionTrendData, hasLength(6));
      expect(snapshot.defectTrendData.last, 2);
      expect(snapshot.satisfactionTrendData.last, 1);
    });

    test('uses manual trend data when provided in quality metrics', () {
      final quality = QualityManagementData.empty().copyWith(
        metrics: QualityMetrics(
          defectDensity: MetricValue.empty(),
          customerSatisfaction: MetricValue.empty(),
          onTimeDelivery: MetricValue.empty(),
          defectTrendData: const [9, 8, 7],
          satisfactionTrendData: const [1, 2, 3],
        ),
      );

      final snapshot = QualityMetricsCalculator.computeSnapshot(
        quality,
        now: DateTime(2026, 2, 10),
      );

      expect(snapshot.defectTrendData, [9, 8, 7]);
      expect(snapshot.satisfactionTrendData, [1, 2, 3]);
    });
  });
}
