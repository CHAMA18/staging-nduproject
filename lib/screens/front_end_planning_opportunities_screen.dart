import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_contract_vendor_quotes_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/front_end_planning_header.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/screens/project_charter_screen.dart';
import 'package:ndu_project/services/sidebar_navigation_service.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/widgets/ai_regenerate_undo_buttons.dart';

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
      MaterialPageRoute(
          builder: (_) => const FrontEndPlanningOpportunitiesScreen()),
    );
  }

  @override
  State<FrontEndPlanningOpportunitiesScreen> createState() =>
      _FrontEndPlanningOpportunitiesScreenState();
}

class _FrontEndPlanningOpportunitiesScreenState
    extends State<FrontEndPlanningOpportunitiesScreen> {
  final TextEditingController _notes = TextEditingController();
  bool _isSyncReady = false;

  // Backing rows for the table; built from incoming requirements (if any).
  late List<_OpportunityItem> _rows;
  bool _isGeneratingOpportunities = false;
  List<_OpportunityItem>? _undoBeforeAi;

  @override
  void initState() {
    super.initState();
    ApiKeyManager.initializeApiKey();
    _rows = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectData = ProjectDataHelper.getData(context);
      _notes.text = projectData.frontEndPlanning.opportunities;
      _notes.addListener(_syncOpportunitiesToProvider);
      _isSyncReady = true;
      _syncOpportunitiesToProvider();

      // Check if selectedSolutionTitle exists, warn if missing
      final selectedSolution =
          projectData.preferredSolutionAnalysis?.selectedSolutionTitle;
      if (selectedSolution == null || selectedSolution.trim().isEmpty) {
        debugPrint(
            'Warning: selectedSolutionTitle is missing. State may not have persisted from selection page.');
      }

      // Load saved opportunities from text
      _loadSavedOpportunities(projectData);

      // Generate opportunities if empty OR if opportunities exist but have empty fields
      if (_rows.isEmpty ||
          _rows.any((r) =>
              r.opportunity.isEmpty ||
              r.discipline.isEmpty ||
              r.stakeholder.isEmpty ||
              r.potentialCost1.isEmpty ||
              r.potentialCost2.isEmpty)) {
        _generateOpportunitiesFromContext();
      }
      if (mounted) setState(() {});
    });
  }

  void _loadSavedOpportunities(ProjectDataModel data) {
    final savedOpportunitiesText = data.frontEndPlanning.opportunities.trim();
    if (savedOpportunitiesText.isNotEmpty) {
      // Parse opportunities from text format: "opportunity: discipline"
      final lines = savedOpportunitiesText
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      if (lines.isNotEmpty) {
        _rows = lines.map((line) {
          // Try to parse "opportunity: discipline" format
          final parts = line.split(':');
          final opportunity = parts.isNotEmpty ? parts[0].trim() : '';
          final discipline = parts.length > 1 ? parts[1].trim() : '';

          return _OpportunityItem(
            opportunity: opportunity,
            discipline: discipline,
            stakeholder: '',
            potentialCost1: '',
            potentialCost2: '',
          );
        }).toList();
      }
    }
  }

  void _useFallbackOpportunities() {
    if (!mounted) return;
    final fallbackList = [
      {
        'opportunity': 'Automate manual data entry processes',
        'discipline': 'IT',
        'stakeholder': 'IT Operations Manager',
        'potentialCost1': '50,000',
        'potentialCost2': '4 weeks',
      },
      {
        'opportunity': 'Consolidate vendor contracts for better pricing',
        'discipline': 'Procurement',
        'stakeholder': 'Procurement Director',
        'potentialCost1': '75,000',
        'potentialCost2': '6 weeks',
      },
      {
        'opportunity': 'Implement early risk detection mechanisms',
        'discipline': 'Project Management',
        'stakeholder': 'Program Manager',
        'potentialCost1': '30,000',
        'potentialCost2': '2 weeks',
      },
      {
        'opportunity': 'Streamline approval workflows',
        'discipline': 'Operations',
        'stakeholder': 'Operations Lead',
        'potentialCost1': '40,000',
        'potentialCost2': '3 weeks',
      },
      {
        'opportunity': 'Leverage existing infrastructure investments',
        'discipline': 'IT',
        'stakeholder': 'IT Infrastructure Manager',
        'potentialCost1': '100,000',
        'potentialCost2': '8 weeks',
      },
    ];

    setState(() {
      _rows = fallbackList
          .map((e) => _OpportunityItem(
                opportunity: (e['opportunity'] ?? '').toString(),
                discipline: (e['discipline'] ?? '').toString(),
                stakeholder: (e['stakeholder'] ?? '').toString(),
                potentialCost1: (e['potentialCost1'] ?? '').toString(),
                potentialCost2: (e['potentialCost2'] ?? '').toString(),
              ))
          .toList();
    });
    _syncOpportunitiesToProvider();
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
    if (_isGeneratingOpportunities) return; // Prevent duplicate calls
    setState(() {
      _isGeneratingOpportunities = true;
    });
    _undoBeforeAi = _rows.map((e) => e.copy()).toList();

    try {
      final data = ProjectDataHelper.getData(context);

      // Verify selectedSolutionTitle exists - if not, log warning
      final selectedSolution =
          data.preferredSolutionAnalysis?.selectedSolutionTitle;
      if (selectedSolution == null || selectedSolution.trim().isEmpty) {
        debugPrint(
            'Warning: selectedSolutionTitle is blank. Opportunities generation may be incomplete.');
        // Still proceed with generation, but context will be missing selected solution
      }

      final ctx = ProjectDataHelper.buildFepContext(data,
          sectionLabel: 'Project Opportunities');
      final ai = OpenAiServiceSecure();
      final list = await ai.generateOpportunitiesFromContext(ctx);
      if (!mounted) return;
      if (list.isNotEmpty) {
        setState(() {
          // If we have existing rows with empty fields, merge generated data into them
          // Otherwise, replace with new generated opportunities
          if (_rows.isNotEmpty &&
              _rows.any((r) =>
                  r.opportunity.isEmpty ||
                  r.stakeholder.isEmpty ||
                  r.potentialCost1.isEmpty ||
                  r.potentialCost2.isEmpty)) {
            // Merge: fill empty fields with generated ones
            final generatedList = list.toList();
            _rows = _rows.asMap().entries.map((entry) {
              final index = entry.key;
              final existing = entry.value;

              // If any critical field is empty, use generated data
              if (index < generatedList.length) {
                final generated = generatedList[index];
                return _OpportunityItem(
                  opportunity:
                      (generated['opportunity'] ?? existing.opportunity)
                              .toString()
                              .isEmpty
                          ? existing.opportunity
                          : (generated['opportunity'] ?? existing.opportunity)
                              .toString(),
                  discipline: (generated['discipline'] ?? existing.discipline)
                          .toString()
                          .isEmpty
                      ? existing.discipline
                      : (generated['discipline'] ?? existing.discipline)
                          .toString(),
                  stakeholder:
                      (generated['stakeholder'] ?? existing.stakeholder)
                              .toString()
                              .isEmpty
                          ? existing.stakeholder
                          : (generated['stakeholder'] ?? existing.stakeholder)
                              .toString(),
                  potentialCost1: (generated['potentialCost1'] ??
                              generated['potential_cost_savings'] ??
                              existing.potentialCost1)
                          .toString()
                          .isEmpty
                      ? existing.potentialCost1
                      : (generated['potentialCost1'] ??
                              generated['potential_cost_savings'] ??
                              existing.potentialCost1)
                          .toString(),
                  potentialCost2: (generated['potentialCost2'] ??
                              generated['potential_cost_schedule_savings'] ??
                              existing.potentialCost2)
                          .toString()
                          .isEmpty
                      ? existing.potentialCost2
                      : (generated['potentialCost2'] ??
                              generated['potential_cost_schedule_savings'] ??
                              existing.potentialCost2)
                          .toString(),
                );
              }
              // If no generated data available, fill empty fields with fallback
              if (existing.stakeholder.isEmpty ||
                  existing.potentialCost1.isEmpty ||
                  existing.potentialCost2.isEmpty) {
                final fallbackData = <Map<String, String>>[
                  {
                    'stakeholder': 'IT Operations Manager',
                    'potentialCost1': '50,000',
                    'potentialCost2': '4 weeks',
                  },
                  {
                    'stakeholder': 'Procurement Director',
                    'potentialCost1': '75,000',
                    'potentialCost2': '6 weeks',
                  },
                  {
                    'stakeholder': 'Program Manager',
                    'potentialCost1': '30,000',
                    'potentialCost2': '2 weeks',
                  },
                  {
                    'stakeholder': 'Operations Lead',
                    'potentialCost1': '40,000',
                    'potentialCost2': '3 weeks',
                  },
                  {
                    'stakeholder': 'IT Infrastructure Manager',
                    'potentialCost1': '100,000',
                    'potentialCost2': '8 weeks',
                  },
                ];
                final fallbackIndex = index % fallbackData.length;
                final fallback = fallbackData[fallbackIndex];
                return _OpportunityItem(
                  opportunity: existing.opportunity,
                  discipline: existing.discipline,
                  stakeholder: existing.stakeholder.isEmpty
                      ? (fallback['stakeholder'] as String)
                      : existing.stakeholder,
                  potentialCost1: existing.potentialCost1.isEmpty
                      ? (fallback['potentialCost1'] as String)
                      : existing.potentialCost1,
                  potentialCost2: existing.potentialCost2.isEmpty
                      ? (fallback['potentialCost2'] as String)
                      : existing.potentialCost2,
                );
              }
              return existing;
            }).toList();

            // Add any additional generated opportunities beyond existing rows
            if (generatedList.length > _rows.length) {
              _rows.addAll(
                  generatedList.skip(_rows.length).map((e) => _OpportunityItem(
                        opportunity: (e['opportunity'] ?? '').toString(),
                        discipline: (e['discipline'] ?? '').toString(),
                        stakeholder: (e['stakeholder'] ?? '').toString(),
                        potentialCost1: (e['potentialCost1'] ??
                                e['potential_cost_savings'] ??
                                '')
                            .toString(),
                        potentialCost2: (e['potentialCost2'] ??
                                e['potential_cost_schedule_savings'] ??
                                '')
                            .toString(),
                      )));
            }
          } else {
            // Replace with new generated opportunities
            _rows = list
                .map((e) => _OpportunityItem(
                      opportunity: (e['opportunity'] ?? '').toString(),
                      discipline: (e['discipline'] ?? '').toString(),
                      stakeholder: (e['stakeholder'] ?? '').toString(),
                      potentialCost1: (e['potentialCost1'] ??
                              e['potential_cost_savings'] ??
                              '')
                          .toString(),
                      potentialCost2: (e['potentialCost2'] ??
                              e['potential_cost_schedule_savings'] ??
                              '')
                          .toString(),
                    ))
                .toList();
          }
        });
        _syncOpportunitiesToProvider();
        await ProjectDataHelper.getProvider(context)
            .saveToFirebase(checkpoint: 'fep_opportunities');
      } else {
        // If generation returned empty, use fallback
        debugPrint('No opportunities generated, using fallback');
        _useFallbackOpportunities();
      }
    } catch (e) {
      debugPrint('AI opportunities suggestion failed: $e');
      // On error, use fallback opportunities
      _useFallbackOpportunities();
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingOpportunities = false;
        });
      }
    }
  }

  void _undoOpportunities() {
    final prev = _undoBeforeAi;
    if (prev == null) return;
    setState(() {
      _rows = prev;
      _undoBeforeAi = null;
    });
    _syncOpportunitiesToProvider();
    ProjectDataHelper.getProvider(context)
        .saveToFirebase(checkpoint: 'fep_opportunities');
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
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Project Opportunities'),
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
                                  controller: _notes,
                                  hint: 'Input your notes here…',
                                  minLines: 3),
                              const SizedBox(height: 22),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _SectionTitle(
                                      trailing: AiRegenerateUndoButtons(
                                        isLoading: _isGeneratingOpportunities,
                                        canUndo: _undoBeforeAi != null,
                                        onRegenerate:
                                            _generateOpportunitiesFromContext,
                                        onUndo: _undoOpportunities,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    height: 40,
                                    child: OutlinedButton.icon(
                                      onPressed: _showAddOpportunityDialog,
                                      icon: const Icon(Icons.add,
                                          size: 18, color: Color(0xFF111827)),
                                      label: const Text('Add',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF111827))),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFF2F4F7),
                                        side: const BorderSide(
                                            color: Color(0xFFE5E7EB)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14),
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
    final headerStyle = const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563));
    final cellStyle = const TextStyle(fontSize: 14, color: Color(0xFF111827));

    Widget td(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: child);

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
                    onPressed: () async {
                      final oppText = rows
                          .map((r) => '${r.opportunity}: ${r.discipline}')
                          .where((s) => s.trim().isNotEmpty)
                          .join('\n');

                      final isBasicPlan =
                          ProjectDataHelper.getData(context).isBasicPlanProject;
                      final nextItem = SidebarNavigationService.instance
                          .getNextAccessibleItem(
                              'fep_opportunities', isBasicPlan);

                      Widget nextScreen;
                      if (nextItem?.checkpoint ==
                          'fep_contract_vendor_quotes') {
                        nextScreen =
                            const FrontEndPlanningContractVendorQuotesScreen();
                      } else if (nextItem?.checkpoint == 'fep_procurement') {
                        nextScreen = const FrontEndPlanningProcurementScreen();
                      } else if (nextItem?.checkpoint == 'project_charter') {
                        nextScreen = const ProjectCharterScreen();
                      } else {
                        // Fallback
                        nextScreen =
                            const FrontEndPlanningContractVendorQuotesScreen();
                      }

                      await ProjectDataHelper.saveAndNavigate(
                        context: context,
                        checkpoint: 'fep_opportunities',
                        nextScreenBuilder: () => nextScreen,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({this.trailing});

  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Row(
            children: [
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
              Expanded(
                child: EditableContentText(
                  contentKey: 'fep_opportunities_subtitle',
                  fallback:
                      '(List out opportunities that would benefit the project here)',
                  category: 'front_end_planning',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
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

  _OpportunityItem copy() => _OpportunityItem(
        opportunity: opportunity,
        discipline: discipline,
        stakeholder: stakeholder,
        potentialCost1: potentialCost1,
        potentialCost2: potentialCost2,
      );
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
                      Text('Add Opportunity',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                      label: 'Potential Opportunity',
                      controller: _oppCtrl,
                      autofocus: true,
                      hintText: 'Describe the opportunity'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _LabeledField(
                            label: 'Discipline',
                            controller: _disciplineCtrl,
                            hintText: 'e.g. Finance/IT/Operations')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _LabeledField(
                            label: 'Stakeholder',
                            controller: _stakeholderCtrl,
                            hintText: 'e.g. VP of IT')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _LabeledField(
                            label: 'Potential Cost Savings',
                            controller: _cost1Ctrl,
                            hintText: 'e.g. 75,000')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _LabeledField(
                            label: 'Potential Cost Schedule Savings',
                            controller: _cost2Ctrl,
                            hintText: 'e.g. 30,000')),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          child: const Text('Cancel')),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, color: Colors.black),
                        label: const Text('Save',
                            style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                        ),
                        onPressed: () {
                          final opp = _oppCtrl.text.trim();
                          if (opp.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please enter a Potential Opportunity')));
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
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280))),
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
