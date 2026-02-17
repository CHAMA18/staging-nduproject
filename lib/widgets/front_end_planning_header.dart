import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/screens/project_activities_log_screen.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/services/user_service.dart';

/// Standardized header for all Front End Planning pages
/// Displays: back button, title, and user profile with email and role
class FrontEndPlanningHeader extends StatelessWidget {
  const FrontEndPlanningHeader({
    super.key,
    this.title = 'Front End Planning',
    this.onBackPressed,
    this.scaffoldKey,
    this.showActivityLogAction = true,
    this.onOpenActivityLog,
  });

  final String title;
  final VoidCallback? onBackPressed;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool showActivityLogAction;
  final VoidCallback? onOpenActivityLog;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final double headerHeight = isMobile ? 72 : 88;

    return Container(
      height: headerHeight,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: Row(
        children: [
          // Navigation buttons
          Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => scaffoldKey?.currentState?.openDrawer(),
                ),
              if (!isMobile)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                ),
            ],
          ),
          const Spacer(),
          // Page Title
          if (!isMobile)
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          const Spacer(),
          if (showActivityLogAction) ...[
            _buildActivityLogAction(context, isMobile),
            SizedBox(width: isMobile ? 8 : 12),
          ],
          // User Profile with RepaintBoundary to prevent unnecessary repaints
          RepaintBoundary(child: _buildUserProfile(isMobile)),
        ],
      ),
    );
  }

  Widget _buildActivityLogAction(BuildContext context, bool isMobile) {
    final action =
        onOpenActivityLog ?? () => ProjectActivitiesLogScreen.open(context);

    return Tooltip(
      message: 'Project Activity Log',
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD873)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: Color(0xFFB45309),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 6),
                const Text(
                  'Activity Log',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile(bool isMobile) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final email = user?.email ?? '';
    final initial = displayName.trim().isNotEmpty
        ? displayName.trim().characters.first.toUpperCase()
        : 'U';
    final photoUrl = user?.photoURL;

    return Row(
      children: [
        photoUrl != null && photoUrl.isNotEmpty
            ? CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(photoUrl),
                backgroundColor: Colors.blue,
              )
            : Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
        if (!isMobile) ...[
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              StreamBuilder<bool>(
                stream: UserService.watchAdminStatus(),
                builder: (context, snapshot) {
                  final isAdmin =
                      snapshot.data ?? UserService.isAdminEmail(email);
                  final role = isAdmin ? 'Admin' : 'Member';
                  return Text(
                    role,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}
