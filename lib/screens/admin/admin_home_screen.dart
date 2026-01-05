import 'package:flutter/material.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/services/navigation_context_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/project_service.dart';
import 'package:ndu_project/screens/admin/admin_users_screen.dart';
import 'package:ndu_project/screens/admin_content_screen.dart';
import 'package:ndu_project/screens/admin/admin_projects_screen.dart';
import 'package:ndu_project/screens/home_screen.dart';
import 'package:ndu_project/widgets/app_logo.dart';

import 'package:ndu_project/screens/admin/admin_coupons_screen.dart';
import 'package:ndu_project/screens/admin/admin_subscription_lookup_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Record admin dashboard context for logo navigation
    NavigationContextService.instance.setLastAdminDashboard(AppRoutes.adminHome);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8FAFF), Color(0xFFF6F7FB)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            right: -120,
            top: -80,
            child: _FrostedOrb(
              size: 260,
              color: const Color(0xFFFFC107).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: -140,
            bottom: 120,
            child: _FrostedOrb(
              size: 240,
              color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(context),
                const SizedBox(height: 28),
                _buildStatsGrid(),
                const SizedBox(height: 32),
                const Text('Quick Actions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _buildQuickActions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          return Wrap(
            spacing: 24,
            runSpacing: 20,
            alignment: WrapAlignment.spaceBetween,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : constraints.maxWidth * 0.58,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFC107).withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const AppLogo(height: 44, width: 170, enableTapToDashboard: false),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Admin Console',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('System Overview', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'Monitor usage, manage critical systems, and keep projects moving forward in real time.',
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _HeroPill(icon: Icons.bolt, label: 'Live metrics'),
                        _HeroPill(icon: Icons.security, label: 'Admin secured'),
                        _HeroPill(icon: Icons.cloud_done, label: 'Realtime sync'),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: isCompact ? double.infinity : constraints.maxWidth * 0.34,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                    const SizedBox(height: 8),
                    _HeroStatTile(
                      title: 'Active sessions',
                      value: 'Realtime',
                      subtitle: 'Monitoring system health',
                      accent: const Color(0xFF4F46E5),
                    ),
                    const SizedBox(height: 12),
                    _HeroStatTile(
                      title: 'Last refresh',
                      value: 'Just now',
                      subtitle: 'All services healthy',
                      accent: const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
                  color: const Color(0xFF2563EB),
                  gradient: const [Color(0xFFE0EEFF), Color(0xFFFFFFFF)],
                  width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                ),
                _StatCard(
                  title: 'Active Users',
                  value: stats['activeUsers'].toString(),
                  icon: Icons.person_outline,
                  color: const Color(0xFF16A34A),
                  gradient: const [Color(0xFFE4F7EC), Color(0xFFFFFFFF)],
                  width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                ),
                _StatCard(
                  title: 'Admins',
                  value: stats['admins'].toString(),
                  icon: Icons.admin_panel_settings,
                  color: const Color(0xFFF59E0B),
                  gradient: const [Color(0xFFFFF3CD), Color(0xFFFFFFFF)],
                  width: isMobile ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                ),
                _StatCard(
                  title: 'Total Projects',
                  value: stats['projects'].toString(),
                  icon: Icons.folder,
                  color: const Color(0xFF7C3AED),
                  gradient: const [Color(0xFFF1E8FF), Color(0xFFFFFFFF)],
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
              title: 'Executive Dashboard',
              description: 'Real-time pulse across every project, program, and portfolio',
              icon: Icons.dashboard_customize_outlined,
              color: const Color(0xFF5B21B6),
              onTap: () => HomeScreen.open(context),
              width: cardWidth,
            ),
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
    required this.gradient,
    required this.width,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 18),
          Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
              ),
              const SizedBox(width: 6),
              Text('Updated just now', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('Manage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Open', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
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

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1F2937)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _FrostedOrb extends StatelessWidget {
  const _FrostedOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
