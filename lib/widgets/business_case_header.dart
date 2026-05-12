import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

/// Standardized header for all Business Case pages
/// Displays: back button, "Initiation Phase" title, and user profile
class BusinessCaseHeader extends StatelessWidget {
  const BusinessCaseHeader({
    super.key,
    this.onBackPressed,
    this.scaffoldKey,
  });

  final VoidCallback? onBackPressed;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  Widget build(BuildContext context) {
    return UnifiedPhaseHeader(
      title: 'Initiation Phase',
      scaffoldKey: scaffoldKey,
      onBackPressed: onBackPressed,
    );
  }
}
