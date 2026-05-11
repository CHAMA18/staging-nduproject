import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/integrated_work_package_service.dart';
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
    final readinessWarnings =
        IntegratedWorkPackageService.validateReadiness(workPackage);

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
                      label: 'Classification',
                      value: workPackage.packageClassification.isNotEmpty
                          ? _classificationLabel(
                              workPackage.packageClassification)
                          : 'Unclassified'),
                  _DetailItem(
                      label: 'Package Code',
                      value: workPackage.packageCode.isNotEmpty
                          ? workPackage.packageCode
                          : 'Not set'),
                  _DetailItem(
                      label: 'Release Status',
                      value: _titleCase(workPackage.releaseStatus)),
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
                      label: 'WBS Level 3',
                      value: workPackage.sourceWbsLevel3Title.isNotEmpty
                          ? workPackage.sourceWbsLevel3Title
                          : 'Unassigned'),
                  _DetailItem(
                      label: 'Area / System',
                      value: workPackage.areaOrSystem.isNotEmpty
                          ? workPackage.areaOrSystem
                          : 'Not set'),
                  _DetailItem(
                      label: 'Contractor / Crew',
                      value: workPackage.contractorOrCrew.isNotEmpty
                          ? workPackage.contractorOrCrew
                          : 'Not set'),
                  _DetailItem(
                      label: 'Contract IDs',
                      value: workPackage.contractIds.isNotEmpty
                          ? workPackage.contractIds.join(', ')
                          : 'Not set'),
                  _DetailItem(
                      label: 'Vendor IDs',
                      value: workPackage.vendorIds.isNotEmpty
                          ? workPackage.vendorIds.join(', ')
                          : 'Not set'),
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
                      value:
                          '\$${workPackage.budgetedCost.toStringAsFixed(2)}'),
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
              const SizedBox(height: 16),
              _WarningPanel(warnings: readinessWarnings),
              const SizedBox(height: 16),
              _PackageSection(
                title: 'Readiness',
                child: _ReadinessSummary(readiness: workPackage.readiness),
              ),
              const SizedBox(height: 16),
              _PackageSection(
                title: 'Estimate Basis',
                child: _EstimateBasisSummary(basis: workPackage.estimateBasis),
              ),
              if (workPackage.packageClassification ==
                      IntegratedWorkPackageService.procurementPackage ||
                  workPackage.procurementBreakdown.category.isNotEmpty ||
                  workPackage
                      .procurementBreakdown.scopeDefinition.isNotEmpty) ...[
                const SizedBox(height: 16),
                _PackageSection(
                  title: 'Procurement Breakdown',
                  child: _ProcurementSummary(
                    procurement: workPackage.procurementBreakdown,
                  ),
                ),
              ],
              if (workPackage.deliverables.isNotEmpty) ...[
                const SizedBox(height: 16),
                _PackageSection(
                  title: 'Package Deliverables',
                  child: Column(
                    children: workPackage.deliverables
                        .map((item) => _InlineRow(
                              label: item.title,
                              value: [
                                item.type,
                                item.status,
                                item.reference,
                              ].where((v) => v.trim().isNotEmpty).join(' | '),
                            ))
                        .toList(),
                  ),
                ),
              ],
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

  String _classificationLabel(String value) {
    switch (value) {
      case IntegratedWorkPackageService.engineeringEwp:
        return 'Engineering Work Package';
      case IntegratedWorkPackageService.procurementPackage:
        return 'Procurement Package';
      case IntegratedWorkPackageService.constructionCwp:
        return 'Construction Work Package';
      case IntegratedWorkPackageService.implementationWorkPackage:
        return 'Implementation Work Package';
      case IntegratedWorkPackageService.agileIterationPackage:
        return 'Agile Iteration Package';
      default:
        return _titleCase(value);
    }
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

class _WarningPanel extends StatelessWidget {
  const _WarningPanel({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: const Text(
          'No readiness warnings.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF047857),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF97316)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${warnings.length} readiness warning${warnings.length == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 6),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '- $warning',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7C2D12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageSection extends StatelessWidget {
  const _PackageSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ReadinessSummary extends StatelessWidget {
  const _ReadinessSummary({required this.readiness});

  final PackageReadinessChecklist readiness;

  @override
  Widget build(BuildContext context) {
    final rows = {
      'Requirements traced': readiness.requirementsTraced,
      'Drawings complete': readiness.drawingsComplete,
      'Specifications complete': readiness.specificationsComplete,
      'BOM complete': readiness.billOfMaterialsComplete,
      'Design review complete': readiness.designReviewComplete,
      'IFC/design approved': readiness.ifcApproved,
      'Procurement scope defined': readiness.procurementScopeDefined,
      'RFQ/RFP issued': readiness.rfqIssued,
      'Bids evaluated': readiness.bidsEvaluated,
      'Contract awarded': readiness.contractAwarded,
      'Materials available': readiness.materialsAvailable,
      'Permits approved': readiness.permitsApproved,
      'Access ready': readiness.accessReady,
      'Predecessors complete': readiness.predecessorsComplete,
      'Resources assigned': readiness.resourcesAssigned,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: rows.entries.map((entry) {
        final complete = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: complete ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  complete ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
            ),
          ),
          child: Text(
            '${complete ? 'OK' : 'OPEN'} ${entry.key}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color:
                  complete ? const Color(0xFF047857) : const Color(0xFF4B5563),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EstimateBasisSummary extends StatelessWidget {
  const _EstimateBasisSummary({required this.basis});

  final PackageEstimateBasis basis;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InlineRow(label: 'Method', value: _fallback(basis.method)),
        _InlineRow(label: 'Source data', value: _fallback(basis.sourceData)),
        _InlineRow(
          label: 'Confidence',
          value: _fallback(basis.confidenceLevel),
        ),
        _InlineRow(
          label: 'Assumptions',
          value: basis.assumptions.isEmpty
              ? 'Not documented'
              : basis.assumptions.join('; '),
        ),
      ],
    );
  }
}

class _ProcurementSummary extends StatelessWidget {
  const _ProcurementSummary({required this.procurement});

  final PackageProcurementBreakdown procurement;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InlineRow(label: 'Category', value: _fallback(procurement.category)),
        _InlineRow(
          label: 'Lead time',
          value: procurement.leadTimeDays > 0
              ? '${procurement.leadTimeDays} days'
              : 'Not set',
        ),
        _InlineRow(
          label: 'Scope',
          value: _fallback(procurement.scopeDefinition),
        ),
        _InlineRow(
          label: 'Activities',
          value: procurement.activities.isEmpty
              ? 'Not set'
              : procurement.activities.join(', '),
        ),
      ],
    );
  }
}

class _InlineRow extends StatelessWidget {
  const _InlineRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _fallback(String value) => value.trim().isEmpty ? 'Not set' : value;

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
