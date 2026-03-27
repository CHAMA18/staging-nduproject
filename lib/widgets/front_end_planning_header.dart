import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

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
    return UnifiedPhaseHeader(
      title: title,
      scaffoldKey: scaffoldKey,
      onBackPressed: onBackPressed,
      showActivityLogAction: showActivityLogAction,
      onOpenActivityLog: onOpenActivityLog,
    );
  }
}
