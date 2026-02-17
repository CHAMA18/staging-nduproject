import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_contract_vendor_quotes_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
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
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';
import 'package:ndu_project/screens/home_screen.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/screens/staff_team_screen.dart';

/// Front End Planning – Project Opportunities page
/// Built to match the provided screenshot exactly:
/// - Left ProgramWorkspaceSidebar
/// - Top bar with back/forward, centered title, and user chip
/// - Rounded notes input
/// - Section title: Project Opportunities (List out opportunities that would benefit the project here)
/// - Table with headers: No | Potential Opportunity | Discipline | Stakeholder | Potential Cost | Potential Cost | Apply
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _notes = TextEditingController();
  bool _isSyncReady = false;

  // Backing rows for the table; built from incoming requirements (if any).
  late List<OpportunityItem> _rows;
  bool _isGeneratingOpportunities = false;

  @override
  void initState() {
    super.initState();
    ApiKeyManager.initializeApiKey();
    _rows = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final projectData = ProjectDataHelper.getData(context);
      _notes.text =
          'Placeholder notes...'; // _notes is typically not used for main data storage here, preserving existing logic if any
      // Actually, looking at previous code, _notes was sync'd to opportunities string.
      // But opportunities string is now legacy/secondary.
      // We will try to sync it if needed, but primarily use list.

      _isSyncReady = true;

      // Check if selectedSolutionTitle exists, warn if missing
      final selectedSolution =
          projectData.preferredSolutionAnalysis?.selectedSolutionTitle;
      if (selectedSolution == null || selectedSolution.trim().isEmpty) {
        debugPrint(
            'Warning: selectedSolutionTitle is missing. State may not have persisted from selection page.');
      }

      // Load saved opportunities
      _loadSavedOpportunities(projectData);
      _syncOpportunitiesToProvider();
      if (mounted) setState(() {});
    });
  }

  void _loadSavedOpportunities(ProjectDataModel data) {
    if (data.frontEndPlanning.opportunityItems.isNotEmpty) {
      _rows = List.from(data.frontEndPlanning.opportunityItems);
    } else {
      // Migration: Try to parse legacy string format "opportunity: discipline"
      final savedOpportunitiesText = data.frontEndPlanning.opportunities.trim();
      if (savedOpportunitiesText.isNotEmpty) {
        final lines = savedOpportunitiesText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

        if (lines.isNotEmpty) {
          _rows = lines.map((line) {
            final parts = line.split(':');
            final opportunity = parts.isNotEmpty ? parts[0].trim() : '';
            final discipline = parts.length > 1 ? parts[1].trim() : '';

            return OpportunityItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              opportunity: opportunity,
              discipline: discipline,
              stakeholder: '',
              potentialCostSavings: '',
              potentialScheduleSavings: '',
            );
          }).toList();
          // Initial sync to persist migration
          _syncOpportunitiesToProvider();
        }
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
        'potentialCostSavings': '50,000',
        'potentialScheduleSavings': '4 weeks',
      },
      {
        'opportunity': 'Consolidate vendor contracts for better pricing',
        'discipline': 'Procurement',
        'stakeholder': 'Procurement Director',
        'potentialCostSavings': '75,000',
        'potentialScheduleSavings': '6 weeks',
      },
      {
        'opportunity': 'Implement early risk detection mechanisms',
        'discipline': 'Project Management',
        'stakeholder': 'Program Manager',
        'potentialCostSavings': '30,000',
        'potentialScheduleSavings': '2 weeks',
      },
      {
        'opportunity': 'Streamline approval workflows',
        'discipline': 'Operations',
        'stakeholder': 'Operations Lead',
        'potentialCostSavings': '40,000',
        'potentialScheduleSavings': '3 weeks',
      },
      {
        'opportunity': 'Leverage existing infrastructure investments',
        'discipline': 'IT',
        'stakeholder': 'IT Infrastructure Manager',
        'potentialCostSavings': '100,000',
        'potentialScheduleSavings': '8 weeks',
      },
    ];

    setState(() {
      _rows = fallbackList
          .map((e) => OpportunityItem(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                opportunity: (e['opportunity'] ?? '').toString(),
                discipline: (e['discipline'] ?? '').toString(),
                stakeholder: (e['stakeholder'] ?? '').toString(),
                potentialCostSavings:
                    (e['potentialCostSavings'] ?? '').toString(),
                potentialScheduleSavings:
                    (e['potentialScheduleSavings'] ?? '').toString(),
                impact: (e['impact'] ?? 'Medium').toString(),
              ))
          .toList();
    });
    _syncOpportunitiesToProvider();
  }

  @override
  void dispose() {
    // No specific listeners to remove other than controllers
    _notes.dispose();
    super.dispose();
  }

  void _syncOpportunitiesToProvider() {
    if (!mounted || !_isSyncReady) return;

    // Legacy string format
    final oppText = _rows
        .map((r) => '${r.opportunity}: ${r.discipline}')
        .where((s) => s.trim().isNotEmpty)
        .join('\n');

    final provider = ProjectDataHelper.getProvider(context);
    provider.updateField(
      (data) {
        final updated = data.copyWith(
          frontEndPlanning: ProjectDataHelper.updateFEPField(
            current: data.frontEndPlanning,
            opportunities: oppText, // Legacy
            opportunityItems: _rows, // New structured list
          ),
        );
        return ProjectDataHelper.applyTaggedFrontEndPlanningData(updated);
      },
    );
  }

  Future<void> _regenerateAllOpportunities() async {
    await _generateOpportunitiesFromContext();
  }

  Future<void> _generateOpportunitiesFromContext() async {
    if (_isGeneratingOpportunities) return; // Prevent duplicate calls
    setState(() {
      _isGeneratingOpportunities = true;
    });

    try {
      final data = ProjectDataHelper.getData(context);
      final provider = ProjectDataHelper.getProvider(context);

      // Track field history before regenerating
      for (int i = 0; i < _rows.length; i++) {
        final row = _rows[i];
        if (row.opportunity.trim().isNotEmpty) {
          provider.addFieldToHistory(
            'fep_opportunity_${i}_opportunity',
            row.opportunity,
            isAiGenerated: true,
          );
        }
      }

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
                  r.potentialCostSavings.isEmpty ||
                  r.potentialScheduleSavings.isEmpty)) {
            // Merge: fill empty fields with generated ones
            final generatedList = list.toList();
            // We'll create a new list to avoid mutating state inside map if possible,
            // but here we just replace _rows fully.
            List<OpportunityItem> merged = [];

            for (int i = 0; i < _rows.length; i++) {
              final existing = _rows[i];
              // If index matches generated list, merge
              if (i < generatedList.length) {
                final generated = generatedList[i];
                merged.add(OpportunityItem(
                  id: existing.id,
                  opportunity: existing.opportunity.isNotEmpty
                      ? existing.opportunity
                      : generated.opportunity,
                  discipline: existing.discipline.isNotEmpty
                      ? existing.discipline
                      : generated.discipline,
                  stakeholder: existing.stakeholder.isNotEmpty
                      ? existing.stakeholder
                      : generated.stakeholder,
                  potentialCostSavings: existing.potentialCostSavings.isNotEmpty
                      ? existing.potentialCostSavings
                      : generated.potentialCostSavings,
                  potentialScheduleSavings:
                      existing.potentialScheduleSavings.isNotEmpty
                          ? existing.potentialScheduleSavings
                          : generated.potentialScheduleSavings,
                  appliesTo: existing.appliesTo,
                  assignedTo: existing.assignedTo,
                  impact: existing.impact.isNotEmpty
                      ? existing.impact
                      : generated.impact,
                ));
              } else {
                // Keep existing as is
                merged.add(existing);
              }
            }

            // Append remaining generated items
            if (generatedList.length > _rows.length) {
              merged.addAll(generatedList.skip(_rows.length));
            }
            _rows = merged;
          } else {
            // Replace with new generated opportunities
            // Track new items history? Only if we overwrite existing populated data.
            // Simplest is to just use the new list.
            _rows = list;
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

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    if (isMobile) {
      return _buildMobileScaffold(context);
    }

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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        SizedBox(height: 6),
                                        EditableContentText(
                                          contentKey:
                                              'fep_opportunities_subtitle',
                                          fallback:
                                              '(List out opportunities that would benefit the project here)',
                                          category: 'front_end_planning',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PageRegenerateAllButton(
                                    onRegenerateAll: () async {
                                      final confirmed =
                                          await showRegenerateAllConfirmation(
                                              context);
                                      if (confirmed && mounted) {
                                        await _regenerateAllOpportunities();
                                      }
                                    },
                                    isLoading: _isGeneratingOpportunities,
                                    tooltip: 'Regenerate all opportunities',
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    height: 40,
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showAddOpportunityDialog(),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add Opportunity',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF111827),
                                        side: const BorderSide(
                                            color: Color(0xFFD1D5DB)),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _OpportunityTable(
                                rows: _rows,
                                onUpdate: (index, item) {
                                  setState(() {
                                    _rows[index] = item;
                                    _syncOpportunitiesToProvider();
                                  });
                                },
                                onEdit: (item) {
                                  _showAddOpportunityDialog(existingItem: item);
                                },
                                onDelete: (id) {
                                  setState(() {
                                    _rows.removeWhere((r) => r.id == id);
                                    _syncOpportunitiesToProvider();
                                  });
                                },
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  _BottomOverlays(onSubmit: _submitOpportunities),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOpportunities() async {
    final oppText = _rows
        .map((r) => '${r.opportunity}: ${r.discipline}')
        .where((s) => s.trim().isNotEmpty)
        .join('\n');

    final isBasicPlan = ProjectDataHelper.getData(context).isBasicPlanProject;
    final nextItem = SidebarNavigationService.instance
        .getNextAccessibleItem('fep_opportunities', isBasicPlan);

    Widget nextScreen;
    if (nextItem?.checkpoint == 'fep_contract_vendor_quotes') {
      nextScreen = const FrontEndPlanningContractVendorQuotesScreen();
    } else if (nextItem?.checkpoint == 'fep_procurement') {
      nextScreen = const FrontEndPlanningProcurementScreen();
    } else if (nextItem?.checkpoint == 'project_charter') {
      nextScreen = const ProjectCharterScreen();
    } else {
      nextScreen = const FrontEndPlanningContractVendorQuotesScreen();
    }

    await ProjectDataHelper.saveAndNavigate(
      context: context,
      checkpoint: 'fep_opportunities',
      nextScreenBuilder: () => nextScreen,
      dataUpdater: (data) => data.copyWith(
        frontEndPlanning: ProjectDataHelper.updateFEPField(
          current: data.frontEndPlanning,
          opportunities: oppText,
          opportunityItems: _rows,
        ),
      ),
    );
  }

  Widget _buildMobileScaffold(BuildContext context) {
    final projectName = ProjectDataHelper.getData(context).projectName.trim();
    final topSummary = _rows.isEmpty
        ? 'No opportunities captured yet.'
        : _rows
            .take(2)
            .map((item) => item.opportunity.trim())
            .where((value) => value.isNotEmpty)
            .join(' ');

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F6F8),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOpportunityDialog(),
        backgroundColor: const Color(0xFFF4B400),
        foregroundColor: Colors.black,
        elevation: 0,
        child: const Icon(Icons.add),
      ),
      drawer: Drawer(
        width: MediaQuery.sizeOf(context).width * 0.88,
        child: const SafeArea(
          child:
              InitiationLikeSidebar(activeItemLabel: 'Project Opportunities'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 10, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(Icons.menu_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Expanded(
                    child: Text(
                      'Front End Planning',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 13,
                    backgroundColor: Color(0xFF2563EB),
                    child: Text('C',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 128),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FRONT END PLANNING   >   ${projectName.isEmpty ? 'ZAMBIA HUB' : projectName.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'AI-Generated Summaries',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showAddOpportunityDialog(),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        topSummary.isEmpty
                            ? 'No summary available.'
                            : topSummary,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF374151),
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _rows.length > 2
                          ? 'Showing ${_rows.length} opportunities...'
                          : 'No additional opportunities.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text(
                          'ACTIVE OPPORTUNITIES',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF374151),
                              letterSpacing: 0.4),
                        ),
                        const Spacer(),
                        Text(
                          '${_rows.length} ITEMS',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF9CA3AF),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._rows.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildMobileOpportunityCard(
                                context, entry.key, entry.value),
                          ),
                        ),
                    OutlinedButton.icon(
                      onPressed: () => _showAddOpportunityDialog(),
                      icon: const Icon(Icons.add, size: 17),
                      label: const Text(
                        'Add Opportunity',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        foregroundColor: const Color(0xFF374151),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitOpportunities,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF4B400),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _mobileNavItem(
                icon: Icons.home_filled,
                label: 'Home',
                active: false,
                onTap: () => HomeScreen.open(context),
              ),
              _mobileNavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'AI Planning',
                active: true,
                onTap: () {},
              ),
              const SizedBox(width: 30),
              _mobileNavItem(
                icon: Icons.design_services_rounded,
                label: 'Design',
                active: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DesignPhaseScreen(
                        activeItemLabel: 'Design Management'),
                  ),
                ),
              ),
              _mobileNavItem(
                icon: Icons.engineering_rounded,
                label: 'Execution',
                active: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StaffTeamScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileOpportunityCard(
      BuildContext context, int index, OpportunityItem item) {
    return InkWell(
      onTap: () => _showAddOpportunityDialog(existingItem: item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.opportunity.trim().isEmpty
                        ? 'Unnamed opportunity'
                        : item.opportunity.trim(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _showAddOpportunityDialog(existingItem: item),
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 17, color: Color(0xFF9CA3AF)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.discipline.trim().isEmpty
                        ? 'Discipline TBD'
                        : item.discipline,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.stakeholder.trim().isEmpty
                        ? 'Stakeholder TBD'
                        : item.stakeholder,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.potentialCostSavings.trim().isEmpty ? '0' : item.potentialCostSavings} USD',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.potentialScheduleSavings.trim().isEmpty
                        ? '0 weeks'
                        : item.potentialScheduleSavings,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileNavItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final color = active ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 9.5, color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOpportunityDialog({OpportunityItem? existingItem}) {
    showDialog(
      context: context,
      builder: (context) => _OpportunityDialog(item: existingItem),
    ).then((val) {
      if (val != null && val is OpportunityItem) {
        setState(() {
          if (existingItem != null) {
            final index = _rows.indexWhere((r) => r.id == existingItem.id);
            if (index != -1) {
              _rows[index] = val;
            }
          } else {
            _rows.add(val);
          }
          _syncOpportunitiesToProvider();
        });
      }
    });
  }
}

class _OpportunityDialog extends StatefulWidget {
  final OpportunityItem? item;
  const _OpportunityDialog({this.item});

  @override
  State<_OpportunityDialog> createState() => _OpportunityDialogState();
}

class _OpportunityDialogState extends State<_OpportunityDialog> {
  final _oppCtrl = TextEditingController();
  final _disciplineCtrl = TextEditingController();
  final _stakeholderCtrl = TextEditingController();
  final _cost1Ctrl = TextEditingController();
  final _cost2Ctrl = TextEditingController();
  final _assignedToCtrl = TextEditingController();
  String _selectedImpact = 'Medium';
  List<String> _selectedAppliesTo = [];

  final List<String> _applyOptions = ['Estimate', 'Schedule', 'Training'];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _oppCtrl.text = widget.item!.opportunity;
      _disciplineCtrl.text = widget.item!.discipline;
      _stakeholderCtrl.text = widget.item!.stakeholder;
      _cost1Ctrl.text = widget.item!.potentialCostSavings;
      _cost2Ctrl.text = widget.item!.potentialScheduleSavings;
      _assignedToCtrl.text = widget.item!.assignedTo;
      _selectedImpact = widget.item!.impact;
      _selectedAppliesTo = List.from(widget.item!.appliesTo);
    }
  }

  @override
  void dispose() {
    _oppCtrl.dispose();
    _disciplineCtrl.dispose();
    _stakeholderCtrl.dispose();
    _cost1Ctrl.dispose();
    _cost2Ctrl.dispose();
    _assignedToCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
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
                    children: [
                      const Icon(Icons.edit_note, color: Color(0xFF111827)),
                      const SizedBox(width: 8),
                      Text(
                          widget.item == null
                              ? 'Add Opportunity'
                              : 'Edit Opportunity',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                      label: 'Potential Opportunity',
                      controller: _oppCtrl,
                      autofocus: widget.item == null,
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
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Impact',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280))),
                            const SizedBox(height: 6),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedImpact,
                                  isExpanded: true,
                                  items: ['High', 'Medium', 'Low']
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e,
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedImpact = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _LabeledField(
                              label: 'Assigned To',
                              controller: _assignedToCtrl,
                              hintText: 'e.g. John Doe')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Apply To',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280))),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _applyOptions.map((option) {
                          final isSelected =
                              _selectedAppliesTo.contains(option);
                          return FilterChip(
                            label: Text(option),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAppliesTo.add(option);
                                } else {
                                  _selectedAppliesTo.remove(option);
                                }
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFFEFF6FF),
                            checkmarkColor: const Color(0xFF3B82F6),
                            side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFE5E7EB)),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF1E40AF)
                                  : const Color(0xFF374151),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
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
                          Navigator.of(context).pop(OpportunityItem(
                            id: widget.item?.id ??
                                DateTime.now()
                                    .microsecondsSinceEpoch
                                    .toString(),
                            opportunity: opp,
                            discipline: _disciplineCtrl.text.trim(),
                            stakeholder: _stakeholderCtrl.text.trim(),
                            potentialCostSavings: _cost1Ctrl.text.trim(),
                            potentialScheduleSavings: _cost2Ctrl.text.trim(),
                            impact: _selectedImpact,
                            appliesTo: _selectedAppliesTo,
                            assignedTo: _assignedToCtrl.text.trim(),
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

class _OpportunityTable extends StatelessWidget {
  const _OpportunityTable(
      {required this.rows,
      required this.onUpdate,
      required this.onEdit,
      required this.onDelete});
  final List<OpportunityItem> rows;
  final Function(int, OpportunityItem) onUpdate;
  final Function(OpportunityItem) onEdit;
  final Function(String) onDelete;

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minTableWidth =
              constraints.maxWidth > 1520 ? constraints.maxWidth : 1520.0;

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
                    2: FlexColumnWidth(1.4),
                    3: FlexColumnWidth(1.4),
                    4: FlexColumnWidth(1.1),
                    5: FlexColumnWidth(1.1),
                    6: FixedColumnWidth(80), // Impact
                    7: FlexColumnWidth(
                        1.8), // Implementation (Applies To + Assignee)
                    8: FixedColumnWidth(50), // Actions
                  },
                  border: TableBorder(
                    horizontalInside: border,
                    verticalInside: border,
                    top: border,
                    bottom: border,
                    left: border,
                    right: border,
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.top,
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
                        _th('Impact', headerStyle),
                        _th('Implementation', headerStyle),
                        _th('Actions', headerStyle),
                      ],
                    ),
                    ...List<TableRow>.generate(rows.length, (i) {
                      final r = rows[i];
                      return TableRow(children: [
                        td(Text('${i + 1}', style: cellStyle)),
                        td(Text(r.opportunity, style: cellStyle)),
                        td(Text(r.discipline, style: cellStyle)),
                        td(Text(r.stakeholder, style: cellStyle)),
                        td(Text(r.potentialCostSavings, style: cellStyle)),
                        td(Text(r.potentialScheduleSavings, style: cellStyle)),
                        td(_ImpactBadge(impact: r.impact)),
                        td(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (r.assignedTo.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 14, color: Color(0xFF6B7280)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        r.assignedTo,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF374151)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                              ],
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: r.appliesTo
                                    .map((tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1E40AF)),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        td(
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz,
                                color: Color(0xFF9CA3AF)),
                            tooltip: 'Actions',
                            onSelected: (value) async {
                              if (value == 'edit') {
                                onEdit(r);
                              } else if (value == 'delete') {
                                onDelete(r.id);
                              } else if (value == 'assign') {
                                final controller =
                                    TextEditingController(text: r.assignedTo);
                                final assigned = await showDialog<String>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Assign Opportunity'),
                                    content: TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Assign To (Role or Name)',
                                        border: OutlineInputBorder(),
                                      ),
                                      autofocus: true,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(
                                            ctx, controller.text.trim()),
                                        child: const Text('Assign'),
                                      ),
                                    ],
                                  ),
                                );
                                if (assigned != null) {
                                  onUpdate(
                                    i,
                                    OpportunityItem(
                                      id: r.id,
                                      opportunity: r.opportunity,
                                      discipline: r.discipline,
                                      stakeholder: r.stakeholder,
                                      potentialCostSavings:
                                          r.potentialCostSavings,
                                      potentialScheduleSavings:
                                          r.potentialScheduleSavings,
                                      impact: r.impact,
                                      appliesTo: r.appliesTo,
                                      assignedTo: assigned,
                                    ),
                                  );
                                }
                              } else if (value == 'toggle_estimate') {
                                final list = List<String>.from(r.appliesTo);
                                if (list.contains('Estimate')) {
                                  list.remove('Estimate');
                                } else {
                                  list.add('Estimate');
                                }
                                onUpdate(
                                  i,
                                  OpportunityItem(
                                    id: r.id,
                                    opportunity: r.opportunity,
                                    discipline: r.discipline,
                                    stakeholder: r.stakeholder,
                                    potentialCostSavings:
                                        r.potentialCostSavings,
                                    potentialScheduleSavings:
                                        r.potentialScheduleSavings,
                                    impact: r.impact,
                                    appliesTo: list,
                                    assignedTo: r.assignedTo,
                                  ),
                                );
                              } else if (value == 'toggle_schedule') {
                                final list = List<String>.from(r.appliesTo);
                                if (list.contains('Schedule')) {
                                  list.remove('Schedule');
                                } else {
                                  list.add('Schedule');
                                }
                                onUpdate(
                                  i,
                                  OpportunityItem(
                                    id: r.id,
                                    opportunity: r.opportunity,
                                    discipline: r.discipline,
                                    stakeholder: r.stakeholder,
                                    potentialCostSavings:
                                        r.potentialCostSavings,
                                    potentialScheduleSavings:
                                        r.potentialScheduleSavings,
                                    impact: r.impact,
                                    appliesTo: list,
                                    assignedTo: r.assignedTo,
                                  ),
                                );
                              } else if (value == 'toggle_training') {
                                final list = List<String>.from(r.appliesTo);
                                if (list.contains('Training')) {
                                  list.remove('Training');
                                } else {
                                  list.add('Training');
                                }
                                onUpdate(
                                  i,
                                  OpportunityItem(
                                    id: r.id,
                                    opportunity: r.opportunity,
                                    discipline: r.discipline,
                                    stakeholder: r.stakeholder,
                                    potentialCostSavings:
                                        r.potentialCostSavings,
                                    potentialScheduleSavings:
                                        r.potentialScheduleSavings,
                                    impact: r.impact,
                                    appliesTo: list,
                                    assignedTo: r.assignedTo,
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'toggle_estimate',
                                child: Row(
                                  children: [
                                    Icon(
                                      r.appliesTo.contains('Estimate')
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Apply to Estimate'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle_schedule',
                                child: Row(
                                  children: [
                                    Icon(
                                      r.appliesTo.contains('Schedule')
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Apply to Schedule'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle_training',
                                child: Row(
                                  children: [
                                    Icon(
                                      r.appliesTo.contains('Training')
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Apply to Training'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'assign',
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_add_alt_1,
                                        size: 18, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text(r.assignedTo.isNotEmpty
                                        ? 'Reassign'
                                        : 'Assign to Role'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit,
                                        size: 18, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }),
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
        contentKey: 'fep_opp_header_${text.toLowerCase().replaceAll(' ', '_')}',
        fallback: text,
        category: 'front_end_planning',
        style: style,
      ),
    );
  }
}

class _BottomOverlays extends StatelessWidget {
  const _BottomOverlays({required this.onSubmit});
  final Future<void> Function() onSubmit;
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
                    onPressed: () => onSubmit(),
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

class _ImpactBadge extends StatelessWidget {
  final String impact;
  const _ImpactBadge({required this.impact});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (impact.toLowerCase()) {
      case 'high':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
      case 'low':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        break;
      case 'medium':
      default:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        impact,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
        textAlign: TextAlign.center,
      ),
    );
  }
}
