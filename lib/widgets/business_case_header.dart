import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

/// Standardized header for all Business Case pages
/// Displays: back button, "Initiation Phase" title, and user profile
class BusinessCaseHeader extends StatelessWidget {
  const BusinessCaseHeader({
    super.key,
    this.onBackPressed,
    this.scaffoldKey,
    this.breadcrumbPhase,
    this.breadcrumbTitle,
  });

  final VoidCallback? onBackPressed;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final String? breadcrumbPhase;
  final String? breadcrumbTitle;

  @override
  Widget build(BuildContext context) {
    return UnifiedPhaseHeader(
      title: 'Initiation Phase',
      breadcrumbPhase: breadcrumbPhase,
      breadcrumbTitle: breadcrumbTitle,
      scaffoldKey: scaffoldKey,
      onBackPressed: onBackPressed,
    );
  }
}
