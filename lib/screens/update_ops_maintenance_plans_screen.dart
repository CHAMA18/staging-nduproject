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

  final List<_CoverageItem> _coverage = const [
    _CoverageItem('Runbooks updated', 0.82, Color(0xFF10B981)),
    _CoverageItem('Maintenance tasks', 0.64, Color(0xFF6366F1)),
    _CoverageItem('Training readiness', 0.58, Color(0xFFF59E0B)),
    _CoverageItem('Ops handoff', 0.74, Color(0xFF0EA5E9)),
  ];

  final List<_SignalItem> _signals = const [
    _SignalItem('Coverage gap', '2 plans missing owner confirmation.'),
    _SignalItem('Tooling access', '1 team pending elevated access.'),
    _SignalItem('Maintenance window', 'Nov 1 scheduled for cutover.'),
  ];

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
    final stats = [
      _StatCardData('Plans updated', '14', '4 pending', const Color(0xFF0EA5E9)),
      _StatCardData('Runbooks ready', '82%', 'Next review Fri', const Color(0xFF10B981)),
      _StatCardData('Training coverage', '58%', '2 sessions left', const Color(0xFFF59E0B)),
      _StatCardData('Maintenance risk', 'Low', 'Stable', const Color(0xFF6366F1)),
    ];

    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _buildStatCard(stat)).toList(),
      );
    }

    return Row(
      children: stats.map((stat) => Expanded(
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
          Text(data.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: data.color)),
          const SizedBox(height: 6),
          Text(data.label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(data.supporting, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: data.color)),
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
                          value: status,
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
        children: _coverage.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(item.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Text('${(item.progress * 100).round()}%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
        }).toList(),
      ),
    );
  }

  Widget _buildSignalsPanel() {
    return _PanelShell(
      title: 'Ops signals',
      subtitle: 'Items that need immediate attention',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _signals.map((signal) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(signal.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(signal.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMaintenancePanel() {
    return _PanelShell(
      title: 'Maintenance windows',
      subtitle: 'Upcoming maintenance schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _MaintenanceItem('Database patching', 'Oct 21 · 2:00 AM', 'Planned'),
          _MaintenanceItem('Network upgrade', 'Oct 28 · 1:00 AM', 'Scheduled'),
          _MaintenanceItem('Failover drill', 'Nov 03 · 10:00 PM', 'Pending approval'),
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

class _MaintenanceItem extends StatelessWidget {
  const _MaintenanceItem(this.title, this.time, this.status);

  final String title;
  final String time;
  final String status;

  @override
  Widget build(BuildContext context) {
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
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF0EA5E9), shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _CoverageItem {
  const _CoverageItem(this.label, this.progress, this.color);

  final String label;
  final double progress;
  final Color color;
}

class _SignalItem {
  const _SignalItem(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
