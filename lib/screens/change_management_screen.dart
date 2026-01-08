import 'package:flutter/material.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/widgets/new_change_request_dialog.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/services/change_request_service.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/utils/download_helper.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/screens/project_framework_screen.dart';
import 'package:ndu_project/providers/project_data_provider.dart';

class ChangeManagementScreen extends StatefulWidget {
  const ChangeManagementScreen({super.key});

  @override
  State<ChangeManagementScreen> createState() => _ChangeManagementScreenState();
}

class _ChangeManagementScreenState extends State<ChangeManagementScreen> {
  final GlobalKey<_ChangeRequestsTableState> _tableKey = GlobalKey<_ChangeRequestsTableState>();


  @override
  Widget build(BuildContext context) {
    final String userName = FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: sidebarWidth,
              child: const InitiationLikeSidebar(activeItemLabel: 'Change Management'),
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
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              _circleButton(icon: Icons.arrow_back_ios_new_rounded),
                              const SizedBox(width: 12),
                              _circleButton(icon: Icons.arrow_forward_ios_rounded),
                              const SizedBox(width: 20),
                              const Text(
                                'Change Management',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                              ),
                              const Spacer(),
                              _UserChip(userName: userName),
                              const SizedBox(width: 12),
                              _OutlinedButton(label: 'Export', onPressed: () {}),
                              const SizedBox(width: 10),
                              _YellowButton(label: 'New Project', onPressed: () {}),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildAiNotesCard(),
                        const SizedBox(height: 24),
                        // Page title
                        const Text(
                          'Contract Management',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Track, evaluate, and manage project change requests.',
                          style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Spacer(),
                            _smallButton(context, icon: Icons.ios_share_outlined, label: 'Export'),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await showDialog(
                                  context: context,
                                builder: (ctx) => NewChangeRequestDialog(),
                                );
                                if (result != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Change request created')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('New Project', style: TextStyle(fontWeight: FontWeight.w600)),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Process Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.08),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: const Text('Change Management Process', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: const [
                                        Expanded(child: _StepTile(step: 1, title: 'Request', subtitle: 'submit change request with details')),
                                        SizedBox(width: 12),
                                        Expanded(child: _StepTile(step: 2, title: 'Evaluate', subtitle: 'Analyze impacts and feasibility')),
                                        SizedBox(width: 12),
                                        Expanded(child: _StepTile(step: 3, title: 'Approve', subtitle: 'Core Stakeholders review and decide')),
                                        SizedBox(width: 12),
                                        Expanded(child: _StepTile(step: 4, title: 'Implement', subtitle: 'Execute and document the change')),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Stats (live from Firestore)
                        const _StatsRow(),

                        const SizedBox(height: 16),

                        // Change requests table header
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Change requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                            _smallButton(
                              context,
                              icon: Icons.filter_list,
                              label: 'Filter',
                              onPressed: () => _tableKey.currentState?.openFilterDialog(context),
                            ),
                            const SizedBox(width: 8),
                            _smallButton(
                              context,
                              icon: Icons.ios_share_outlined,
                              label: 'Export',
                              onPressed: () => _tableKey.currentState?.exportCurrentSnapshot(context),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await showDialog(
                                  context: context,
                                builder: (ctx) => NewChangeRequestDialog(),
                                );
                                if (result != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Change request created')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('New Change request', style: TextStyle(fontWeight: FontWeight.w600)),
                            )
                          ],
                        ),

                        const SizedBox(height: 10),

                        _ChangeRequestsTable(key: _tableKey),
                        const SizedBox(height: 24),
                          LaunchPhaseNavigation(
                            backLabel: 'Back: Issue Management',
                            nextLabel: 'Next: Project Management Framework',
                            onBack: () => Navigator.of(context).maybePop(),
                            onNext: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProjectFrameworkScreen())),
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

  Widget _smallButton(BuildContext context, {required IconData icon, required String label, VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: Colors.grey[800]),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            BoxShadow(color: Color(0x0F000000), blurRadius: 18, offset: Offset(0, 12)),
          ],
        ),
        child: const Text(
          'AI Notes unavailable (project context not loaded).',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      );
    }
    return const PlanningAiNotesCard(
      title: 'AI Notes',
      sectionLabel: 'Change Management',
      noteKey: 'planning_change_management_notes',
      checkpoint: 'change_management',
      description: 'Capture change governance, approval workflows, and impact assessment focus areas.',
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
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              const Text(
                'Owner',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: const Color(0xFF111827),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _YellowButton extends StatelessWidget {
  const _YellowButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD54F),
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  const _StepTile({required this.step, required this.title, required this.subtitle});
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
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: Center(child: Text('$step', style: const TextStyle(fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ChangeRequestService.streamChangeRequests(),
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
  const _ChangeRequestsTable({super.key});

  @override
  State<_ChangeRequestsTable> createState() => _ChangeRequestsTableState();
}

class _ChangeRequestsTableState extends State<_ChangeRequestsTable> {
  final Set<String> _statusFilters = {'Pending', 'Approved', 'Rejected'};
  final List<String> _allStatuses = const ['Pending', 'Approved', 'Rejected'];
  List<ChangeRequest> _latestItems = [];

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
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
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

  Future<void> exportCurrentSnapshot(BuildContext context) async {
    if (_latestItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No change requests to export')));
      return;
    }
    final buffer = StringBuffer();
    buffer.writeln('ID,Title,Request Date,Type,Impact,Status,Requester');
    for (final request in _latestItems) {
      buffer.writeln(
        [
          request.displayId,
          _escapeCsv(request.title),
          _formatDate(request.requestDate),
          request.type,
          request.impact,
          request.status,
          request.requester,
        ].join(','),
      );
    }
    downloadTextFile('change_requests.csv', buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export prepared')));
  }

  Future<void> _openEditDialog(ChangeRequest request) async {
    await showDialog(
      context: context,
      builder: (ctx) => NewChangeRequestDialog(
        changeRequest: request,
        onSaved: () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Change request updated')));
          }
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String _escapeCsv(String value) {
    final needsQuotes = value.contains(',') || value.contains('"') || value.contains('\n');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: boxWidth),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.10), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                  child: _TableRow(
                    isHeader: true,
                    cells: ['#', 'ID', 'TITLE', 'REQUEST DATE', 'TYPE', 'IMPACT', 'STATUS', 'REQUESTER', 'Actions'],
                  ),
                  ),
                  StreamBuilder(
                    stream: ChangeRequestService.streamChangeRequests(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                        );
                      }
                      final items = snapshot.data ?? [];
                      _latestItems = items;
                      final filtered = items.where((item) => _statusFilters.contains(item.status)).toList();
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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
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

class _TableRow extends StatelessWidget {
  final List<String> cells;
  final bool isHeader;
  final ChangeRequest? request;
  final void Function(ChangeRequest)? onEdit;

  _TableRow({
    required this.cells,
    required this.isHeader,
    this.request,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    const flexes = [2, 3, 6, 4, 3, 4, 4, 4, 3];
    final TextStyle headerStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87);
    final TextStyle cellStyle = const TextStyle(fontSize: 13, color: Colors.black87);
    return Row(
      children: [
        for (int i = 0; i < cells.length; i++)
          if (i == cells.length - 1)
            _actionsCell(
              flex: flexes[i],
              context: context,
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              text: cells[i],
              request: request,
              onEdit: onEdit,
            )
          else if (i == 4)
            _typeCell(cells[i], flex: flexes[i], isHeader: isHeader, headerStyle: headerStyle, cellStyle: cellStyle)
          else if (i == 6)
            _statusCell(cells[i], flex: flexes[i], isHeader: isHeader, headerStyle: headerStyle, cellStyle: cellStyle)
          else
            _cell(
              cells[i],
              flex: flexes[i],
              isHeader: isHeader,
              headerStyle: headerStyle,
              cellStyle: cellStyle,
              textAlign: {0, 5}.contains(i) ? TextAlign.center : TextAlign.left,
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
      child: Text(text, style: isHeader ? headerStyle : cellStyle, overflow: TextOverflow.ellipsis, textAlign: textAlign),
    );
  }

  Widget _typeCell(String text, {required int flex, required bool isHeader, required TextStyle headerStyle, required TextStyle cellStyle}) {
    if (isHeader) return _cell(text, flex: flex, isHeader: isHeader, headerStyle: headerStyle, cellStyle: cellStyle);
    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFE7F0FF), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFB2C6FF))),
          child: Text(text, style: const TextStyle(color: Color(0xFF3B5EDB), fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _statusCell(String text, {required int flex, required bool isHeader, required TextStyle headerStyle, required TextStyle cellStyle}) {
    if (isHeader) return _cell(text, flex: flex, isHeader: isHeader, headerStyle: headerStyle, cellStyle: cellStyle);
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
            style: TextStyle(color: _statusColor(text), fontWeight: FontWeight.w700, fontSize: 12),
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
      return _cell(text, flex: flex, isHeader: true, headerStyle: headerStyle, cellStyle: cellStyle);
    }

    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Edit request',
            onPressed: request == null ? null : () => onEdit?.call(request),
            icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey[700]),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_horiz, size: 18, color: Colors.grey[700]),
            onSelected: (value) async {
              if (value != 'delete' || request == null) return;
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete change request?'),
                  content: const Text('This action cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirmed != true) return;
              try {
                await ChangeRequestService.deleteChangeRequest(request.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Change request deleted')));
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String>(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }
}
