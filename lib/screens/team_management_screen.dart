import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/screens/stakeholder_management_screen.dart';

class TeamManagementScreen extends StatelessWidget {
  const TeamManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TeamManagementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Team Management'),
            ),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(child: _StripedBackdrop()),
                  const AdminEditToggle(),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                              child: LayoutBuilder(
                                builder: (context, contentConstraints) {
                                  // Calculate dynamic widths
                                  final double availableWidth = contentConstraints.maxWidth;
                                  // Aim for 4 columns, with a minimum width for cards
                                  // If screen is small, wrap to 2 or 1 column
                                  double cardWidth = (availableWidth - 48) / 4; // 48 = 16 spacing * 3
                                  if (cardWidth < 200) {
                                    // Fallback to 2 columns
                                    cardWidth = (availableWidth - 16) / 2;
                                  }
                                  if (cardWidth < 150) {
                                    // Fallback to 1 column
                                    cardWidth = availableWidth;
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header row with arrows, title, profile
                                      Row(
                                        children: [
                                          _circleIconButton(context, Icons.arrow_back_ios, onTap: () => Navigator.of(context).pop()),
                                          const SizedBox(width: 12),
                                          _circleIconButton(context, Icons.arrow_forward_ios),
                                          const SizedBox(width: 16),
                                          const Expanded(
                                            child: Center(
                                              child: Text(
                                                'Team Management',
                                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                                              ),
                                            ),
                                          ),
                                          _profileChip(),
                                        ],
                                      ),
                                      const SizedBox(height: 48),
                                      
                                      // Team Management Actions Section
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        runSpacing: 16,
                                        children: [
                                          const Text(
                                            'Team Management Actions',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                                          ),
                                          // Spacer if needed or just let Wrap handle space
                                          // But WrapAlignment.spaceBetween handles it.
                                          // However, if there's only one item in a line, it aligns start.
                                          // We want the buttons to be on the right if there is space.
                                          // If wrapping happens, buttons go to next line.
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton.icon(
                                                onPressed: () {},
                                                icon: const Icon(Icons.file_download_outlined, size: 18),
                                                label: const Text('Export All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(0xFF374151),
                                                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              ElevatedButton.icon(
                                                onPressed: () {},
                                                icon: const Icon(Icons.add_circle_outline, size: 18),
                                                label: const Text('Add Role', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.black,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // Action Cards
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: [
                                          SizedBox(
                                            width: cardWidth,
                                            child: _ActionCard(
                                              icon: Icons.group_outlined,
                                              title: 'Team Members',
                                              subtitle: 'Assign people to roles',
                                              iconColor: const Color(0xFF2563EB),
                                            ),
                                          ),
                                          SizedBox(
                                            width: cardWidth,
                                            child: _ActionCard(
                                              icon: Icons.account_tree_outlined,
                                              title: 'Org Chart',
                                              subtitle: 'Create hierarchy',
                                              iconColor: const Color(0xFF2563EB),
                                            ),
                                          ),
                                          SizedBox(
                                            width: cardWidth,
                                            child: _ActionCard(
                                              icon: Icons.groups_outlined,
                                              title: 'Stakeholders',
                                              subtitle: 'Manage external contacts',
                                              iconColor: const Color(0xFF2563EB),
                                            ),
                                          ),
                                          SizedBox(
                                            width: cardWidth,
                                            child: _ActionCard(
                                              icon: Icons.description_outlined,
                                              title: 'Documents',
                                              subtitle: 'Generate plans',
                                              iconColor: const Color(0xFF2563EB),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 48),
                                      
                                      // Section Header & Add Button
                                      Row(
                                        children: [
                                          const Expanded(
                                            child: Text(
                                              'Manage roles and responsibilities',
                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(Icons.add_circle_outline, size: 20),
                                            label: const Text('Add New Member', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFFD700),
                                              foregroundColor: const Color(0xFF111827),
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // Role Card - Initially shows only creator's role
                                      const _RoleCard(),

                                      const SizedBox(height: 24),

                                      // Empty State Section
                                      SizedBox(
                                        height: 200,
                                        child: const _EmptyStateSection(),
                                      ),

                                      const SizedBox(height: 24),

                                      // Next Button
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              StakeholderManagementScreen.open(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFFD700),
                                              foregroundColor: const Color(0xFF111827),
                                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                              elevation: 0,
                                            ),
                                            child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

  Widget _circleIconButton(BuildContext context, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }

  Widget _profileChip() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'User';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: user?.photoURL != null
                ? Image.network(user!.photoURL!, width: 32, height: 32, fit: BoxFit.cover,
                    errorBuilder: (ctx, _, __) => _defaultAvatar())
                : _defaultAvatar(),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const Text('Project Manager', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 18),
        ],
      ),
    );
  }
  
  Widget _defaultAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[300],
      child: const Icon(Icons.person, size: 20, color: Colors.white),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email ?? 'User';
    
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: user?.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(user!.photoURL!, fit: BoxFit.cover,
                            errorBuilder: (ctx, _, __) => const Icon(Icons.person, color: Color(0xFF2563EB), size: 24)),
                      )
                    : const Icon(Icons.person, color: Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    const Text('Project Manager', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Text(userName, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4)),
                  ]
                ),
              ),
              Icon(Icons.edit_outlined, size: 18, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 24),
          
          // Responsibilities
          const Text('Key Responsibilities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          _checkLine('Project planning and scheduling'),
          _checkLine('Resource allocation'),
          _checkLine('Risk mangement'),
          
          const SizedBox(height: 24),
          Container(height: 1, color: const Color(0xFFF3F4F6)),
          const SizedBox(height: 24),
          
          // Work Progress
          const Text('Work Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          _WorkStatusRow(label: 'Work A in prog', status: 'Done'),
          const SizedBox(height: 12),
          _WorkStatusRow(label: 'Work B in prog', status: 'Done'),
          const SizedBox(height: 12),
          _WorkStatusRow(label: 'Work C in prog', status: 'Done'),
          const SizedBox(height: 12),
          _WorkStatusRow(label: 'Work D in prog', status: 'Done'),
          const SizedBox(height: 12),
          _WorkStatusRow(label: 'Work E in prog', status: 'Not Started'),
        ],
      ),
    );
  }

  Widget _checkLine(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)))),
      ]),
    );
  }
}

