import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ndu_project/screens/launch_checklist_screen.dart';
import 'package:ndu_project/screens/stakeholder_alignment_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/project_insights_service.dart';

class UpdateOpsMaintenancePlansScreen extends StatefulWidget {
  const UpdateOpsMaintenancePlansScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UpdateOpsMaintenancePlansScreen()),
    );
  }

  @override
  State<UpdateOpsMaintenancePlansScreen> createState() => _UpdateOpsMaintenancePlansScreenState();
}

class _UpdateOpsMaintenancePlansScreenState extends State<UpdateOpsMaintenancePlansScreen> {
  final Set<String> _selectedFilters = {'All plans'};
  final List<String> _planStatuses = const ['Ready', 'In review', 'Pending', 'Scheduled'];

  final List<_CoverageItem> _coverage = [];
  final List<_SignalItem> _signals = [];
  final List<_MaintenanceWindowItem> _maintenanceWindows = [];
  final List<_StatCardData> _stats = [];

  final _Debouncer _saveDebouncer = _Debouncer();
  bool _isLoading = false;
  bool _suspendSave = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFromFirestore();
    });
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    if (_suspendSave) return;
    _saveDebouncer.run(_saveToFirestore);
  }

  Future<void> _loadFromFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('update_ops_maintenance_plans')
          .get();
      final data = doc.data() ?? {};
      final stats = _StatCardData.fromList(data['stats']);
      final coverage = _CoverageItem.fromList(data['coverage']);
      final signals = _SignalItem.fromList(data['signals']);
      final windows = _MaintenanceWindowItem.fromList(data['maintenanceWindows']);

      _suspendSave = true;
      if (!mounted) return;
      setState(() {
        _stats
          ..clear()
          ..addAll(stats.isEmpty ? _defaultStats() : stats);
        _coverage
          ..clear()
          ..addAll(coverage.isEmpty ? _defaultCoverage() : coverage);
        _signals
          ..clear()
          ..addAll(signals);
        _maintenanceWindows
          ..clear()
          ..addAll(windows);
      });
      _suspendSave = false;
    } catch (error) {
      debugPrint('Update ops maintenance load error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveToFirestore() async {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('update_ops_maintenance_plans')
          .set({
        'stats': _stats.map((e) => e.toMap()).toList(),
        'coverage': _coverage.map((e) => e.toMap()).toList(),
        'signals': _signals.map((e) => e.toMap()).toList(),
        'maintenanceWindows': _maintenanceWindows.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Update ops maintenance save error: $error');
    }
  }

  List<_StatCardData> _defaultStats() {
    return [
      _StatCardData(id: _newId(), label: 'Plans updated', value: '', supporting: '', color: const Color(0xFF0EA5E9)),
      _StatCardData(id: _newId(), label: 'Runbooks ready', value: '', supporting: '', color: const Color(0xFF10B981)),
      _StatCardData(id: _newId(), label: 'Training coverage', value: '', supporting: '', color: const Color(0xFFF59E0B)),
      _StatCardData(id: _newId(), label: 'Maintenance risk', value: '', supporting: '', color: const Color(0xFF6366F1)),
    ];
  }

  List<_CoverageItem> _defaultCoverage() {
    return [
      _CoverageItem(id: _newId(), label: 'Runbooks updated', progress: 0.0, color: const Color(0xFF10B981)),
      _CoverageItem(id: _newId(), label: 'Maintenance tasks', progress: 0.0, color: const Color(0xFF6366F1)),
      _CoverageItem(id: _newId(), label: 'Training readiness', progress: 0.0, color: const Color(0xFFF59E0B)),
      _CoverageItem(id: _newId(), label: 'Ops handoff', progress: 0.0, color: const Color(0xFF0EA5E9)),
    ];
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;

    return ResponsiveScaffold(
      activeItemLabel: 'Update Ops and Maintenance Plans',
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                if (_isLoading) const SizedBox(height: 16),
                _buildHeader(isNarrow),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 20),
                _buildStatsRow(isNarrow),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPlanRegister(projectId),
                    const SizedBox(height: 20),
                    _buildCoveragePanel(),
                    const SizedBox(height: 20),
                    _buildSignalsPanel(),
                    const SizedBox(height: 20),
                    _buildMaintenancePanel(),
                  ],
                ),
                const SizedBox(height: 24),
                LaunchPhaseNavigation(
                  backLabel: 'Back: Stakeholder Alignment',
                  nextLabel: 'Next: Start-up / Launch Checklist',
                  onBack: () => StakeholderAlignmentScreen.open(context),
                  onNext: () => LaunchChecklistScreen.open(context),
                ),
              ],
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'OPS MAINTENANCE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Update Ops and Maintenance Plans',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Finalize operational playbooks, maintenance cadence, and training updates before launch.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (!isNarrow) _buildHeaderActions(),
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 12),
          _buildHeaderActions(),
        ],
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _actionButton(Icons.add, 'Add plan update'),
        _actionButton(Icons.upload_outlined, 'Upload runbook'),
        _actionButton(Icons.description_outlined, 'Export plan'),
        _primaryButton('Publish ops update'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _primaryButton(String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.play_arrow, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All plans', 'Ready', 'In review', 'Pending', 'Scheduled'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final selected = _selectedFilters.contains(filter);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedFilters.remove(filter);
              } else {
                _selectedFilters.add(filter);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              filter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _stats.map((stat) => _buildStatCard(stat)).toList(),
      );
    }

    return Row(
      children: _stats.map((stat) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildStatCard(stat),
        ),
      )).toList(),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: ValueKey('stat-value-${data.id}'),
            initialValue: data.value,
            decoration: _inlineDecoration('Value'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: data.color),
            onChanged: (value) => _updateStat(data.copyWith(value: value)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey('stat-label-${data.id}'),
            initialValue: data.label,
            decoration: _inlineDecoration('Label'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            onChanged: (value) => _updateStat(data.copyWith(label: value)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey('stat-support-${data.id}'),
            initialValue: data.supporting,
            decoration: _inlineDecoration('Supporting note'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: data.color),
            onChanged: (value) => _updateStat(data.copyWith(supporting: value)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanRegister(String? projectId) {
    return _PanelShell(
      title: 'Ops plan register',
      subtitle: 'Maintenance and runbook updates',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton(Icons.add, 'Add', onPressed: projectId == null ? null : () => _openAddPlanDialog(projectId)),
          const SizedBox(width: 8),
          _actionButton(Icons.filter_list, 'Filter'),
        ],
      ),
      child: projectId == null
          ? _emptyPanelMessage('Select a project to manage ops plans.')
          : StreamBuilder<List<OpsPlanItem>>(
              stream: ProjectInsightsService.streamOpsPlans(projectId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _emptyPanelMessage('Unable to load ops plans. ${snapshot.error}');
                }
                final plans = snapshot.data ?? [];
                final filtered = plans.where((plan) {
                  if (_selectedFilters.contains('All plans')) return true;
                  return _selectedFilters.contains(plan.status);
                }).toList();
                if (filtered.isEmpty) {
                  return _emptyState(
                    message: 'No ops plans recorded yet.',
                    onAdd: () => _openAddPlanDialog(projectId),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                          columns: const [
                            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Plan item', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Team', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Due', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.w600))),
                          ],
                          rows: filtered.map((plan) {
                            return DataRow(cells: [
                              DataCell(Text(plan.id, style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9)))),
                              DataCell(Text(plan.title, style: const TextStyle(fontSize: 13))),
                              DataCell(Text(plan.team, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                              DataCell(_statusChip(plan.status)),
                              DataCell(Text(plan.due, style: const TextStyle(fontSize: 12))),
                              DataCell(Text(plan.owner, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                            ]);
                          }).toList(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Future<void> _openAddPlanDialog(String projectId) async {
    final idController = TextEditingController();
    final titleController = TextEditingController();
    final teamController = TextEditingController();
    final ownerController = TextEditingController();
    final dueController = TextEditingController();
    String status = _planStatuses.first;
    DateTime? dueDate;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF0EA5E9)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add ops plan item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Log a runbook or maintenance update for the ops register.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _dialogField('Plan ID', controller: idController, hint: 'e.g. OP-301'),
                  const SizedBox(height: 12),
                  _dialogField('Plan item', controller: titleController, hint: 'e.g. Runbook refresh'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _dialogField('Team', controller: teamController, hint: 'e.g. Operations')),
                      const SizedBox(width: 12),
                      Expanded(child: _dialogField('Owner', controller: ownerController, hint: 'e.g. M. Thompson')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: status,
                          items: _planStatuses.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
                          decoration: _dialogDecoration('Status'),
                          onChanged: (value) => setDialogState(() => status = value ?? _planStatuses.first),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: dueController,
                          readOnly: true,
                          decoration: _dialogDecoration('Due date', hint: 'Select date')
                              .copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
                          onTap: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: dialogContext,
                              firstDate: now.subtract(const Duration(days: 365)),
                              lastDate: now.add(const Duration(days: 365 * 5)),
                              initialDate: dueDate ?? now,
                            );
                            if (picked != null) {
                              setDialogState(() {
                                dueDate = picked;
                                dueController.text = '${picked.month}/${picked.day}/${picked.year}';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (idController.text.trim().isEmpty ||
                              titleController.text.trim().isEmpty ||
                              teamController.text.trim().isEmpty ||
                              ownerController.text.trim().isEmpty ||
                              dueController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please complete all fields.')),
                            );
                            return;
                          }
                          await FirebaseFirestore.instance
                              .collection('projects')
                              .doc(projectId)
                              .collection('opsMaintenance')
                              .doc('overview')
                              .collection('plans')
                              .add({
                                'id': idController.text.trim(),
                                'title': titleController.text.trim(),
                                'team': teamController.text.trim(),
                                'status': status,
                                'due': dueController.text.trim(),
                                'owner': ownerController.text.trim(),
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                          if (mounted) Navigator.of(dialogContext).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Add plan'),
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyPanelMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF64748B))),
    );
  }

  Widget _emptyState({required String message, required VoidCallback onAdd}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(message, style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add plan item'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dialogDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.6)),
    );
  }

  Widget _dialogField(String label, {required TextEditingController controller, String? hint}) {
    return TextFormField(
      controller: controller,
      decoration: _dialogDecoration(label, hint: hint),
    );
  }

  Widget _buildCoveragePanel() {
    return _PanelShell(
      title: 'Readiness coverage',
      subtitle: 'Operational readiness by capability',
      child: Column(
        children: [
          if (_coverage.isEmpty)
            _emptyPanelMessage('No coverage items yet.')
          else
            ..._coverage.map(_buildCoverageRow),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addCoverageItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add coverage line'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: const Color(0xFFFFF3C4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalsPanel() {
    return _PanelShell(
      title: 'Ops signals',
      subtitle: 'Items that need immediate attention',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_signals.isEmpty)
            _emptyPanelMessage('No ops signals yet.')
          else
            ..._signals.map(_buildSignalRow),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addSignal,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add ops signal'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: const Color(0xFFFFF3C4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenancePanel() {
    return _PanelShell(
      title: 'Maintenance windows',
      subtitle: 'Upcoming maintenance schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_maintenanceWindows.isEmpty)
            _emptyPanelMessage('No maintenance windows yet.')
          else
            ..._maintenanceWindows.map(_buildMaintenanceRow),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addMaintenanceWindow,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add maintenance window'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: const Color(0xFFFFF3C4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label) {
    Color color;
    switch (label) {
      case 'Ready':
        color = const Color(0xFF10B981);
        break;
      case 'In review':
        color = const Color(0xFF0EA5E9);
        break;
      case 'Pending':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = const Color(0xFF6366F1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildCoverageRow(_CoverageItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('coverage-label-${item.id}'),
                  initialValue: item.label,
                  decoration: _inlineDecoration('Coverage label'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  onChanged: (value) =>
                      _updateCoverage(item.copyWith(label: value)),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextFormField(
                  key: ValueKey('coverage-progress-${item.id}'),
                  initialValue: (item.progress * 100).round().toString(),
                  decoration: _inlineDecoration('%'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final parsed = double.tryParse(value) ?? 0;
                    _updateCoverage(
                        item.copyWith(progress: (parsed / 100).clamp(0.0, 1.0)));
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                onPressed: () => _deleteCoverage(item.id),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalRow(_SignalItem signal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: ValueKey('signal-title-${signal.id}'),
                  initialValue: signal.title,
                  decoration: _inlineDecoration('Signal title'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  onChanged: (value) => _updateSignal(signal.copyWith(title: value)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: ValueKey('signal-sub-${signal.id}'),
                  initialValue: signal.subtitle,
                  decoration: _inlineDecoration('Signal detail'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  onChanged: (value) => _updateSignal(signal.copyWith(subtitle: value)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteSignal(signal.id),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceRow(_MaintenanceWindowItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  const BoxDecoration(color: Color(0xFF0EA5E9), shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  key: ValueKey('maintenance-title-${item.id}'),
                  initialValue: item.title,
                  decoration: _inlineDecoration('Window'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  onChanged: (value) =>
                      _updateMaintenance(item.copyWith(title: value)),
                ),
                TextFormField(
                  key: ValueKey('maintenance-time-${item.id}'),
                  initialValue: item.time,
                  decoration: _inlineDecoration('Time window'),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  onChanged: (value) =>
                      _updateMaintenance(item.copyWith(time: value)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: TextFormField(
              key: ValueKey('maintenance-status-${item.id}'),
              initialValue: item.status,
              decoration: _inlineDecoration('Status'),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              onChanged: (value) =>
                  _updateMaintenance(item.copyWith(status: value)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteMaintenance(item.id),
          ),
        ],
      ),
    );
  }

  InputDecoration _inlineDecoration(String hint) {
    return const InputDecoration(
      isDense: true,
      border: InputBorder.none,
      hintText: '',
    ).copyWith(hintText: hint);
  }

  void _updateStat(_StatCardData data) {
    final index = _stats.indexWhere((item) => item.id == data.id);
    if (index == -1) return;
    setState(() => _stats[index] = data);
    _scheduleSave();
  }

  void _addCoverageItem() {
    setState(() {
      _coverage.add(
        _CoverageItem(id: _newId(), label: '', progress: 0, color: const Color(0xFF0EA5E9)),
      );
    });
    _scheduleSave();
  }

  void _updateCoverage(_CoverageItem item) {
    final index = _coverage.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _coverage[index] = item);
    _scheduleSave();
  }

  void _deleteCoverage(String id) {
    setState(() => _coverage.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addSignal() {
    setState(() {
      _signals.add(_SignalItem(id: _newId(), title: '', subtitle: ''));
    });
    _scheduleSave();
  }

  void _updateSignal(_SignalItem signal) {
    final index = _signals.indexWhere((item) => item.id == signal.id);
    if (index == -1) return;
    setState(() => _signals[index] = signal);
    _scheduleSave();
  }

  void _deleteSignal(String id) {
    setState(() => _signals.removeWhere((item) => item.id == id));
    _scheduleSave();
  }

  void _addMaintenanceWindow() {
    setState(() {
      _maintenanceWindows.add(
        _MaintenanceWindowItem(id: _newId(), title: '', time: '', status: ''),
      );
    });
    _scheduleSave();
  }

  void _updateMaintenance(_MaintenanceWindowItem item) {
    final index =
        _maintenanceWindows.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    setState(() => _maintenanceWindows[index] = item);
    _scheduleSave();
  }

  void _deleteMaintenance(String id) {
    setState(() => _maintenanceWindows.removeWhere((item) => item.id == id));
    _scheduleSave();
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CoverageItem {
  const _CoverageItem({
    required this.id,
    required this.label,
    required this.progress,
    required this.color,
  });

  final String id;
  final String label;
  final double progress;
  final Color color;

  _CoverageItem copyWith({String? label, double? progress, Color? color}) {
    return _CoverageItem(
      id: id,
      label: label ?? this.label,
      progress: progress ?? this.progress,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'progress': progress,
        'color': color.value,
      };

  static List<_CoverageItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _CoverageItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        progress: (map['progress'] is num)
            ? (map['progress'] as num).toDouble()
            : double.tryParse(map['progress']?.toString() ?? '0') ?? 0,
        color: Color(map['color'] is int ? map['color'] as int : const Color(0xFF0EA5E9).value),
      );
    }).toList();
  }
}

class _SignalItem {
  const _SignalItem({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;

  _SignalItem copyWith({String? title, String? subtitle}) {
    return _SignalItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
      };

  static List<_SignalItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _SignalItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
      );
    }).toList();
  }
}

class _StatCardData {
  const _StatCardData({
    required this.id,
    required this.label,
    required this.value,
    required this.supporting,
    required this.color,
  });

  final String id;
  final String label;
  final String value;
  final String supporting;
  final Color color;

  _StatCardData copyWith({
    String? label,
    String? value,
    String? supporting,
    Color? color,
  }) {
    return _StatCardData(
      id: id,
      label: label ?? this.label,
      value: value ?? this.value,
      supporting: supporting ?? this.supporting,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'value': value,
        'supporting': supporting,
        'color': color.value,
      };

  static List<_StatCardData> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _StatCardData(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        value: map['value']?.toString() ?? '',
        supporting: map['supporting']?.toString() ?? '',
        color: Color(map['color'] is int ? map['color'] as int : const Color(0xFF0EA5E9).value),
      );
    }).toList();
  }
}

class _MaintenanceWindowItem {
  const _MaintenanceWindowItem({
    required this.id,
    required this.title,
    required this.time,
    required this.status,
  });

  final String id;
  final String title;
  final String time;
  final String status;

  _MaintenanceWindowItem copyWith({String? title, String? time, String? status}) {
    return _MaintenanceWindowItem(
      id: id,
      title: title ?? this.title,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'time': time,
        'status': status,
      };

  static List<_MaintenanceWindowItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _MaintenanceWindowItem(
        id: map['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        time: map['time']?.toString() ?? '',
        status: map['status']?.toString() ?? '',
      );
    }).toList();
  }
}

class _Debouncer {
  _Debouncer({Duration? delay}) : delay = delay ?? const Duration(milliseconds: 600);

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
