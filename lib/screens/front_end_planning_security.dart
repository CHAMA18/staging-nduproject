import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/screens/front_end_planning_allowance.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';

/// Front End Planning – Security screen
/// Mirrors the provided layout with shared workspace chrome,
/// large notes area, security text panel, and AI hint + Next controls.
class FrontEndPlanningSecurityScreen extends StatefulWidget {
  const FrontEndPlanningSecurityScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FrontEndPlanningSecurityScreen()),
    );
  }

  @override
  State<FrontEndPlanningSecurityScreen> createState() => _FrontEndPlanningSecurityScreenState();
}

class _FrontEndPlanningSecurityScreenState extends State<FrontEndPlanningSecurityScreen> {
  final TextEditingController _notes = TextEditingController();
  final TextEditingController _securityNotes = TextEditingController();
  bool _isSyncReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ProjectDataHelper.getData(context);
      _securityNotes.text = data.frontEndPlanning.security;
      _securityNotes.addListener(_syncSecurityToProvider);
      _isSyncReady = true;
      _syncSecurityToProvider();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    if (_isSyncReady) {
      _securityNotes.removeListener(_syncSecurityToProvider);
    }
    _notes.dispose();
    _securityNotes.dispose();
    super.dispose();
  }

  void _syncSecurityToProvider() {
    if (!mounted || !_isSyncReady) return;
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          security: _securityNotes.text.trim(),
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Security'),
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
                        _SecurityPanel(controller: _securityNotes),
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _BottomOverlay(securityController: _securityNotes),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: const [
                CircleAvatar(radius: 14, backgroundColor: Color(0xFFE5E7EB), child: Icon(Icons.person, color: Colors.black54, size: 16)),
                SizedBox(width: 8),
                Text('Samuel kamanga', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                SizedBox(width: 8),
                Text('Product manager', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
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
            text: 'Security  ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          TextSpan(
            text: '(Identify security considerations and requirements for the project.)',
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

class _SecurityPanel extends StatelessWidget {
  const _SecurityPanel({required this.controller});

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
  const _BottomOverlay({required this.securityController});
  
  final TextEditingController securityController;

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
                          'Identify security measures and compliance requirements.',
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
                        checkpoint: 'fep_security',
                        nextScreenBuilder: () => const FrontEndPlanningAllowanceScreen(),
                        dataUpdater: (data) => data.copyWith(
                          frontEndPlanning: ProjectDataHelper.updateFEPField(
                            current: data.frontEndPlanning,
                            security: securityController.text.trim(),
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
