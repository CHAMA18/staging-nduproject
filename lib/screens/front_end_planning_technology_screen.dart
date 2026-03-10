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

class FrontEndPlanningTechnologyScreen extends StatelessWidget {
  const FrontEndPlanningTechnologyScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningTechnologyScreen()),
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
                  child: const InitiationLikeSidebar(
                      activeItemLabel: 'Technology'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlanningPhaseHeader(
                          title: 'Technology Planning',
                          showImportButton: false,
                          showContentButton: false,
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                              context, 'technology'),
                          onForward: () => PlanningPhaseNavigation.goToNext(
                            context,
                            'technology',
                          ),
                        ),
                        const SizedBox(height: 24),
                        const PlanningAiNotesCard(
                          title: 'Technology Notes',
                          sectionLabel: 'Technology Planning',
                          noteKey: 'planning_technology_notes',
                          checkpoint: 'technology',
                          description:
                              'Capture assumptions, dependencies, and alignment reminders before execution.',
                        ),
                        const SizedBox(height: 24),
                        const _InfoBanner(),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return const TechnologyPlanCard();
                          },
                        ),
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel:
                              PlanningPhaseNavigation.backLabel('technology'),
                          nextLabel:
                              PlanningPhaseNavigation.nextLabel('technology'),
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                              context, 'technology'),
                          onNext: () => PlanningPhaseNavigation.goToNext(
                              context, 'technology'),
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
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4CC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Text(
        'Early technology alignment keeps tooling, integrations, and teams moving in sync before execution ramps up.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _kPrimaryText,
        ),
      ),
    );
  }
}

class TechnologyPlanCard extends StatefulWidget {
  const TechnologyPlanCard({super.key});

  @override
  State<TechnologyPlanCard> createState() => _TechnologyPlanCardState();
}

class _TechnologyPlanCardState extends State<TechnologyPlanCard> {
  static const String _noteKey = 'planning_technology_plan';
  Timer? _saveDebounce;
  DateTime? _lastSavedAt;
  late String _initialText;

  @override
  void initState() {
    super.initState();
    _initialText =
        ProjectDataHelper.getData(context).planningNotes[_noteKey] ?? '';
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () async {
      final trimmed = value.trim();
      final success = await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'technology',
        dataUpdater: (data) => data.copyWith(
          planningNotes: {
            ...data.planningNotes,
            _noteKey: trimmed,
          },
        ),
        showSnackbar: false,
      );
      if (!mounted) return;
      if (success) {
        setState(() => _lastSavedAt = DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Technology Plan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _kPrimaryText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Describe the high-level approach, integrations, and timing so execution can align with your technology strategy.',
            style: TextStyle(fontSize: 12, color: _kSecondaryText),
          ),
          const SizedBox(height: 16),
          AiSuggestingTextField(
            fieldLabel: 'Technology Plan',
            hintText:
                'Summarize the technology approach, key platforms, and coordination needs.',
            sectionLabel: 'Technology Planning',
            showLabel: false,
            autoGenerate: true,
            autoGenerateSection: 'Technology Plan',
            initialText: _initialText,
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
