import 'package:flutter/material.dart';
import 'package:ndu_project/screens/ssher_components.dart';
import 'package:ndu_project/screens/ssher_screen_4.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/unified_phase_header.dart';

class SsherScreen3 extends StatelessWidget {
  const SsherScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);

    // Content shared between mobile and desktop
    final content = Column(
      children: [
        // Health section (again per screenshot before Environment)
        SsherSectionCard(
          leadingIcon: Icons.volunteer_activism_outlined,
          accentColor: const Color(0xFF1E88E5),
          title: 'Health',
          subtitle: 'Occupational health and wellness programs',
          detailsPlaceholder:
              'Multi- layered security approach including physical access controls, cybersecurity measures, surveillance systems, and incident response',
          itemsLabel: '12 Items',
          addButtonLabel: 'Add Safety Item',
          columns: const [
            '#',
            'Department',
            'Team Member',
            'Health Concern',
            'Risk Level',
            'Mitigation Strategy',
            'Actions'
          ],
          rows: const [
            [
              Text('1', style: TextStyle(fontSize: 12)),
              Text('Operations', style: TextStyle(fontSize: 13)),
              Text('Sarah Johnson', style: TextStyle(fontSize: 13)),
              Text('Chemical exposure i...', style: TextStyle(fontSize: 13)),
              RiskBadge.high(),
              Text('Enhanced ventilation s...', style: TextStyle(fontSize: 13)),
              ActionButtons(),
            ],
            [
              Text('2', style: TextStyle(fontSize: 12)),
              Text('Manufacturing', style: TextStyle(fontSize: 13)),
              Text('Mike Chen', style: TextStyle(fontSize: 13)),
              Text('Heavy machinery o...', style: TextStyle(fontSize: 13)),
              RiskBadge.high(),
              Text('Operator certification, ...',
                  style: TextStyle(fontSize: 13)),
              ActionButtons(),
            ],
          ],
        ),

        // Environment section
        SsherSectionCard(
          leadingIcon: Icons.eco_outlined,
          accentColor: const Color(0xFF2E7D32),
          title: 'Environment',
          subtitle: 'Environmental sustainability and compliance',
          detailsPlaceholder:
              'Environmental stewardship program including waste reduction initiatives, energy efficiency measures, carbon footprint monitoring, and sustainable resource management. Regular environmental impact assessments ensure compliance with regulations .',
          itemsLabel: '9 Items',
          addButtonLabel: 'Add Safety Item',
          columns: const [
            '#',
            'Department',
            'Team Member',
            'Health Concern',
            'Risk Level',
            'Mitigation Strategy',
            'Actions'
          ],
          rows: const [
            [
              Text('1', style: TextStyle(fontSize: 12)),
              Text('Operations', style: TextStyle(fontSize: 13)),
              Text('Sarah Johnson', style: TextStyle(fontSize: 13)),
              Text('Chemical exposure i...', style: TextStyle(fontSize: 13)),
              RiskBadge.high(),
              Text('Enhanced ventilation s...', style: TextStyle(fontSize: 13)),
              ActionButtons(),
            ],
            [
              Text('2', style: TextStyle(fontSize: 12)),
              Text('Manufacturing', style: TextStyle(fontSize: 13)),
              Text('Mike Chen', style: TextStyle(fontSize: 13)),
              Text('Heavy machinery o...', style: TextStyle(fontSize: 13)),
              RiskBadge.high(),
              Text('Operator certification, ...',
                  style: TextStyle(fontSize: 13)),
              ActionButtons(),
            ],
          ],
        ),

        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SsherScreen4())),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Next'),
          ),
        ),
      ],
    );

    // --- Mobile layout ---
    if (isMobile) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        drawer: Drawer(
          width: sidebarWidth,
          child: SafeArea(
            child: InitiationLikeSidebar(
              activeItemLabel: 'SSHE Planning',
              showHeader: true,
            ),
          ),
        ),
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              UnifiedPhaseHeader(
                title: 'SSHER',
                breadcrumbPhase: 'Planning Phase',
                breadcrumbTitle: 'SSHE Planning',
                onBackPressed: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: content,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --- Desktop layout ---
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            UnifiedPhaseHeader(
              title: 'SSHER',
              breadcrumbPhase: 'Planning Phase',
              breadcrumbTitle: 'SSHE Planning',
              onBackPressed: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Row(
                children: [
                  DraggableSidebar(
                    openWidth: sidebarWidth,
                    child: const InitiationLikeSidebar(
                      activeItemLabel: 'SSHE Planning',
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
