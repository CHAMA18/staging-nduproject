import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/screens/front_end_planning_allowance.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/widgets/user_access_chip.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/ai_regenerate_undo_buttons.dart';

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
  bool _isGenerating = false;
  String? _undoBeforeAi;
  late final OpenAiServiceSecure _openAi;

  @override
  void initState() {
    super.initState();
    _openAi = OpenAiServiceSecure();
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = ProjectDataHelper.getData(context);
      _securityNotes.text = data.frontEndPlanning.security;
      _securityNotes.addListener(_syncSecurityToProvider);
      _isSyncReady = true;
      _syncSecurityToProvider();
      
      // Auto-generate security content if empty
      if (_securityNotes.text.trim().isEmpty) {
        await _generateSecurityContent();
      }
      
      if (mounted) setState(() {});
    });
  }

  Future<void> _generateSecurityContent() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    _undoBeforeAi = _securityNotes.text;

    try {
      final data = ProjectDataHelper.getData(context);
      final projectContext = ProjectDataHelper.buildFepContext(data, sectionLabel: 'Security');
      
      if (projectContext.trim().isNotEmpty) {
        try {
          final generatedText = await _openAi.generateFepSectionText(
            section: 'Security',
            context: projectContext,
            maxTokens: 800,
          );
          
          if (mounted && generatedText.isNotEmpty) {
            setState(() {
              _securityNotes.text = generatedText;
              _syncSecurityToProvider();
            });
            await ProjectDataHelper.getProvider(context)
                .saveToFirebase(checkpoint: 'fep_security');
          }
        } catch (e) {
          debugPrint('Error generating security content: $e');
          // Use fallback content
          if (mounted) {
            setState(() {
              _securityNotes.text = _getFallbackSecurityContent(data);
              _syncSecurityToProvider();
            });
          }
        }
      } else {
        // Use fallback if no context available
        if (mounted) {
          setState(() {
            _securityNotes.text = _getFallbackSecurityContent(data);
            _syncSecurityToProvider();
          });
        }
      }
    } catch (e) {
      debugPrint('Error in security generation: $e');
      // Use fallback content
      if (mounted) {
        final data = ProjectDataHelper.getData(context);
        setState(() {
          _securityNotes.text = _getFallbackSecurityContent(data);
          _syncSecurityToProvider();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _undoSecurity() {
    final prev = _undoBeforeAi;
    if (prev == null) return;
    _undoBeforeAi = null;
    _securityNotes.text = prev;
    _syncSecurityToProvider();
    ProjectDataHelper.getProvider(context).saveToFirebase(checkpoint: 'fep_security');
    setState(() {});
  }

  String _getFallbackSecurityContent(ProjectDataModel data) {
    return '''Security Considerations and Requirements

Access Control and Authentication:
- Implement role-based access control (RBAC) to ensure users have appropriate permissions
- Establish multi-factor authentication (MFA) for sensitive systems and data access
- Define user access policies and review access rights regularly

Data Protection:
- Encrypt sensitive data at rest and in transit using industry-standard encryption protocols
- Implement data classification policies to identify and protect confidential information
- Establish secure data backup and recovery procedures

Network Security:
- Deploy firewalls and intrusion detection/prevention systems
- Implement network segmentation to isolate critical systems
- Establish secure VPN access for remote users

Compliance and Governance:
- Ensure compliance with relevant security standards and regulations (e.g., ISO 27001, GDPR)
- Conduct regular security audits and vulnerability assessments
- Establish incident response procedures and security monitoring

Physical Security:
- Secure physical access to facilities and equipment
- Implement environmental controls for data centers and server rooms
- Establish visitor access policies and procedures

Security Training:
- Provide security awareness training for all project team members
- Establish clear security policies and procedures
- Conduct regular security reviews and updates''';
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
                        _SectionTitle(
                          trailing: AiRegenerateUndoButtons(
                            isLoading: _isGenerating,
                            canUndo: _undoBeforeAi != null,
                            onRegenerate: _generateSecurityContent,
                            onUndo: _undoSecurity,
                          ),
                        ),
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
  const _SectionTitle({this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
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
                  text:
                      '(Identify security considerations and requirements for the project.)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
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
