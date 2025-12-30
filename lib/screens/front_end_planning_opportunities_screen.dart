import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_contract_vendor_quotes_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

/// Front End Planning – Project Opportunities page
/// Built to match the provided screenshot exactly:
/// - Left ProgramWorkspaceSidebar
/// - Top bar with back/forward, centered title, and user chip
/// - Rounded notes input
/// - Section title: Project Opportunities (List out opportunities that would benefit the project here)
/// - Table with headers: No | Potential Opportunity | Discipline | Stakeholder | Potential Cost | Potential Cost
/// - Three sample rows (1..3)
/// - Bottom-left circular info icon
/// - Bottom-right yellow Submit pill button and blue AI hint card (as shown)
class FrontEndPlanningOpportunitiesScreen extends StatefulWidget {
  const FrontEndPlanningOpportunitiesScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FrontEndPlanningOpportunitiesScreen()),
    );
  }

  @override
  State<FrontEndPlanningOpportunitiesScreen> createState() => _FrontEndPlanningOpportunitiesScreenState();
}

class _FrontEndPlanningOpportunitiesScreenState extends State<FrontEndPlanningOpportunitiesScreen> {
  final TextEditingController _notes = TextEditingController();
  bool _isSyncReady = false;

  // Backing rows for the table; built from incoming requirements (if any).
  late List<_OpportunityItem> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectData = ProjectDataHelper.getData(context);
      _notes.text = projectData.frontEndPlanning.opportunities;
      _notes.addListener(_syncOpportunitiesToProvider);
      _isSyncReady = true;
      _syncOpportunitiesToProvider();
      if (_rows.isEmpty) {
        _generateOpportunitiesFromContext();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    if (_isSyncReady) {
      _notes.removeListener(_syncOpportunitiesToProvider);
    }
    _notes.dispose();
    super.dispose();
  }

  void _syncOpportunitiesToProvider() {
    if (!mounted || !_isSyncReady) return;
    final oppText = _rows
        .map((r) => '${r.opportunity}: ${r.discipline}')
        .where((s) => s.trim().isNotEmpty)
        .join('\n');
    final value = oppText.isNotEmpty ? oppText : _notes.text.trim();
    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          opportunities: value,
        ),
      ),
    );
  }

  Future<void> _generateOpportunitiesFromContext() async {
    try {
      final data = ProjectDataHelper.getData(context);
      final ctx = ProjectDataHelper.buildFepContext(data, sectionLabel: 'Project Opportunities');
      final ai = OpenAiServiceSecure();
      final list = await ai.generateOpportunitiesFromContext(ctx);
      if (!mounted) return;
      if (list.isNotEmpty) {
        setState(() {
          _rows = list
              .map((e) => _OpportunityItem(
                    opportunity: (e['opportunity'] ?? '').toString(),
                    discipline: (e['discipline'] ?? '').toString(),
                    stakeholder: (e['stakeholder'] ?? '').toString(),
                    potentialCost1: (e['potentialCost1'] ?? e['potential_cost_savings'] ?? '').toString(),
                    potentialCost2: (e['potentialCost2'] ?? e['potential_cost_schedule_savings'] ?? '').toString(),
                  ))
              .toList();
        });
        _syncOpportunitiesToProvider();
      }
    } catch (e) {
      debugPrint('AI opportunities suggestion failed: $e');
    }
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
            // Use the same sidebar pattern as PreferredSolutionAnalysisScreen
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Project Opportunities'),
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
                        _roundedField(controller: _notes, hint: 'Input your notes here…', minLines: 3),
                        const SizedBox(height: 22),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded(
                              child: _SectionTitle(),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 40,
                              child: OutlinedButton.icon(
                                onPressed: _showAddOpportunityDialog,
                                icon: const Icon(Icons.add, size: 18, color: Color(0xFF111827)),
                                label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF2F4F7),
                                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _OpportunityTable(rows: _rows),
                              const SizedBox(height: 140),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _BottomOverlays(rows: _rows),
                  const Positioned(
                    bottom: 90,
                    right: 24,
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

  Future<void> _showAddOpportunityDialog() async {
    final item = await showDialog<_OpportunityItem>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => const _AddOpportunityDialog(),
    );
    if (item != null) {
      setState(() => _rows.add(item));
      _syncOpportunitiesToProvider();
    }
  }
}

class _OpportunityTable extends StatelessWidget {
  const _OpportunityTable({required this.rows});
  final List<_OpportunityItem> rows;

  @override
  Widget build(BuildContext context) {
    final border = const BorderSide(color: Color(0xFFE5E7EB));
    final headerStyle = const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563));
    final cellStyle = const TextStyle(fontSize: 14, color: Color(0xFF111827));

    Widget td(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: child);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(52),
          1: FlexColumnWidth(2.2),
          2: FlexColumnWidth(1.6),
          3: FlexColumnWidth(1.6),
          4: FlexColumnWidth(1.4),
          5: FlexColumnWidth(1.4),
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
              _th('Potential Opportunity', headerStyle),
              _th('Discipline', headerStyle),
              _th('Stakeholder', headerStyle),
              _th('Potential Cost Savings', headerStyle),
              _th('Potential Cost Schedule Savings', headerStyle),
            ],
          ),
          ...List<TableRow>.generate(rows.length, (i) {
            final r = rows[i];
            return TableRow(children: [
              td(Text('${i + 1}', style: cellStyle)),
              td(Text(r.opportunity, style: cellStyle)),
              td(Text(r.discipline, style: cellStyle)),
              td(Text(r.stakeholder, style: cellStyle)),
              td(Text(r.potentialCost1, style: cellStyle)),
              td(Text(r.potentialCost2, style: cellStyle)),
            ]);
          }),
        ],
      ),
    );
  }

  Widget _th(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: EditableContentText(
        contentKey: 'fep_opp_header_${text.toLowerCase().replaceAll(' ', '_')}',
        fallback: text,
        category: 'front_end_planning',
        style: style,
      ),
    );
  }
}

