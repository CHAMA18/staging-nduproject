import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/screens/technical_alignment_screen.dart';

class RequirementsImplementationScreen extends StatefulWidget {
  const RequirementsImplementationScreen({super.key});

  @override
  State<RequirementsImplementationScreen> createState() => _RequirementsImplementationScreenState();
}

class _RequirementsImplementationScreenState extends State<RequirementsImplementationScreen> {
  final TextEditingController _notesController = TextEditingController();

  // Checklist items with status
  final List<_ChecklistItem> _checklistItems = [
    _ChecklistItem(
      title: 'Key flows covered',
      description: 'All priority user journeys have mapped requirements.',
      status: ChecklistStatus.ready,
    ),
    _ChecklistItem(
      title: 'Constraints documented',
      description: 'Performance, security, and compliance captured.',
      status: ChecklistStatus.inReview,
    ),
    _ChecklistItem(
      title: 'Stakeholder sign-off',
      description: 'Product, design, and engineering alignment.',
      status: ChecklistStatus.pending,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final pid = provider?.projectData.projectId;
      if (pid != null && pid.isNotEmpty) {
        await ProjectNavigationService.instance.saveLastPage(pid, 'requirements-implementation');
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _navigateToDesignOverview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DesignPhaseScreen()),
    );
  }

  void _navigateToTechnicalAlignment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TechnicalAlignmentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 16.0 : 40.0;

    return ResponsiveScaffold(
      activeItemLabel: 'Requirements Implementation',
      body: Column(
        children: [
          const PlanningPhaseHeader(title: 'Design'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main content area
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section label
                        Text(
                          'REQUIREMENTS IMPLEMENTATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Main heading
                        const Text(
                          'Translate agreed design scope into clear, actionable requirements',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1D1F),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Description
                        Text(
                          'Break down the approved design intent into user stories, functional requirements, and constraints that downstream teams can build against.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Next in flow banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Next in flow: Technical alignment',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Notes input field
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D3748),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _notesController,
                            maxLines: 2,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Capture key implementation notes here... (priorities, story mapping decisions, sequencing, and non-negotiables)',
                              hintStyle: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Keep this focused on what implementation teams must understand before estimating and building.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Two column layout
                        if (isMobile)
                          Column(
                            children: [
                              _buildRequirementsBreakdownCard(),
                              const SizedBox(height: 20),
                              _buildReadinessChecklistCard(),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildRequirementsBreakdownCard()),
                              const SizedBox(width: 24),
                              Expanded(child: _buildReadinessChecklistCard()),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Bottom navigation bar
                  _buildBottomNavigation(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requirements breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1D1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Turn design outcomes into implementation units',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          // Core requirement groups section
          Text(
            'Core requirement groups',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildRequirementItem(
            'User journeys:',
            'Map journeys into epics and user stories.',
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            'System behaviours:',
            'Define functional and non-functional requirements.',
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            'Integration points:',
            'Capture contracts, payloads, and error handling.',
          ),
          const SizedBox(height: 24),
          // Definition of ready section
          Text(
            'Definition of ready',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildDefinitionItem('Stories have clear acceptance criteria and owner.'),
          const SizedBox(height: 6),
          _buildDefinitionItem('Dependencies and blockers are listed explicitly.'),
          const SizedBox(height: 6),
          _buildDefinitionItem('Testing and validation expectations are captured.'),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String label, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1D1F),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefinitionItem(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildReadinessChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Readiness checklist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1D1F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Confirm what is complete before moving to technical alignment',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          // Checklist items section
          Text(
            'Checklist items',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          ..._checklistItems.map((item) => _buildChecklistItemWidget(item)),
          const SizedBox(height: 24),
          // Implementation notes section
          Text(
            'Implementation notes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use this section to highlight sequencing decisions, launch scope, and items intentionally pushed to later releases.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItemWidget(_ChecklistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildStatusBadge(item.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ChecklistStatus status) {
    Color bgColor;
    Color textColor;
    String label;
    bool showDot = false;

    switch (status) {
      case ChecklistStatus.ready:
        bgColor = Colors.transparent;
        textColor = const Color(0xFF22C55E);
        label = 'Ready';
        showDot = true;
        break;
      case ChecklistStatus.inReview:
        bgColor = Colors.transparent;
        textColor = const Color(0xFF6B7280);
        label = 'In review';
        break;
      case ChecklistStatus.pending:
        bgColor = Colors.transparent;
        textColor = const Color(0xFF6B7280);
        label = 'Pending';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDot) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16.0 : 40.0,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBackButton(),
                const SizedBox(height: 12),
                Text(
                  'Design phase · Requirements implementation',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                _buildNextButton(),
              ],
            )
          else
            Row(
              children: [
                _buildBackButton(),
                const SizedBox(width: 16),
                Text(
                  'Design phase · Requirements implementation',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                _buildNextButton(),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: Colors.amber[700],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use this page to ensure requirements are complete and understandable. The next step, Technical alignment, will validate feasibility, architecture, and sequencing against these requirements.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: _navigateToDesignOverview,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 18, color: Color(0xFF1A1D1F)),
            const SizedBox(width: 8),
            const Text(
              'Back: Design overview',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1D1F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return InkWell(
      onTap: _navigateToTechnicalAlignment,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Next: Technical alignment',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

enum ChecklistStatus { ready, inReview, pending }

class _ChecklistItem {
  final String title;
  final String description;
  final ChecklistStatus status;

  _ChecklistItem({
    required this.title,
    required this.description,
    required this.status,
  });
}
