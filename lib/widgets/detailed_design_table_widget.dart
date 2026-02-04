import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ndu_project/models/design_component.dart';
import 'package:ndu_project/services/execution_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/widgets/inline_editable_text.dart';

/// Custom Detailed Design Table with inline editing, CRUD actions, and AI capabilities
class DetailedDesignTableWidget extends StatelessWidget {
  const DetailedDesignTableWidget({
    super.key,
    required this.components,
    required this.onUpdated,
    required this.onDeleted,
  });

  final List<DesignComponent> components;
  final ValueChanged<DesignComponent> onUpdated;
  final ValueChanged<DesignComponent> onDeleted;

  @override
  Widget build(BuildContext context) {
    if (components.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No design components found.',
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
                dataRowMaxHeight: 120,
                columns: const [
                  DataColumn(
                    label: Text('Component Name',
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
                    label: Text('Specification Details',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                  ),
                  DataColumn(
                    label: Text('Integration Point',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151))),
                  ),
                  DataColumn(
                    label: Text('Status',
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
                rows: components.map((component) {
                  return DataRow(
                    cells: [
                      DataCell(
                        _DesignComponentRowWidget(
                          component: component,
                          onUpdated: onUpdated,
                          onDeleted: onDeleted,
                          column: 'name',
                        ),
                      ),
                      DataCell(
                        _DesignComponentRowWidget(
                          component: component,
                          onUpdated: onUpdated,
                          onDeleted: onDeleted,
                          column: 'category',
                        ),
                      ),
                      DataCell(
                        _DesignComponentRowWidget(
                          component: component,
                          onUpdated: onUpdated,
                          onDeleted: onDeleted,
                          column: 'specification',
                        ),
                      ),
                      DataCell(
                        _DesignComponentRowWidget(
                          component: component,
                          onUpdated: onUpdated,
                          onDeleted: onDeleted,
                          column: 'integration',
                        ),
                      ),
                      DataCell(
                        _DesignComponentRowWidget(
                          component: component,
                          onUpdated: onUpdated,
                          onDeleted: onDeleted,
                          column: 'status',
                        ),
                      ),
                      DataCell(
                        _DesignComponentRowWidget(
                          component: component,
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

class _DesignComponentRowWidget extends StatefulWidget {
  const _DesignComponentRowWidget({
    required this.component,
    required this.onUpdated,
    required this.onDeleted,
    required this.column,
  });

  final DesignComponent component;
  final ValueChanged<DesignComponent> onUpdated;
  final ValueChanged<DesignComponent> onDeleted;
  final String
      column; // 'name', 'category', 'specification', 'integration', 'status', 'actions'

  @override
  State<_DesignComponentRowWidget> createState() =>
      _DesignComponentRowWidgetState();
}

class _DesignComponentRowWidgetState extends State<_DesignComponentRowWidget> {
  late DesignComponent _component;
  DesignComponent? _previousState;
  bool _isHovering = false;
  bool _isRegenerating = false;
  final _Debouncer _saveDebouncer = _Debouncer();

  @override
  void initState() {
    super.initState();
    _component = widget.component;
  }

  @override
  void didUpdateWidget(_DesignComponentRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.component != widget.component) {
      _component = widget.component;
    }
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }

  Future<void> _updateComponent(DesignComponent updated) async {
    setState(() {
      _previousState = _component;
      _component = updated;
    });

    // Debounced auto-save
    _saveDebouncer.run(() async {
      final projectId = _getProjectId();
      if (projectId == null) return;

      try {
        final components = await ExecutionPhaseService.loadDesignComponents(
          projectId: projectId,
        );
        final index = components.indexWhere((c) => c.id == updated.id);
        if (index != -1) {
          components[index] = updated;
        } else {
          components.add(updated);
        }
        await ExecutionPhaseService.saveDesignComponents(
          projectId: projectId,
          components: components,
        );
      } catch (e) {
        debugPrint('Error saving design component: $e');
      }
    });

    widget.onUpdated(updated);
  }

  String? _getProjectId() {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  Future<void> _undo() async {
    if (_previousState != null) {
      final previous = _previousState!;
      setState(() {
        _component = previous;
        _previousState = null;
      });
      await _updateComponent(previous);
    }
  }

  Future<void> _regenerateSpecification() async {
    if (_isRegenerating) return;
    setState(() => _isRegenerating = true);

    try {
      final provider = ProjectDataInherited.maybeOf(context);
      if (provider == null) return;

      final contextText = ProjectDataHelper.buildExecutivePlanContext(
        provider.projectData,
        sectionLabel: 'Detailed Design',
      );

      final ai = OpenAiServiceSecure();
      final specifications = await ai.generateDesignSpecification(
        context: contextText,
        componentName: _component.componentName,
        category: _component.category,
      );

      final updated = _component.copyWith(
        specificationDetails: specifications,
      );

      await _updateComponent(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Specification regenerated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error regenerating specification: $e'),
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

  Future<void> _deleteComponent() async {
    final deleted = _component;
    final projectId = _getProjectId();

    try {
      if (projectId != null) {
        final components = await ExecutionPhaseService.loadDesignComponents(
          projectId: projectId,
        );
        components.removeWhere((c) => c.id == deleted.id);
        await ExecutionPhaseService.saveDesignComponents(
          projectId: projectId,
          components: components,
        );
      }
    } catch (e) {
      debugPrint('Error deleting design component: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting component: $e'),
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
              Text('Component deleted'),
              Spacer(),
            ],
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () async {
              try {
                final projectId = _getProjectId();
                if (projectId != null) {
                  final components =
                      await ExecutionPhaseService.loadDesignComponents(
                    projectId: projectId,
                  );
                  components.add(deleted);
                  await ExecutionPhaseService.saveDesignComponents(
                    projectId: projectId,
                    components: components,
                  );
                  widget.onUpdated(deleted);
                }
              } catch (e) {
                debugPrint('Error restoring component: $e');
              }
            },
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF111827),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    return switch (status.toLowerCase()) {
      'draft' => const Color(0xFF9CA3AF),
      'reviewed' => const Color(0xFF0EA5E9),
      'approved' => const Color(0xFF10B981),
      _ => const Color(0xFF9CA3AF),
    };
  }

  DesignComponent _createUpdatedComponent({
    String? componentName,
    String? category,
    String? specificationDetails,
    String? integrationPoint,
    String? status,
    String? designNotes,
  }) {
    return _component.copyWith(
      componentName: componentName,
      category: category,
      specificationDetails: specificationDetails,
      integrationPoint: integrationPoint,
      status: status,
      designNotes: designNotes,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.column) {
      case 'name':
        return InlineEditableText(
          value: _component.componentName,
          isListField: false,
          onChanged: (v) =>
              _updateComponent(_createUpdatedComponent(componentName: v)),
          style: const TextStyle(fontSize: 11, color: Color(0xFF111827)),
          textAlign: TextAlign.left,
        );
      case 'category':
        return Center(
          child: DropdownButton<String>(
            value: _component.category,
            isDense: true,
            underline: const SizedBox(),
            items: const [
              'UI/UX',
              'Backend',
              'Security',
              'Networking',
              'Physical Infrastructure',
            ]
                .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: const TextStyle(fontSize: 11)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                _updateComponent(_createUpdatedComponent(category: v));
              }
            },
          ),
        );
      case 'specification':
        return SizedBox(
          width: 200,
          child: InlineEditableText(
            value: _component.specificationDetails,
            isListField: true, // Use AutoBulletTextController
            onChanged: (v) => _updateComponent(
                _createUpdatedComponent(specificationDetails: v)),
            style: const TextStyle(fontSize: 11, color: Color(0xFF111827)),
            textAlign: TextAlign.left,
          ),
        );
      case 'integration':
        return SizedBox(
          width: 150,
          child: InlineEditableText(
            value: _component.integrationPoint,
            isListField: false,
            onChanged: (v) =>
                _updateComponent(_createUpdatedComponent(integrationPoint: v)),
            style: const TextStyle(fontSize: 11, color: Color(0xFF111827)),
            textAlign: TextAlign.left,
          ),
        );
      case 'status':
        return Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(_component.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<String>(
              value: _component.status,
              isDense: true,
              underline: const SizedBox(),
              items: ['Draft', 'Reviewed', 'Approved']
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(status))),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  _updateComponent(_createUpdatedComponent(status: v));
                }
              },
            ),
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
                        onPressed:
                            _isRegenerating ? null : _regenerateSpecification,
                        tooltip: 'Regenerate Specification',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Color(0xFF9CA3AF)),
                        onPressed: _deleteComponent,
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

class _Debouncer {
  Timer? _timer;

  void run(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 500), callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}
