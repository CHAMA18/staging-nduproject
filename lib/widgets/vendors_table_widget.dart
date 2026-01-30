import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ndu_project/services/vendor_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/widgets/inline_editable_text.dart';

/// Custom Vendors Table with inline editing, CRUD actions, and AI capabilities
class VendorsTableWidget extends StatelessWidget {
  const VendorsTableWidget({
    super.key,
    required this.vendors,
    required this.onUpdated,
    required this.onDeleted,
  });

  final List<VendorModel> vendors;
  final ValueChanged<VendorModel> onUpdated;
  final ValueChanged<VendorModel> onDeleted;

  @override
  Widget build(BuildContext context) {
    if (vendors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No vendors found.',
              style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth > 0 ? constraints.maxWidth : 900,
              ),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columnSpacing: 24,
                horizontalMargin: 20,
                headingRowHeight: 56,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 80,
                columns: const [
                  DataColumn(
                    label: Text('Vendor Name',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                  ),
                  DataColumn(
                    label: Text('Category',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                  ),
                  DataColumn(
                    label: Text('Criticality',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                  ),
                  DataColumn(
                    label: Text('SLA Performance',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                  ),
                  DataColumn(
                    label: Text('Lead Time',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                  ),
                  DataColumn(
                    label: Text('Actions',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                  ),
                ],
                rows: vendors.map((vendor) {
                  return DataRow(
                    cells: [
                      DataCell(
                        _VendorRowWidget(
                          vendor: vendor,
                          onUpdated: onUpdated,
                          onDeleted: onDeleted,
                          column: 'name',
                        ),
                      ),
                      DataCell(
                        _VendorRowWidget(
                          vendor: vendor,
                          onUpdated: onUpdated,
                          onDeleted: onDeleted,
                          column: 'category',
                        ),
                      ),
                      DataCell(
                        _VendorRowWidget(
                          vendor: vendor,
                          onUpdated: onUpdated,
                          onDeleted: onDeleted,
                          column: 'criticality',
                        ),
                      ),
                      DataCell(
                        _VendorRowWidget(
                          vendor: vendor,
                          onUpdated: onUpdated,
                          onDeleted: onDeleted,
                          column: 'sla',
                        ),
                      ),
                      DataCell(
                        _VendorRowWidget(
                          vendor: vendor,
                          onUpdated: onUpdated,
                          onDeleted: onDeleted,
                          column: 'leadTime',
                        ),
                      ),
                      DataCell(
                        _VendorRowWidget(
                          vendor: vendor,
                          onUpdated: onUpdated,
                          onDeleted: onDeleted,
                          column: 'actions',
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VendorRowWidget extends StatefulWidget {
  const _VendorRowWidget({
    required this.vendor,
    required this.onUpdated,
    required this.onDeleted,
    required this.column,
  });

  final VendorModel vendor;
  final ValueChanged<VendorModel> onUpdated;
  final ValueChanged<VendorModel> onDeleted;
  final String
      column; // 'name', 'category', 'criticality', 'sla', 'leadTime', 'actions'

  @override
  State<_VendorRowWidget> createState() => _VendorRowWidgetState();
}

class _VendorRowWidgetState extends State<_VendorRowWidget> {
  late VendorModel _vendor;
  VendorModel? _previousState;
  bool _isHovering = false;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _vendor = widget.vendor;
  }

  @override
  void didUpdateWidget(_VendorRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vendor != widget.vendor) {
      _vendor = widget.vendor;
    }
  }

  Future<void> _updateVendor(VendorModel updated) async {
    setState(() {
      _previousState = _vendor;
      _vendor = updated;
    });

    // Save via VendorService
    try {
      await VendorService.updateVendor(
        projectId: updated.projectId,
        vendorId: updated.id,
        name: updated.name,
        category: updated.category,
        criticality: updated.criticality,
        sla: updated.sla,
        slaPerformance: updated.slaPerformance,
        leadTime: updated.leadTime,
        requiredDeliverables: updated.requiredDeliverables,
        rating: updated.rating,
        status: updated.status,
        nextReview: updated.nextReview,
        contractId: updated.contractId,
        onTimeDelivery: updated.onTimeDelivery,
        incidentResponse: updated.incidentResponse,
        qualityScore: updated.qualityScore,
        costAdherence: updated.costAdherence,
        notes: updated.notes,
      );
    } catch (e) {
      debugPrint('Error updating vendor: $e');
    }

    widget.onUpdated(updated);
  }

  Future<void> _undo() async {
    if (_previousState != null) {
      final previous = _previousState!;
      setState(() {
        _vendor = previous;
        _previousState = null;
      });
      await _updateVendor(previous);
    }
  }

  Future<void> _regenerateSLATerms() async {
    if (_isRegenerating) return;
    setState(() => _isRegenerating = true);

    try {
      final provider = ProjectDataInherited.maybeOf(context);
      if (provider == null) return;

      final contextText = ProjectDataHelper.buildExecutivePlanContext(
        provider.projectData,
        sectionLabel: 'Vendor Tracking',
      );

      final ai = OpenAiServiceSecure();
      final slaTerms = await ai.generateVendorSLATerms(
        context: contextText,
        vendorCategory: _vendor.category,
      );

      final updated = VendorModel(
        id: _vendor.id,
        projectId: _vendor.projectId,
        name: _vendor.name,
        category: _vendor.category,
        criticality: _vendor.criticality,
        sla: _vendor.sla,
        slaPerformance: _vendor.slaPerformance,
        leadTime: _vendor.leadTime,
        requiredDeliverables: slaTerms,
        rating: _vendor.rating,
        status: _vendor.status,
        nextReview: _vendor.nextReview,
        contractId: _vendor.contractId,
        onTimeDelivery: _vendor.onTimeDelivery,
        incidentResponse: _vendor.incidentResponse,
        qualityScore: _vendor.qualityScore,
        costAdherence: _vendor.costAdherence,
        notes: _vendor.notes,
        createdById: _vendor.createdById,
        createdByEmail: _vendor.createdByEmail,
        createdByName: _vendor.createdByName,
        createdAt: _vendor.createdAt,
        updatedAt: DateTime.now(),
      );

      await _updateVendor(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SLA terms regenerated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error regenerating SLA terms: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }

  Future<void> _deleteVendor() async {
    final deleted = _vendor;

    try {
      await VendorService.deleteVendor(
        projectId: deleted.projectId,
        vendorId: deleted.id,
      );
    } catch (e) {
      debugPrint('Error deleting vendor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting vendor: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    widget.onDeleted(deleted);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Vendor deleted'),
              Spacer(),
            ],
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () async {
              try {
                await VendorService.createVendor(
                  projectId: deleted.projectId,
                  name: deleted.name,
                  category: deleted.category,
                  criticality: deleted.criticality,
                  sla: deleted.sla,
                  slaPerformance: deleted.slaPerformance,
                  leadTime: deleted.leadTime,
                  requiredDeliverables: deleted.requiredDeliverables,
                  rating: deleted.rating,
                  status: deleted.status,
                  nextReview: deleted.nextReview,
                  contractId: deleted.contractId,
                  onTimeDelivery: deleted.onTimeDelivery,
                  incidentResponse: deleted.incidentResponse,
                  qualityScore: deleted.qualityScore,
                  costAdherence: deleted.costAdherence,
                  notes: deleted.notes,
                  createdById: deleted.createdById,
                  createdByEmail: deleted.createdByEmail,
                  createdByName: deleted.createdByName,
                );
                widget.onUpdated(deleted);
              } catch (e) {
                debugPrint('Error restoring vendor: $e');
              }
            },
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF111827),
        ),
      );
    }
  }

  Color _getCriticalityColor(String criticality) {
    return switch (criticality.toLowerCase()) {
      'high' => const Color(0xFFEF4444),
      'medium' => const Color(0xFFF59E0B),
      'low' => const Color(0xFF10B981),
      _ => const Color(0xFF9CA3AF),
    };
  }

  VendorModel _createUpdatedVendor({
    String? name,
    String? category,
    String? criticality,
    String? sla,
    double? slaPerformance,
    String? leadTime,
    String? requiredDeliverables,
  }) {
    return VendorModel(
      id: _vendor.id,
      projectId: _vendor.projectId,
      name: name ?? _vendor.name,
      category: category ?? _vendor.category,
      criticality: criticality ?? _vendor.criticality,
      sla: sla ?? _vendor.sla,
      slaPerformance: slaPerformance ?? _vendor.slaPerformance,
      leadTime: leadTime ?? _vendor.leadTime,
      requiredDeliverables:
          requiredDeliverables ?? _vendor.requiredDeliverables,
      rating: _vendor.rating,
      status: _vendor.status,
      nextReview: _vendor.nextReview,
      contractId: _vendor.contractId,
      onTimeDelivery: _vendor.onTimeDelivery,
      incidentResponse: _vendor.incidentResponse,
      qualityScore: _vendor.qualityScore,
      costAdherence: _vendor.costAdherence,
      notes: _vendor.notes,
      createdById: _vendor.createdById,
      createdByEmail: _vendor.createdByEmail,
      createdByName: _vendor.createdByName,
      createdAt: _vendor.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.column) {
      case 'name':
        return InlineEditableText(
          value: _vendor.name,
          isListField: false,
          onChanged: (v) => _updateVendor(_createUpdatedVendor(name: v)),
          style: const TextStyle(fontSize: 11, color: Color(0xFF111827)),
          textAlign: TextAlign.left,
        );
      case 'category':
        return Center(
          child: DropdownButton<String>(
            value: _vendor.category,
            isDense: true,
            underline: const SizedBox(),
            items: const [
              'Logistics',
              'IT Hardware',
              'Consulting',
              'Raw Materials',
              'Utilities',
            ]
                .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: const TextStyle(fontSize: 11)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                _updateVendor(_createUpdatedVendor(category: v));
              }
            },
          ),
        );
      case 'criticality':
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getCriticalityColor(_vendor.criticality)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _vendor.criticality,
              isDense: true,
              underline: const SizedBox(),
              items: ['High', 'Medium', 'Low']
                  .map((crit) => DropdownMenuItem(
                        value: crit,
                        child: Text(crit,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getCriticalityColor(crit))),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  _updateVendor(_createUpdatedVendor(criticality: v));
                }
              },
            ),
          ),
        );
      case 'sla':
        return Center(
          child: SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: _vendor.slaPerformance.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                _vendor.slaPerformance >= 0.8
                    ? const Color(0xFF10B981)
                    : _vendor.slaPerformance >= 0.6
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
              ),
            ),
          ),
        );
      case 'leadTime':
        return Center(
          child: InlineEditableText(
            value: _vendor.leadTime,
            isListField: false,
            onChanged: (v) => _updateVendor(_createUpdatedVendor(leadTime: v)),
            style: const TextStyle(fontSize: 11, color: Color(0xFF111827)),
            textAlign: TextAlign.center,
          ),
        );
      case 'actions':
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovering = true),
          onExit: (_) => setState(() => _isHovering = false),
          child: Center(
            child: _isHovering
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_previousState != null)
                        IconButton(
                          icon: const Icon(Icons.undo,
                              size: 16, color: Color(0xFF64748B)),
                          onPressed: _undo,
                          tooltip: 'Undo',
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      IconButton(
                        icon: _isRegenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF7C3AED),
                                ),
                              )
                            : const Icon(Icons.auto_awesome,
                                size: 16, color: Color(0xFF7C3AED)),
                        onPressed: _isRegenerating ? null : _regenerateSLATerms,
                        tooltip: 'Regenerate SLA Terms',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Color(0xFF9CA3AF)),
                        onPressed: _deleteVendor,
                        tooltip: 'Delete',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  )
                : const SizedBox(width: 40),
          ),
        );
      default:
        return const SizedBox();
    }
  }
}
