import 'package:flutter/material.dart';

import 'package:ndu_project/screens/front_end_planning_requirements_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';

import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';

/// Front End Planning – Details (Scope, Assumptions, Constraints)
///
/// TODO: These sections NEED to be auto-generated using AI based on initial
/// project information (project type, description, goals, etc.). The AI should
/// generate intelligent suggestions for:
/// - Within Scope: Activities explicitly included (e.g., "erecting the building")
/// - Out of Scope: Activities explicitly excluded
/// - Assumptions: Conditions assumed true (e.g., "assuming rent, not purchase")
/// - Constraints: Fixed limitations (e.g., "budget cap", "regulatory requirements")
///
/// Users should be prompted to edit and add to the auto-generated lists.
/// This feature is highlighted in the requirements screenshots and needs implementation.
class FrontEndPlanningWorkspaceScreen extends StatefulWidget {
  const FrontEndPlanningWorkspaceScreen({
    super.key,
    this.initialNotes = '',
    this.initialSummary = '',
  });

  final String initialNotes;
  final String initialSummary;

  static void open(
    BuildContext context, {
    String initialNotes = '',
    String initialSummary = '',
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FrontEndPlanningWorkspaceScreen(
          initialNotes: initialNotes,
          initialSummary: initialSummary,
        ),
      ),
    );
  }

  @override
  State<FrontEndPlanningWorkspaceScreen> createState() =>
      _FrontEndPlanningWorkspaceScreenState();
}

