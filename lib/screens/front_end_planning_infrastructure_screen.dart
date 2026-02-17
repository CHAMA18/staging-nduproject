import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ndu_project/screens/front_end_planning_technology_personnel_screen.dart';
import 'package:ndu_project/screens/front_end_planning_technology_screen.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/user_access_chip.dart';

/// Front End Planning – Project Infrastructure page
/// Matches the provided screenshot:
/// - ProgramWorkspaceSidebar on the left
/// - Top bar with centered "Front End Planning" and user chip
/// - Rounded notes input at the top
/// - Section header: "Project Infrastructure (Early planning for required project infrastructure.)"
///   with a yellow "Go to Detailed View" button on the right
/// - Table with headers: No | Infrastructure | Summary | Detailed Description | Potential cost
///   and three stub rows 1..3
/// - Bottom overlays: blue AI hint card (same content) and yellow "Next" pill
class FrontEndPlanningInfrastructureScreen extends StatefulWidget {
  const FrontEndPlanningInfrastructureScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningInfrastructureScreen()),
    );
  }

  @override
  State<FrontEndPlanningInfrastructureScreen> createState() =>
      _FrontEndPlanningInfrastructureScreenState();
}

class _FrontEndPlanningInfrastructureScreenState
    extends State<FrontEndPlanningInfrastructureScreen> {
  final TextEditingController _notes = TextEditingController();
  Timer? _infrastructurePromptTimer;
  bool _hasShownPrompt = false;
  // ignore: unused_field
  DateTime? _lastActivityTime;

  @override
  void initState() {
    super.initState();
    _lastActivityTime = DateTime.now();

    // Listen to text field changes to track activity
    _notes.addListener(_onTextChanged);

    // Start timer for infrastructure prompt (60 seconds of inactivity)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInactivityTimer();
    });
  }

  void _onTextChanged() {
    _lastActivityTime = DateTime.now();
    // Reset timer if user is typing
    _infrastructurePromptTimer?.cancel();
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _infrastructurePromptTimer?.cancel();
    _infrastructurePromptTimer = Timer(const Duration(seconds: 60), () {
      if (mounted && !_hasShownPrompt) {
        _checkAndShowInfrastructurePrompt();
      }
    });
  }

  void _checkAndShowInfrastructurePrompt() {
    // Check if notes field is empty
    if (_notes.text.trim().isEmpty && mounted && !_hasShownPrompt) {
      _hasShownPrompt = true;
      _showInfrastructureDialog().then((_) {
        // Reset flag after dialog is closed so it can show again if needed
        if (mounted) {
          _hasShownPrompt = false;
          _startInactivityTimer(); // Restart timer
        }
      });
    }
  }

  Future<String?> _showInfrastructureDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline,
                        color: Colors.black87, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Project Infrastructure :',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Provide more information on identified infrastructure. Identify additional infrastructure if applicable',
                style:
                    TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter infrastructure details here...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    Navigator.of(context).pop(text.isEmpty ? null : text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Sure Continue !',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _infrastructurePromptTimer?.cancel();
    _notes.removeListener(_onTextChanged);
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InitiationLikeSidebar(
                activeItemLabel: 'Initiation: Front End Planning'),
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
                                  controller: _notes,
                                  hint: 'Input your notes here...',
                                  minLines: 3),
                              const SizedBox(height: 22),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: RichText(
                                      text: const TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Project Infrastructure  ',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                '(Early planning for required project infrastructure.)',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _yellowPillButton(
                                    label: 'Go to Detailed View',
                                    onTap: () =>
                                        FrontEndPlanningTechnologyScreen.open(
                                            context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _InfrastructureTable(),
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _BottomOverlays(
                    nextLabel: 'Next',
                    onAddItems: () {
                      // TODO: Implement add items dialog
                    },
                  ),
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

class _InfrastructureTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final border = const BorderSide(color: Color(0xFFE5E7EB));
    final headerStyle = const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563));
    final cellStyle = const TextStyle(fontSize: 14, color: Color(0xFF111827));

    TableRow dataRow(int index) {
      Widget td(Widget child) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child);
      return TableRow(children: [
        td(Text('$index', style: cellStyle)),
        td(Text('Potential Opportunity', style: cellStyle)),
        td(Text('Summary', style: cellStyle)),
        td(Text('Detailed Description', style: cellStyle)),
        td(Text('Potential Cost', style: cellStyle)),
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
              constraints.maxWidth > 1220 ? constraints.maxWidth : 1220.0;

          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minTableWidth),
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(52),
                    1: FlexColumnWidth(2.0),
                    2: FlexColumnWidth(1.6),
                    3: FlexColumnWidth(2.0),
                    4: FlexColumnWidth(1.4),
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
                        _th('Infrastructure', headerStyle),
                        _th('Summary', headerStyle),
                        _th('Detailed Description', headerStyle),
                        _th('Potential cost', headerStyle),
                      ],
                    ),
                    dataRow(1),
                    dataRow(2),
                    dataRow(3),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _th(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: EditableContentText(
        contentKey:
            'fep_infra_header_${text.toLowerCase().replaceAll(' ', '_')}',
        fallback: text,
        category: 'front_end_planning',
        style: style,
      ),
    );
  }
}

class _BottomOverlays extends StatelessWidget {
  const _BottomOverlays({required this.nextLabel, required this.onAddItems});
  final String nextLabel;
  final VoidCallback onAddItems;

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
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                        color: Color(0xFFB3D9FF), shape: BoxShape.circle),
                    child: const Icon(Icons.info_outline, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onAddItems,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Add Items',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ],
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
                    onPressed: () =>
                        FrontEndPlanningTechnologyPersonnelScreen.open(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: Text(nextLabel,
                        style: const TextStyle(
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

Widget _yellowPillButton({required String label, required VoidCallback onTap}) {
  return ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFD700),
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    ),
    child: Text(label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
  );
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
