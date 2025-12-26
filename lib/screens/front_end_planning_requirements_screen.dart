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
      MaterialPageRoute(builder: (_) => const FrontEndPlanningRequirementsScreen()),
    );
  }

  @override
  State<FrontEndPlanningRequirementsScreen> createState() => _FrontEndPlanningRequirementsScreenState();
}

class _FrontEndPlanningRequirementsScreenState extends State<FrontEndPlanningRequirementsScreen> {
  final TextEditingController _notesController = TextEditingController();

  // Start with a single requirement row; additional rows are added via "Add another"
  final List<_RequirementRow> _rows = [
    _RequirementRow(number: 1),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectData = ProjectDataHelper.getData(context);
      _notesController.text = projectData.frontEndPlanning.requirements;
      // Seed requirement rows from AI if empty
      if (_rows.isEmpty || (_rows.length == 1 && _rows.first.descriptionController.text.trim().isEmpty)) {
        _generateRequirementsFromContext();
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _generateRequirementsFromContext() async {
    try {
      final data = ProjectDataHelper.getData(context);
      final ctx = ProjectDataHelper.buildFepContext(data, sectionLabel: 'Project Requirements');
      final ai = OpenAiServiceSecure();
      final reqs = await ai.generateRequirementsFromBusinessCase(ctx);
      if (!mounted) return;
      if (reqs.isNotEmpty) {
        setState(() {
          _rows
            ..clear()
            ..addAll(reqs.asMap().entries.map((e) {
              final r = _RequirementRow(number: e.key + 1);
              r.descriptionController.text = (e.value['requirement'] ?? '').toString();
              r.commentsController.text = '';
              r.selectedType = (e.value['requirementType'] ?? '').toString();
              return r;
            }));
        });
      }
    } catch (e) {
      debugPrint('AI requirements suggestion failed: $e');
    }
  }

  @override
  void dispose() {
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Project Requirements'),
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
                        _roundedField(
                          controller: _notesController,
                          hint: 'Input your notes here…',
                          minLines: 3,
                        ),
                        const SizedBox(height: 20),
                        const EditableContentText(
                          contentKey: 'fep_requirements_title',
                          fallback: 'Project Requirements',
                          category: 'front_end_planning',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 6),
                        const EditableContentText(
                          contentKey: 'fep_requirements_subtitle',
                          fallback: 'Identify actual needs, conditions, or capabilities that this project must meet to be\nconsidered successful',
                          category: 'front_end_planning',
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.2),
                        ),
                        const SizedBox(height: 14),
                        _buildRequirementsTable(context),
                        const SizedBox(height: 16),
                        _addAnotherButton(),
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
    final headerStyle = const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563));
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
            ],
          ),
          ..._rows.map((r) => r.buildRow(context)),
        ],
      ),
    );
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

  Widget _addAnotherButton() {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _rows.add(_RequirementRow(number: _rows.length + 1));
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF2F4F7),
          foregroundColor: const Color(0xFF111827),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        ),
        child: const Text('Add another', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _handleSubmit() async {
    // Gather non-empty requirement descriptions
    final requirements = _rows
        .map((r) => r.descriptionController.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    
    final requirementsText = requirements.join('\n');
    
    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'fep_requirements',
      nextScreenBuilder: () => const FrontEndPlanningRisksScreen(),
      dataUpdater: (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          requirements: requirementsText,
        ),
      ),
    );
  }
}

class _RequirementRow {
  _RequirementRow({required this.number})
      : descriptionController = TextEditingController(),
        commentsController = TextEditingController();

  final int number;
  final TextEditingController descriptionController;
  final TextEditingController commentsController;
  String? selectedType;

  void dispose() {
    descriptionController.dispose();
    commentsController.dispose();
  }

  TableRow buildRow(BuildContext context) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text('$number', style: const TextStyle(fontSize: 14, color: Color(0xFF111827))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: descriptionController,
            minLines: 2,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Requirement description',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _TypeDropdown(
            value: selectedType,
            onChanged: (v) => selectedType = v,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: commentsController,
            minLines: 2,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Add comments…',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
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
  final List<String> _options = const ['Technical', 'Regulatory', 'Functional', 'Operational', 'Non-Functional', 'Business', 'Stakeholder', 'Solutions', 'Transitional', 'Other'];

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
          hint: const Text('Select…', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280), size: 20),
          isExpanded: true,
          onChanged: (v) {
            setState(() => _value = v);
            widget.onChanged(v);
          },
          items: _options
              .map((e) => DropdownMenuItem<String?>(
                    value: e,
                    child: Text(e, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
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
              child: _circleButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.maybePop(context)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
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