class _WorkStatusRow extends StatelessWidget {
  final String label;
  final String status;

  const _WorkStatusRow({required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
        ),
        Container(
          width: 1,
          height: 16,
          color: const Color(0xFFE5E7EB),
          margin: const EdgeInsets.symmetric(horizontal: 12),
        ),
        Expanded(
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                _statusSegment('Done', status == 'Done', const Color(0xFF10B981)),
                _statusSegment('In Progress', status == 'In Progress', const Color(0xFFF59E0B)),
                _statusSegment('Not Started', status == 'Not Started', const Color(0xFFEF4444)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusSegment(String text, bool isActive, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : const Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class _EmptyStateSection extends StatelessWidget {
  const _EmptyStateSection();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No team members yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start building your project team by adding members',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add Your First Team Member'),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF),
                foregroundColor: const Color(0xFF1D4ED8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    final PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double length = 8.0;
        final double gap = 6.0;
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + length),
          paint,
        );
        distance += length + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StripedBackdrop extends StatelessWidget {
  const _StripedBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFFF9FAFC)),
        CustomPaint(painter: _StripedBackgroundPainter()),
      ],
    );
  }
}

class _StripedBackgroundPainter extends CustomPainter {
  const _StripedBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 1.5;
    const spacing = 24.0;
    for (double offset = -size.height; offset < size.width; offset += spacing) {
      final start = Offset(offset, 0);
      final end = Offset(offset + size.height, size.height);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}