import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';

class TrainingProjectTasksScreen extends StatelessWidget {
  const TrainingProjectTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          _sidebar(context),
          Expanded(child: _main()),
        ],
      ),
    );
  }

  Widget _sidebar(BuildContext context) {
    return Container(
      width: 320,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFFFD700), width: 3),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppLogo(
                height: 56,
                width: 148,
              ),
              SizedBox(height: 20),
              Row(children: [
                Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('StackOne', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                ]),
              ]),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: const [
                _SidebarItem(icon: Icons.group_work_outlined, title: 'Team Training and Team Building', isActive: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _main() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _circleIconButton(Icons.arrow_back_ios),
            const SizedBox(width: 12),
            _circleIconButton(Icons.arrow_forward_ios),
            const SizedBox(width: 16),
            const Expanded(
              child: Center(child: Text('Project Tasks', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600))),
            ),
            _profileChip(),
          ]),
          const SizedBox(height: 8),
          // Search and actions
          Row(children: [
            // Search
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  Icon(Icons.search, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration.collapsed(hintText: 'Search...'),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_alt_outlined),
              label: const Text('Filter'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Lesson'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          // Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
            ),
            child: DataTable(
              columnSpacing: 20,
              headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('LESSON')),
                DataColumn(label: Text('TYPE')),
                DataColumn(label: Text('CATEGORY')),
                DataColumn(label: Text('PHASE')),
                DataColumn(label: Text('IMPACT')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('SUBMITTED BY')),
                DataColumn(label: Text('DATE')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: List.generate(4, (i) => _row(i)),
            ),
          ),
        ]),
      ),
    );
  }

  DataRow _row(int index) {
    final strong = index == 0;
    final textStyleMuted = TextStyle(color: Colors.grey[400]);
    final baseStyle = strong ? const TextStyle(color: Colors.black) : textStyleMuted;
    return DataRow(cells: [
      DataCell(Text('${index + 1}', style: baseStyle)),
      DataCell(Text(strong ? 'T-001' : 'T-001', style: baseStyle)),
      DataCell(Text('Early stakeholder engagement improved', style: baseStyle)),
      DataCell(_chip(text: 'Success', bg: const Color(0xFFE6F4EA), fg: const Color(0xFF2E7D32))),
      DataCell(_chip(text: 'Process', bg: const Color(0xFFE6F4EA), fg: const Color(0xFF2E7D32))),
      DataCell(Text('Planning', style: baseStyle)),
      DataCell(_chip(text: 'High', bg: const Color(0xFFFFEBEE), fg: const Color(0xFFC62828))),
      DataCell(_chip(text: 'Implemented', bg: const Color(0xFFFFEBEE), fg: const Color(0xFFC62828))),
      DataCell(Text('Emily Johnson', style: baseStyle)),
      DataCell(Text('2025-02-15', style: baseStyle)),
      const DataCell(Icon(Icons.edit_outlined, size: 20)),
    ]);
  }

  Widget _chip({required String text, required Color bg, required Color fg}) {
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _circleIconButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, size: 16, color: Colors.grey[700]),
    );
  }

  Widget _profileChip() {
    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final user = FirebaseAuth.instance.currentUser;
        final displayName = FirebaseAuthService.displayNameOrEmail(fallback: 'User');
        final email = user?.email ?? '';
        final name = displayName.isNotEmpty ? displayName : (email.isNotEmpty ? email : 'User');
        final photoUrl = user?.photoURL ?? '';
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[400],
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(role, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 8),
              Icon(Icons.keyboard_arrow_down, color: Colors.grey[700], size: 18),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  const _SidebarItem({required this.icon, required this.title, this.isActive = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.grey.withValues(alpha: 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700]), softWrap: true, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}
