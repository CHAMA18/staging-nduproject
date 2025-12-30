import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/theme.dart';

class UiUxDesignScreen extends StatefulWidget {
  const UiUxDesignScreen({super.key});

  @override
  State<UiUxDesignScreen> createState() => _UiUxDesignScreenState();
}

class _UiUxDesignScreenState extends State<UiUxDesignScreen> {
  final TextEditingController _notesController = TextEditingController();

  // Primary user journeys data
  final List<_JourneyItem> _journeys = [
    _JourneyItem('Onboard & first value', 'From sign-up to experiencing the first meaningful outcome.', 'Mapped'),
    _JourneyItem('Core task completion', 'Critical path to complete the main job-to-be-done.', 'Draft'),
    _JourneyItem('Support & recovery', 'Error states, help entry points, and escalation paths.', 'Planned'),
  ];

  // Interface structure data
  final List<_InterfaceItem> _interfaces = [
    _InterfaceItem('Dashboard', 'One-glance status and key shortcuts into primary actions.', 'Wireframe'),
    _InterfaceItem('Workflows', 'Step-by-step guidance for complex, multi-screen tasks.', 'User flow map'),
    _InterfaceItem('Settings & admin', 'Configuration, access management, and audit history.', 'To define'),
  ];

  // Design system elements data
  final List<_DesignElement> _coreTokens = [
    _DesignElement('Color & typography', 'Brand palette, semantic roles, hierarchy, spacing scale.', 'Ready'),
    _DesignElement('Interactions & feedback', 'Loading, success, warning, error, and empty states.', 'Draft'),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'UI/UX Design',
      body: Column(
        children: [
          const PlanningPhaseHeader(title: 'Design Phase'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  Text(
                    'UI/UX Design',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: LightModeColors.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture only the critical screens, flows, and components so teams can implement a consistent experience without over-designing.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),

                  // Notes Input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppSemanticColors.border),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Input your notes here... (target users, accessibility constraints, brand rules, must-have journeys)',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Helper Text
                  Text(
                    'Focus on high-impact touchpoints first: how users discover, complete core tasks, and get support.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // Three Cards - stacked layout
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPrimaryUserJourneysCard(),
                      const SizedBox(height: 16),
                      _buildInterfaceStructureCard(),
                      const SizedBox(height: 16),
                      _buildDesignSystemElementsCard(),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Bottom Navigation
                  _buildBottomNavigation(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryUserJourneysCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Primary user journeys', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('What users need to accomplish end-to-end', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          ..._journeys.map((j) => _buildJourneyItem(j)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add journey', style: TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyItem(_JourneyItem journey) {
    Color statusColor;
    switch (journey.status) {
      case 'Mapped':
        statusColor = AppSemanticColors.success;
        break;
      case 'Draft':
        statusColor = Colors.grey;
        break;
      case 'Planned':
        statusColor = AppSemanticColors.info;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(journey.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(journey.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(journey.status, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceStructureCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Interface structure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('How screens connect and what each view owns', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          // Table Header
          Row(
            children: [
              Expanded(flex: 2, child: Text('Area', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500))),
              Expanded(flex: 3, child: Text('Purpose', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500))),
              Expanded(flex: 2, child: Text('State', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500))),
            ],
          ),
          const Divider(height: 16),
          ..._interfaces.map((i) => _buildInterfaceRow(i)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add area', style: TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceRow(_InterfaceItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(item.area, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Expanded(flex: 3, child: Text(item.purpose, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(item.state, style: TextStyle(fontSize: 11, color: Colors.grey[700]), textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignSystemElementsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Design system elements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tokens, components, and states the build will rely on', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),

          // Core tokens section
          Text('Core tokens', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ..._coreTokens.map((e) => _buildDesignElementItem(e)),
          const SizedBox(height: 16),

          // Key components section
          Text('Key components', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            'List the minimum set of reusable components (navigation, cards, forms, modals) that must be finalized before development starts.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add item', style: TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          const SizedBox(height: 16),

          // Export button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Export UI/UX specification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignElementItem(_DesignElement element) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(element.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(element.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(element.status, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isMobile) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Design phase · UI/UX design', style: TextStyle(fontSize: 13, color: Colors.grey[500]), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Text('Next: Backend design'),
                label: const Icon(Icons.arrow_forward, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1D1F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back: Development set up'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Text('Design phase · UI/UX design', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Text('Next: Backend design'),
                label: const Icon(Icons.arrow_forward, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1D1F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        // Tip
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, size: 18, color: LightModeColors.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Design only what will unblock developers in the first increments: core journeys, navigation, and the smallest useful design system.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _JourneyItem {
  final String title;
  final String description;
  final String status;
  _JourneyItem(this.title, this.description, this.status);
}

class _InterfaceItem {
  final String area;
  final String purpose;
  final String state;
  _InterfaceItem(this.area, this.purpose, this.state);
}

class _DesignElement {
  final String title;
  final String description;
  final String status;
  _DesignElement(this.title, this.description, this.status);
}
