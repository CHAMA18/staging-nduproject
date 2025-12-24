import 'package:flutter/material.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/widgets/new_change_request_dialog.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/services/change_request_service.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';

class ChangeManagementScreen extends StatelessWidget {
  const ChangeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userName = FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: sidebarWidth,
                  child: const InitiationLikeSidebar(activeItemLabel: 'Change Management'),
                ),
                Expanded(
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
                                  builder: (ctx) => const NewChangeRequestDialog(),
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
                            _smallButton(context, icon: Icons.filter_list, label: 'Filter'),
                            const SizedBox(width: 8),
                            _smallButton(context, icon: Icons.ios_share_outlined, label: 'Export'),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await showDialog(
                                  context: context,
                                  builder: (ctx) => const NewChangeRequestDialog(),
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

                        _ChangeRequestsTable(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const KazAiChatBubble(),
          ],
        ),
      ),
    );
  }

  Widget _smallButton(BuildContext context, {required IconData icon, required String label}) {
    return OutlinedButton.icon(
      onPressed: () {},
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

class _ChangeRequestsTable extends StatelessWidget {
  const _ChangeRequestsTable();

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.10), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
            child: const _TableRow(
              isHeader: true,
              cells: ['#', 'ID', 'TITLE', 'REQUEST DATE', 'TYPE', 'IMPACT', 'STATUS', 'REQUESTER', 'ACTIONS'],
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
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No change requests yet.'),
                );
              }
              return Column(
                children: [
                  for (int index = 0; index < items.length; index++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
                      ),
                      child: _TableRow(
                        isHeader: false,
                        cells: [
                          '${index + 1}',
                          items[index].displayId,
                          items[index].title,
                          _formatDate(items[index].requestDate),
                          items[index].type,
                          items[index].impact,
                          items[index].status,
                          items[index].requester,
                          '',
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final List<String> cells;
  final bool isHeader;
  const _TableRow({required this.cells, required this.isHeader});

  @override
  Widget build(BuildContext context) {
    TextStyle headerStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87);
    TextStyle cellStyle = const TextStyle(fontSize: 13, color: Colors.black87);
    const flexes = [2, 3, 6, 4, 3, 4, 4, 4, 3];
    return Row(
      children: [
        for (int i = 0; i < cells.length; i++)
          if (i == cells.length - 1)
            _actionsCell(flex: flexes[i])
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

  Widget _actionsCell({required int flex}) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.edit_outlined, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Icon(Icons.more_horiz, size: 18, color: Colors.grey[700]),
        ],
      ),
    );
  }
}
