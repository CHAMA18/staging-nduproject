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
                            'Change Management',
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
                  return _ChangeRequestRegisterTable(
                    requests: requests,
                    onEdit: (request) => _openChangeDialog(request: request),
                    onDelete: _deleteRequest,
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

class _ChangeRequestRegisterTable extends StatelessWidget {
  const _ChangeRequestRegisterTable({
    required this.requests,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ChangeRequest> requests;
  final ValueChanged<ChangeRequest> onEdit;
  final ValueChanged<ChangeRequest> onDelete;

  @override
  Widget build(BuildContext context) {
    const rowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    const columns = <_ChangeTableColumn>[
      _ChangeTableColumn('#', 72),
      _ChangeTableColumn('ID', 120),
      _ChangeTableColumn('Request', 320),
      _ChangeTableColumn('Impact', 150),
      _ChangeTableColumn('Owner', 180),
      _ChangeTableColumn('Status', 140),
      _ChangeTableColumn('Actions', 120),
    ];

    final contentWidth =
        columns.fold<double>(0, (sum, column) => sum + column.width);
    final minTableWidth = contentWidth + 32;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth > minTableWidth
            ? constraints.maxWidth
            : minTableWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                Container(
                  width: tableWidth,
                  padding: rowPadding,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: columns
                        .map(
                          (column) => SizedBox(
                            width: column.width,
                            child: Text(
                              column.label.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                for (int i = 0; i < requests.length; i++)
                  Container(
                    width: tableWidth,
                    padding: rowPadding,
                    decoration: BoxDecoration(
                      color: i.isEven ? Colors.white : const Color(0xFFF9FAFB),
                      border: const Border(
                        top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
                      ),
                    ),
                    child: _ChangeRequestTableRow(
                      index: i,
                      request: requests[i],
                      columns: columns,
                      onEdit: () => onEdit(requests[i]),
                      onDelete: () => onDelete(requests[i]),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

class _ChangeRequestTableRow extends StatelessWidget {
  const _ChangeRequestTableRow({
    required this.index,
    required this.request,
    required this.columns,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final ChangeRequest request;
  final List<_ChangeTableColumn> columns;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      Center(
        child: Text(
          '${index + 1}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4B5563),
          ),
        ),
      ),
      _ChangeTableTextCell(
        request.displayId,
        textAlign: TextAlign.center,
        color: const Color(0xFF0EA5E9),
        fontWeight: FontWeight.w700,
      ),
      _ChangeTableTextCell(
        request.title,
        fontWeight: FontWeight.w600,
      ),
      _ChangeTableTextCell(
        request.impact,
        textAlign: TextAlign.center,
        fontWeight: FontWeight.w600,
      ),
      _ChangeTableTextCell(request.requester),
      Center(
        child: _StatusChip(
            label: request.status, color: _statusColor(request.status)),
      ),
      Align(
        alignment: Alignment.topCenter,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit request',
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: Color(0xFF111827),
              ),
            ),
            IconButton(
              tooltip: 'Delete request',
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Color(0xFFEF4444),
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        cells.length,
        (cellIndex) => SizedBox(
          width: columns[cellIndex].width,
          child: cells[cellIndex],
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
      case 'in review':
        return const Color(0xFFF59E0B);
      case 'submitted':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF8D6E00);
    }
  }
}

class _ChangeTableTextCell extends StatelessWidget {
  const _ChangeTableTextCell(
    this.text, {
    this.textAlign = TextAlign.left,
    this.color = const Color(0xFF111827),
    this.fontWeight = FontWeight.w500,
  });

  final String text;
  final TextAlign textAlign;
  final Color color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: textAlign,
        softWrap: true,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: color,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

class _ChangeTableColumn {
  const _ChangeTableColumn(this.label, this.width);

  final String label;
  final double width;
}
