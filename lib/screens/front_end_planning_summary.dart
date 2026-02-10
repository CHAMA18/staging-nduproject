import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/screens/front_end_planning_requirements_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/user_access_chip.dart';
import 'package:ndu_project/widgets/planning_dashboard_card.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:provider/provider.dart';
import 'package:ndu_project/providers/project_data_provider.dart'; // Ensure provider is imported

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
  State<FrontEndPlanningSummaryScreen> createState() =>
      _FrontEndPlanningSummaryScreenState();
}

class _FrontEndPlanningSummaryScreenState
    extends State<FrontEndPlanningSummaryScreen> {
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
    return ResponsiveScaffold(
      activeItemLabel: 'Summary',
      backgroundColor: Colors.white,
      floatingActionButton: const KazAiChatBubble(),
      body: Stack(
        children: [
          const AdminEditToggle(),
          Column(
            children: [
              const FrontEndPlanningHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _roundedField(
                          controller: _notes,
                          hint: 'Input your notes here...',
                          minLines: 3),
                      const SizedBox(height: 24),
                      const _SectionTitle(),
                      const SizedBox(height: 18),
                      _SummaryPanel(controller: _summaryNotes),
                      const SizedBox(height: 24),
                      const _PlanningCardsSection(),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _BottomOverlay(summaryController: _summaryNotes),
        ],
      ),
    );
  }
}

// ignore: unused_element
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
            _circleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.maybePop(context)),
            const SizedBox(width: 8),
            _circleButton(icon: Icons.arrow_forward_ios_rounded, onTap: () {}),
          ]),
          const Spacer(),
          const Text('Front End Planning',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
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
            text:
                '(Provide a comprehensive summary of the front end planning activities.)',
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

class _PlanningCardsSection extends StatefulWidget {
  const _PlanningCardsSection();

  @override
  State<_PlanningCardsSection> createState() => _PlanningCardsSectionState();
}

class _PlanningCardsSectionState extends State<_PlanningCardsSection> {
  // Track generating state for each section key
  final Map<String, bool> _generatingStates = {};

  final _openAiService = OpenAiServiceSecure();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAutoGenerate();
    });
  }

  void _checkAndAutoGenerate() {
    final data = ProjectDataHelper.getData(context);

    // Safety check: Only generate if ALL lists are empty to avoid spamming or overwriting
    // functionality if the user just hasn't added anything yet.
    // Actually user wants "automatically when u load in".
    // We will check each individually but maybe limit concurrency?
    // Let's do it sequentially to be safe.

    _autoGenerateIfEmpty(data.withinScopeItems, 'Within Scope', 'withinScope',
            'withinScopeItems')
        .then((_) => _autoGenerateIfEmpty(data.outOfScopeItems, 'Out of Scope',
            'outOfScope', 'outOfScopeItems'))
        .then((_) => _autoGenerateIfEmpty(data.assumptionItems, 'Assumptions',
            'assumptions', 'assumptionItems'))
        .then((_) => _autoGenerateIfEmpty(data.constraintItems, 'Constraints',
            'constraints', 'constraintItems'));
  }

  Future<void> _autoGenerateIfEmpty(List<PlanningDashboardItem> items,
      String title, String loadingKey, String listKey) async {
    if (items.isEmpty && mounted) {
      // Check if we already generated this session to avoid infinite loops if AI returns nothing
      // For now, just call it.
      debugPrint('Auto-generating $title...');
      await _handleGenerateAI(context, title, loadingKey, items);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to provider to rebuild when data changes
    final provider = Provider.of<ProjectDataProvider>(context);
    final data = provider.projectData;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PlanningDashboardCard(
                title: 'Within Project Scope',
                description:
                    'Work, features, deliverables, and activities that are explicitly included.',
                items: data.withinScopeItems,
                isGenerating: _generatingStates['withinScope'] ?? false,
                onAdd: () => _handleAddItem(context, 'withinScopeItems',
                    'Within Scope', data.withinScopeItems),
                onEdit: (item) => _handleEditItem(
                    context, 'withinScopeItems', item, data.withinScopeItems),
                onDelete: (item) => _handleDeleteItem(
                    context, 'withinScopeItems', item, data.withinScopeItems),
                onGenerateAI: () => _handleGenerateAI(context, 'Within Scope',
                    'withinScope', data.withinScopeItems),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PlanningDashboardCard(
                title: 'Out of Project Scope',
                description:
                    'Work, features, or activities that are explicitly excluded.',
                items: data.outOfScopeItems,
                isGenerating: _generatingStates['outOfScope'] ?? false,
                onAdd: () => _handleAddItem(context, 'outOfScopeItems',
                    'Out of Scope', data.outOfScopeItems),
                onEdit: (item) => _handleEditItem(
                    context, 'outOfScopeItems', item, data.outOfScopeItems),
                onDelete: (item) => _handleDeleteItem(
                    context, 'outOfScopeItems', item, data.outOfScopeItems),
                onGenerateAI: () => _handleGenerateAI(context, 'Out of Scope',
                    'outOfScope', data.outOfScopeItems),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PlanningDashboardCard(
                title: 'Project Assumptions',
                description:
                    'Conditions or events assumed to be true for planning.',
                items: data.assumptionItems,
                isGenerating: _generatingStates['assumptions'] ?? false,
                onAdd: () => _handleAddItem(context, 'assumptionItems',
                    'Assumptions', data.assumptionItems),
                onEdit: (item) => _handleEditItem(
                    context, 'assumptionItems', item, data.assumptionItems),
                onDelete: (item) => _handleDeleteItem(
                    context, 'assumptionItems', item, data.assumptionItems),
                onGenerateAI: () => _handleGenerateAI(context, 'Assumptions',
                    'assumptions', data.assumptionItems),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PlanningDashboardCard(
                title: 'Project Constraints',
                description: 'Fixed limitations or boundaries.',
                items: data.constraintItems,
                isGenerating: _generatingStates['constraints'] ?? false,
                onAdd: () => _handleAddItem(context, 'constraintItems',
                    'Constraints', data.constraintItems),
                onEdit: (item) => _handleEditItem(
                    context, 'constraintItems', item, data.constraintItems),
                onDelete: (item) => _handleDeleteItem(
                    context, 'constraintItems', item, data.constraintItems),
                onGenerateAI: () => _handleGenerateAI(context, 'Constraints',
                    'constraints', data.constraintItems),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleGenerateAI(BuildContext context, String sectionLabel,
      String loadingKey, List<PlanningDashboardItem> currentList) async {
    setState(() => _generatingStates[loadingKey] = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final data = ProjectDataHelper.getData(context);
      final projectContext =
          ProjectDataHelper.buildFepContext(data, sectionLabel: sectionLabel);

      final newItems = await _openAiService.generatePlanningItems(
        section: sectionLabel,
        context: projectContext,
      );

      if (!mounted) return;

      if (newItems.isNotEmpty) {
        // Append new items to existing list
        final updatedList = List<PlanningDashboardItem>.from(currentList)
          ..addAll(newItems);

        await _updateList(this.context, loadingKey, updatedList);
      }
    } catch (e) {
      debugPrint('Error generating planning items: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
              content: Text('Failed to generate items: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _generatingStates[loadingKey] = false);
      }
    }
  }

  Future<void> _handleAddItem(BuildContext context, String listKey,
      String title, List<PlanningDashboardItem> currentList) async {
    final newItem = await _showItemDialog(context, title: 'Add $title Item');
    if (newItem != null) {
      final updatedList = List<PlanningDashboardItem>.from(currentList)
        ..add(newItem);
      if (context.mounted) {
        await _updateList(context, listKey, updatedList);
      }
    }
  }

  Future<void> _handleEditItem(
      BuildContext context,
      String listKey,
      PlanningDashboardItem item,
      List<PlanningDashboardItem> currentList) async {
    final editedItem =
        await _showItemDialog(context, title: 'Edit Item', existingItem: item);
    if (editedItem != null) {
      final updatedList = List<PlanningDashboardItem>.from(currentList);
      final index = updatedList.indexWhere((element) => element.id == item.id);
      if (index != -1) {
        updatedList[index] = editedItem;
        if (context.mounted) {
          await _updateList(context, listKey, updatedList);
        }
      }
    }
  }

  Future<void> _handleDeleteItem(
      BuildContext context,
      String listKey,
      PlanningDashboardItem item,
      List<PlanningDashboardItem> currentList) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedList = List<PlanningDashboardItem>.from(currentList)
        ..removeWhere((element) => element.id == item.id);
      if (context.mounted) {
        await _updateList(context, listKey, updatedList);
      }
    }
  }

  // Updates the specific list in ProjectDataModel
  Future<void> _updateList(BuildContext context, String listKey,
      List<PlanningDashboardItem> newList) async {
    // Map listKey to correct field update
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'fep_summary',
      dataUpdater: (data) {
        // Need to identify which field to update based on key
        // Unfortunately standard copyWith doesn't support dynamic keys easily
        // We have to specific check
        if (listKey == 'withinScopeItems' || listKey == 'withinScope') {
          return data.copyWith(withinScopeItems: newList);
        } else if (listKey == 'outOfScopeItems' || listKey == 'outOfScope') {
          return data.copyWith(outOfScopeItems: newList);
        } else if (listKey == 'assumptionItems' || listKey == 'assumptions') {
          return data.copyWith(assumptionItems: newList);
        } else if (listKey == 'constraintItems' || listKey == 'constraints') {
          return data.copyWith(constraintItems: newList);
        }
        return data;
      },
    );
  }

  Future<PlanningDashboardItem?> _showItemDialog(BuildContext context,
      {required String title, PlanningDashboardItem? existingItem}) {
    final titleController = TextEditingController(text: existingItem?.title);
    final descController =
        TextEditingController(text: existingItem?.description);

    return showDialog<PlanningDashboardItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title (Optional)',
                hintText: 'e.g., Kitchen Equipment',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter detailed description...',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (descController.text.trim().isEmpty) return;
              Navigator.pop(
                context,
                PlanningDashboardItem(
                  id: existingItem?.id, // Preserve ID if editing
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  createdAt: existingItem?.createdAt,
                  isAiGenerated: existingItem?.isAiGenerated ?? false,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
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
                decoration: const BoxDecoration(
                    color: Color(0xFFB3D9FF), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
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
                        Text('AI',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB))),
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
                        nextScreenBuilder: () =>
                            const FrontEndPlanningRequirementsScreen(),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 34, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const Text('Next',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
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

Widget _roundedField(
    {required TextEditingController controller,
    required String hint,
    int minLines = 1}) {
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
