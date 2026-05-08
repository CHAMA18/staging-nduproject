import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

class DesignPhaseStableShell extends StatelessWidget {
  const DesignPhaseStableShell({
    super.key,
    required this.activeLabel,
    required this.child,
    required this.onItemSelected,
  });

  final String activeLabel;
  final Widget child;
  final ValueChanged<String> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    if (isMobile) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: UnifiedScaffoldAppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: activeLabel,
        ),
        drawer: Drawer(
          width: AppBreakpoints.sidebarWidth(context),
          child: SafeArea(
            child: InitiationLikeSidebar(
              activeItemLabel: activeLabel,
              showHeader: true,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: AppBreakpoints.sidebarWidth(context),
              child: InitiationLikeSidebar(
                activeItemLabel: activeLabel,
                showHeader: true,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: UnifiedPhaseHeader(
                        title: activeLabel,
                        showActivityLogAction: true,
                      ),
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