class _FrontEndPlanningWorkspaceScreenState
    extends State<FrontEndPlanningWorkspaceScreen> {
  // We keep local controllers/lists to manage state before sync
  final TextEditingController _notesController = TextEditingController();

  // Note: We are migrating away from a big "Summary" text block to structured fields.
  // However, we'll keep the summary text for backward compatibility or as an "Executive Summary".
  final TextEditingController _summaryController = TextEditingController();

  // Structured Data Lists
  List<String> _withinScope = [];
  List<String> _outOfScope = [];
  List<String> _assumptions = [];
  List<String> _constraints = [];

  bool _isSyncReady = false;

  // AI Service
  final OpenAiServiceSecure _openAi = OpenAiServiceSecure();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    ApiKeyManager.initializeApiKey();
    _notesController.text = widget.initialNotes;
    _summaryController.text = widget.initialSummary;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ProjectDataHelper.getData(context);
      _notesController.text = data.frontEndPlanning
          .summary; // We might use summary field for notes? Or check mapping.
      // Actually widget.initialNotes might be passed, but usually we load from provider.
      // Let's stick to loading from provider.
      // The previous code mapped `_notesController` to... wait, previous code didn't strictly sync back in a visible way in `initState`
      // except via `_syncToProvider` if listeners were attached.

      // Let's map consistent with `ProjectDataModel`:
      // `FrontEndPlanningData.summary` -> `_summaryController` ?
      // `ProjectDataModel.notes` (initiation) -> `_notesController` ?

      // The user wants "Details" page.
      // Let's rely on `ProjectDataHelper.getData` to source truth.
      _withinScope = List.from(data.withinScope);
      _outOfScope = List.from(data.outOfScope);
      _assumptions = List.from(data.assumptions);
      _constraints = List.from(data.constraints);

      // Legacy mapping if needed, or just use what we have
      if (_summaryController.text.isEmpty) {
        _summaryController.text = data.frontEndPlanning.summary;
      }

      _isSyncReady = true;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  void _syncLists() {
    if (!mounted || !_isSyncReady) return;
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField((data) => data.copyWith(
        withinScope: _withinScope,
        outOfScope: _outOfScope,
        assumptions: _assumptions,
        constraints: _constraints,
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          summary: _summaryController.text,
        )));
    // We intentionally don't auto-save to Firestore on every keystroke/add for lists
    // to avoid excessive writes, but we update provider.
    // The "Next" button or explicit Save should persist.
    // However, for consistency with other screens, we might want to save.
    // Let's trigger save on list modifications.
    provider.saveToFirebase(checkpoint: 'fep_details_lists');
  }

  void _updateList(String type, List<String> newList) {
    setState(() {
      if (type == 'scope') _withinScope = newList;
      if (type == 'out') _outOfScope = newList;
      if (type == 'assumptions') _assumptions = newList;
      if (type == 'constraints') _constraints = newList;
    });
    _syncLists();
  }

  Future<void> _generateList(String type, String sectionLabel) async {
    if (_isGenerating) return;

    // Check if list is not empty
    List<String> currentList = [];
    if (type == 'scope') currentList = _withinScope;
    if (type == 'out') currentList = _outOfScope;
    if (type == 'assumptions') currentList = _assumptions;
    if (type == 'constraints') currentList = _constraints;

    if (currentList.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace existing items?'),
          content: const Text(
              'Generating new items will append to your existing list. Do you want to continue?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    if (!mounted) return;

    setState(() => _isGenerating = true);

    try {
      final data = ProjectDataHelper.getData(context);
      final contextStr =
          ProjectDataHelper.buildFepContext(data, sectionLabel: 'Details');

      final items = await _openAi.generatePlanningItems(
        section: sectionLabel,
        context: contextStr,
      );

      if (!mounted) return;

      final stringList = items
          .map((i) => i.title.isNotEmpty
              ? '${i.title}: ${i.description}'
              : i.description)
          .toList();

      setState(() {
        if (type == 'scope') _withinScope.addAll(stringList);
        if (type == 'out') _outOfScope.addAll(stringList);
        if (type == 'assumptions') _assumptions.addAll(stringList);
        if (type == 'constraints') _constraints.addAll(stringList);
      });

      _syncLists();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Generated ${items.length} items for $sectionLabel')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating items: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const AdminEditToggle(),
          SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: AppBreakpoints.sidebarWidth(context),
                  child:
                      const InitiationLikeSidebar(activeItemLabel: 'Details'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FrontEndPlanningHeader(),
                        const SizedBox(height: 24),

                        // Structured Cards Grid/Column
                        // We use a column of full-width cards or wrapped cards
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ListEditorCard(
                                title: 'Within Project Scope',
                                items: _withinScope,
                                icon: Icons.check_circle_outline,
                                color: Colors.green,
                                onGenerate: () =>
                                    _generateList('scope', 'Within Scope'),
                                onItemAdded: (val) => _updateList(
                                    'scope', [..._withinScope, val]),
                                onItemDeleted: (index) {
                                  final l = [..._withinScope];
                                  l.removeAt(index);
                                  _updateList('scope', l);
                                },
                                onItemEdited: (index, val) {
                                  final l = [..._withinScope];
                                  l[index] = val;
                                  _updateList('scope', l);
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _ListEditorCard(
                                title: 'Out of Project Scope',
                                items: _outOfScope,
                                icon: Icons.cancel_presentation_outlined,
                                color: Colors.red,
                                onGenerate: () =>
                                    _generateList('out', 'Out of Scope'),
                                onItemAdded: (val) =>
                                    _updateList('out', [..._outOfScope, val]),
                                onItemDeleted: (index) {
                                  final l = [..._outOfScope];
                                  l.removeAt(index);
                                  _updateList('out', l);
                                },
                                onItemEdited: (index, val) {
                                  final l = [..._outOfScope];
                                  l[index] = val;
                                  _updateList('out', l);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ListEditorCard(
                                title: 'Project Assumptions',
                                items: _assumptions,
                                icon: Icons.lightbulb_outline,
                                color: Colors.amber,
                                onGenerate: () =>
                                    _generateList('assumptions', 'Assumptions'),
                                onItemAdded: (val) => _updateList(
                                    'assumptions', [..._assumptions, val]),
                                onItemDeleted: (index) {
                                  final l = [..._assumptions];
                                  l.removeAt(index);
                                  _updateList('assumptions', l);
                                },
                                onItemEdited: (index, val) {
                                  final l = [..._assumptions];
                                  l[index] = val;
                                  _updateList('assumptions', l);
                                },
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _ListEditorCard(
                                title: 'Project Constraints',
                                items: _constraints,
                                icon: Icons.gavel_outlined,
                                color: Colors.orange,
                                onGenerate: () =>
                                    _generateList('constraints', 'Constraints'),
                                onItemAdded: (val) => _updateList(
                                    'constraints', [..._constraints, val]),
                                onItemDeleted: (index) {
                                  final l = [..._constraints];
                                  l.removeAt(index);
                                  _updateList('constraints', l);
                                },
                                onItemEdited: (index, val) {
                                  final l = [..._constraints];
                                  l[index] = val;
                                  _updateList('constraints', l);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Executive Summary Section (Legacy/Fallback)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            EditableContentText(
                              contentKey: 'fep_workspace_summary_title',
                              fallback: 'Executive Summary',
                              category: 'front_end_planning',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87),
                            ),
                            SizedBox(width: 8),
                            EditableContentText(
                              contentKey: 'fep_workspace_summary_subtitle',
                              fallback:
                                  '(Brief high-level overview not captured above)',
                              category: 'front_end_planning',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _roundedField(
                          context,
                          controller: _summaryController,
                          hint: 'Enter executive summary...',
                          minLines: 6,
                          onChanged: (_) {
                            // Debounce save logic could be added here
                          },
                        ),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: ElevatedButton(
              onPressed: () {
                ProjectDataHelper.saveAndNavigate(
                  context: context,
                  checkpoint: 'fep_details_complete',
                  nextScreenBuilder: () =>
                      const FrontEndPlanningRequirementsScreen(),
                  dataUpdater: (data) => data.copyWith(
                    withinScope: _withinScope,
                    outOfScope: _outOfScope,
                    assumptions: _assumptions,
                    constraints: _constraints,
                    frontEndPlanning: ProjectDataHelper.updateFEPField(
                      current: data.frontEndPlanning,
                      summary: _summaryController.text,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC812),
                foregroundColor: const Color(0xFF111827),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
                elevation: 0,
              ),
              child: const Text('Next',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _roundedField(BuildContext context,
      {required TextEditingController controller,
      required String hint,
      int minLines = 1,
      Function(String)? onChanged}) {
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
        onChanged: onChanged,
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
}

class _ListEditorCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;
  final Function(String) onItemAdded;
  final Function(int) onItemDeleted;
  final Function(int, String) onItemEdited;
  final VoidCallback? onGenerate;

  const _ListEditorCard({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
    required this.onItemAdded,
    required this.onItemDeleted,
    required this.onItemEdited,
    this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color.withOpacity(
                        0.8), // Darker shade approximation or just allow generic
                  ),
                ),
                const Spacer(),
                if (onGenerate != null) ...[
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    onPressed: onGenerate,
                    color: color,
                    tooltip: 'Generate with AI',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(right: 8),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _showAddDialog(context),
                  color: color,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'No items identified yet.',
                  style: TextStyle(
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                      fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 6, color: Color(0xFFD1D5DB)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item,
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF374151))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 16, color: Color(0xFF9CA3AF)),
                        onPressed: () => _showEditDialog(context, index, item),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: Color(0xFFEF4444)),
                        onPressed: () => onItemDeleted(index),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    String value = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add to $title'),
        content: TextField(
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Enter item description...'),
          onChanged: (v) => value = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (value.trim().isNotEmpty) onItemAdded(value.trim());
              Navigator.pop(context);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, int index, String current) {
    String value = current;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit item in $title'),
        content: TextField(
          autofocus: true,
          decoration:
              const InputDecoration(hintText: 'Enter item description...'),
          controller: TextEditingController(text: current),
          onChanged: (v) => value = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (value.trim().isNotEmpty) onItemEdited(index, value.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}
