import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/theme.dart';

class WorkPackageDetailView extends StatelessWidget {
  const WorkPackageDetailView({
    super.key,
    required this.workPackage,
    required this.activities,
    this.onEdit,
  });

  final WorkPackage workPackage;
  final List<ScheduleActivity> activities;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final progress = workPackage.budgetedCost > 0
        ? (workPackage.actualCost / workPackage.budgetedCost).clamp(0.0, 1.0)
        : 0.0;

    return Dialog(
      child: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workPackage.title.isNotEmpty
                          ? workPackage.title
                          : 'Untitled Work Package',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (onEdit != null)
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                    ),
                ],
              ),
              if (workPackage.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  workPackage.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _DetailGrid(
                items: [
                  _DetailItem(
                      label: 'Type', value: _titleCase(workPackage.type)),
                  _DetailItem(
                      label: 'Phase', value: _titleCase(workPackage.phase)),
                  _DetailItem(
                      label: 'Status', value: _titleCase(workPackage.status)),
                  _DetailItem(
                      label: 'Owner',
                      value: workPackage.owner.isNotEmpty
                          ? workPackage.owner
                          : 'Unassigned'),
                  _DetailItem(
                      label: 'Discipline',
                      value: workPackage.discipline.isNotEmpty
                          ? workPackage.discipline
                          : 'N/A'),
                  _DetailItem(
                      label: 'WBS Level 2',
                      value: workPackage.wbsLevel2Title.isNotEmpty
                          ? workPackage.wbsLevel2Title
                          : 'Unassigned'),
                  _DetailItem(
                      label: 'Planned Start',
                      value: workPackage.plannedStart != null &&
                              workPackage.plannedStart!.isNotEmpty
                          ? workPackage.plannedStart!
                          : 'Not set'),
                  _DetailItem(
                      label: 'Planned End',
                      value: workPackage.plannedEnd != null &&
                              workPackage.plannedEnd!.isNotEmpty
                          ? workPackage.plannedEnd!
                          : 'Not set'),
                  _DetailItem(
                      label: 'Budgeted Cost',
                      value: '\$${workPackage.budgetedCost.toStringAsFixed(2)}'),
                  _DetailItem(
                      label: 'Actual Cost',
                      value: '\$${workPackage.actualCost.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Cost Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress > 1.0
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% of budget used',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              if (workPackage.acceptingCriteria.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Accepting Criteria',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  workPackage.acceptingCriteria,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
              if (activities.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Linked Activities (${activities.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                ...activities.map((a) => Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppSemanticColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _statusDotColor(a.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a.title.isNotEmpty
                                  ? a.title
                                  : 'Untitled Activity',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          Text(
                            '${(a.progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
              if (workPackage.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppSemanticColors.border),
                  ),
                  child: Text(
                    workPackage.notes,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleCase(String value) {
    final words = value.split('_');
    return words.map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  Color _statusDotColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'overdue':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.items});

  final List<_DetailItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: items
          .map((item) => SizedBox(
                width: (MediaQuery.sizeOf(context).width - 120) / 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;

  _DetailItem({required this.label, required this.value});
}
