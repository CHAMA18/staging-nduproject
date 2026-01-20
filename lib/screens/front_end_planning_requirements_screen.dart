import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_risks_screen.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/models/project_data_model.dart';

/// Front End Planning – Project Requirements page
/// Implements the layout from the provided screenshot exactly:
/// - Top notes field
/// - "Project Requirements" table with No, Requirement, Requirement type
/// - Add another row button
/// - Bottom AI hint chip and yellow Submit button
/// - Bottom-left and bottom-right pager chevrons
class FrontEndPlanningRequirementsScreen extends StatefulWidget {
  const FrontEndPlanningRequirementsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningRequirementsScreen()),
    );
  }

  @override
  State<FrontEndPlanningRequirementsScreen> createState() =>
      _FrontEndPlanningRequirementsScreenState();
}

class _FrontEndPlanningRequirementsScreenState
    extends State<FrontEndPlanningRequirementsScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isGeneratingRequirements = false;
  bool _isRegeneratingRow = false;
  int? _regeneratingRowIndex;
  Timer? _autoSaveTimer;
  DateTime? _lastAutoSaveSnackAt;

  // Start with a single requirement row; additional rows are added via "Add another"
  final List<_RequirementRow> _rows = [];

  @override
  void initState() {
    super.initState();
    // Ensure OpenAI key/env is loaded for per-row regenerate.
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_rows.isEmpty) {
        _rows.add(_createRow(1));
      }
      final projectData = ProjectDataHelper.getData(context);
      _notesController.text = projectData.frontEndPlanning.requirementsNotes;
      _notesController.addListener(_handleNotesChanged);
      _loadSavedRequirements(projectData);
      // Seed requirement rows from AI if empty
      if (_rows.isEmpty ||
          (_rows.length == 1 &&
              _rows.first.descriptionController.text.trim().isEmpty)) {
        _generateRequirementsFromContext();
      }
      if (mounted) setState(() {});
    });
  }

  _RequirementRow _createRow(int number) {
    return _RequirementRow(number: number, onChanged: _scheduleAutoSave);
  }

  void _loadSavedRequirements(ProjectDataModel data) {
    final savedItems = data.frontEndPlanning.requirementItems;
    if (savedItems.isNotEmpty) {
      _rows
        ..clear()
        ..addAll(savedItems.asMap().entries.map((entry) {
          final item = entry.value;
          final row = _createRow(entry.key + 1);
          row.descriptionController.text = item.description;
          row.commentsController.text = item.comments;
          row.selectedType = item.requirementType;
          return row;
        }));
      return;
    }

    final savedText = data.frontEndPlanning.requirements.trim();
    if (savedText.isNotEmpty) {
      final lines = savedText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (lines.isNotEmpty) {
        _rows
          ..clear()
          ..addAll(lines.asMap().entries.map((entry) {
            final row = _createRow(entry.key + 1);
            row.descriptionController.text = entry.value;
            return row;
          }));
      }
    }
  }

  Future<void> _generateRequirementsFromContext() async {
    setState(() => _isGeneratingRequirements = true);
    try {
      final data = ProjectDataHelper.getData(context);
      final ctx = ProjectDataHelper.buildFepContext(data,
          sectionLabel: 'Project Requirements');
      final ai = OpenAiServiceSecure();
      final reqs = await ai.generateRequirementsFromBusinessCase(ctx);
      if (!mounted) return;
      if (reqs.isNotEmpty) {
        setState(() {
          _rows
            ..clear()
            ..addAll(reqs.asMap().entries.map((e) {
              final r = _createRow(e.key + 1);
              r.descriptionController.text =
                  (e.value['requirement'] ?? '').toString();
              r.commentsController.text = '';
              r.selectedType = (e.value['requirementType'] ?? '').toString();
              return r;
            }));
          _isGeneratingRequirements = false;
        });
        _commitAutoSave(showSnack: false);
        return;
      }
    } catch (e) {
      debugPrint('AI requirements suggestion failed: $e');
    }
    if (mounted) {
      setState(() => _isGeneratingRequirements = false);
    }
  }

  Future<void> _regenerateRequirementRow(int index) async {
    if (index < 0 || index >= _rows.length) return;
    if (_isGeneratingRequirements || _isRegeneratingRow) return;
    setState(() {
      _isRegeneratingRow = true;
      _regeneratingRowIndex = index;
    });

    try {
      final data = ProjectDataHelper.getData(context);
      final ctx = ProjectDataHelper.buildFepContext(data,
          sectionLabel: 'Project Requirements');
      final ai = OpenAiServiceSecure();
      final reqs = await ai.generateRequirementsFromBusinessCase(ctx);
      if (!mounted) return;

      final pickedIndex = reqs.isNotEmpty ? (index % reqs.length) : null;
      final nextText = pickedIndex == null
          ? ''
          : (reqs[pickedIndex]['requirement'] ?? '').toString().trim();
      if (nextText.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI returned no requirement text.')),
          );
        }
        return;
      }
      final row = _rows[index];
      row.aiUndoText = row.descriptionController.text;
      row.descriptionController.text = nextText;
      _commitAutoSave(showSnack: false);
      // Persist so the regenerated version is what Firestore gets.
      await ProjectDataHelper.getProvider(context)
          .saveToFirebase(checkpoint: 'fep_requirements');
      if (mounted) setState(() {}); // refresh undo enabled state
    } catch (e) {
      debugPrint('Row requirement regenerate failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Regenerate failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegeneratingRow = false;
          _regeneratingRowIndex = null;
        });
      }
    }
  }

  void _undoRequirementRow(int index) {
    if (index < 0 || index >= _rows.length) return;
    final row = _rows[index];
    final previous = row.aiUndoText;
    if (previous == null) return;
    row.descriptionController.text = previous;
    row.aiUndoText = null;
    _commitAutoSave(showSnack: false);
    // Persist so the undone version is what Firestore gets.
    ProjectDataHelper.getProvider(context)
        .saveToFirebase(checkpoint: 'fep_requirements');
    setState(() {}); // refresh undo enabled state
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _notesController.removeListener(_handleNotesChanged);
    _notesController.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ensure white background as requested
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use the exact same sidebar style as PreferredSolutionAnalysisScreen
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Project Requirements'),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _roundedField(
                                controller: _notesController,
                                hint: 'Input your notes here…',
                                minLines: 3,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const EditableContentText(
                                          contentKey: 'fep_requirements_title',
                                          fallback: 'Project Requirements',
                                          category: 'front_end_planning',
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF111827)),
                                        ),
                                        const SizedBox(height: 6),
                                        const EditableContentText(
                                          contentKey:
                                              'fep_requirements_subtitle',
                                          fallback:
                                              'Identify actual needs, conditions, or capabilities that this project must meet to be\nconsidered successful',
                                          category: 'front_end_planning',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF6B7280),
                                              height: 1.2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Refresh icon in top-right of card header
                                  IconButton(
                                    icon: _isGeneratingRequirements
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFF2563EB)),
                                          )
                                        : const Icon(Icons.refresh,
                                            size: 20, color: Color(0xFF2563EB)),
                                    onPressed: _isGeneratingRequirements
                                        ? null
                                        : _confirmRegenerate,
                                    tooltip: 'Regenerate requirements',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 40, minHeight: 40),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildRequirementsTable(context),
                              const SizedBox(height: 16),
                              _buildActionButtons(),
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _BottomOverlays(onSubmit: _handleSubmit),
                  const Positioned(
                    right: 24,
                    bottom: 90,
                    child: KazAiChatBubble(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsTable(BuildContext context) {
    final headerStyle = const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563));
    final border = const BorderSide(color: Color(0xFFE5E7EB));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(70),
          1: FlexColumnWidth(2.5),
          2: FixedColumnWidth(220),
          3: FlexColumnWidth(2.5),
          4: FixedColumnWidth(60),
        },
        border: TableBorder(
          horizontalInside: border,
          verticalInside: border,
          top: border,
          bottom: border,
          left: border,
          right: border,
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
            children: [
              _th('No', headerStyle),
              _th('Requirement', headerStyle),
              _th('Requirement type', headerStyle),
              _th('Comments', headerStyle),
              _th('', headerStyle), // Empty header for delete column
            ],
          ),
          ..._rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isRowLoading =
                _isRegeneratingRow && _regeneratingRowIndex == index;
            return row.buildRow(
              context,
              index,
              _deleteRow,
              isRegenerating: isRowLoading,
              onRegenerate: () => _regenerateRequirementRow(index),
              onUndo: () => _undoRequirementRow(index),
            );
          }),
        ],
      ),
    );
  }

  void _deleteRow(int index) {
    if (index < 0 || index >= _rows.length) return;

    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
      // Renumber remaining rows
      for (int i = 0; i < _rows.length; i++) {
        _rows[i].number = i + 1;
      }
    });

    // Update provider state and Firebase
    _commitAutoSave(showSnack: false);
  }

  Widget _th(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: EditableContentText(
        contentKey: 'fep_req_header_${text.toLowerCase().replaceAll(' ', '_')}',
        fallback: text,
        category: 'front_end_planning',
        style: style,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _rows.add(_createRow(_rows.length + 1));
              });
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFF2F4F7),
              foregroundColor: const Color(0xFF111827),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Add another',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    final requirementItems = _buildRequirementItems();
    final requirementsText = requirementItems
        .map((item) => item.description.trim())
        .where((t) => t.isNotEmpty)
        .join('\n');
    final requirementsNotes = _notesController.text.trim();

    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'fep_requirements',
      nextScreenBuilder: () => const FrontEndPlanningRisksScreen(),
      dataUpdater: (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          requirements: requirementsText,
          requirementsNotes: requirementsNotes,
          requirementItems: requirementItems,
        ),
      ),
    );
  }

  List<RequirementItem> _buildRequirementItems() {
    return _rows
        .map((row) => RequirementItem(
              description: row.descriptionController.text.trim(),
              requirementType: row.selectedType ?? '',
              comments: row.commentsController.text.trim(),
            ))
        .where((item) =>
            item.description.isNotEmpty ||
            item.requirementType.isNotEmpty ||
            item.comments.isNotEmpty)
        .toList();
  }

  void _handleNotesChanged() {
    _scheduleAutoSave();
  }

  void _scheduleAutoSave({bool showSnack = true}) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () {
      _commitAutoSave(showSnack: showSnack);
    });
  }

  void _commitAutoSave({bool showSnack = true}) {
    if (!mounted) return;
    final items = _buildRequirementItems();
    final requirementsText = items
        .map((item) => item.description.trim())
        .where((t) => t.isNotEmpty)
        .join('\n');
    final requirementsNotes = _notesController.text.trim();
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          requirements: requirementsText,
          requirementsNotes: requirementsNotes,
          requirementItems: items,
        ),
      ),
    );

    if (showSnack) {
      _showAutoSaveSnack();
    }
  }

  void _showAutoSaveSnack() {
    final now = DateTime.now();
    if (_lastAutoSaveSnackAt != null &&
        now.difference(_lastAutoSaveSnackAt!) < const Duration(seconds: 4)) {
      return;
    }
    _lastAutoSaveSnackAt = now;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Draft saved'),
          duration: Duration(seconds: 1),
        ),
      );
  }

  bool _hasAnyRequirementInputs() {
    for (final row in _rows) {
      if (row.descriptionController.text.trim().isNotEmpty ||
          row.commentsController.text.trim().isNotEmpty ||
          (row.selectedType ?? '').trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> _confirmRegenerate() async {
    if (_isGeneratingRequirements) return;
    if (!_hasAnyRequirementInputs()) {
      await _generateRequirementsFromContext();
      return;
    }

    final shouldRegenerate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Regenerate requirements?'),
          content: const Text(
              'This will replace your current requirements. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Regenerate'),
            ),
          ],
        );
      },
    );

    if (shouldRegenerate == true && mounted) {
      await _generateRequirementsFromContext();
    }
  }
}

