import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/services/ops_service.dart';
import 'package:ndu_project/providers/project_data_provider.dart';

class IdentifyStaffOpsTeamScreen extends StatefulWidget {
  const IdentifyStaffOpsTeamScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IdentifyStaffOpsTeamScreen()),
    );
  }

  @override
  State<IdentifyStaffOpsTeamScreen> createState() => _IdentifyStaffOpsTeamScreenState();
}

class _IdentifyStaffOpsTeamScreenState extends State<IdentifyStaffOpsTeamScreen> {
  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Identify and Staff Ops Team',
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isNarrow),
                const SizedBox(height: 18),
                _buildStatsRow(isNarrow),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildRosterPanel(),
                    const SizedBox(height: 20),
                    _buildCoveragePanel(),
                    const SizedBox(height: 20),
                    _buildChecklistPanel(),
                    const SizedBox(height: 20),
                    _buildHandoffPanel(),
                  ],
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
            'OPS READINESS',
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
                    'Identify & Staff Ops Team',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Confirm operational roles, coverage, and training readiness before handover.',
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
        _actionButton(Icons.person_add_alt_1, 'Add role', onPressed: () => _showAddMemberDialog(context)),
        _actionButton(Icons.assignment_ind_outlined, 'Assign member'),
        _actionButton(Icons.description_outlined, 'Export roster'),
        _primaryButton('Publish handoff'),
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
      icon: const Icon(Icons.check_circle_outline, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    if (_projectId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<OpsMemberModel>>(
      stream: OpsService.streamMembers(_projectId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final members = snapshot.data!;
        final activeCount = members.where((m) => m.status == 'Active').length;
        final avgReadiness = members.isEmpty
            ? 0.0
            : members.map((m) => m.readinessScore).reduce((a, b) => a + b) / members.length;
        final pendingCount = members.where((m) => m.status == 'Pending').length;

        final stats = [
          _StatCardData('Roles filled', '$activeCount/${members.length}', '${members.length - activeCount} open roles', const Color(0xFF0EA5E9)),
          _StatCardData('Avg readiness', '${avgReadiness.round()}%', 'Team capability', const Color(0xFF10B981)),
          _StatCardData('Pending', '$pendingCount', pendingCount > 0 ? 'Awaiting assignment' : 'All assigned', const Color(0xFFF59E0B)),
          _StatCardData('Total members', '${members.length}', 'Ops team size', const Color(0xFF6366F1)),
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
      },
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

  Widget _buildRosterPanel() {
    if (_projectId == null) {
      return _PanelShell(
        title: 'Ops roster',
        subtitle: 'Role assignments, workload, and focus areas',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text('No project selected. Please open a project first.', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ),
      );
    }

    return _PanelShell(
      title: 'Ops roster',
      subtitle: 'Role assignments, workload, and focus areas',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: StreamBuilder<List<OpsMemberModel>>(
        stream: OpsService.streamMembers(_projectId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading members: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          final members = snapshot.data ?? [];

          if (members.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('No ops members found.', style: TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddMemberDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add First Member'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Responsibility', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Readiness', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
              rows: members.map((member) {
                return DataRow(cells: [
                  DataCell(Text(member.name, style: const TextStyle(fontSize: 13))),
                  DataCell(Text(member.role, style: const TextStyle(fontSize: 13))),
                  DataCell(Text(member.responsibility, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                  DataCell(_statusChip(member.status)),
                  DataCell(_capacityChip(member.readinessScore)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Color(0xFF64748B)),
                          onPressed: () => _showEditMemberDialog(context, member),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Color(0xFFEF4444)),
                          onPressed: () => _showDeleteMemberDialog(context, member),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoveragePanel() {
    if (_projectId == null) {
      return _PanelShell(
        title: 'Capability coverage',
        subtitle: 'Readiness by operational capability',
        child: const SizedBox.shrink(),
      );
    }

    return _PanelShell(
      title: 'Capability coverage',
      subtitle: 'Readiness by operational capability',
      child: StreamBuilder<List<OpsMemberModel>>(
        stream: OpsService.streamMembers(_projectId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No member data available', style: TextStyle(color: Color(0xFF64748B))),
              ),
            );
          }

          final members = snapshot.data!;
          final avgReadiness = members.map((m) => m.readinessScore / 100.0).reduce((a, b) => a + b) / members.length;
          final incidentResponse = members.where((m) => m.responsibility.toLowerCase().contains('incident') || m.responsibility.toLowerCase().contains('response')).isEmpty
              ? 0.0
              : members.where((m) => m.responsibility.toLowerCase().contains('incident') || m.responsibility.toLowerCase().contains('response'))
                  .map((m) => m.readinessScore / 100.0)
                  .reduce((a, b) => a + b) / members.where((m) => m.responsibility.toLowerCase().contains('incident') || m.responsibility.toLowerCase().contains('response')).length;
          final trainingCompletion = avgReadiness * 0.75; // Estimate based on readiness
          final serviceDesk = avgReadiness * 0.9; // Estimate

          final capabilities = [
            _CapabilityItem('Incident response coverage', incidentResponse > 0 ? incidentResponse : avgReadiness * 0.78, const Color(0xFF0EA5E9)),
            _CapabilityItem('Runbook completeness', avgReadiness * 0.64, const Color(0xFF6366F1)),
            _CapabilityItem('Training completion', trainingCompletion, const Color(0xFFF59E0B)),
            _CapabilityItem('Service desk readiness', serviceDesk, const Color(0xFF10B981)),
          ];

          return Column(
            children: capabilities.map((capability) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(capability.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Text('${(capability.progress * 100).round()}%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: capability.progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(capability.color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildChecklistPanel() {
    if (_projectId == null) {
      return _PanelShell(
        title: 'Readiness checklist',
        subtitle: 'Pre-handover verification',
        child: const SizedBox.shrink(),
      );
    }

    return _PanelShell(
      title: 'Readiness checklist',
      subtitle: 'Pre-handover verification',
      child: StreamBuilder<List<OpsChecklistItemModel>>(
        stream: OpsService.streamChecklist(_projectId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading checklist: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('No checklist items found.', style: TextStyle(color: Color(0xFF64748B))),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddChecklistItemDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add First Item'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(item.completed ? Icons.check_circle : Icons.radio_button_unchecked, 
                          size: 20, 
                          color: item.completed ? const Color(0xFF10B981) : const Color(0xFF94A3B8)),
                      onPressed: () {
                        OpsService.updateChecklistItem(
                          projectId: _projectId!,
                          itemId: item.id,
                          completed: !item.completed,
                        );
                      },
                    ),
                    Expanded(child: Text(item.item, style: const TextStyle(fontSize: 12))),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16, color: Color(0xFF64748B)),
                      onPressed: () => _showEditChecklistItemDialog(context, item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 16, color: Color(0xFFEF4444)),
                      onPressed: () => _showDeleteChecklistItemDialog(context, item),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildHandoffPanel() {
    return _PanelShell(
      title: 'Handoff summary',
      subtitle: 'Critical items to complete before launch',
      child: Column(
        children: const [
          _HandoffItem('On-call rotation published', 'Pending confirmation'),
          _HandoffItem('Ops runbook review', 'Scheduled for Oct 16'),
          _HandoffItem('Stakeholder sign-off', 'Awaiting sponsor'),
        ],
      ),
    );
  }

  Widget _statusChip(String label) {
    final color = label == 'Active' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _capacityChip(int value) {
    final color = value >= 80 ? const Color(0xFF10B981) : value >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$value%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showMemberDialog(context, null, projectId);
  }

  void _showEditMemberDialog(BuildContext context, OpsMemberModel member) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showMemberDialog(context, member, projectId);
  }

  void _showMemberDialog(BuildContext context, OpsMemberModel? member, String projectId) {
    final isEdit = member != null;
    final nameController = TextEditingController(text: member?.name ?? '');
    final roleController = TextEditingController(text: member?.role ?? '');
    final responsibilityController = TextEditingController(text: member?.responsibility ?? '');
    final statusController = TextEditingController(text: member?.status ?? 'Active');
    final readinessController = TextEditingController(text: member?.readinessScore.toString() ?? '0');
    final notesController = TextEditingController(text: member?.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Ops Member' : 'Add New Ops Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name *')),
              const SizedBox(height: 12),
              TextField(controller: roleController, decoration: const InputDecoration(labelText: 'Role *')),
              const SizedBox(height: 12),
              TextField(controller: responsibilityController, decoration: const InputDecoration(labelText: 'Responsibility *')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: statusController.text,
                decoration: const InputDecoration(labelText: 'Status *'),
                items: ['Active', 'Pending', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => statusController.text = v ?? 'Active',
              ),
              const SizedBox(height: 12),
              TextField(controller: readinessController, decoration: const InputDecoration(labelText: 'Readiness Score (0-100) *')),
              const SizedBox(height: 12),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || roleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in required fields')),
                );
                return;
              }

              try {
                final readiness = int.tryParse(readinessController.text) ?? 0;

                if (isEdit) {
                  await OpsService.updateMember(
                    projectId: projectId,
                    memberId: member.id,
                    name: nameController.text,
                    role: roleController.text,
                    responsibility: responsibilityController.text,
                    status: statusController.text,
                    readinessScore: readiness,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );
                } else {
                  await OpsService.createMember(
                    projectId: projectId,
                    name: nameController.text,
                    role: roleController.text,
                    responsibility: responsibilityController.text,
                    status: statusController.text,
                    readinessScore: readiness,
                    notes: notesController.text.isEmpty ? null : notesController.text,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'Member updated successfully' : 'Member added successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteMemberDialog(BuildContext context, OpsMemberModel member) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete "${member.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await OpsService.deleteMember(projectId: projectId, memberId: member.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting member: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddChecklistItemDialog(BuildContext context) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showChecklistItemDialog(context, null, projectId);
  }

  void _showEditChecklistItemDialog(BuildContext context, OpsChecklistItemModel item) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showChecklistItemDialog(context, item, projectId);
  }

  void _showChecklistItemDialog(BuildContext context, OpsChecklistItemModel? item, String projectId) {
    final isEdit = item != null;
    final itemController = TextEditingController(text: item?.item ?? '');
    final notesController = TextEditingController(text: item?.notes ?? '');
    bool completed = item?.completed ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Checklist Item' : 'Add Checklist Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: itemController, decoration: const InputDecoration(labelText: 'Item *')),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Completed'),
                value: completed,
                onChanged: (v) => setState(() => completed = v ?? false),
              ),
              const SizedBox(height: 12),
              TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (itemController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in the item field')),
                  );
                  return;
                }

                try {
                  if (isEdit) {
                    await OpsService.updateChecklistItem(
                      projectId: projectId,
                      itemId: item.id,
                      item: itemController.text,
                      completed: completed,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                    );
                  } else {
                    await OpsService.createChecklistItem(
                      projectId: projectId,
                      item: itemController.text,
                      completed: completed,
                      notes: notesController.text.isEmpty ? null : notesController.text,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Item updated successfully' : 'Item added successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteChecklistItemDialog(BuildContext context, OpsChecklistItemModel item) {
    final projectId = _projectId;
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No project selected. Please open a project first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Checklist Item'),
        content: Text('Are you sure you want to delete "${item.item}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await OpsService.deleteChecklistItem(projectId: projectId, itemId: item.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting item: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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

class _HandoffItem extends StatelessWidget {
  const _HandoffItem(this.title, this.status);

  final String title;
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
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: const Color(0xFF0EA5E9), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(status, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CapabilityItem {
  const _CapabilityItem(this.label, this.progress, this.color);

  final String label;
  final double progress;
  final Color color;
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
