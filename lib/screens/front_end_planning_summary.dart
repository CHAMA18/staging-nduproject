import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/screens/front_end_planning_requirements_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/user_access_chip.dart';

/// Front End Planning – Summary screen
/// Mirrors the provided layout with shared workspace chrome,
/// large notes area, summary text panel, and AI hint + Next controls.
class FrontEndPlanningSummaryScreen extends StatefulWidget {
  const FrontEndPlanningSummaryScreen({super.key});

  static void open(BuildContext context) {
    PhaseTransitionHelper.pushPhaseAware(
      context: context,
      builder: (_) => const FrontEndPlanningSummaryScreen(),
      destinationCheckpoint: 'fep_summary',
    );
  }

  @override
  State<FrontEndPlanningSummaryScreen> createState() => _FrontEndPlanningSummaryScreenState();
}

class _FrontEndPlanningSummaryScreenState extends State<FrontEndPlanningSummaryScreen> {
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _summaryNotes = TextEditingController();
  bool _isSyncReady = false;

  @override
  void initState() {
    super.initState();
    // Notes = prose; no auto-bullet
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _summaryNotes.addListener(_syncSummaryToProvider);
      _isSyncReady = true;
      final data = ProjectDataHelper.getData(context);
      
      // Auto-populate summary if it's empty, concatenating from:
      // Project Vision (notes) + Core Stakeholders + Business Case + Selected Preferred Solution
      if (data.frontEndPlanning.summary.isEmpty) {
        final summary = _buildMasterSummary(data);
        _summaryNotes.text = summary;
      } else {
        _summaryNotes.text = data.frontEndPlanning.summary;
      }
      
      _syncSummaryToProvider();
      if (mounted) setState(() {});
    });
  }
  
  /// Builds the master summary by concatenating Project Vision, Core Stakeholders,
  /// Business Case, and Selected Preferred Solution
  String _buildMasterSummary(dynamic data) {
    final parts = <String>[];
    
    // 1. Project Vision (from notes field)
    if (data.notes.isNotEmpty) {
      parts.add('Project Vision:');
      parts.add(data.notes);
      parts.add('');
    }
    
    // 2. Core Stakeholders
    if (data.coreStakeholdersData != null) {
      final stakeholders = data.coreStakeholdersData;
      if (stakeholders.solutionStakeholderData.isNotEmpty) {
        parts.add('Core Stakeholders:');
        for (final stakeholderData in stakeholders.solutionStakeholderData) {
          if (stakeholderData.solutionTitle.isNotEmpty) {
            parts.add('${stakeholderData.solutionTitle}:');
          }
          if (stakeholderData.notableStakeholders.isNotEmpty) {
            parts.add(stakeholderData.notableStakeholders);
          }
        }
        parts.add('');
      }
    }
    
    // 3. Business Case
    if (data.businessCase.isNotEmpty) {
      parts.add('Business Case:');
      parts.add(data.businessCase);
      parts.add('');
    }
    
    // 4. Selected Preferred Solution
    if (data.preferredSolutionAnalysis?.selectedSolutionTitle != null &&
        data.preferredSolutionAnalysis!.selectedSolutionTitle!.isNotEmpty) {
      parts.add('Selected Preferred Solution:');
      parts.add(data.preferredSolutionAnalysis!.selectedSolutionTitle!);
    }
    
    return parts.join('\n');
  }

  @override
  void dispose() {
    if (_isSyncReady) {
      _summaryNotes.removeListener(_syncSummaryToProvider);
    }
    _notes.dispose();
    _summaryNotes.dispose();
    super.dispose();
  }

  void _syncSummaryToProvider() {
    if (!mounted) return;
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          summary: _summaryNotes.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Summary'),
            ),
            Expanded(
              child: Stack(
                children: [
                  const AdminEditToggle(),
                  Column(
                    children: [
                      const FrontEndPlanningHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        _roundedField(controller: _notes, hint: 'Input your notes here...', minLines: 3),
                        const SizedBox(height: 24),
                        const _SectionTitle(),
                        const SizedBox(height: 18),
                        _SummaryPanel(controller: _summaryNotes),
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _BottomOverlay(summaryController: _summaryNotes),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Row(children: [
            _circleButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.maybePop(context)),
            const SizedBox(width: 8),
            _circleButton(icon: Icons.arrow_forward_ios_rounded, onTap: () {}),
          ]),
          const Spacer(),
          const Text('Front End Planning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
          const Spacer(),
          const UserAccessChip(),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'Description  ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          TextSpan(
            text: '(Provide a comprehensive summary of the front end planning activities.)',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        minLines: 12,
        maxLines: null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '',
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.summaryController});
  
  final TextEditingController summaryController;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            Positioned(
              left: 24,
              bottom: 24,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Color(0xFFB3D9FF), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F1FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD7E5FF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                        SizedBox(width: 10),
                        Text('AI', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
                        SizedBox(width: 12),
                        Text(
                          'Generate a summary of all front end planning activities.',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await ProjectDataHelper.saveAndNavigate(
                        context: context,
                        checkpoint: 'fep_summary',
                        nextScreenBuilder: () => const FrontEndPlanningRequirementsScreen(),
                        dataUpdater: (data) => data.copyWith(
                          frontEndPlanning: ProjectDataHelper.updateFEPField(
                            current: data.frontEndPlanning,
                            summary: summaryController.text.trim(),
                          ),
                        ),
                      );
                    }, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC812),
                      foregroundColor: const Color(0xFF111827),
                      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

Widget _roundedField({required TextEditingController controller, required String hint, int minLines = 1}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE4E7EC)),
    ),
    padding: const EdgeInsets.all(14),
    child: TextField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
    ),
  );
}
