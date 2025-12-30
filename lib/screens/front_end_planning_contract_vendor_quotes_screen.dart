import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

/// Front End Planning – Contract and Vendor Quotes screen.
/// Mirrors the provided mock with the shared workspace chrome,
/// short notes field, large contract/vendor entry area, and
/// the bottom info + AI hint + next control row.
class FrontEndPlanningContractVendorQuotesScreen extends StatefulWidget {
  const FrontEndPlanningContractVendorQuotesScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FrontEndPlanningContractVendorQuotesScreen()),
    );
  }

  @override
  State<FrontEndPlanningContractVendorQuotesScreen> createState() => _FrontEndPlanningContractVendorQuotesScreenState();
}

class _FrontEndPlanningContractVendorQuotesScreenState extends State<FrontEndPlanningContractVendorQuotesScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _contractsController = TextEditingController();
  bool _isSyncReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ProjectDataHelper.getData(context);
      _contractsController.text = data.frontEndPlanning.contractVendorQuotes;
      _contractsController.addListener(_syncContractsToProvider);
      _isSyncReady = true;
      _syncContractsToProvider();
      if (_contractsController.text.trim().isEmpty) {
        _generateAiSuggestion();
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _generateAiSuggestion() async {
    try {
      final data = ProjectDataHelper.getData(context);
      final ctx = ProjectDataHelper.buildFepContext(data, sectionLabel: 'Contract & Vendor Quotes');
      final ai = OpenAiServiceSecure();
      final suggestion = await ai.generateFepSectionText(section: 'Contract & Vendor Quotes', context: ctx, maxTokens: 900, temperature: 0.55);
      if (!mounted) return;
      if (_contractsController.text.trim().isEmpty && suggestion.trim().isNotEmpty) {
        setState(() {
          _contractsController.text = suggestion.trim();
        });
      }
    } catch (e) {
      debugPrint('AI contracts suggestion failed: $e');
    }
  }

  @override
  void dispose() {
    if (_isSyncReady) {
      _contractsController.removeListener(_syncContractsToProvider);
    }
    _notesController.dispose();
    _contractsController.dispose();
    super.dispose();
  }

  void _syncContractsToProvider() {
    if (!mounted || !_isSyncReady) return;
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          contractVendorQuotes: _contractsController.text.trim(),
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Contract & Vendor Quotes'),
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
                        _roundedField(controller: _notesController, hint: 'Input your notes here...', minLines: 3),
                        const SizedBox(height: 24),
                        const _SectionTitle(),
                        const SizedBox(height: 18),
                        _ContractsPanel(controller: _contractsController),
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _BottomOverlay(onNext: () async {
                    await ProjectDataHelper.saveAndNavigate(
                      context: context,
                      checkpoint: 'fep_contracts',
                      nextScreenBuilder: () => const FrontEndPlanningProcurementScreen(),
                      dataUpdater: (data) => data.copyWith(
                        frontEndPlanning: ProjectDataHelper.updateFEPField(
                          current: data.frontEndPlanning,
                          contractVendorQuotes: _contractsController.text.trim(),
                        ),
                      ),
                    );
                  }),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        EditableContentText(
          contentKey: 'fep_contract_vendor_quotes_title',
          fallback: 'Contract and Vendor Quotes',
          category: 'front_end_planning',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(width: 8),
        EditableContentText(
          contentKey: 'fep_contract_vendor_quotes_subtitle',
          fallback: '(Brief explanation here)',
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

class _ContractsPanel extends StatelessWidget {
  const _ContractsPanel({required this.controller});

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
  const _BottomOverlay({required this.onNext});

  final VoidCallback onNext;

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
                          'Focus on major risks associated with each potential solution.',
                          style: TextStyle(color: Color(0xFF1F2937)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF6C437),
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
          Row(
            children: [
              _circleButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.maybePop(context)),
              const SizedBox(width: 8),
              _circleButton(icon: Icons.arrow_forward_ios_rounded, onTap: () {}),
            ],
          ),
          const Spacer(),
          const Text(
            'Front End Planning',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
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
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFE5E7EB),
                  child: Icon(Icons.person, color: Colors.black54, size: 16),
                ),
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
