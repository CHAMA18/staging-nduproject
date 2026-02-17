import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_contracts_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/program_workspace_scaffold.dart';
import 'package:ndu_project/widgets/user_access_chip.dart';

/// Front End Planning – Technology Personnel screen
/// Follows the same visual language as the other Front End Planning pages.
class FrontEndPlanningTechnologyPersonnelScreen extends StatefulWidget {
  const FrontEndPlanningTechnologyPersonnelScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningTechnologyPersonnelScreen()),
    );
  }

  @override
  State<FrontEndPlanningTechnologyPersonnelScreen> createState() =>
      _FrontEndPlanningTechnologyPersonnelScreenState();
}

class _FrontEndPlanningTechnologyPersonnelScreenState
    extends State<FrontEndPlanningTechnologyPersonnelScreen> {
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
                          hint: 'Input your notes here...',
                          minLines: 3),
                      const SizedBox(height: 22),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Expanded(child: _SectionTitle()),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _TechnologyPersonnelTable(),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _BottomOverlay(
              onSubmit: () => FrontEndPlanningContractsScreen.open(context)),
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
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'Technology Personnel  ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          TextSpan(
            text: '(Key roles and owners for project technologies)',
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

class _TechnologyPersonnelTable extends StatelessWidget {
  const _TechnologyPersonnelTable();

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

    TableRow buildRow(int index) {
      Widget td(Widget child) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          );
      return TableRow(children: [
        td(Text('$index', style: cellStyle)),
        td(Text('Technology area', style: cellStyle)),
        td(Text('Primary owner', style: cellStyle)),
        td(Text('Backup/Support', style: cellStyle)),
        td(Text('Notes', style: cellStyle)),
      ]);
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
              constraints.maxWidth > 1180 ? constraints.maxWidth : 1180.0;

          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minTableWidth),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(60),
                    1: FlexColumnWidth(2.0),
                    2: FlexColumnWidth(1.6),
                    3: FlexColumnWidth(1.6),
                    4: FlexColumnWidth(2.0),
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
                        th('Technology'),
                        th('Owner'),
                        th('Support'),
                        th('Notes'),
                      ],
                    ),
                    buildRow(1),
                    buildRow(2),
                    buildRow(3),
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

class _BottomOverlay extends StatelessWidget {
  const _BottomOverlay({required this.onSubmit});

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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F1FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD7E5FF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.auto_awesome, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Text('AI',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB))),
                        SizedBox(width: 10),
                        Text('Capture technology owners and support contacts.',
                            style: TextStyle(color: Color(0xFF1F2937))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: onSubmit,
                      child: const Text('Submit',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
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
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: 'Input your notes here...',
        hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
    ),
  );
}
