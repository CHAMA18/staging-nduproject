import 'package:flutter/material.dart';
import 'package:ndu_project/models/deliverable_row.dart';
import 'package:ndu_project/models/recurring_deliverable_row.dart';
import 'package:ndu_project/models/status_report_row.dart';

/// Progress Tracking Dashboard with Live Status bar and Summary Cards
class ProgressTrackingDashboard extends StatelessWidget {
  const ProgressTrackingDashboard({
    super.key,
    required this.deliverables,
    required this.recurringDeliverables,
    required this.statusReports,
    required this.onDeliverablesChanged,
    required this.onRecurringChanged,
    required this.onStatusReportsChanged,
  });

  final List<DeliverableRow> deliverables;
  final List<RecurringDeliverableRow> recurringDeliverables;
  final List<StatusReportRow> statusReports;
  final ValueChanged<List<DeliverableRow>> onDeliverablesChanged;
  final ValueChanged<List<RecurringDeliverableRow>> onRecurringChanged;
  final ValueChanged<List<StatusReportRow>> onStatusReportsChanged;

  // Calculate summary metrics
  double get _completionPercentage {
    if (deliverables.isEmpty) return 0.0;
    final completed = deliverables.where((d) => d.status == 'Completed').length;
    return (completed / deliverables.length) * 100;
  }

  int get _atRiskCount {
    return deliverables.where((d) => d.isAtRisk || d.isOverdue).length;
  }

  int get _totalBlockers {
    return deliverables.where((d) => d.blockers.trim().isNotEmpty).length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Status Bar
        _buildLiveStatusBar(),
        const SizedBox(height: 24),
        // Summary Cards
        _buildSummaryCards(),
      ],
    );
  }

  Widget _buildLiveStatusBar() {
    final completion = _completionPercentage;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Live Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                '${completion.toStringAsFixed(0)}% Complete',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor: AlwaysStoppedAnimation<Color>(
                completion >= 80
                    ? const Color(0xFF10B981)
                    : completion >= 50
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Completion %',
            value: '${_completionPercentage.toStringAsFixed(0)}%',
            icon: Icons.check_circle_outline,
            color: _completionPercentage >= 80
                ? const Color(0xFF10B981)
                : _completionPercentage >= 50
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'At Risk',
            value: '$_atRiskCount items',
            icon: Icons.warning_amber,
            color: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Current Blockers',
            value: '$_totalBlockers',
            icon: Icons.block,
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
