import 'package:flutter/material.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/services/navigation_context_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/project_service.dart';
import 'package:ndu_project/screens/admin/admin_users_screen.dart';
import 'package:ndu_project/screens/admin_content_screen.dart';
import 'package:ndu_project/screens/admin/admin_projects_screen.dart';

import 'package:ndu_project/screens/admin/admin_coupons_screen.dart';
import 'package:ndu_project/screens/admin/admin_subscription_lookup_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Record admin dashboard context for logo navigation
    NavigationContextService.instance.setLastAdminDashboard(AppRoutes.adminHome);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Color(0xFFFFC107), size: 28),
            const SizedBox(width: 12),
            const Text('Admin Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                FirebaseAuthService.displayNameOrEmail(fallback: 'Admin'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _handleSignOut(context),
            icon: const Icon(Icons.logout, color: Colors.black87),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Overview', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Welcome to the NDU Project Admin Dashboard', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            const SizedBox(height: 32),
            _buildStatsGrid(),
            const SizedBox(height: 32),
            const Text('Quick Actions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return FutureBuilder<Map<String, int>>(
      future: _loadStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {'users': 0, 'activeUsers': 0, 'admins': 0, 'projects': 0};

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  title: 'Total Users',
                  value: stats['users'].toString(),
                  icon: Icons.people,
                  color: const Color(0xFF2196F3),
                  width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                ),
                _StatCard(
                  title: 'Active Users',
                  value: stats['activeUsers'].toString(),
                  icon: Icons.person_outline,
                  color: const Color(0xFF4CAF50),
                  width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                ),
                _StatCard(
                  title: 'Admins',
                  value: stats['admins'].toString(),
                  icon: Icons.admin_panel_settings,
                  color: const Color(0xFFFFC107),
                  width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                ),
                _StatCard(
                  title: 'Total Projects',
                  value: stats['projects'].toString(),
                  icon: Icons.folder,
                  color: const Color(0xFF9C27B0),
                  width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, int>> _loadStats() async {
    final users = await UserService.getTotalUserCount();
    final activeUsers = await UserService.getActiveUserCount();
    final admins = await UserService.getAdminUserCount();
    final projects = await ProjectService.getTotalProjectCount();

    return {
      'users': users,
      'activeUsers': activeUsers,
      'admins': admins,
      'projects': projects,
    };
  }

  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        final cardWidth = isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 4;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _ActionCard(
              title: 'User Management',
              description: 'View and manage all users, roles, and permissions',
              icon: Icons.people,
              color: const Color(0xFF2196F3),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen())),
              width: cardWidth,
            ),
            _ActionCard(
              title: 'Content Management',
              description: 'Edit app content, labels, and system messages',
              icon: Icons.edit_document,
              color: const Color(0xFFFFC107),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminContentScreen())),
              width: cardWidth,
            ),
            _ActionCard(
              title: 'Project Overview',
              description: 'View all projects across the platform',
              icon: Icons.folder_open,
              color: const Color(0xFF9C27B0),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProjectsScreen())),
              width: cardWidth,
            ),
            _ActionCard(
              title: 'Coupon Management',
              description: 'Create and manage discount coupons for Stripe, PayPal, and Paystack',
              icon: Icons.local_offer,
              color: const Color(0xFF4CAF50),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCouponsScreen())),
              width: cardWidth,
            ),
            _ActionCard(
              title: 'Subscription Lookup',
              description: 'Search users and manage their subscriptions, trials, and access',
              icon: Icons.search,
              color: const Color(0xFF00BCD4),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSubscriptionLookupScreen())),
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107)),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await FirebaseAuthService.signOut();
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.width,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Manage', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: color, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