class _RequirementRow {
  _RequirementRow({required int number, this.onChanged})
      : _number = number,
        descriptionController = TextEditingController(),
        commentsController = TextEditingController();

  int _number;
  int get number => _number;
  set number(int value) => _number = value;

  final TextEditingController descriptionController;
  final TextEditingController commentsController;
  String? selectedType;
  final VoidCallback? onChanged;
  String? aiUndoText;

  void dispose() {
    descriptionController.dispose();
    commentsController.dispose();
  }

  TableRow buildRow(
    BuildContext context,
    int index,
    void Function(int) onDelete, {
    required bool isRegenerating,
    required VoidCallback onRegenerate,
    required VoidCallback onUndo,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text('$number',
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: descriptionController,
            minLines: 2,
            maxLines: null,
            onChanged: (_) => onChanged?.call(),
            decoration: InputDecoration(
              hintText: 'Requirement description',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              isDense: true,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Regenerate (AI)',
                      child: IconButton(
                        onPressed: isRegenerating ? null : onRegenerate,
                        icon: isRegenerating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh,
                                size: 18, color: Color(0xFF2563EB)),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ),
                    Tooltip(
                      message: 'Undo last AI regenerate',
                      child: IconButton(
                        onPressed: (aiUndoText != null) ? onUndo : null,
                        icon: const Icon(Icons.undo,
                            size: 18, color: Color(0xFF6B7280)),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _TypeDropdown(
            value: selectedType,
            onChanged: (v) {
              selectedType = v;
              onChanged?.call();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: commentsController,
            minLines: 2,
            maxLines: null,
            onChanged: (_) => onChanged?.call(),
            decoration: const InputDecoration(
              hintText: 'Add comments…',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: Color(0xFFEF4444)),
            onPressed: () => onDelete(index),
            tooltip: 'Delete requirement',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }
}

class _TypeDropdown extends StatefulWidget {
  const _TypeDropdown({this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  State<_TypeDropdown> createState() => _TypeDropdownState();
}

class _TypeDropdownState extends State<_TypeDropdown> {
  late String? _value = widget.value;
  final List<String> _options = const [
    'Technical',
    'Regulatory',
    'Functional',
    'Operational',
    'Non-Functional',
    'Business',
    'Stakeholder',
    'Solutions',
    'Transitional',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _value,
          hint: const Text('Select…',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280), size: 20),
          isExpanded: true,
          onChanged: (v) {
            setState(() => _value = v);
            widget.onChanged(v);
          },
          items: _options
              .map((e) => DropdownMenuItem<String?>(
                    value: e,
                    child: Text(e,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _BottomOverlays extends StatelessWidget {
  const _BottomOverlays({required this.onSubmit});
  final VoidCallback onSubmit;

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
              child: _circleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.maybePop(context)),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: Row(
                children: [
                  _aiHint(),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const Text('Submit',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  // Removed the standalone '>' icon per request
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aiHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E5FF)),
      ),
      child: Row(
        children: const [
          Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
          SizedBox(width: 8),
          Text(
            'AI',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
          ),
          SizedBox(width: 10),
          Text(
            'Focus on major risks associated with each potential solution.',
            style: TextStyle(color: Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
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
