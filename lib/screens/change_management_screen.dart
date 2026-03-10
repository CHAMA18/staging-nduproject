import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/widgets/new_change_request_dialog.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/services/change_request_service.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';

class ChangeManagementScreen extends StatefulWidget {
  const ChangeManagementScreen({super.key});

  @override
  State<ChangeManagementScreen> createState() => _ChangeManagementScreenState();
}

class _ChangeManagementScreenState extends State<ChangeManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final String userName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: sidebarWidth,
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Change Management'),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top navigation bar
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              children: [
                                _circleButton(
                                    icon: Icons.arrow_back_ios_new_rounded,
                                    onTap: () =>
                                        PlanningPhaseNavigation.goToPrevious(
                                            context, 'change_management')),
                                const SizedBox(width: 12),
                                _circleButton(
                                    icon: Icons.arrow_forward_ios_rounded,
                                    onTap: () =>
                                        PlanningPhaseNavigation.goToNext(
                                            context, 'change_management')),
                                const SizedBox(width: 20),
                                const Text(
                                  'Change Management',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827)),
                                ),
                                const Spacer(),
                                _UserChip(userName: userName),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildAiNotesCard(),
                          const SizedBox(height: 24),
                          // Page title
                          const Text(
                            'Contract Management',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Track, evaluate, and manage project change requests.',
                            style: TextStyle(
                                fontSize: 15, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Stats (live from Firestore)
                          _StatsRow(
                              projectId:
                                  ProjectDataHelper.getData(context).projectId),

                          const SizedBox(height: 16),

                          _ChangeRegisterCard(
                            projectId:
                                ProjectDataHelper.getData(context).projectId,
                          ),
                          const SizedBox(height: 24),
                          LaunchPhaseNavigation(
                            backLabel: PlanningPhaseNavigation.backLabel(
                                'change_management'),
                            nextLabel: PlanningPhaseNavigation.nextLabel(
                                'change_management'),
                            onBack: () => PlanningPhaseNavigation.goToPrevious(
                                context, 'change_management'),
                            onNext: () => PlanningPhaseNavigation.goToNext(
                                context, 'change_management'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiNotesCard() {
    final provider = ProjectDataInherited.maybeOf(context);
    if (provider == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 18,
                offset: Offset(0, 12)),
          ],
        ),
        child: const Text(
          'AI Notes unavailable (project context not loaded).',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      );
    }
    return const PlanningAiNotesCard(
      title: 'Notes',
      sectionLabel: 'Change Management',
      noteKey: 'planning_change_management_notes',
      checkpoint: 'change_management',
      description:
          'Capture change governance, approval workflows, and impact assessment focus areas.',
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final name = userName.isNotEmpty
        ? userName
        : FirebaseAuthService.displayNameOrEmail(fallback: 'User');

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[400],
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                  ),
                  Text(
                    role,
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepTile extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  const _StepTile(
      {required this.step, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.18),
                  shape: BoxShape.circle),
              child: Center(
                  child: Text('$step',
                      style: const TextStyle(fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  const _StatTile({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({this.projectId});
  final String? projectId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ChangeRequestService.streamChangeRequests(projectId: projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: const [
              Expanded(child: _StatTile(title: 'Total Changes', value: '—')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(title: 'Pending', value: '—')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(title: 'Approved', value: '—')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(title: 'Rejected', value: '—')),
            ],
          );
        }
        if (snapshot.hasError) {
          // Fallback to zeros on error while keeping the layout stable.
          return Row(
            children: const [
              Expanded(child: _StatTile(title: 'Total Changes', value: '0')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(title: 'Pending', value: '0')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(title: 'Approved', value: '0')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(title: 'Rejected', value: '0')),
            ],
          );
        }

        final items = snapshot.data ?? [];
        final total = items.length;
        int pending = 0, approved = 0, rejected = 0;
        for (final r in items) {
          switch (r.status.toLowerCase()) {
            case 'approved':
              approved++;
              break;
            case 'rejected':
              rejected++;
              break;
            case 'pending':
            default:
              pending++;
          }
        }

        return Row(
          children: [
            Expanded(child: _StatTile(title: 'Total Changes', value: '$total')),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(title: 'Pending', value: '$pending')),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(title: 'Approved', value: '$approved')),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(title: 'Rejected', value: '$rejected')),
          ],
        );
      },
    );
  }
}

