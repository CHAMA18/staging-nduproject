import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/ai_suggesting_textfield.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';

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
                  child: const InitiationLikeSidebar(activeItemLabel: 'Design'),
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
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                              context, 'design'),
                          onForward: () => PlanningPhaseNavigation.goToNext(
                            context,
                            'design',
                          ),
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
                        const SizedBox(height: 24),
                        _buildInfoBanner(),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return const _DesignPlanAutoCard(
                                key: ValueKey('design-plan-card'));
                          },
                        ),
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel:
                              PlanningPhaseNavigation.backLabel('design'),
                          nextLabel:
                              PlanningPhaseNavigation.nextLabel('design'),
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                              context, 'design'),
                          onNext: () => PlanningPhaseNavigation.goToNext(
                              context, 'design'),
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
        'Align on design intent, constraints, and the design plan so execution can move fast without rework.',
        style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimaryText),
      ),
    );
  }
}

class _DesignPlanAutoCard extends StatefulWidget {
  const _DesignPlanAutoCard({super.key});

  @override
  State<_DesignPlanAutoCard> createState() => _DesignPlanAutoCardState();
}

class _DesignPlanAutoCardState extends State<_DesignPlanAutoCard> {
  static const String _noteKey = 'planning_design_plan';
  String _currentText = '';
  Timer? _saveDebounce;
  DateTime? _lastSavedAt;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _currentText = value;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () async {
      final trimmed = value.trim();
      final success = await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'design',
        dataUpdater: (data) => data.copyWith(
          planningNotes: {
            ...data.planningNotes,
            _noteKey: trimmed,
          },
        ),
        showSnackbar: false,
      );
      if (mounted && success) {
        setState(() => _lastSavedAt = DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentText.isEmpty) {
      final saved =
          ProjectDataHelper.getData(context).planningNotes[_noteKey] ?? '';
      if (saved.trim().isNotEmpty) {
        _currentText = saved;
      }
    }

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
            'Design Plan',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _kPrimaryText),
          ),
          const SizedBox(height: 6),
          const Text(
            'Auto-populated from project context. Edit to reflect your real design approach.',
            style: TextStyle(fontSize: 12, color: _kSecondaryText),
          ),
          const SizedBox(height: 16),
          AiSuggestingTextField(
            fieldLabel: 'Design Plan',
            hintText:
                'Outline the design plan: key activities, deliverables, reviews, and handoffs.',
            sectionLabel: 'Design Planning',
            showLabel: false,
            autoGenerate: true,
            autoGenerateSection: 'Design Plan',
            initialText:
                ProjectDataHelper.getData(context).planningNotes[_noteKey],
            onChanged: _handleChanged,
          ),
          if (_lastSavedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Saved ${TimeOfDay.fromDateTime(_lastSavedAt!).format(context)}',
                style: const TextStyle(fontSize: 11, color: _kSecondaryText),
              ),
            ),
        ],
      ),
    );
  }
}
