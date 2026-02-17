import 'package:flutter/material.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/program_workspace_scaffold.dart';
import 'package:ndu_project/widgets/user_access_chip.dart';

/// Front End Planning – Project Personnel page
/// Mirrors the provided screenshot with:
/// - Left program sidebar
/// - Top bar featuring back/forward buttons, centered title, and user chip
/// - Notes input field
/// - Section header "Project Personnel" with contextual subtitle and an action pill
/// - Table listing Project Roles and Definition dropdowns
/// - Bottom overlays with info icon, AI hint, and yellow Submit button
class FrontEndPlanningPersonnelScreen extends StatefulWidget {
  const FrontEndPlanningPersonnelScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningPersonnelScreen()),
    );
  }

  @override
  State<FrontEndPlanningPersonnelScreen> createState() =>
      _FrontEndPlanningPersonnelScreenState();
}

class _FrontEndPlanningPersonnelScreenState
    extends State<FrontEndPlanningPersonnelScreen> {
  final TextEditingController _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProgramWorkspaceScaffold(
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
                          hint: 'Input your notes here…',
                          minLines: 3),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Expanded(child: _SectionTitle()),
                          SizedBox(width: 12),
                          _AddRoleButton(),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _PersonnelTable(),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _BottomOverlays(
              onSubmit: () => WorkBreakdownStructureScreen.open(context)),
          const KazAiChatBubble(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        EditableContentText(
          contentKey: 'fep_personnel_title',
          fallback: 'Project Personnel',
          category: 'front_end_planning',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        EditableContentText(
          contentKey: 'fep_personnel_subtitle',
          fallback:
              '(Early identification of core project roles and people ( if known))',
          category: 'front_end_planning',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _AddRoleButton extends StatelessWidget {
  const _AddRoleButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFF2F4F7),
          foregroundColor: const Color(0xFF111827),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        child: const Text('Add a role and description'),
      ),
    );
  }
}

class _PersonnelTable extends StatelessWidget {
  const _PersonnelTable();

  @override
  Widget build(BuildContext context) {
    final border = const BorderSide(color: Color(0xFFE5E7EB));
    final headerStyle = const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563));
    final cellStyle = const TextStyle(fontSize: 14, color: Color(0xFF111827));

    Widget th(String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(text, style: headerStyle),
        );

    Widget dropdownPlaceholder() {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: const [
            Expanded(
                child: Text('Select...',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14))),
            Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
          ],
        ),
      );
    }

    TableRow buildRow(int index) {
      Widget td(Widget child) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          );
      return TableRow(
        children: [
          td(Text('$index', style: cellStyle)),
          td(Text('Project Roles', style: cellStyle)),
          td(dropdownPlaceholder()),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minTableWidth =
              constraints.maxWidth > 980 ? constraints.maxWidth : 980.0;

          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minTableWidth),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(70),
                    1: FlexColumnWidth(2.2),
                    2: FlexColumnWidth(2.8),
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
                        th('No'),
                        th('Project Roles'),
                        th('Definition'),
                      ],
                    ),
                    buildRow(1),
                    buildRow(2),
                  ],
                ),
              ),
            ),
          );
        },
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
          Text('AI',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
          SizedBox(width: 10),
          Text('Focus on major risks associated with each potential solution.',
              style: TextStyle(color: Color(0xFF1F2937))),
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
          const EditableContentText(
            contentKey: 'fep_top_bar_title',
            fallback: 'Front End Planning',
            category: 'front_end_planning',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
          ),
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