class _BottomOverlays extends StatelessWidget {
  const _BottomOverlays({required this.rows});
  
  final List<_OpportunityItem> rows;

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
                  _aiHint(),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final oppText = rows.map((r) => '${r.opportunity}: ${r.discipline}').where((s) => s.trim().isNotEmpty).join('\n');
                      await ProjectDataHelper.saveAndNavigate(
                        context: context,
                        checkpoint: 'fep_opportunities',
                        nextScreenBuilder: () => const FrontEndPlanningContractVendorQuotesScreen(),
                        dataUpdater: (data) => data.copyWith(
                          frontEndPlanning: ProjectDataHelper.updateFEPField(
                            current: data.frontEndPlanning,
                            opportunities: oppText,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: const Text('Submit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
          Text('AI', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
          SizedBox(width: 10),
          Text('Focus on major risks associated with each potential solution.', style: TextStyle(color: Color(0xFF1F2937))),
        ],
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
          contentKey: 'fep_opportunities_title',
          fallback: 'Project Opportunities',
          category: 'front_end_planning',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(width: 8),
        EditableContentText(
          contentKey: 'fep_opportunities_subtitle',
          fallback: '(List out opportunities that would benefit the project here)',
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

class _OpportunityItem {
  final String opportunity;
  final String discipline;
  final String stakeholder;
  final String potentialCost1;
  final String potentialCost2;
  const _OpportunityItem({
    required this.opportunity,
    required this.discipline,
    required this.stakeholder,
    required this.potentialCost1,
    required this.potentialCost2,
  });
}

class _AddOpportunityDialog extends StatefulWidget {
  const _AddOpportunityDialog();

  @override
  State<_AddOpportunityDialog> createState() => _AddOpportunityDialogState();
}

class _AddOpportunityDialogState extends State<_AddOpportunityDialog> {
  final _oppCtrl = TextEditingController();
  final _disciplineCtrl = TextEditingController();
  final _stakeholderCtrl = TextEditingController();
  final _cost1Ctrl = TextEditingController();
  final _cost2Ctrl = TextEditingController();

  @override
  void dispose() {
    _oppCtrl.dispose();
    _disciplineCtrl.dispose();
    _stakeholderCtrl.dispose();
    _cost1Ctrl.dispose();
    _cost2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.add_box_outlined, color: Color(0xFF111827)),
                      SizedBox(width: 8),
                      Text('Add Opportunity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(label: 'Potential Opportunity', controller: _oppCtrl, autofocus: true, hintText: 'Describe the opportunity'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _LabeledField(label: 'Discipline', controller: _disciplineCtrl, hintText: 'e.g. Finance/IT/Operations')),
                    const SizedBox(width: 12),
                    Expanded(child: _LabeledField(label: 'Stakeholder', controller: _stakeholderCtrl, hintText: 'e.g. VP of IT')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _LabeledField(label: 'Potential Cost Savings', controller: _cost1Ctrl, hintText: 'e.g. 75,000')),
                    const SizedBox(width: 12),
                    Expanded(child: _LabeledField(label: 'Potential Cost Schedule Savings', controller: _cost2Ctrl, hintText: 'e.g. 30,000')),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancel')),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.black),
                        label: const Text('Save', style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        onPressed: () {
                          final opp = _oppCtrl.text.trim();
                          if (opp.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a Potential Opportunity')));
                            return;
                          }
                          Navigator.of(context).pop(_OpportunityItem(
                            opportunity: opp,
                            discipline: _disciplineCtrl.text.trim(),
                            stakeholder: _stakeholderCtrl.text.trim(),
                            potentialCost1: _cost1Ctrl.text.trim(),
                            potentialCost2: _cost2Ctrl.text.trim(),
                          ));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool autofocus;
  const _LabeledField({
    required this.label,
    required this.controller,
    this.hintText,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
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
