import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/providers/project_data_provider.dart';

class SpecializedDesignScreen extends StatefulWidget {
  const SpecializedDesignScreen({super.key});

  @override
  State<SpecializedDesignScreen> createState() => _SpecializedDesignScreenState();
}

class _SpecializedDesignScreenState extends State<SpecializedDesignScreen> {
  final TextEditingController _notesController = TextEditingController();
  Timer? _saveDebounce;
  bool _isLoading = false;
  String? _loadError;

  final List<_SecurityPatternRow> _securityRows = [];

  final List<_PerformancePatternRow> _performanceRows = [];

  final List<_IntegrationFlowRow> _integrationRows = [];

  final List<String> _statusOptions = const ['Ready', 'In review', 'Draft', 'Pending', 'In progress'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
  }

  @override
  void dispose() {
    _notesController.dispose();
    _saveDebounce?.cancel();
    super.dispose();
  }

  String? _currentProjectId() {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return null;
    return projectId;
  }

  Future<void> _loadFromFirestore() async {
    final projectId = _currentProjectId();
    if (projectId == null) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('projects').doc(projectId).get();
      final data = doc.data();
      final specialized = (data?['specializedDesign'] as Map<String, dynamic>?) ?? const {};

      setState(() {
        _notesController.text = specialized['notes']?.toString() ?? '';
        _securityRows
          ..clear()
          ..addAll(_parseSecurityRows(specialized['securityPatterns']));
        _performanceRows
          ..clear()
          ..addAll(_parsePerformanceRows(specialized['performancePatterns']));
        _integrationRows
          ..clear()
          ..addAll(_parseIntegrationRows(specialized['integrationFlows']));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load specialized design data.';
      });
    }
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), _saveToFirestore);
  }

  Future<void> _saveToFirestore() async {
    final projectId = _currentProjectId();
    if (projectId == null) return;

    final payload = {
      'specializedDesign': {
        'notes': _notesController.text.trim(),
        'securityPatterns': _securityRows
            .map((row) => {
                  'pattern': row.pattern.trim(),
                  'decision': row.decision.trim(),
                  'owner': row.owner.trim(),
                  'status': row.status.trim(),
                })
            .toList(),
        'performancePatterns': _performanceRows
            .map((row) => {
                  'hotspot': row.hotspot.trim(),
                  'focus': row.focus.trim(),
                  'sla': row.sla.trim(),
                  'status': row.status.trim(),
                })
            .toList(),
        'integrationFlows': _integrationRows
            .map((row) => {
                  'flow': row.flow.trim(),
                  'owner': row.owner.trim(),
                  'system': row.system.trim(),
                  'status': row.status.trim(),
                })
            .toList(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('projects').doc(projectId).set(payload, SetOptions(merge: true));
  }

  String _normalizeStatus(String? value) {
    final candidate = value?.trim();
    if (candidate == null || candidate.isEmpty) return 'Draft';
    if (_statusOptions.contains(candidate)) return candidate;
    return 'Draft';
  }

  List<_SecurityPatternRow> _parseSecurityRows(dynamic raw) {
    if (raw is! Iterable) return const [];
    return raw.map((entry) {
      final map = entry is Map ? entry : const {};
      return _SecurityPatternRow(
        pattern: map['pattern']?.toString() ?? '',
        decision: map['decision']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        status: _normalizeStatus(map['status']?.toString()),
      );
    }).toList();
  }

  List<_PerformancePatternRow> _parsePerformanceRows(dynamic raw) {
    if (raw is! Iterable) return const [];
    return raw.map((entry) {
      final map = entry is Map ? entry : const {};
      return _PerformancePatternRow(
        hotspot: map['hotspot']?.toString() ?? '',
        focus: map['focus']?.toString() ?? '',
        sla: map['sla']?.toString() ?? '',
        status: _normalizeStatus(map['status']?.toString()),
      );
    }).toList();
  }

  List<_IntegrationFlowRow> _parseIntegrationRows(dynamic raw) {
    if (raw is! Iterable) return const [];
    return raw.map((entry) {
      final map = entry is Map ? entry : const {};
      return _IntegrationFlowRow(
        flow: map['flow']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        system: map['system']?.toString() ?? '',
        status: _normalizeStatus(map['status']?.toString()),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);
    final ownerOptions = _ownerOptions();

    return ResponsiveScaffold(
      activeItemLabel: 'Specialized Design',
      body: Column(
        children: [
          const PlanningPhaseHeader(
            title: 'Design Phase',
            showImportButton: false,
            showContentButton: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  Text(
                    'SPECIALIZED DESIGN',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: LightModeColors.accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lock in specialized patterns for security, performance, and data',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture the critical, non-generic design decisions so engineers know exactly how to implement edge cases, secure zones, and high-scale components.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),

                  // Notes Input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppSemanticColors.border),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 2,
                      onChanged: (_) => _scheduleSave(),
                      decoration: InputDecoration(
                        hintText: 'Summarize the specialized design choices here... security zones, performance patterns, data flows, integrations that must be implemented in a very specific way.',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Helper Text
                  Text(
                    'Keep this focused on decisions that go beyond standard templates and will be hard to change later.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text('Loading specialized design data...', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  if (_loadError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        _loadError!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                      ),
                    ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSecurityPatternsCard(ownerOptions),
                      const SizedBox(height: 20),
                      _buildPerformancePatternsCard(),
                      const SizedBox(height: 20),
                      _buildIntegrationFlowsCard(ownerOptions),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Bottom Navigation
                  _buildBottomNavigation(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPatternsCard(List<String> ownerOptions) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.verified_user_outlined,
            color: const Color(0xFF1D4ED8),
            title: 'Security & compliance patterns',
            subtitle: 'Exceptional guardrails for world-class data protection and access control.',
            actionLabel: 'Add control',
            onAction: () {
              setState(() {
                _securityRows.add(
                  _SecurityPatternRow(
                    pattern: 'New security control',
                    decision: 'Define the implementation requirement.',
                    owner: 'Owner',
                    status: 'Draft',
                  ),
                );
              });
              _scheduleSave();
            },
          ),
          const SizedBox(height: 16),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Pattern', flex: 3),
              _TableColumn(label: 'Decision and scope', flex: 5),
              _TableColumn(label: 'Owner', flex: 2),
              _TableColumn(label: 'Status', flex: 2),
              _TableColumn(label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          if (_securityRows.isEmpty)
            _buildEmptyTableState(
              message: 'No security patterns captured yet. Add your first control.',
              actionLabel: 'Add control',
              onAction: () {
                setState(() {
                  _securityRows.add(
                    _SecurityPatternRow(
                      pattern: '',
                      decision: '',
                      owner: '',
                      status: 'Draft',
                    ),
                  );
                });
                _scheduleSave();
              },
            )
          else
            for (int i = 0; i < _securityRows.length; i++) ...[
              _buildSecurityRow(
                _securityRows[i],
                index: i,
                isStriped: i.isOdd,
                ownerOptions: ownerOptions,
              ),
              if (i != _securityRows.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildPerformancePatternsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.auto_graph_outlined,
            color: const Color(0xFF0F766E),
            title: 'Performance & scale patterns',
            subtitle: 'Exceptional performance decisions that keep the system stable at peak load.',
            actionLabel: 'Add hotspot',
            onAction: () {
              setState(() {
                _performanceRows.add(
                  _PerformancePatternRow(
                    hotspot: 'New hotspot',
                    focus: 'Describe the scaling or resiliency focus.',
                    sla: 'Define SLA',
                    status: 'Draft',
                  ),
                );
              });
              _scheduleSave();
            },
          ),
          const SizedBox(height: 16),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Service hotspot', flex: 3),
              _TableColumn(label: 'Design focus', flex: 5),
              _TableColumn(label: 'SLA target', flex: 2),
              _TableColumn(label: 'Status', flex: 2),
              _TableColumn(label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          if (_performanceRows.isEmpty)
            _buildEmptyTableState(
              message: 'No performance hotspots yet. Add the first scaling decision.',
              actionLabel: 'Add hotspot',
              onAction: () {
                setState(() {
                  _performanceRows.add(
                    _PerformancePatternRow(
                      hotspot: '',
                      focus: '',
                      sla: '',
                      status: 'Draft',
                    ),
                  );
                });
                _scheduleSave();
              },
            )
          else
            for (int i = 0; i < _performanceRows.length; i++) ...[
              _buildPerformanceRow(_performanceRows[i], index: i, isStriped: i.isOdd),
              if (i != _performanceRows.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildIntegrationFlowsCard(List<String> ownerOptions) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.account_tree_outlined,
            color: const Color(0xFF9333EA),
            title: 'Complex data & integration flows',
            subtitle: 'World-class clarity for every system boundary and data contract.',
            actionLabel: 'Add flow',
            onAction: () {
              setState(() {
                _integrationRows.add(
                  _IntegrationFlowRow(
                    flow: 'New integration flow',
                    owner: 'Owner',
                    system: 'System',
                    status: 'Draft',
                  ),
                );
              });
              _scheduleSave();
            },
          ),
          const SizedBox(height: 16),
          _buildTableHeaderRow(
            columns: const [
              _TableColumn(label: 'Flow or contract', flex: 4),
              _TableColumn(label: 'Owner', flex: 2),
              _TableColumn(label: 'System', flex: 2),
              _TableColumn(label: 'Status', flex: 2),
              _TableColumn(label: 'Action', flex: 2, alignment: Alignment.center),
            ],
          ),
          const SizedBox(height: 10),
          if (_integrationRows.isEmpty)
            _buildEmptyTableState(
              message: 'No integration flows yet. Add the first contract or system boundary.',
              actionLabel: 'Add flow',
              onAction: () {
                setState(() {
                  _integrationRows.add(
                    _IntegrationFlowRow(
                      flow: '',
                      owner: '',
                      system: '',
                      status: 'Draft',
                    ),
                  );
                });
                _scheduleSave();
              },
            )
          else
            for (int i = 0; i < _integrationRows.length; i++) ...[
              _buildIntegrationRow(
                _integrationRows[i],
                index: i,
                isStriped: i.isOdd,
                ownerOptions: ownerOptions,
              ),
              if (i != _integrationRows.length - 1) const SizedBox(height: 8),
            ],
          const SizedBox(height: 16),
          // Export button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export specialized design brief'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add, size: 18),
          label: Text(actionLabel),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: const BorderSide(color: Color(0xFFD6DCE8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderRow({required List<_TableColumn> columns}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          for (final column in columns)
            Expanded(
              flex: column.flex,
              child: Align(
                alignment: column.alignment,
                child: Text(
                  column.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow(
    _SecurityPatternRow row, {
    required int index,
    required bool isStriped,
    required List<String> ownerOptions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriped ? const Color(0xFFF9FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildTableField(
              initialValue: row.pattern,
              hintText: 'Security pattern',
              onChanged: (value) {
                row.pattern = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _buildTableField(
              initialValue: row.decision,
              hintText: 'Decision and scope',
              maxLines: 2,
              onChanged: (value) {
                row.decision = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildOwnerDropdown(
              value: row.owner,
              options: ownerOptions,
              onChanged: (value) {
                row.owner = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildStatusDropdown(
              value: row.status,
              onChanged: (value) {
                setState(() => _securityRows[index].status = value);
                _scheduleSave();
              },
              accent: const Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: _buildDeleteAction(() async {
                final confirmed = await _confirmDelete('security pattern');
                if (!confirmed) return;
                setState(() => _securityRows.removeAt(index));
                _scheduleSave();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(_PerformancePatternRow row, {required int index, required bool isStriped}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriped ? const Color(0xFFF9FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildTableField(
              initialValue: row.hotspot,
              hintText: 'Service hotspot',
              onChanged: (value) {
                row.hotspot = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 5,
            child: _buildTableField(
              initialValue: row.focus,
              hintText: 'Design focus',
              maxLines: 2,
              onChanged: (value) {
                row.focus = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildTableField(
              initialValue: row.sla,
              hintText: 'SLA target',
              onChanged: (value) {
                row.sla = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildStatusDropdown(
              value: row.status,
              onChanged: (value) {
                setState(() => _performanceRows[index].status = value);
                _scheduleSave();
              },
              accent: const Color(0xFF0F766E),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: _buildDeleteAction(() async {
                final confirmed = await _confirmDelete('performance pattern');
                if (!confirmed) return;
                setState(() => _performanceRows.removeAt(index));
                _scheduleSave();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationRow(
    _IntegrationFlowRow row, {
    required int index,
    required bool isStriped,
    required List<String> ownerOptions,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStriped ? const Color(0xFFF9FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: _buildTableField(
              initialValue: row.flow,
              hintText: 'Flow or contract',
              maxLines: 2,
              onChanged: (value) {
                row.flow = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildOwnerDropdown(
              value: row.owner,
              options: ownerOptions,
              onChanged: (value) {
                row.owner = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildTableField(
              initialValue: row.system,
              hintText: 'System',
              onChanged: (value) {
                row.system = value;
                _scheduleSave();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _buildStatusDropdown(
              value: row.status,
              onChanged: (value) {
                setState(() => _integrationRows[index].status = value);
                _scheduleSave();
              },
              accent: const Color(0xFF9333EA),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: _buildDeleteAction(() async {
                final confirmed = await _confirmDelete('integration flow');
                if (!confirmed) return;
                setState(() => _integrationRows.removeAt(index));
                _scheduleSave();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableField({
    required String initialValue,
    required String hintText,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500]),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
        ),
      ),
    );
  }

  List<String> _ownerOptions() {
    final provider = ProjectDataInherited.maybeOf(context);
    final members = provider?.projectData.teamMembers ?? [];
    final names = members
        .map((member) => member.name.trim().isNotEmpty ? member.name.trim() : member.email.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      return const ['Owner'];
    }
    return names.toSet().toList();
  }

  Widget _buildOwnerDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final normalized = value.trim();
    final items = normalized.isEmpty || options.contains(normalized)
        ? options
        : [normalized, ...options];
    return DropdownButtonFormField<String>(
      initialValue: items.first,
      alignment: Alignment.center,
      items: items.map((owner) => DropdownMenuItem(value: owner, child: Text(owner))).toList(),
      onChanged: (newValue) {
        if (newValue == null) return;
        onChanged(newValue);
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
        ),
      ),
    );
  }

  Widget _buildEmptyTableState({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1D1F),
              side: const BorderSide(color: Color(0xFFD6DCE8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown({
    required String value,
    required ValueChanged<String> onChanged,
    required Color accent,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      alignment: Alignment.center,
      items: _statusOptions
          .map((status) => DropdownMenuItem(value: status, child: Text(status)))
          .toList(),
      onChanged: (newValue) {
        if (newValue == null) return;
        onChanged(newValue);
      },
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }

  Widget _buildDeleteAction(Future<void> Function() onDelete) {
    return TextButton.icon(
      onPressed: () async {
        await onDelete();
      },
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('Delete'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFB91C1C),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

  Future<bool> _confirmDelete(String label) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete row?'),
        content: Text('Remove this $label from the table?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildBottomNavigation(bool isMobile) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Design phase · Specialized design', style: TextStyle(fontSize: 13, color: Colors.grey[500]), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back: Long lead equipment ordering'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next: Design deliverables'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back: Long lead equipment ordering'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Text('Design phase · Specialized design', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next: Design deliverables'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        // Footer hint
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: LightModeColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Only capture the opinions that truly shape implementation: anything that affects security posture, resilience, data integrity, or cross-team contracts should live in this specialized design summary.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TableColumn {
  const _TableColumn({
    required this.label,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });

  final String label;
  final int flex;
  final Alignment alignment;
}

class _SecurityPatternRow {
  _SecurityPatternRow({
    required this.pattern,
    required this.decision,
    required this.owner,
    required this.status,
  });

  String pattern;
  String decision;
  String owner;
  String status;
}

class _PerformancePatternRow {
  _PerformancePatternRow({
    required this.hotspot,
    required this.focus,
    required this.sla,
    required this.status,
  });

  String hotspot;
  String focus;
  String sla;
  String status;
}

class _IntegrationFlowRow {
  _IntegrationFlowRow({
    required this.flow,
    required this.owner,
    required this.system,
    required this.status,
  });

  String flow;
  String owner;
  String system;
  String status;
}
