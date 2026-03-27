import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/screens/project_activities_log_screen.dart';
import 'package:ndu_project/screens/settings_screen.dart';
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/widgets/responsive.dart';

class UnifiedPhaseHeader extends StatelessWidget {
  const UnifiedPhaseHeader({
    super.key,
    required this.title,
    this.scaffoldKey,
    this.onBackPressed,
    this.trailingActions = const <Widget>[],
    this.showActivityLogAction = true,
    this.onOpenActivityLog,
    this.backgroundColor = Colors.white,
  });

  final String title;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final VoidCallback? onBackPressed;
  final List<Widget> trailingActions;
  final bool showActivityLogAction;
  final VoidCallback? onOpenActivityLog;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final headerHeight = isMobile ? 72.0 : 88.0;
    final useDrawerTrigger = isMobile && scaffoldKey != null;

    return Container(
      height: headerHeight,
      color: backgroundColor,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: Row(
        children: [
          if (useDrawerTrigger)
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Open menu',
              onPressed: () => scaffoldKey?.currentState?.openDrawer(),
            )
          else
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              tooltip: 'Back',
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            ),
          const Spacer(),
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
          if (showActivityLogAction)
            _ActivityLogAction(
              compact: isMobile,
              onTap: onOpenActivityLog ??
                  () => ProjectActivitiesLogScreen.open(context),
            ),
          if (showActivityLogAction) SizedBox(width: isMobile ? 8 : 12),
          ...trailingActions,
          if (trailingActions.isNotEmpty) SizedBox(width: isMobile ? 8 : 12),
          const UnifiedProfileMenu(),
        ],
      ),
    );
  }
}

class UnifiedScaffoldAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const UnifiedScaffoldAppBar({
    super.key,
    this.backgroundColor,
    this.title,
    this.onMenuTap,
    this.showActivityLogAction = true,
    this.onOpenActivityLog,
  });

  final Color? backgroundColor;
  final String? title;
  final VoidCallback? onMenuTap;
  final bool showActivityLogAction;
  final VoidCallback? onOpenActivityLog;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;
    final isMobile = AppBreakpoints.isMobile(context);

    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF374151)),
          tooltip: 'Open menu',
          onPressed: onMenuTap ?? () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: title == null
          ? null
          : Text(
              title!,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
      centerTitle: true,
      actions: [
        if (showActivityLogAction)
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 8 : 10),
            child: _ActivityLogAction(
              compact: isMobile,
              onTap: onOpenActivityLog ??
                  () => ProjectActivitiesLogScreen.open(context),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(right: isMobile ? 8 : 12),
          child: const UnifiedProfileMenu(compact: true),
        ),
      ],
    );
  }
}

class UnifiedProfileMenu extends StatelessWidget {
  const UnifiedProfileMenu({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'Unknown User');
    final email = user?.email?.trim() ?? '';
    final avatarInitial = displayName.trim().isNotEmpty
        ? displayName.trim().characters.first.toUpperCase()
        : 'U';
    final photoUrl = user?.photoURL;
    Stream<bool> adminStatusStream;
    try {
      adminStatusStream = UserService.watchAdminStatus();
    } catch (_) {
      adminStatusStream = Stream<bool>.value(UserService.isAdminEmail(email));
    }

    final label = Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          photoUrl != null && photoUrl.isNotEmpty
              ? CircleAvatar(
                  radius: compact ? 16 : 20,
                  backgroundImage: NetworkImage(photoUrl),
                  backgroundColor: Colors.blue,
                )
              : Container(
                  width: compact ? 32 : 40,
                  height: compact ? 32 : 40,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    avatarInitial,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 13 : 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
          const SizedBox(width: 10),
          StreamBuilder<bool>(
            stream: adminStatusStream,
            builder: (context, snapshot) {
              final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
              final role = isAdmin ? 'Admin' : 'Member';
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 130 : 220),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      email.isEmpty ? 'No email' : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      role,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 10 : 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    return PopupMenuButton<String>(
      tooltip: 'Profile actions',
      onSelected: (value) {
        if (value == 'settings') {
          SettingsScreen.open(context);
        } else if (value == 'logout') {
          AuthNav.signOutAndExit(context);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_outlined),
            title: Text('Logout'),
          ),
        ),
      ],
      child: label,
    );
  }
}

class _ActivityLogAction extends StatelessWidget {
  const _ActivityLogAction({
    required this.compact,
    required this.onTap,
  });

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Project Activity Log',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
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
              if (!compact) ...[
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
}
