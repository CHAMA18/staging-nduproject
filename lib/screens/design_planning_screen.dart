import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';

const Color _kSurfaceBackground = Color(0xFFF7F8FC);
const Color _kCardBorder = Color(0xFFE5E7EB);
const Color _kPrimaryText = Color(0xFF111827);
const Color _kSecondaryText = Color(0xFF6B7280);

class DesignPlanningScreen extends StatelessWidget {
  const DesignPlanningScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DesignPlanningScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = EdgeInsets.fromLTRB(
      isMobile ? 16 : 32,
      24,
      isMobile ? 16 : 32,
      120,
    );
    final data = ProjectDataHelper.getData(context);

    return Scaffold(
      backgroundColor: _kSurfaceBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: AppBreakpoints.sidebarWidth(context),
                  child:
                      const InitiationLikeSidebar(activeItemLabel: 'Design'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlanningPhaseHeader(
                          title: 'Design Planning',
                          showImportButton: false,
                          showContentButton: false,
                          onBack: () => Navigator.maybePop(context),
                          onForward: () =>
                              PlanningPhaseNavigation.navigateToNext(
                            context,
                            'design_planning',
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildInfoBanner(),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final useColumn =
                                isMobile || constraints.maxWidth < 980;
                            if (useColumn) {
                              return Column(
                                children: [
                                  _buildProjectContextCard(data),
                                  const SizedBox(height: 16),
                                  _buildFocusAreasCard(),
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildProjectContextCard(data)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildFocusAreasCard()),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const PlanningAiNotesCard(
                          title: 'Design Planning Notes',
                          sectionLabel: 'Design Planning',
                          noteKey: 'planning_design_notes',
                          checkpoint: 'design',
                          description:
                              'Capture design assumptions, constraints, and early decisions before execution.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const KazAiChatBubble(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4CC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Text(
        'Align on design intent, constraints, and focus areas so execution can move fast without rework.',
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimaryText),
      ),
    );
  }

  Widget _buildProjectContextCard(ProjectDataModel data) {
    final goals = data.projectGoals
        .where((g) => g.name.trim().isNotEmpty || g.description.trim().isNotEmpty)
        .toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Context',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: _kPrimaryText),
          ),
          const SizedBox(height: 12),
          _buildContextField('Project Name', data.projectName),
          const SizedBox(height: 12),
          _buildContextField('Objective', data.projectObjective),
          const SizedBox(height: 16),
          const Text(
            'Key Goals',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kPrimaryText),
          ),
          const SizedBox(height: 8),
          if (goals.isEmpty)
            const Text(
              'No project goals provided yet.',
              style: TextStyle(fontSize: 12, color: _kSecondaryText),
            )
          else
            Column(
              children: goals.map((goal) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kCardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name.isNotEmpty ? goal.name : 'Goal',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kPrimaryText),
                      ),
                      if (goal.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          goal.description,
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondaryText),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildContextField(String label, String value) {
    final display = value.trim().isEmpty ? 'Not provided' : value.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kSecondaryText),
        ),
        const SizedBox(height: 4),
        Text(
          display,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimaryText),
        ),
      ],
    );
  }

  Widget _buildFocusAreasCard() {
    const focusAreas = [
      _FocusArea(
        title: 'Architecture',
        description: 'Define core components, data flows, and integration points.',
        icon: Icons.account_tree_outlined,
      ),
      _FocusArea(
        title: 'Experience',
        description: 'Align UX goals, accessibility needs, and interaction rules.',
        icon: Icons.palette_outlined,
      ),
      _FocusArea(
        title: 'Data & Security',
        description: 'Identify data ownership, privacy constraints, and controls.',
        icon: Icons.shield_outlined,
      ),
      _FocusArea(
        title: 'Delivery Strategy',
        description: 'Sequence design handoffs, reviews, and validation cycles.',
        icon: Icons.timeline_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Design Focus Areas',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: _kPrimaryText),
          ),
          const SizedBox(height: 12),
          ...focusAreas.map((area) => _FocusAreaTile(area: area)),
        ],
      ),
    );
  }
}

class _FocusArea {
  final String title;
  final String description;
  final IconData icon;

  const _FocusArea({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _FocusAreaTile extends StatelessWidget {
  const _FocusAreaTile({required this.area});

  final _FocusArea area;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4CC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(area.icon, size: 18, color: const Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kPrimaryText),
                ),
                const SizedBox(height: 4),
                Text(
                  area.description,
                  style:
                      const TextStyle(fontSize: 12, color: _kSecondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