class _ChangeRequestsTable extends StatefulWidget {
  const _ChangeRequestsTable({super.key, this.projectId});

  final String? projectId;

  @override
  State<_ChangeRequestsTable> createState() => _ChangeRequestsTableState();
}

class _ChangeRequestsTableState extends State<_ChangeRequestsTable> {
  final Set<String> _statusFilters = {'Pending', 'Approved', 'Rejected'};
  final List<String> _allStatuses = const ['Pending', 'Approved', 'Rejected'];

  Future<void> openFilterDialog(BuildContext context) async {
    final selected = Set<String>.from(_statusFilters);
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Filter change requests'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _allStatuses
                .map(
                  (status) => CheckboxListTile(
                    value: selected.contains(status),
                    title: Text(status),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setStateDialog(() {
                        if (value ?? false) {
                          selected.add(status);
                        } else {
                          selected.remove(status);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                setState(() {
                  _statusFilters
                    ..clear()
                    ..addAll(selected.isEmpty ? _allStatuses : selected);
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialog(ChangeRequest request) async {
    await showDialog(
      context: context,
      builder: (ctx) => NewChangeRequestDialog(
        changeRequest: request,
        onSaved: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change request updated')));
          }
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        final targetWidth = boxWidth < 1000 ? 1000.0 : boxWidth;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: targetWidth,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.10),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12))),
                    child: _TableRow(
                      isHeader: true,
                      cells: [
                        '#',
                        'ID',
                        'TITLE',
                        'REQUEST DATE',
                        'TYPE',
                        'IMPACT',
                        'STATUS',
                        'REQUESTER',
                        'Actions',
                      ],
                    ),
                  ),
                  StreamBuilder(
                    stream: ChangeRequestService.streamChangeRequests(
                        projectId: widget.projectId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.redAccent)),
                        );
                      }
                      final items = snapshot.data ?? [];
                      final filtered = items
                          .where((item) => _statusFilters.contains(item.status))
                          .toList();
                      if (filtered.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No change requests yet.'),
                        );
                      }
                      return Column(
                        children: [
                          for (int index = 0; index < filtered.length; index++)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                                        color: Colors.grey
                                            .withValues(alpha: 0.15))),
                              ),
                              child: _TableRow(
                                isHeader: false,
                                cells: [
                                  '${index + 1}',
                                  filtered[index].displayId,
                                  filtered[index].title,
                                  _formatDate(filtered[index].requestDate),
                                  filtered[index].type,
                                  filtered[index].impact,
                                  filtered[index].status,
                                  filtered[index].requester,
                                  '',
                                ],
                                request: filtered[index],
                                onEdit: _openEditDialog,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChangeRegisterCard extends StatefulWidget {
  const _ChangeRegisterCard({required this.projectId});

  final String? projectId;

  @override
  State<_ChangeRegisterCard> createState() => _ChangeRegisterCardState();
}

class _ChangeRegisterCardState extends State<_ChangeRegisterCard> {
  Future<void> _openChangeDialog({ChangeRequest? request}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => NewChangeRequestDialog(
        changeRequest: request,
        projectId: widget.projectId,
      ),
    );
    if (!mounted) return;
    if (result == true) {
      final message =
          request == null ? 'Change request created' : 'Change request updated';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteRequest(ChangeRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete change request'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) return;
    try {
      await ChangeRequestService.deleteChangeRequest(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Change request deleted')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $error')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'in review':
        return const Color(0xFFF59E0B);
      case 'submitted':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF8D6E00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Change Request Register',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openChangeDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New change request',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Track scope change requests, impact, and approval status.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<ChangeRequest>>(
            stream: ChangeRequestService.streamChangeRequests(
                projectId: widget.projectId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                      'Unable to load change requests: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red)),
                );
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  alignment: Alignment.center,
                  child: const Text('No change requests have been created yet.',
                      style: TextStyle(color: Color(0xFF6B7280))),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowHeight: 44,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 52,
                        headingRowColor:
                            WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(
                              label: Text('ID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(
                              label: Text('Request',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(
                              label: Text('Impact',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(
                              label: Text('Owner',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(
                              label: Text('Status',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(
                              label: Text('Actions',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600))),
                        ],
                        rows: requests.map((request) {
                          return DataRow(cells: [
                            DataCell(Text(request.displayId,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF0EA5E9)))),
                            DataCell(Text(request.title,
                                style: const TextStyle(fontSize: 13))),
                            DataCell(Text(request.impact,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600))),
                            DataCell(Text(request.requester,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B)))),
                            DataCell(_StatusChip(
                                label: request.status,
                                color: _statusColor(request.status))),
                            DataCell(
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit request',
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18, color: Color(0xFF111827)),
                                    onPressed: () =>
                                        _openChangeDialog(request: request),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete request',
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: Color(0xFFEF4444)),
                                    onPressed: () => _deleteRequest(request),
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final List<String> cells;
  final bool isHeader;
  final ChangeRequest? request;
  final void Function(ChangeRequest)? onEdit;

  const _TableRow({
    required this.cells,
    required this.isHeader,
    this.request,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Columns: #(0), ID(1), TITLE(2), REQUEST DATE(3), TYPE(4), IMPACT(5), STATUS(6), REQUESTER(7), Actions(8)
    const flexes = [2, 3, 6, 4, 3, 4, 4, 4, 3];
    final TextStyle headerStyle = const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87);
    final TextStyle cellStyle =
        const TextStyle(fontSize: 13, color: Colors.black87);
    return Row(
      children: [
        for (int i = 0; i < cells.length; i++)
          if (i == cells.length - 1) // Actions column at end
            _actionsCell(
              flex: flexes[i],
              context: context,
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              text: cells[i],
              request: request,
              onEdit: onEdit,
            )
          else if (i == 4) // TYPE column
            _typeCell(cells[i],
                flex: flexes[i],
                isHeader: isHeader,
                headerStyle: headerStyle,
                cellStyle: cellStyle)
          else if (i == 6) // STATUS column
            _statusCell(cells[i],
                flex: flexes[i],
                isHeader: isHeader,
                headerStyle: headerStyle,
                cellStyle: cellStyle)
          else
            _cell(
              cells[i],
              flex: flexes[i],
              isHeader: isHeader,
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              textAlign: i == 0 ? TextAlign.center : TextAlign.left,
            ),
      ],
    );
  }

  Widget _cell(String text,
      {required int flex,
      required bool isHeader,
      required TextStyle headerStyle,
      required TextStyle cellStyle,
      TextAlign textAlign = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: isHeader ? headerStyle : cellStyle,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign),
    );
  }

  Widget _typeCell(String text,
      {required int flex,
      required bool isHeader,
      required TextStyle headerStyle,
      required TextStyle cellStyle}) {
    if (isHeader) {
      return _cell(text,
          flex: flex,
          isHeader: isHeader,
          headerStyle: headerStyle,
          cellStyle: cellStyle);
    }
    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFFE7F0FF),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFB2C6FF))),
          child: Text(text,
              style: const TextStyle(
                  color: Color(0xFF3B5EDB),
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ),
      ),
    );
  }

  Widget _statusCell(String text,
      {required int flex,
      required bool isHeader,
      required TextStyle headerStyle,
      required TextStyle cellStyle}) {
    if (isHeader) {
      return _cell(text,
          flex: flex,
          isHeader: isHeader,
          headerStyle: headerStyle,
          cellStyle: cellStyle);
    }
    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(text).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            text,
            style: TextStyle(
                color: _statusColor(text),
                fontWeight: FontWeight.w700,
                fontSize: 12),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'pending':
      default:
        return const Color(0xFF8D6E00);
    }
  }

  Widget _actionsCell({
    required int flex,
    required BuildContext context,
    required TextStyle headerStyle,
    required TextStyle cellStyle,
    required String text,
    ChangeRequest? request,
    void Function(ChangeRequest)? onEdit,
  }) {
    if (isHeader) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Text(text,
              style: headerStyle,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
        ),
      );
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'View request',
              onPressed: request == null ? null : () => onEdit?.call(request),
              icon: Icon(Icons.visibility_outlined,
                  size: 18, color: Colors.grey[700]),
            ),
            IconButton(
              tooltip: 'Delete request',
              icon:
                  const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: request == null
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete change request?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        await ChangeRequestService.deleteChangeRequest(
                            request.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Change request deleted')));
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Delete failed: $error')));
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
