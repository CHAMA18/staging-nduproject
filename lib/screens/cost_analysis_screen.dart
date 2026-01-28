import 'dart:math' as math;
import 'package:ndu_project/utils/finance.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/screens/ssher_stacked_screen.dart';
import 'package:ndu_project/screens/team_management_screen.dart';
import 'package:ndu_project/screens/change_management_screen.dart';
import 'package:ndu_project/screens/home_screen.dart';
import 'package:ndu_project/screens/lessons_learned_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/business_case_header.dart';
import 'package:ndu_project/screens/preferred_solution_analysis_screen.dart';
import 'package:ndu_project/widgets/expanding_text_field.dart';
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/potential_solutions_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/it_considerations_screen.dart';
import 'package:ndu_project/screens/infrastructure_considerations_screen.dart';
import 'package:ndu_project/screens/core_stakeholders_screen.dart';
import 'package:ndu_project/screens/settings_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/auto_bullet_text_controller.dart';
import 'package:ndu_project/services/sidebar_navigation_service.dart';
import 'package:ndu_project/widgets/page_hint_dialog.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';

class CostAnalysisScreen extends StatefulWidget {
  final String notes;
  final List<AiSolutionItem> solutions;
  const CostAnalysisScreen(
      {super.key, required this.notes, required this.solutions});

  @override
  State<CostAnalysisScreen> createState() => _CostAnalysisScreenState();
}

class _CostAnalysisScreenState extends State<CostAnalysisScreen>
    with SingleTickerProviderStateMixin {
  static const List<_StepDefinition> _stepDefinitions = [
    _StepDefinition(
      shortLabel: 'Project Value',
      title: 'Estimate project Value and Investment Benefit',
      subtitle:
          'Estimate the projects\' value. This would be the profitability analysis basis.',
    ),
    _StepDefinition(
      shortLabel: 'Initial Cost Estimate',
      title: 'Estimate solution investments',
      subtitle:
          'Every potential solution keeps an AI-assisted cost profile so you can compare spend before diving into the detailed line items.',
    ),
    _StepDefinition(
      shortLabel: 'Profitability Analysis',
      title: 'Compare ROI, NPV, IRR, and DCFR',
      subtitle:
          'Pick a 3, 5, or 10-year horizon so every solution compares on the same timeframe before exporting to the Preferred Solution Analysis.',
    ),
  ];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _mainScrollController = ScrollController();
  bool _initiationExpanded = true;
  bool _businessCaseExpanded = true;
  final GlobalKey _tablesSectionKey = GlobalKey();
  int _currentStepIndex = 0;
  bool _hasUnsavedChanges = false;
  bool _suppressDirtyTracking = false;
  late final TextEditingController _notesController;
  late final List<List<_CostRow>> _rowsPerSolution;
  late final List<_SolutionCostContext> _solutionContexts;
  // High-level category cost matrix per solution (for Initial Cost Estimate)
  late final List<Map<String, _CategoryCostEntry>> _categoryCostsPerSolution;
  // AI idea pool: per-solution, per-category suggested line items (with costs)
  late final List<Map<String, List<AiCostItem>>> _categoryIdeasPerSolution;
  static const List<_QualitativeOption> _resourceOptions = [
    _QualitativeOption(
      label: 'Lean squad',
      detail: '3-5 FTEs covering core build',
      aiHint: 'Lean cross-functional squad of roughly 3-5 dedicated FTEs.',
    ),
    _QualitativeOption(
      label: 'Core programme team',
      detail: '6-10 FTEs incl. vendor support',
      aiHint:
          'Cross-functional programme team with 6-10 FTEs plus vendor support.',
    ),
    _QualitativeOption(
      label: 'Enterprise delivery model',
      detail: '10+ FTEs across business & IT',
      aiHint:
          'Enterprise-scale delivery model spanning 10+ internal and external FTEs.',
    ),
  ];
  static const List<_QualitativeOption> _timelineOptions = [
    _QualitativeOption(
      label: '0-6 months',
      detail: 'Accelerated delivery window',
      aiHint:
          'Aggressive implementation window under six months (parallelised sprints).',
    ),
    _QualitativeOption(
      label: '6-12 months',
      detail: 'Phased rollout cadence',
      aiHint: 'Phased delivery cadence spanning roughly six to twelve months.',
    ),
    _QualitativeOption(
      label: '12+ months',
      detail: 'Multi-phase programme',
      aiHint:
          'Multi-phase programme extending beyond twelve months with staged deployments.',
    ),
  ];
  static const List<_QualitativeOption> _complexityOptions = [
    _QualitativeOption(
      label: 'Foundational',
      detail: 'Limited integrations, low risk',
      aiHint:
          'Foundational complexity with limited integration and regulatory risk.',
    ),
    _QualitativeOption(
      label: 'Moderate',
      detail: 'Cross-team coordination required',
      aiHint:
          'Moderate complexity requiring cross-team coordination and controlled change.',
    ),
    _QualitativeOption(
      label: 'High',
      detail: 'Heavy integration & governance',
      aiHint:
          'High complexity with heavy integration, governance checks, and dependencies.',
    ),
  ];
  static const Map<String, String> _benefitMetrics = {
    'revenue':
        'A calculation of the income from the number of products/services that would come from the project multiplied by months/year for the number of years. Could be a lumpsum too.',
    'cost_saving':
        'Could be a lumpsum or similar math as #1 but with how much money would be saved from not buying, making something thanks to project.',
    'ops_efficiency':
        'Operational costs saved due to project. Could be same math as #1 and #2 if it\'s renting an equipment or something similar.',
    'productivity':
        'Directly tied to manpower. So, number of people multiplied by number of hours per month, per year. Multiply by salary rate.',
    'regulatory_compliance':
        'Could be a one-time or recurring non-compliance fee and/or cost of being fully shut down for a certain period of time.',
    'process_improvement':
        'Similar to productivity and/or operational efficiency. They can choose which applies the most.',
    'brand_image':
        'Estimation of how much more market gains, revenue (#1), or market loss, cost savings (#2) will result from project. Could also be %.',
    'stakeholder_commitment':
        'Could be gain (#1) or loss avoidance (#2) that\'s associated with meeting shareholder commitments.',
    'other':
        'They can decide which category and use any of the above formulas.',
  };
  static const List<MapEntry<String, String>> _projectValueFields = [
    MapEntry('revenue', 'Revenue'),
    MapEntry('cost_saving', 'Cost Saving'),
    MapEntry('ops_efficiency', 'Operational Efficiency'),
    MapEntry('productivity', 'Productivity'),
    MapEntry('regulatory_compliance', 'Regulatory & Compliance'),
    MapEntry('process_improvement', 'Process Improvement'),
    MapEntry('brand_image', 'Brand Image'),
    MapEntry('stakeholder_commitment', 'Shareholder Communication'),
    MapEntry('other', 'Other'),
  ];
  late final TextEditingController _projectValueAmountController;
  late final Map<String, TextEditingController> _projectValueBenefitControllers;
  late final TabController _benefitCategoryTabController;
  int _activeBenefitCategoryIndex = 0;
  int _activeTab = 0;
  String _currency = 'USD';
  String _lastCurrency = 'USD';
  static const Map<String, double> _currencyRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
  };
  late final OpenAiServiceSecure _openAi;
  bool _isGenerating = false;
  bool _isGeneratingValue = false;
  // Basis frequency for multi-year benefit calculations (required selection)
  String? _basisFrequency;
  static const List<String> _frequencyOptions = [
    'Monthly',
    'Quarterly',
    'Yearly'
  ];
  // Basis frequency for tracker table (Annual vs Monthly)
  String _trackerBasisFrequency = 'Annual';
  String? _error;
  String? _projectValueError;
  int _npvHorizon = 5;
  double _discountRate = 0.10; // Default 10% discount rate for NPV calculations
  final Set<int> _solutionLoading = <int>{};
  final List<_BenefitLineItemEntry> _benefitLineItems = [];
  int _benefitTabIndex = 0;
  final Set<String> _selectedBenefitCategories = <String>{};
  final TextEditingController _savingsNotesController = TextEditingController();
  final TextEditingController _savingsTargetController =
      TextEditingController(text: '10');
  bool _isSavingsGenerating = false;
  String? _savingsError;
  List<AiBenefitSavingsSuggestion> _savingsSuggestions = [];
  bool _hasShownTableHint = false;

  @override
  void initState() {
    super.initState();
    _suppressDirtyTracking = true;
    _notesController = TextEditingController(text: widget.notes);
    _notesController.addListener(_markDirty);
    _projectValueAmountController = TextEditingController();
    _projectValueBenefitControllers = {
      for (final field in _projectValueFields)
        field.key: TextEditingController(),
    };
    _benefitCategoryTabController =
        TabController(length: _projectValueFields.length, vsync: this);
    _activeBenefitCategoryIndex = _benefitCategoryTabController.index;
    _benefitCategoryTabController.addListener(() {
      if (_benefitCategoryTabController.indexIsChanging) return;
      if (!mounted) return;
      setState(() {
        _activeBenefitCategoryIndex = _benefitCategoryTabController.index;
      });
    });
    _rowsPerSolution = List.generate(
        widget.solutions.isEmpty ? 3 : widget.solutions.length, (i) {
      // Seed each tab with 3 placeholder rows to mirror the screenshot
      return List.generate(
          3, (j) => _CostRow(currencyProvider: () => _currency));
    });
    _solutionContexts =
        List.generate(_rowsPerSolution.length, (_) => _SolutionCostContext());
    _categoryCostsPerSolution = List.generate(_rowsPerSolution.length, (_) {
      return {
        for (final field in _projectValueFields)
          field.key: _CategoryCostEntry(categoryKey: field.key)
            ..bind(_markDirty),
      };
    });
    _categoryIdeasPerSolution = List.generate(_rowsPerSolution.length, (_) {
      return {
        for (final field in _projectValueFields) field.key: <AiCostItem>[],
      };
    });
    for (final context in _solutionContexts) {
      context.justificationController.addListener(_markDirty);
    }
    _projectValueAmountController.addListener(_onProjectValueFieldChanged);
    for (final controller in _projectValueBenefitControllers.values) {
      controller.addListener(_onProjectValueFieldChanged);
    }
    _savingsNotesController.addListener(_markDirty);
    _savingsTargetController.addListener(_markDirty);
    for (final list in _rowsPerSolution) {
      for (final row in list) {
        _attachRowDirtyListeners(row);
      }
    }
    for (int i = 0; i < _solutionContexts.length; i++) {
      _refreshJustificationFor(i, force: true);
    }
    ApiKeyManager.initializeApiKey();
    _openAi = OpenAiServiceSecure();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadExistingData();
      if (widget.solutions.isNotEmpty) {
        _generateCostBreakdown().whenComplete(() {
          _suppressDirtyTracking = false;
        });
      } else {
        _suppressDirtyTracking = false;
      }
    });
  }

  void _loadExistingData() {
    try {
      final provider = ProjectDataInherited.of(context);
      final costAnalysisData = provider.projectData.costAnalysisData;

      if (costAnalysisData == null) return;

      // Load notes
      if (costAnalysisData.notes.isNotEmpty) {
        _notesController.text = costAnalysisData.notes;
      }

      // Load Step 1: Project Value data
      if (costAnalysisData.projectValueAmount.isNotEmpty) {
        _projectValueAmountController.text =
            costAnalysisData.projectValueAmount;
      }

      // Load Project Value benefits
      for (final entry in costAnalysisData.projectValueBenefits.entries) {
        final controller = _projectValueBenefitControllers[entry.key];
        if (controller != null) {
          controller.text = entry.value;
        }
      }

      // Load benefit line items
      _benefitLineItems.clear();
      for (final item in costAnalysisData.benefitLineItems) {
        final entry = _BenefitLineItemEntry(
          id: item.id,
          categoryKey: item.categoryKey.isEmpty
              ? _projectValueFields.first.key
              : item.categoryKey,
          title: item.title,
          unitValue: double.tryParse(item.unitValue) ?? 0,
          units: double.tryParse(item.units) ?? 0,
          notes: item.notes,
        );
        entry.bind(_onBenefitEntryEdited);
        _benefitLineItems.add(entry);
      }

      // Load savings data
      if (costAnalysisData.savingsNotes.isNotEmpty) {
        _savingsNotesController.text = costAnalysisData.savingsNotes;
      }
      if (costAnalysisData.savingsTarget.isNotEmpty) {
        _savingsTargetController.text = costAnalysisData.savingsTarget;
      }

      // Load Step 2: Cost rows for each solution
      for (int i = 0;
          i < costAnalysisData.solutionCosts.length &&
              i < _rowsPerSolution.length;
          i++) {
        final solutionCost = costAnalysisData.solutionCosts[i];
        final rows = _rowsPerSolution[i];

        // Ensure we have enough rows
        while (rows.length < solutionCost.costRows.length) {
          final newRow = _CostRow(currencyProvider: () => _currency);
          _attachRowDirtyListeners(newRow);
          rows.add(newRow);
        }

        for (int j = 0;
            j < solutionCost.costRows.length && j < rows.length;
            j++) {
          final costRow = solutionCost.costRows[j];
          final row = rows[j];

          row.itemController.text = costRow.itemName;
          row.descriptionController.text = costRow.description;
          row.costController.text = costRow.cost;
          row.assumptionsController.text = costRow.assumptions;
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading existing cost analysis data: $e');
    }
  }

  AiSolutionItem? _solutionAt(int index) {
    if (index < 0 || index >= widget.solutions.length) return null;
    return widget.solutions[index];
  }

  String _solutionTitle(int index) {
    final solution = _solutionAt(index);
    final title = solution?.title.trim() ?? '';
    return title.isNotEmpty
        ? solution!.title
        : 'Potential Solution ${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: isMobile ? _buildMobileDrawer() : null,
        body: Stack(
          children: [
            Column(children: [
              BusinessCaseHeader(scaffoldKey: _scaffoldKey),
              Expanded(
                  child: Row(children: [
                DraggableSidebar(
                  openWidth: sidebarWidth,
                  child: const InitiationLikeSidebar(
                      activeItemLabel:
                          'Cost Benefit Analysis & Financial Metrics'),
                ),
                Expanded(child: _buildMainContent()),
              ])),
            ]),
            const KazAiChatBubble(),
            const AdminEditToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final isMobile = AppBreakpoints.isMobile(context);
    // Match InitiationPhaseScreen header: no logo, centered title, profile at right
    final double headerHeight = isMobile ? 72 : 88;
    return Container(
      height: headerHeight,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: Row(
        children: [
          Row(
            children: [
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                )
              else
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: _handleBackNavigation,
                ),
            ],
          ),
          const Spacer(),
          if (!isMobile)
            const Text(
              'Initiation Phase',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black),
            ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                    color: Colors.blue, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                StreamBuilder<bool>(
                  stream: UserService.watchAdminStatus(),
                  builder: (context, snapshot) {
                    final email =
                        FirebaseAuth.instance.currentUser?.email ?? '';
                    final isAdmin =
                        snapshot.data ?? UserService.isAdminEmail(email);
                    final role = isAdmin ? 'Admin' : 'Member';
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          FirebaseAuthService.displayNameOrEmail(
                              fallback: 'User'),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                        Text(role,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down,
                    color: Colors.grey, size: 20),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    // Match RiskIdentificationScreen sidebar styling and structure
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    // Keep banner height consistent with other initiation-like sidebars
    final double bannerHeight = AppBreakpoints.isMobile(context) ? 72 : 96;
    return Container(
      width: sidebarWidth,
      color: Colors.white,
      child: Column(
        children: [
          // Full-width banner image above "StackOne"
          SizedBox(
            width: double.infinity,
            height: bannerHeight,
            child: Center(child: AppLogo(height: 64)),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFFFD700), width: 1)),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFFFD700),
                  child: Icon(Icons.person_outline, color: Colors.black87),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('StackOne',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildMenuItem(Icons.home_outlined, 'Home',
                    onTap: () => HomeScreen.open(context)),
                _buildExpandableHeader(
                  Icons.flag_outlined,
                  'Initiation Phase',
                  expanded: _initiationExpanded,
                  onTap: () => setState(
                      () => _initiationExpanded = !_initiationExpanded),
                  isActive: true,
                ),
                if (_initiationExpanded) ...[
                  _buildExpandableHeaderLikeCost(
                    Icons.business_center_outlined,
                    'Business Case',
                    expanded: _businessCaseExpanded,
                    onTap: () => setState(
                        () => _businessCaseExpanded = !_businessCaseExpanded),
                    isActive: false,
                  ),
                  if (_businessCaseExpanded) ...[
                    _buildNestedSubMenuItem('Business Case',
                        onTap: _openBusinessCase),
                    _buildNestedSubMenuItem('Potential Solutions',
                        onTap: _openPotentialSolutions),
                    _buildNestedSubMenuItem('Risk Identification',
                        onTap: _openRiskIdentification),
                    _buildNestedSubMenuItem('IT Considerations',
                        onTap: _openITConsiderations),
                    _buildNestedSubMenuItem('Infrastructure Considerations',
                        onTap: _openInfrastructureConsiderations),
                    _buildNestedSubMenuItem('Core Stakeholders',
                        onTap: _openCoreStakeholders),
                    _buildNestedSubMenuItem(
                        'Cost Benefit Analysis & Financial Metrics',
                        isActive: true),
                    _buildNestedSubMenuItem('Preferred Solution Analysis',
                        onTap: _openPreferredSolutionAnalysis),
                  ],
                ],
                _buildMenuItem(
                    Icons.timeline, 'Initiation: Front End Planning'),
                _buildMenuItem(Icons.account_tree_outlined, 'Workflow Roadmap'),
                _buildMenuItem(Icons.flash_on, 'Agile Roadmap'),
                _buildMenuItem(Icons.description_outlined, 'Contracting'),
                _buildMenuItem(Icons.shopping_cart_outlined, 'Procurement'),
                const SizedBox(height: 20),
                _buildMenuItem(Icons.settings_outlined, 'Settings',
                    onTap: () => SettingsScreen.open(context)),
                _buildMenuItem(Icons.logout_outlined, 'LogOut',
                    onTap: () => AuthNav.signOutAndExit(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildMobileDrawer() {
    // Match RiskIdentificationScreen drawer look
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFFFD700),
                child: Icon(Icons.person_outline, color: Colors.black87),
              ),
              title: Text('StackOne'),
            ),
            const Divider(height: 1),
            _buildMenuItem(Icons.home_outlined, 'Home',
                onTap: () => HomeScreen.open(context)),
            _buildExpandableHeader(
              Icons.flag_outlined,
              'Initiation Phase',
              expanded: _initiationExpanded,
              onTap: () =>
                  setState(() => _initiationExpanded = !_initiationExpanded),
              isActive: true,
            ),
            if (_initiationExpanded) ...[
              _buildExpandableHeaderLikeCost(
                Icons.business_center_outlined,
                'Business Case',
                expanded: _businessCaseExpanded,
                onTap: () => setState(
                    () => _businessCaseExpanded = !_businessCaseExpanded),
                isActive: false,
              ),
              if (_businessCaseExpanded) ...[
                _buildNestedSubMenuItem('Business Case', onTap: () {
                  Navigator.of(context).maybePop();
                  _openBusinessCase();
                }),
                _buildNestedSubMenuItem('Potential Solutions', onTap: () {
                  Navigator.of(context).maybePop();
                  _openPotentialSolutions();
                }),
                _buildNestedSubMenuItem('Risk Identification', onTap: () {
                  Navigator.of(context).maybePop();
                  _openRiskIdentification();
                }),
                _buildNestedSubMenuItem('IT Considerations', onTap: () {
                  Navigator.of(context).maybePop();
                  _openITConsiderations();
                }),
                _buildNestedSubMenuItem('Infrastructure Considerations',
                    onTap: () {
                  Navigator.of(context).maybePop();
                  _openInfrastructureConsiderations();
                }),
                _buildNestedSubMenuItem('Core Stakeholders', onTap: () {
                  Navigator.of(context).maybePop();
                  _openCoreStakeholders();
                }),
                _buildNestedSubMenuItem(
                    'Cost Benefit Analysis & Financial Metrics',
                    isActive: true),
                _buildNestedSubMenuItem('Preferred Solution Analysis',
                    onTap: () {
                  Navigator.of(context).maybePop();
                  _openPreferredSolutionAnalysis();
                }),
              ],
            ],
            _buildMenuItem(Icons.timeline, 'Initiation: Front End Planning'),
            _buildMenuItem(Icons.account_tree_outlined, 'Workflow Roadmap'),
            _buildMenuItem(Icons.flash_on, 'Agile Roadmap'),
            _buildMenuItem(Icons.description_outlined, 'Contracting'),
            _buildMenuItem(Icons.shopping_cart_outlined, 'Procurement'),
            const Divider(height: 1),
            _buildMenuItem(Icons.settings_outlined, 'Settings', onTap: () {
              Navigator.of(context).maybePop();
              SettingsScreen.open(context);
            }),
            _buildMenuItem(Icons.logout_outlined, 'LogOut',
                onTap: () => AuthNav.signOutAndExit(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title,
      {bool disabled = false, VoidCallback? onTap, bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    VoidCallback? handler;
    if (!disabled) {
      handler = onTap ??
          () {
            if (title == 'Home') {
              HomeScreen.open(context);
            } else if (title == 'SSHER') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SsherStackedScreen()));
            } else if (title == 'LogOut') {
              AuthNav.signOutAndExit(context);
            } else if (title == 'Team Management') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TeamManagementScreen()));
            } else if (title == 'Change Management') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChangeManagementScreen()));
            } else if (title == 'Lessons Learned') {
              LessonsLearnedScreen.open(context);
            }
          };
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: InkWell(
        onTap: handler,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isActive ? primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: isActive
                      ? primary
                      : (disabled ? Colors.grey[400] : Colors.black87)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive
                        ? primary
                        : (disabled ? Colors.grey[500] : Colors.black87),
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuItem(String title,
      {VoidCallback? onTap, bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 24, top: 2, bottom: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:
                isActive ? primary.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.circle,
                  size: 8, color: isActive ? primary : Colors.grey[500]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive ? primary : Colors.black87,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableHeaderLikeCost(IconData icon, String title,
      {required bool expanded,
      required VoidCallback onTap,
      bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 24, top: 2, bottom: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:
                isActive ? primary.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.circle,
                size: 8, color: isActive ? primary : Colors.grey[500]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? primary : Colors.black87,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.grey[600], size: 18),
          ]),
        ),
      ),
    );
  }

  Widget _buildNestedSubMenuItem(String title,
      {VoidCallback? onTap, bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 24, top: 2, bottom: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:
                isActive ? primary.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.circle,
                size: 6, color: isActive ? primary : Colors.grey[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? primary : Colors.black87,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildExpandableHeader(IconData icon, String title,
      {required bool expanded,
      required VoidCallback onTap,
      bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isActive ? primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isActive ? primary : Colors.black87),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? primary : Colors.black87,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[700],
                  size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openBusinessCase() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const InitiationPhaseScreen(scrollToBusinessCase: true),
      ),
    );
  }

  void _openPotentialSolutions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PotentialSolutionsScreen(),
      ),
    );
  }

  void _openRiskIdentification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiskIdentificationScreen(
          notes: _notesController.text,
          solutions: widget.solutions,
        ),
      ),
    );
  }

  void _openITConsiderations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ITConsiderationsScreen(
          notes: _notesController.text,
          solutions: widget.solutions,
        ),
      ),
    );
  }

  void _openInfrastructureConsiderations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InfrastructureConsiderationsScreen(
          notes: _notesController.text,
          solutions: widget.solutions,
        ),
      ),
    );
  }

  void _openCoreStakeholders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoreStakeholdersScreen(
          notes: _notesController.text,
          solutions: widget.solutions,
        ),
      ),
    );
  }

  void _openPreferredSolutionAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreferredSolutionAnalysisScreen(
          notes: _notesController.text,
          solutions: widget.solutions,
          businessCase: '',
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizonLabel = '$_npvHorizon-year';
    final horizontalPadding = AppBreakpoints.pagePadding(context);
    final contentPadding = EdgeInsets.fromLTRB(
        horizontalPadding, 0, horizontalPadding, horizontalPadding);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _mainScrollController,
          child: SingleChildScrollView(
            controller: _mainScrollController,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontalPadding,
                        horizontalPadding, horizontalPadding, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EditableContentText(
                            contentKey: 'cost_analysis_heading',
                            fallback:
                                'Cost Benefit Analysis & Financial Metrics',
                            category: 'business_case',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: EditableContentText(
                                contentKey: 'cost_analysis_description',
                                fallback:
                                    'Analyze the selected solution\'s investment profile, project value, ROI and NPV in a consolidated workspace.',
                                category: 'business_case',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ),
                            // Page-level Regenerate All button
                            PageRegenerateAllButton(
                              onRegenerateAll: () async {
                                final confirmed = await showRegenerateAllConfirmation(context);
                                if (confirmed && mounted) {
                                  await _regenerateAllCostAnalysis();
                                }
                              },
                              isLoading: _isGeneratingValue,
                              tooltip: 'Regenerate all cost analysis content',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Currency selector at the very top (before table)
                        if (_currentStepIndex == 0) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: _buildCurrencySelector(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Data Table at the top - first thing user sees (before step indicator)
                        if (_currentStepIndex == 0) ...[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            child: _buildBenefitLineItemsTab(),
                          ),
                          const SizedBox(height: 20),
                        ],
                        _buildStepProgressIndicator(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildStepPage(
                    index: _currentStepIndex,
                    isMobile: isMobile,
                    horizonLabel: horizonLabel,
                    padding: contentPadding,
                  ),
                  _buildStepNavigationControls(),
                  // Removed duplicate BusinessCaseNavigationButtons - navigation is handled by _buildStepNavigationControls()
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepProgressIndicator() {
    final totalSteps = _stepDefinitions.length;
    final progress =
        totalSteps <= 1 ? 1.0 : (_currentStepIndex + 1) / totalSteps;
    final progressValue = progress.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < totalSteps; i++) ...[
                    Expanded(child: _buildProgressChip(i, expand: true)),
                    if (i != totalSteps - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            }
            return SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: totalSteps,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _buildProgressChip(index),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            backgroundColor: Colors.grey.withOpacity(0.18),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressChip(int index, {bool expand = false}) {
    final definition = _stepDefinitions[index];
    final isActive = index == _currentStepIndex;
    final isComplete = index < _currentStepIndex;
    final backgroundColor = isActive
        ? const Color(0xFFFFF6CC)
        : isComplete
            ? const Color(0xFFE8F5E9)
            : Colors.white;
    final borderColor = isActive
        ? const Color(0xFFFFD700)
        : isComplete
            ? const Color(0xFF4CAF50).withOpacity(0.4)
            : Colors.grey.withOpacity(0.25);
    final Color? rawTextColor = isActive
        ? Colors.black
        : isComplete
            ? const Color(0xFF1B5E20)
            : Colors.grey[700];
    final Color resolvedTextColor = rawTextColor ?? Colors.grey.shade700;
    final Color subtitleColor = resolvedTextColor.withOpacity(0.78);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _goToStep(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.26),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: isActive
                    ? const Color(0xFFFFD700)
                    : isComplete
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade200,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive
                        ? Colors.black
                        : isComplete
                            ? Colors.white
                            : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (expand)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        definition.shortLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: resolvedTextColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        definition.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: subtitleColor),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  // Allow long headings to wrap instead of truncating.
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        definition.shortLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: resolvedTextColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        definition.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 11.5, color: subtitleColor),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepPage({
    required int index,
    required bool isMobile,
    required String horizonLabel,
    required EdgeInsets padding,
  }) {
    final stepDefinition = _stepDefinitions[index];
    final stepLabel = 'Step ${index + 1}';
    final children = <Widget>[];

    switch (index) {
      case 0:
        // Currency selector moved to top of page (before step indicator) - no longer here
        // children.add(_buildCurrencySelector()); // Moved to top of page
        // children.add(const SizedBox(height: 16));
        // Table moved to top of page (before step indicator) - no longer here
        // children.add(_buildBenefitLineItemsTab()); // Moved to top of page
        // children.add(const SizedBox(height: 24));
        if (_projectValueError != null) {
          children.add(_errorBanner(_projectValueError!,
              onRetry: _isGeneratingValue ? null : _generateProjectValue));
        }
        children.add(_stepHeading(
            step: stepLabel,
            title: stepDefinition.title,
            subtitle: stepDefinition.subtitle));
        children.add(_buildProjectValueSection());
        // Project Benefits Review section (moved down, no longer in tab)
        children.add(const SizedBox(height: 24));
        children.add(_buildProjectBenefitsReviewTab(
          summaries: _benefitSummaries(),
          totalValue: _benefitTotalValue(),
          totalUnits: _benefitTotalUnits(),
        ));
        children.add(const SizedBox(height: 24));
        break;
      case 1:
        // Initial Cost Estimate as Step 2
        children.add(_stepHeading(
            step: stepLabel,
            title: stepDefinition.title,
            subtitle: stepDefinition.subtitle));
        if (_error != null) {
          children.add(_errorBanner(_error!,
              onRetry: _isGenerating ? null : _generateCostBreakdown));
        }
        if (_isGenerating) {
          children.add(const LinearProgressIndicator(minHeight: 2));
          children.add(const SizedBox(height: 12));
        }
        children.add(_buildInitialCostEstimateTabs());
        children.add(const SizedBox(height: 16));
        children.add(_buildOpportunitySavingsSection());
        children.add(const SizedBox(height: 24));
        break;
      case 2:
        // Profitability Analysis as Step 3
        children.add(_stepHeading(
            step: stepLabel,
            title: stepDefinition.title,
            subtitle: stepDefinition.subtitle));
        children.add(_buildMetricToolbar(
            isMobile: isMobile, horizonLabel: horizonLabel));
        children.add(const SizedBox(height: 16));
        children.add(_buildProfitabilitySummaryTable());
        children.add(const SizedBox(height: 16));
        // Moved from Step 2: Show solution cost snapshots within Probability Analysis
        children.add(_buildSolutionSummaries(isMobile: isMobile));
        children.add(const SizedBox(height: 16));
        children.add(_buildValuesGainedSummary());
        // Per request: remove all tables below the "Values gained per solution" section.
        children.add(const SizedBox(height: 24));
        break;
      case 3:
        children.add(_stepHeading(
            step: stepLabel,
            title: stepDefinition.title,
            subtitle: stepDefinition.subtitle));
        children.add(_buildNotesSection());
        children.add(const SizedBox(height: 16));
        children.add(_buildNotesCallout());
        children.add(const SizedBox(height: 24));
        break;
      default:
        children.add(_stepHeading(
            step: stepLabel,
            title: stepDefinition.title,
            subtitle: stepDefinition.subtitle));
        break;
    }

    if (children.isNotEmpty) {
      children.insert(0, const SizedBox(height: 12));
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildStepNavigationControls() {
    final horizontalPadding = AppBreakpoints.pagePadding(context);
    final isFirst = _currentStepIndex == 0;
    final isLast = _currentStepIndex == _stepDefinitions.length - 1;
    final stepStatus =
        'Step ${_currentStepIndex + 1} of ${_stepDefinitions.length}';
    final primaryLabel =
        isLast ? 'Continue to Preferred Solution' : 'Next Step';
    final primaryIcon = isLast ? Icons.check : Icons.arrow_forward_ios_rounded;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          horizontalPadding, 12, horizontalPadding, horizontalPadding),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: isFirst ? null : _handlePreviousStep,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            label: const Text('Previous'),
          ),
          const SizedBox(width: 16),
          Text(
            stepStatus,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800]),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Save'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[800],
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: isLast ? _openPreferredSolution : _handleNextStep,
            icon: Icon(primaryIcon, size: 16),
            label: Text(primaryLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCallout() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF90CAF9).withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: Color(0xFF87CEEB), shape: BoxShape.circle),
            child:
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Switch between steps freely—your financial inputs stay in place until you export or confirm exit.',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToStep(int index) async {
    if (!mounted || index == _currentStepIndex) return;
    if (index < 0 || index >= _stepDefinitions.length) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStepIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_mainScrollController.hasClients) {
        _mainScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handlePreviousStep() {
    final previous = _currentStepIndex - 1;
    if (previous >= 0) {
      _goToStep(previous);
    }
  }

  Future<void> _handleNextStep() async {
    // Save cost analysis data before navigating to next step
    await _saveCostAnalysisData();

    // Show 3-second loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Saving your progress...'),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    final next = _currentStepIndex + 1;
    if (next < _stepDefinitions.length) {
      _goToStep(next);
    }
  }

  Future<void> _openPreferredSolution() async {
    FocusScope.of(context).unfocus();

    // 1. Save data FIRST before validation
    await _saveCostAnalysisData();
    if (!mounted) return;

    // 2. Validate data completeness
    final provider = ProjectDataInherited.of(context);
    final projectData = provider.projectData;

    if (projectData.costAnalysisData == null) {
      if (mounted) {
        ProjectDataHelper.showMissingDataMessage(
            context, 'Please complete the cost analysis before proceeding.');
      }
      return;
    }

    // 3. Smart checkpoint check
    final nextCheckpoint =
        SidebarNavigationService.instance.getNextItem('cost_analysis');
    if (nextCheckpoint?.checkpoint != 'preferred_solution_analysis') {
      // Use standard lock check for non-sequential navigation
      final isLocked = ProjectDataHelper.isDestinationLocked(
          context, 'preferred_solution_analysis');
      if (isLocked) {
        ProjectDataHelper.showLockedDestinationMessage(
            context, 'Preferred Solution Analysis');
        return;
      }
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing cost analysis data...'),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 1)); // Reduced delay

    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    // Navigate to Preferred Solution Analysis
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreferredSolutionAnalysisScreen(
          notes: widget.notes,
          solutions: widget.solutions,
          businessCase: projectData.businessCase,
        ),
      ),
    );
  }

  Future<void> _saveCostAnalysisData() async {
    try {
      final provider = ProjectDataInherited.of(context);

      // Collect cost row data for single selected solution (Step 2)
      // Use first solution or first available solution
      final solutionCosts = <SolutionCostData>[];
      if (_rowsPerSolution.isNotEmpty) {
        final solutionIndex =
            0; // Single solution approach - use first solution
        final solutionTitle = solutionIndex < widget.solutions.length
            ? widget.solutions[solutionIndex].title
            : (widget.solutions.isNotEmpty
                ? widget.solutions.first.title
                : 'Selected Solution');

        final costRows = _rowsPerSolution[solutionIndex].map((row) {
          return CostRowData(
            itemName: row.itemController.text,
            description: row.descriptionController.text,
            cost: row.costController.text,
            assumptions: row.assumptionsController.text,
          );
        }).toList();

        solutionCosts.add(SolutionCostData(
          solutionTitle: solutionTitle,
          costRows: costRows,
        ));
      }

      // Collect Project Value data (Step 1)
      final projectValueBenefits = <String, String>{};
      for (final field in _projectValueFields) {
        final controller = _projectValueBenefitControllers[field.key];
        if (controller != null && controller.text.isNotEmpty) {
          projectValueBenefits[field.key] = controller.text;
        }
      }

      // Collect benefit line items
      final benefitLineItems = _benefitLineItems.map((entry) {
        return BenefitLineItem(
          id: entry.id,
          categoryKey: entry.categoryKey,
          title: entry.titleController.text,
          unitValue: entry.unitValueController.text,
          units: entry.unitsController.text,
          notes: entry.notesController.text,
        );
      }).toList();

      final costAnalysisData = CostAnalysisData(
        notes: _notesController.text,
        solutionCosts: solutionCosts,
        projectValueAmount: _projectValueAmountController.text,
        projectValueBenefits: projectValueBenefits,
        benefitLineItems: benefitLineItems,
        savingsNotes: _savingsNotesController.text,
        savingsTarget: _savingsTargetController.text,
      );

      provider.updateProjectData(
        provider.projectData.copyWith(costAnalysisData: costAnalysisData),
      );

      // Save to Firebase with checkpoint
      await provider.saveToFirebase(checkpoint: 'cost_analysis');
      _hasUnsavedChanges = false;
    } catch (e) {
      debugPrint('Error saving cost analysis data: $e');
    }
  }

  Future<void> _handleSave() async {
    // Show saving indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Saving...'),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF424242),
      ),
    );

    await _saveCostAnalysisData();

    if (!mounted) return;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 12),
            Text('Changes saved successfully'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _markDirty() {
    if (_suppressDirtyTracking || _hasUnsavedChanges || !mounted) {
      return;
    }
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  void _attachRowDirtyListeners(_CostRow row) {
    void handleChange() => _markDirty();
    row.itemController.addListener(handleChange);
    row.descriptionController.addListener(handleChange);
    row.costController.addListener(handleChange);
    row.assumptionsController.addListener(handleChange);
  }

  Future<bool> _confirmExit() async {
    if (!mounted) return true;
    if (!_hasUnsavedChanges) return true;
    final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
                'You have unsaved updates on this screen. Leaving now will discard them.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
    if (shouldLeave && mounted) {
      setState(() {
        _hasUnsavedChanges = false;
      });
    }
    return shouldLeave;
  }

  Future<void> _handleBackNavigation() async {
    final shouldLeave = await _confirmExit();
    if (!shouldLeave) return;
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    HomeScreen.open(context);
  }

  void _onProjectValueFieldChanged() {
    _markDirty();
    if (mounted) setState(() {});
  }

  double _parseCurrencyInput(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(sanitized) ?? 0;
  }

  _ValueSetupInvestmentSnapshot? _valueSetupInvestmentSnapshot() {
    final estimatedCost =
        _parseCurrencyInput(_projectValueAmountController.text.trim());
    if (estimatedCost <= 0) {
      return null;
    }
    final totalBenefits = _benefitTotalValue();
    final activeBenefitCount = _benefitLineItems
        .where((entry) => entry.totalValue > 0 || entry.title.isNotEmpty)
        .length;
    final averageRoi = totalBenefits > 0 && estimatedCost > 0
        ? ((totalBenefits - estimatedCost) / estimatedCost) * 100
        : null;
    // Calculate NPV properly using discount rate and time periods
    // NPV = -Initial Cost + Sum of (Benefits / (1 + r)^t) for each period
    double? npv;
    if (totalBenefits > 0 && estimatedCost > 0 && _npvHorizon > 0) {
      // Assume benefits are received evenly over the horizon period
      final annualBenefit = totalBenefits / _npvHorizon;
      final cashflows = <double>[
        -estimatedCost
      ]; // Initial investment (negative)
      for (int year = 1; year <= _npvHorizon; year++) {
        cashflows.add(annualBenefit); // Annual benefits
      }
      npv = Finance.npv(_discountRate, cashflows);
    } else {
      npv = null;
    }
    return _ValueSetupInvestmentSnapshot(
      estimatedCost: estimatedCost,
      averageRoi: averageRoi,
      npv: npv,
      costRange:
          _CostRange(lower: estimatedCost * 0.85, upper: estimatedCost * 1.15),
      benefitLineItemCount: activeBenefitCount,
      totalBenefits: totalBenefits,
    );
  }

  Widget _stepHeading(
      {required String step, required String title, String? subtitle}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7CC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFFD700)),
          ),
          child: Text(step,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700))),
      ]),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
      const SizedBox(height: 12),
    ]);
  }

  Widget _buildCurrencySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Text(
            'Select Currency:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _currency,
            items: const [
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              DropdownMenuItem(value: 'GBP', child: Text('GBP')),
              DropdownMenuItem(value: 'ZMW', child: Text('ZMW')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currency = value;
                  _markDirty();
                });
                // Update provider
                final provider = ProjectDataHelper.getProvider(context);
                provider.updateCostBenefitCurrency(value);
              }
            },
            style: const TextStyle(fontSize: 14),
            underline: Container(height: 2, color: const Color(0xFFFFD700)),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectValueSection() {
    final selectedField = _projectValueFields[_activeBenefitCategoryIndex];
    final categoryDescriptor = _benefitMetrics[selectedField.key] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Project Benefit Calculation',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  _AiTag(),
                ]),
                SizedBox(height: 4),
                Text(
                  'AI-assisted estimation to showcase project benefits',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_isGeneratingValue)
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2)),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _isGeneratingValue ? null : _generateProjectValue,
            icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
            label: const Text('Populate with AI'),
          ),
        ]),
        const SizedBox(height: 16),
        // Basis frequency dropdown and estimated value row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 2,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Estimated Project Benefit Value ($_currency)',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: _projectValueAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g. 250000',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFFD700))),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Basis Frequency',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _basisFrequency,
                items: _frequencyOptions
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _basisFrequency = value);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey.withOpacity(0.3))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFFFD700))),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                hint: const Text('Select'),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        // Move the table up (per updated design)
        _buildMultiYearBenefitTable(),
        const SizedBox(height: 16),
        _buildInlineYearBoxes(),
        const SizedBox(height: 20),
        Text('Project Benefits Value Summary',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < _projectValueFields.length; i++)
              _buildBenefitCategoryChip(
                field: _projectValueFields[i],
                isSelected: _activeBenefitCategoryIndex == i,
                onTap: () {
                  setState(() {
                    _activeBenefitCategoryIndex = i;
                    _benefitCategoryTabController.animateTo(i);
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _buildBenefitCategoryTabContent(
            field: selectedField,
            descriptor: categoryDescriptor,
          ),
        ),
        const SizedBox(height: 18),
        Divider(color: Colors.grey.withOpacity(0.2), height: 1),
        const SizedBox(height: 14),
        _buildProjectValueSummary(),
      ]),
    );
  }

  Widget _buildBenefitCategoryChip({
    required MapEntry<String, String> field,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final IconData icon;
    const Color accentColor = Color(0xFFFFC812);

    // Assign icons based on category
    switch (field.key) {
      case 'revenue':
        icon = Icons.trending_up;
        break;
      case 'cost_saving':
        icon = Icons.savings;
        break;
      case 'ops_efficiency':
        icon = Icons.speed;
        break;
      case 'productivity':
        icon = Icons.access_time;
        break;
      case 'regulatory_compliance':
        icon = Icons.verified_user;
        break;
      case 'process_improvement':
        icon = Icons.auto_awesome;
        break;
      case 'brand_image':
        icon = Icons.star;
        break;
      case 'stakeholder_commitment':
        icon = Icons.handshake;
        break;
      case 'other':
      default:
        icon = Icons.more_horiz;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? accentColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : accentColor,
            ),
            const SizedBox(width: 8),
            Text(
              field.value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCategoryTabContent(
      {required MapEntry<String, String> field, required String descriptor}) {
    final controller = _projectValueBenefitControllers[field.key]!;
    final metricTags = _metricTagsFor(field.key);

    return KeyedSubtree(
      key: ValueKey(field.key),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(field.value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        if (descriptor.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(descriptor,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
        const SizedBox(height: 12),
        const Text('Project Benefit Details',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ExpandingTextField(
            key: ValueKey('${field.key}-input'),
            controller: controller,
            minLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Highlight primary project benefits, drivers, and realization strategy.',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        if (metricTags.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Project Benefits Highlights',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in metricTags)
                Chip(
                  avatar: const Icon(Icons.insights_outlined, size: 16),
                  label: Text(tag,
                      style: const TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w600)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Tooltip(
          message: 'Switch tabs as needed',
          preferBelow: false,
          showDuration: const Duration(seconds: 3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7CC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFFFF8F00), size: 18),
              const SizedBox(width: 8),
              Text(
                'Switch tabs as needed',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildInlineYearBoxes() {
    final amountText = _projectValueAmountController.text.trim();
    final baseValue = _parseCurrencyInput(amountText);

    if (_basisFrequency == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Select a basis frequency to calculate 1, 3, 5, and 10-year project value.',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );
    }

    // Calculate multiplier based on frequency
    int frequencyMultiplier;
    switch (_basisFrequency) {
      case 'Monthly':
        frequencyMultiplier = 12;
        break;
      case 'Quarterly':
        frequencyMultiplier = 4;
        break;
      case 'Yearly':
      default:
        frequencyMultiplier = 1;
    }

    // Annualized value
    final annualValue = baseValue * frequencyMultiplier;

    // Multi-year calculations
    final year1 = annualValue;
    final year3 = annualValue * 3;
    final year5 = annualValue * 5;
    final year10 = annualValue * 10;

    return Row(children: [
      _buildYearBox('in 1 year', year1, const Color(0xFFFFF59D)),
      const SizedBox(width: 8),
      _buildYearBox('in 3 years', year3, const Color(0xFFFFE082)),
      const SizedBox(width: 8),
      _buildYearBox('in 5 years', year5, const Color(0xFFFFCC80)),
      const SizedBox(width: 8),
      _buildYearBox('in 10 years', year10, const Color(0xFFFFAB40)),
    ]);
  }

  Widget _buildYearBox(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatCurrencyValue(value),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiYearBenefitTable() {
    final amountText = _projectValueAmountController.text.trim();
    final baseValue = _parseCurrencyInput(amountText);

    if (_basisFrequency == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calculate_outlined,
                size: 20, color: Color(0xFFFF8F00)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Select a basis frequency to calculate Project Value for 1, 3, 5, and 10 years.',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      );
    }

    // Calculate multiplier based on frequency
    int frequencyMultiplier;
    switch (_basisFrequency) {
      case 'Monthly':
        frequencyMultiplier = 12;
        break;
      case 'Quarterly':
        frequencyMultiplier = 4;
        break;
      case 'Yearly':
      default:
        frequencyMultiplier = 1;
    }

    // Annualized value
    final annualValue = baseValue * frequencyMultiplier;

    // Multi-year calculations
    final year1 = annualValue;
    final year3 = annualValue * 3;
    final year5 = annualValue * 5;
    final year10 = annualValue * 10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.calculate_outlined,
              size: 20, color: Color(0xFFFF8F00)),
          const SizedBox(width: 8),
          const Text('Project Value Estimation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Text(
          'Based on $_basisFrequency basis${frequencyMultiplier > 1 ? " (×$frequencyMultiplier to annualize first)" : ""}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8), topRight: Radius.circular(8)),
          ),
          child: Row(children: [
            Expanded(
                flex: 2,
                child: Text('Time Horizon',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600))),
            Expanded(
                flex: 3,
                child: Align(
                    alignment: Alignment.center,
                    child: Text('Projected Benefit ($_currency)',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)))),
          ]),
        ),
        // Table rows
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8)),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          child: Column(children: [
            _multiYearRow('1 Year', year1, isFirst: true),
            _multiYearRow('3 Years', year3),
            _multiYearRow('5 Years', year5),
            _multiYearRow('10 Years', year10, isLast: true),
          ]),
        ),
      ]),
    );
  }

  Widget _multiYearRow(String label, double value,
      {bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : Border(
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Row(children: [
        Expanded(
            flex: 2, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              _formatCurrencyValue(value),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                  color: isLast ? const Color(0xFF1B5E20) : null),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildProjectBenefitDescriptions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Project Benefit Descriptions',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(
        'Select the category that best aligns with your project\'s benefits. If none apply, choose Other to specify your benefit.',
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        if (isNarrow) {
          return Column(children: [
            for (final field in _projectValueFields) ...[
              _buildBenefitDescriptionCard(field),
              const SizedBox(height: 12),
            ],
          ]);
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final field in _projectValueFields)
              _buildBenefitDescriptionCard(field),
          ],
        );
      }),
    ]);
  }

  Widget _buildProjectValueSummary() {
    final amountText = _projectValueAmountController.text.trim();
    final amountValue = _parseCurrencyInput(amountText);
    final hasAmount = amountValue > 0;
    final definedBenefitLabels = <String>[];
    final benefitTiles = <Widget>[];

    for (final field in _projectValueFields) {
      final text = _projectValueBenefitControllers[field.key]!.text.trim();
      final categoryLabel = field.value;
      final metrics = _benefitMetrics[field.key] ?? '';
      if (text.isNotEmpty) {
        definedBenefitLabels.add(categoryLabel.split('&').first.trim());
      }
      benefitTiles.add(Container(
        width: 400,
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(categoryLabel,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              text.isNotEmpty
                  ? text
                  : 'Capture the value impact for this category.',
              style: TextStyle(
                  fontSize: 12,
                  color:
                      text.isNotEmpty ? Colors.grey[700] : Colors.grey[500])),
          const SizedBox(height: 6),
          Text('Metrics: $metrics',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ]),
      ));
    }

    final statementPrefix = hasAmount
        ? 'Estimated project value: ${_formatCurrencyValue(amountValue)} to anchor ROI and NPV calculations.'
        : 'Add an estimated project value to anchor ROI and NPV calculations.';
    final statementSuffix = definedBenefitLabels.isEmpty
        ? 'Capture benefit statements so finance can trace inputs to ROI metrics.'
        : 'Benefit pillars captured: ${definedBenefitLabels.join(', ')}.';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Project Benefit Descriptions',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(
        'Select the category that best aligns with your project\'s benefits. If none apply, choose Other to specify your benefit.',
        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
      ),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Display all 9 categories with their descriptions
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;
            if (isNarrow) {
              return Column(children: [
                for (final field in _projectValueFields) ...[
                  _buildBenefitDescriptionCard(field),
                  const SizedBox(height: 12),
                ],
              ]);
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final field in _projectValueFields)
                  _buildBenefitDescriptionCard(field),
              ],
            );
          }),
        ]),
      ),
    ]);
  }

  Widget _buildBenefitDescriptionCard(MapEntry<String, String> field) {
    final formula = _benefitMetrics[field.key] ?? '';
    final width = 400.0;
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          field.value,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B5E20)),
        ),
        const SizedBox(height: 8),
        Text(
          formula,
          style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
        ),
      ]),
    );
  }

  List<String> _metricTagsFor(String categoryKey) {
    final raw = _benefitMetrics[categoryKey];
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  String _benefitCategoryLabel(String key) {
    final match = _projectValueFields.firstWhere(
      (entry) => entry.key == key,
      orElse: () => const MapEntry('other', 'Other'),
    );
    return match.value;
  }

  _BenefitLineItemEntry _createBenefitEntry({String? categoryKey}) {
    final entry = _BenefitLineItemEntry(
      id: 'benefit-${DateTime.now().microsecondsSinceEpoch}',
      categoryKey: categoryKey ?? _projectValueFields.first.key,
    );
    entry.bind(_onBenefitEntryEdited);
    return entry;
  }

  void _addBenefitLineItem({String? categoryKey}) {
    setState(() {
      _benefitLineItems.add(_createBenefitEntry(categoryKey: categoryKey));
      _savingsSuggestions = [];
      _savingsError = null;
    });
    _markDirty();
  }

  void _removeBenefitLineItem(_BenefitLineItemEntry entry) {
    setState(() {
      _benefitLineItems.remove(entry);
      _savingsSuggestions = [];
      _savingsError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => entry.dispose());
    _markDirty();
  }

  void _onBenefitEntryEdited() {
    if (!mounted) return;
    setState(() {
      _savingsError = null;
      if (!_isSavingsGenerating && _savingsSuggestions.isNotEmpty) {
        _savingsSuggestions = [];
      }
    });
    _markDirty();
  }

  Map<String, _BenefitCategorySummary> _benefitSummaries() {
    final map = <String, _BenefitCategorySummary>{};
    for (final entry in _benefitLineItems) {
      final summary =
          map.putIfAbsent(entry.categoryKey, () => _BenefitCategorySummary());
      summary.add(entry);
    }
    return map;
  }

  double _benefitTotalValue() {
    return _benefitLineItems.fold<double>(
        0, (sum, entry) => sum + entry.totalValue);
  }

  double _benefitTotalUnits() {
    return _benefitLineItems.fold<double>(0, (sum, entry) => sum + entry.units);
  }

  double _calculateTotalBenefitsWithFrequency() {
    final baseTotal = _benefitTotalValue();
    if (_trackerBasisFrequency == 'Monthly') {
      return baseTotal * 12; // Annualize monthly values
    }
    return baseTotal; // Already annual
  }

  Widget _buildFinancialBenefitsTrackerSection() {
    final tabs = const ['Line Items', 'Project Benefits Review'];
    final summaries = _benefitSummaries();
    final totalValue = _benefitTotalValue();
    final totalUnits = _benefitTotalUnits();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Project Benefits',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const _AiTag(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Project Value Estimation',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Assign an estimated financial value to identified project benefits.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Page-level Regenerate All button
          PageRegenerateAllButton(
            onRegenerateAll: () async {
              final confirmed = await showRegenerateAllConfirmation(context);
              if (confirmed && mounted) {
                await _regenerateAllCostAnalysis();
              }
            },
            isLoading: _isGeneratingValue,
            tooltip: 'Regenerate all cost analysis content',
          ),
          const SizedBox(width: 12),
          // Basis Frequency Toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Basis Frequency:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              const SizedBox(width: 8),
              _BasisFrequencyToggle(
                value: _trackerBasisFrequency,
                onChanged: (value) {
                  setState(() {
                    _trackerBasisFrequency = value;
                    _markDirty();
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 12),
          Chip(
            label: Text('${_benefitLineItems.length} items'),
            avatar: const Icon(Icons.table_chart_outlined, size: 16),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < tabs.length; i++)
              ChoiceChip(
                label: Text(tabs[i],
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                selected: _benefitTabIndex == i,
                onSelected: (selected) {
                  if (!selected) return;
                  // Show hint on first tab interaction
                  if (!_hasShownTableHint) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_hasShownTableHint) {
                        PageHintDialog.showIfNeeded(
                          context: context,
                          pageId: 'financial_benefits_tracker_table',
                          title: 'Financial Benefits Tracker',
                          message: 'Switch tabs as needed',
                        ).then((_) {
                          if (mounted) {
                            setState(() {
                              _hasShownTableHint = true;
                            });
                          }
                        });
                      }
                    });
                  }
                  setState(() {
                    _benefitTabIndex = i;
                  });
                },
                selectedColor: const Color(0xFFFFD700),
                backgroundColor: Colors.grey.shade200,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
          ],
        ),
        const SizedBox(height: 16),
        IndexedStack(
          index: _benefitTabIndex,
          children: [
            _buildBenefitLineItemsTab(),
            _buildProjectBenefitsReviewTab(
                summaries: summaries,
                totalValue: totalValue,
                totalUnits: totalUnits),
          ],
        ),
        // Project Benefit Descriptions footer
        const SizedBox(height: 24),
        _buildProjectBenefitDescriptions(),
      ]),
    );
  }

  Widget _buildBenefitLineItemsTab() {
    if (_benefitLineItems.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text(
          'No benefit line items yet',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Add benefit records with unit value and quantity so each initiative converts directly into monetary impact.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _addBenefitLineItem(),
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Add first benefit line item'),
        ),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(
        builder: (context, constraints) {
          // Calculate minimum width needed for all columns
          const minTableWidth = 1200.0;
          final tableWidth = constraints.maxWidth < minTableWidth
              ? minTableWidth
              : constraints.maxWidth;
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Currency indicator at top of table
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Currency: $_currency',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Header row - reduced padding and font size
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.withOpacity(0.35)),
                    ),
                    child: Row(children: [
                      // Reordered columns: Benefit, Category, Basis, Unit Value, Number of Units, Subtotal Benefit
                      SizedBox(
                        width: 200,
                        child: Center(
                          child: Text('Benefit',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: Center(
                          child: Text('Category',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 200,
                        child: Center(
                          child: Text('Basis',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: Center(
                          child: Text('Unit Value',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: Center(
                          child: Text('Number of Units',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: Center(
                          child: Text('Subtotal Benefit',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(width: 36), // Space for delete button
                    ]),
                  ),
                  const SizedBox(height: 6),
                  // Data rows
                  Builder(
                    builder: (context) {
                      // Reset selected categories before building rows
                      _selectedBenefitCategories.clear();
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.withOpacity(0.25)),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < _benefitLineItems.length; i++)
                              _benefitLineItemRow(i, _benefitLineItems[i]),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // TOTAL benefits row (dynamic based on Annual/Monthly) - reduced padding and font
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 200,
                        child: Center(
                          child: Text(
                            'TOTAL benefits',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B5E20)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(width: 140, child: Container()), // Category column spacer
                      const SizedBox(width: 10),
                      SizedBox(width: 200, child: Container()), // Basis column spacer
                      const SizedBox(width: 10),
                      SizedBox(width: 140, child: Container()), // Unit Value column spacer
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: Center(
                          child: Text(
                            '${_benefitTotalUnits().toStringAsFixed(1)}',
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: Center(
                          child: Text(
                            _formatCurrencyValue(_benefitTotalValue()),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B5E20)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      Row(children: [
        Text(
            'Basis: $_trackerBasisFrequency${_trackerBasisFrequency == 'Monthly' ? ' (×12 for annual roll-up)' : ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () => _addBenefitLineItem(),
          icon: const Icon(Icons.add),
          label: const Text('Add benefit item'),
        ),
      ]),
    ]);
  }

  Widget _benefitLineItemRow(int index, _BenefitLineItemEntry entry) {
    // Track selected category
    _selectedBenefitCategories.add(entry.categoryKey);

    // Filter out selected categories except 'Others'
    final categoryItems = _projectValueFields
        .where((e) =>
            e.key == 'other' ||
            e.key == entry.categoryKey ||
            !_selectedBenefitCategories.contains(e.key))
        .map((e) => DropdownMenuItem<String>(
              value: e.key,
              child: Text(e.value, style: const TextStyle(fontSize: 11)),
            ))
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Reordered: Benefit first (no # column) - reduced padding and font
        SizedBox(
          width: 200,
          child: TextField(
            controller: entry.titleController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
            decoration: InputDecoration(
              hintText: 'Benefit name',
              hintStyle: const TextStyle(fontSize: 11),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Category second - reduced padding and font
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<String>(
            initialValue: entry.categoryKey,
            items: categoryItems,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                entry.categoryKey = value;
              });
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
            isExpanded: true,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        const SizedBox(width: 10),
        // Basis third (replaces Notes) - reduced padding and font
        SizedBox(
          width: 200,
          child: TextField(
            controller: entry.notesController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Assumptions/basis',
              hintStyle: const TextStyle(fontSize: 11),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 140,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: entry.unitValueController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: const TextStyle(fontSize: 11),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                tooltip: 'Suggest unit value with AI',
                onPressed: () => _suggestUnitValueWithAI(entry),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 140,
          child: TextField(
            controller: entry.unitsController,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(fontSize: 11),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 140,
          child: Align(
            alignment: Alignment.center,
            child: Text(
              _formatCurrencyValue(entry.totalValue),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Remove item',
          onPressed: () => _removeBenefitLineItem(entry),
          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        )
      ]),
    );
  }

  Widget _buildBenefitEstimatesTab({
    required Map<String, _BenefitCategorySummary> summaries,
    required double totalValue,
    required double totalUnits,
  }) {
    if (summaries.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('No estimates yet',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          'Add benefit line items to see category-level rollups and ensure every initiative has a monetary estimate.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LayoutBuilder(builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final singleColumn = maxWidth < 600;
        final cards = [
          _benefitSummaryCard(
            title: 'Tracked line items',
            value: '${_benefitLineItems.length}',
            helper: 'With monetary values and unit drivers.',
            icon: Icons.list_alt,
          ),
          _benefitSummaryCard(
            title: 'Total monetised benefits',
            value: _formatCurrencyValue(totalValue),
            helper: 'Across all categories and portfolios.',
            icon: Icons.attach_money,
          ),
          _benefitSummaryCard(
            title: 'Total units',
            value: totalUnits.toStringAsFixed(1),
            helper: 'Sum of all unit drivers captured.',
            icon: Icons.stacked_line_chart,
          ),
        ];

        if (singleColumn) {
          return Column(children: [
            for (final card in cards) ...[
              card,
              const SizedBox(height: 12),
            ],
          ]);
        }
        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
            ]
          ],
        );
      }),
      const SizedBox(height: 16),
      const Text('Project Benefits Value Summary',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final entry in summaries.entries)
            _benefitCategoryCard(
              label: _benefitCategoryLabel(entry.key),
              summary: entry.value,
            ),
        ],
      ),
    ]);
  }

  Widget _benefitSummaryCard({
    required String title,
    required String value,
    required String helper,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7CC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFFF8F00)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(helper,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ]),
        ),
      ]),
    );
  }

  Widget _benefitCategoryCard(
      {required String label, required _BenefitCategorySummary summary}) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Items: ${summary.itemCount}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text('Total units: ${summary.unitTotal.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text('Monetised value: ${_formatCurrencyValue(summary.valueTotal)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildBenefitSavingsTab({required double totalValue}) {
    final items = _benefitLineItems
        .where((entry) => entry.totalValue > 0 && entry.title.isNotEmpty)
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(
            'Run an AI-assisted savings calculator to spot optimisation levers across the captured benefits. Provide a target percentage to calibrate recommendations.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isSavingsGenerating ? null : _generateSavingsSuggestions,
          icon: _isSavingsGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome),
          label: const Text('Generate savings scenarios'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 280,
            height: 56,
            child: TextField(
              controller: _savingsTargetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Savings target (%)',
                hintText: 'e.g. 10',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            width: 280,
            height: 56,
            child: TextField(
              controller: _savingsNotesController,
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: 'Context notes',
                hintText: 'Add portfolio, budget, or timing constraints',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Chip(
            avatar: const Icon(Icons.payments_outlined, size: 16),
            label: Text(
                'Total monetised benefits: ${_formatCurrencyValue(totalValue)}'),
          ),
          Chip(
            avatar: const Icon(Icons.fact_check_outlined, size: 16),
            label: Text('${items.length} eligible items for AI'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (_savingsError != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Text(_savingsError!,
              style: const TextStyle(color: Colors.red, fontSize: 12)),
        ),
      if (_savingsSuggestions.isEmpty && _savingsError == null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            items.isEmpty
                ? 'Add at least one monetised benefit (with unit cost and units) to run the savings calculator.'
                : 'Generate AI scenarios to explore savings opportunities linked to the captured benefits.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      if (_savingsSuggestions.isNotEmpty)
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 12),
          const Text('AI savings scenarios',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(children: [
              for (int i = 0; i < _savingsSuggestions.length; i++)
                _savingsSuggestionTile(i, _savingsSuggestions[i]),
            ]),
          ),
        ]),
    ]);
  }

  Widget _buildProjectBenefitsReviewTab({
    required Map<String, _BenefitCategorySummary> summaries,
    required double totalValue,
    required double totalUnits,
  }) {
    // Calculate top 3 most selected categories from benefit line items
    final categoryCounts = <String, int>{};
    for (final entry in _benefitLineItems) {
      categoryCounts[entry.categoryKey] =
          (categoryCounts[entry.categoryKey] ?? 0) + 1;
    }
    final topCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3CategoryKeys = topCategories.take(3).map((e) => e.key).toList();
    final top3CategoryLabels =
        top3CategoryKeys.map((key) => _benefitCategoryLabel(key)).toList();

    // Sort benefit categories by total value (highest first)
    final sortedCategories = summaries.entries.toList()
      ..sort((a, b) => b.value.valueTotal.compareTo(a.value.valueTotal));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Only show summaries if there are benefit items
      if (summaries.isEmpty) ...[
        const Text('No benefits tracked yet',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          'Add benefit line items in the "Line Items" tab to see a comprehensive review of project benefits across all categories.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ] else ...[
        // Summary cards row
        LayoutBuilder(builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final singleColumn = maxWidth < 600;
          final cards = [
            _benefitSummaryCard(
              title: 'Tracked line items',
              value: '${_benefitLineItems.length}',
              helper: 'With monetary values and unit drivers.',
              icon: Icons.list_alt,
            ),
            _benefitSummaryCard(
              title: 'Total monetised benefits',
              value: _formatCurrencyValue(totalValue),
              helper: 'Across all categories and portfolios.',
              icon: Icons.attach_money,
            ),
            _benefitSummaryCard(
              title: 'Total units',
              value: totalUnits.toStringAsFixed(1),
              helper: 'Sum of all unit drivers captured.',
              icon: Icons.stacked_line_chart,
            ),
          ];

          if (singleColumn) {
            return Column(children: [
              for (final card in cards) ...[
                card,
                const SizedBox(height: 12),
              ],
            ]);
          }
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) const SizedBox(width: 12),
              ]
            ],
          );
        }),
        const SizedBox(height: 20),

        // Project Benefits Highlights section (top 3 metrics)
        const Text('Project Benefits Highlights',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          'Top 3 most selected project benefits from the 9 categories for this project.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        if (top3CategoryLabels.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
            ),
            child: Text(
              'No project benefits highlights yet. Add benefit line items to see highlights.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final categoryLabel in top3CategoryLabels)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stacked_line_chart,
                          size: 18, color: const Color(0xFFFFD700)),
                      const SizedBox(width: 8),
                      Text(
                        categoryLabel,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(height: 24),

        // Project Benefits Value Summary section
        const Text('Project Benefits Value Summary',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(
          'Total currency value ($_currency) of each of the 9 benefit categories for this project, ordered by highest amount.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            // Create a map of all 9 categories with their values
            final allCategoriesWithValues = <String, double>{};
            for (final field in _projectValueFields) {
              final summary = summaries[field.key];
              allCategoriesWithValues[field.key] = summary?.valueTotal ?? 0.0;
            }

            // Sort all categories by value (highest first)
            final sortedAllCategories = allCategoriesWithValues.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final entry in sortedAllCategories)
                  _projectBenefitValueCard(
                    label: _benefitCategoryLabel(entry.key),
                    categoryKey: entry.key,
                    summary: summaries[entry.key],
                    isHighest:
                        entry == sortedAllCategories.first && entry.value > 0,
                  ),
              ],
            );
          },
        ),
      ],
      const SizedBox(height: 32),
      // Value Calculation Formulas Table (moved down)
      const Text('Value Calculation Formulas',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(
        'Each benefit category has a specific calculation method for determining financial impact.',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A3F),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Center(
                      child: Text('#',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text('Title',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: Text('Value Calculation Formula',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            // Table Rows
            ...List.generate(_projectValueFields.length, (index) {
              final field = _projectValueFields[index];
              final formula = _benefitMetrics[field.key] ?? '';
              final isLast = index == _projectValueFields.length - 1;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: isLast
                      ? null
                      : Border(
                          bottom:
                              BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 50,
                      child: Center(
                        child: Text('${index + 1}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(field.value,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Text(formula,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    ]);
  }

  Widget _projectBenefitValueCard({
    required String label,
    required String categoryKey,
    required _BenefitCategorySummary? summary,
    required bool isHighest,
  }) {
    final IconData icon;
    switch (categoryKey) {
      case 'revenue':
        icon = Icons.trending_up;
        break;
      case 'cost_saving':
        icon = Icons.savings;
        break;
      case 'ops_efficiency':
        icon = Icons.speed;
        break;
      case 'productivity':
        icon = Icons.access_time;
        break;
      case 'regulatory_compliance':
        icon = Icons.verified_user;
        break;
      case 'process_improvement':
        icon = Icons.auto_awesome;
        break;
      case 'brand_image':
        icon = Icons.star;
        break;
      case 'stakeholder_commitment':
        icon = Icons.handshake;
        break;
      case 'other':
      default:
        icon = Icons.more_horiz;
    }

    final hasValue = summary != null && summary.valueTotal > 0;
    final Color bgColor =
        isHighest && hasValue ? const Color(0xFF2196F3) : Colors.white;
    final Color textColor =
        isHighest && hasValue ? Colors.white : Colors.grey.shade800;
    final Color iconColor =
        isHighest && hasValue ? Colors.white : const Color(0xFFFFD700);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighest && hasValue
              ? const Color(0xFF2196F3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (hasValue) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isHighest
                    ? Colors.white.withValues(alpha: 0.2)
                    : const Color(0xFFFFF7CC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _formatCurrencyValue(summary.valueTotal),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isHighest ? Colors.white : const Color(0xFFFF8F00),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Initial Cost Estimate: per-solution itemized cost matrix (AI-derived items)
  Widget _buildCategoryCostMatrix() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Initial itemized estimates by solution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const _AiTag(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enter high-level estimates per AI-identified cost item for each solution. These anchor your Initial Cost Estimate.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        if (_categoryCostsPerSolution.isEmpty)
          Text(
              'Add at least one potential solution to start estimating per-category costs.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]))
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _categoryCostsPerSolution.length; i++) ...[
                _categoryCostCard(i),
                const SizedBox(height: 12),
              ],
            ],
          ),
      ]),
    );
  }

  Widget _categoryCostCard(int solutionIndex) {
    final rows = _rowsPerSolution[solutionIndex];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(_solutionTitle(solutionIndex),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700))),
          Chip(
            avatar: const Icon(Icons.summarize_outlined, size: 16),
            label: Text(
                'Total: ${_formatCurrencyValue(_solutionTotalCost(solutionIndex))}'),
          )
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.35))),
          child: Row(children: const [
            Expanded(
                flex: 3,
                child: Text('Item',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            SizedBox(width: 12),
            Expanded(
                flex: 2,
                child: Align(
                    alignment: Alignment.center,
                    child: Text('Estimated cost',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)))),
            SizedBox(width: 12),
            Expanded(
                flex: 4,
                child: Text('Comments',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            SizedBox(width: 8),
            SizedBox(width: 36),
          ]),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.25))),
          child: Column(children: [
            for (final r in rows) _initialItemCostRow(r),
          ]),
        ),
      ]),
    );
  }

  Widget _categoryCostRow(int solutionIndex, String categoryKey, String label,
      _CategoryCostEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            flex: 3, child: Text(label, style: const TextStyle(fontSize: 12))),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.topRight,
            child: TextField(
              controller: entry.costController,
              textAlign: TextAlign.right,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                prefixIcon: _costFieldAiPrefix(
                  loading: entry.aiLoading,
                  onSuggest: () => _suggestCategoryCost(
                      solutionIndex, categoryKey, label, entry),
                ),
                prefixIconConstraints:
                    const BoxConstraints.tightFor(width: 28, height: 28),
                suffix: _currencySuffix(_currency),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: ExpandingTextField(
            controller: entry.notesController,
            decoration: const InputDecoration(
              hintText: 'Assumptions or notes for this category',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            minLines: 1,
          ),
        ),
      ]),
    );
  }

  // Row renderer for itemized initial estimate (reuses _CostRow controllers)
  Widget _initialItemCostRow(_CostRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 300,
          child: ExpandingTextField(
            controller: row.itemController,
            minLines: 1,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'Item name',
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 150,
          child: Align(
            alignment: Alignment.topRight,
            child: TextField(
              controller: row.costController,
              textAlign: TextAlign.right,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                prefixIcon: _costFieldAiPrefix(
                  loading: row.aiLoading,
                  onSuggest: () => _suggestCostForRow(row),
                ),
                prefixIconConstraints:
                    const BoxConstraints.tightFor(width: 28, height: 28),
                suffix: _currencySuffix(_currency),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 300,
          child: ExpandingTextField(
            controller: row.assumptionsController,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: 'Assumptions or notes for this item',
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Delete row',
          onPressed: () => _removeInitialCostRow(row),
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        ),
      ]),
    );
  }

  // Compact controls moved: AI icon at the start (prefix), currency at the end (suffix)
  Widget _costFieldAiPrefix(
      {required bool loading, required VoidCallback onSuggest}) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.only(left: 6),
        child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return IconButton(
      onPressed: onSuggest,
      tooltip: 'Suggest with AI',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 24, height: 24),
      icon: const Icon(Icons.auto_awesome, size: 16, color: Colors.amber),
    );
  }

  Widget _currencySuffix(String currency) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(currency,
          style: TextStyle(fontSize: 11, color: Colors.grey[700])),
    );
  }

  Future<void> _suggestCostForRow(_CostRow row) async {
    if (row.aiLoading) return;
    setState(() => row.aiLoading = true);
    try {
      final cost = await _openAi.estimateCostForItem(
        itemName: row.itemController.text,
        description: row.descriptionController.text,
        assumptions: row.assumptionsController.text,
        currency: _currency,
        contextNotes: _buildCostContextNotes(forSolution: _activeTab),
      );
      if (!mounted) return;
      setState(() {
        final v = cost.isFinite ? cost : 0;
        row.costController.text =
            v == 0 ? '' : v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
      });
    } catch (e) {
      print('Error estimating cost: $e');
    } finally {
      if (mounted) setState(() => row.aiLoading = false);
    }
  }

  Future<void> _suggestCategoryCost(int solutionIndex, String categoryKey,
      String label, _CategoryCostEntry entry) async {
    if (entry.aiLoading) return;
    setState(() => entry.aiLoading = true);
    try {
      final cost = await _openAi.estimateCostForItem(
        itemName: '$label (category estimate)',
        description: 'High-level category estimate for $_currency',
        assumptions: entry.notesController.text,
        currency: _currency,
        contextNotes: _buildCostContextNotes(forSolution: solutionIndex),
      );
      if (!mounted) return;
      setState(() {
        final v = cost.isFinite ? cost : 0;
        entry.costController.text =
            v == 0 ? '' : v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
      });
    } catch (e) {
      print('Error estimating category cost: $e');
    } finally {
      if (mounted) setState(() => entry.aiLoading = false);
    }
  }

  double _initialCostEstimateTotalFor(int index) {
    if (index < 0 || index >= _categoryCostsPerSolution.length) return 0;
    final map = _categoryCostsPerSolution[index];
    double sum = 0;
    for (final entry in map.values) {
      sum += entry.cost;
    }
    return sum;
  }

  Widget _buildValuesGainedSummary() {
    final snapshot = _valueSetupInvestmentSnapshot();
    // Only show benefits if Initial Project Value is set in Step 1
    final double benefits = snapshot != null ? snapshot.totalBenefits : 0.0;
    if (_rowsPerSolution.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withOpacity(0.25))),
        child: Text(
            'Add solutions to compare values gained in Profitability Analysis.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Project Value per solution',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final single = width < 760;
        final cards = [
          for (int i = 0; i < _rowsPerSolution.length; i++)
            _valuesGainedCard(i, benefits),
        ];
        if (single) {
          return Column(children: [
            for (final c in cards) ...[c, const SizedBox(height: 12)]
          ]);
        }
        return Row(children: [
          for (int i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i != cards.length - 1) const SizedBox(width: 12),
          ]
        ]);
      }),
    ]);
  }

  // Step 2: Initial Cost Estimate with solution tabs and currency selector
  Widget _buildInitialCostEstimateTabs() {
    final tabCount = _categoryCostsPerSolution.length;
    final activeIndex = _boundedIndex(_activeTab, tabCount == 0 ? 1 : tabCount);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Initial cost estimate',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const _AiTag(),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _isGenerating ? null : _populateCategoriesFromAi,
            icon: _isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_fix_high_outlined, size: 18),
            label: const Text('Populate categories (AI)'),
          ),
          const SizedBox(width: 8),
          _currencyDropdown(),
        ]),
        const SizedBox(height: 12),
        if (tabCount == 0)
          Text('Add solutions to start estimating per-solution costs.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]))
        else ...[
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < tabCount; i++)
                ChoiceChip(
                  label: Text(_solutionTitle(i),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  selected: activeIndex == i,
                  onSelected: (_) => setState(() => _activeTab = i),
                  selectedColor: const Color(0xFFFFD700),
                  backgroundColor: Colors.grey.shade200,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInitialCostTable(activeIndex),
          const SizedBox(height: 12),
          _buildCategoryIdeasSection(activeIndex),
        ]
      ]),
    );
  }

  // Opportunity Savings Section for Step 2 (Initial Cost Estimate)
  // Shows savings that can be subtracted from total cost for identified opportunities
  Widget _buildOpportunitySavingsSection() {
    final totalValue = _benefitTotalValue();
    final activeIndex = _boundedIndex(
        _activeTab, _rowsPerSolution.isEmpty ? 1 : _rowsPerSolution.length);
    final currentSolutionTotal =
        _rowsPerSolution.isNotEmpty ? _solutionTotalCost(activeIndex) : 0.0;

    // Calculate total savings from suggestions
    double totalSavings = 0.0;
    for (final suggestion in _savingsSuggestions) {
      totalSavings += suggestion.projectedSavings;
    }

    // Net cost after savings
    final netCost = currentSolutionTotal - totalSavings;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Opportunity Savings Calculator',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const _AiTag(),
          const Spacer(),
          ElevatedButton.icon(
            onPressed:
                _isSavingsGenerating ? null : _generateSavingsSuggestions,
            icon: _isSavingsGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: const Text('Generate savings scenarios'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          'Identify cost savings opportunities for this solution. Generated savings can be subtracted from the total estimated cost.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 200,
              height: 56,
              child: TextField(
                controller: _savingsTargetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Savings target (%)',
                  hintText: 'e.g. 10',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              width: 280,
              height: 56,
              child: TextField(
                controller: _savingsNotesController,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Context notes',
                  hintText: 'Add constraints or priorities',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.payments_outlined,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text('Total benefits: ${_formatCurrencyValue(totalValue)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_savingsError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Text(_savingsError!,
                style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        if (_savingsSuggestions.isEmpty && _savingsError == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _benefitLineItems.isEmpty
                    ? 'Add benefit line items in Step 1 to enable AI savings analysis.'
                    : 'Click "Generate savings scenarios" to identify cost reduction opportunities for this solution.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ]),
          ),
        if (_savingsSuggestions.isNotEmpty) ...[
          const Text('Identified Savings Opportunities',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              for (int i = 0; i < _savingsSuggestions.length; i++)
                _savingsSuggestionTile(i, _savingsSuggestions[i]),
            ]),
          ),
          const SizedBox(height: 16),
          // Summary: Total savings to subtract from cost
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7CC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cost Summary',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estimated Solution Cost:',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700])),
                                Text(_formatCurrencyValue(currentSolutionTotal),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                              ]),
                        ),
                        const SizedBox(width: 8),
                        const Text('−',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Identified Savings:',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700])),
                                Text(_formatCurrencyValue(totalSavings),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green)),
                              ]),
                        ),
                        const SizedBox(width: 8),
                        const Text('=',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Net Cost:',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700])),
                                Text(_formatCurrencyValue(netCost),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                              ]),
                        ),
                      ]),
                    ]),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildContingencyButtons(int solutionIndex) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Text('Contingency:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          ...[10, 20, 25, 30, 35, 40].map((percent) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: () => _applyContingency(solutionIndex, percent),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child:
                      Text('$percent%', style: const TextStyle(fontSize: 11)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildInitialCostTable(int solutionIndex) {
    final rows = _rowsPerSolution[solutionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const minTableWidth = 800.0;
            final tableWidth = constraints.maxWidth < minTableWidth
                ? minTableWidth
                : constraints.maxWidth;
            
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.withOpacity(0.35))),
                      child: Row(children: [
                        SizedBox(
                          width: 300,
                          child: const Text('Item',
                              style:
                                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 150,
                          child: const Align(
                              alignment: Alignment.center,
                              child: Text('Estimated cost',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600))),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 300,
                          child: const Text('Comments',
                              style:
                                  TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(width: 36),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.withOpacity(0.25))),
                      child: Column(children: [
                        for (final r in rows) _initialItemCostRow(r),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(color: Colors.grey.withOpacity(0.2)))),
                          child: Row(children: [
                            SizedBox(
                              width: 300,
                              child: const Text('Total',
                                  style: TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 150,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  _formatCurrencyValue(_solutionTotalCost(solutionIndex)),
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(width: 300, child: const SizedBox()),
                            const SizedBox(width: 8),
                            const SizedBox(width: 36),
                          ]),
                        )
                      ]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        _buildContingencyButtons(solutionIndex),
        const SizedBox(height: 10),
        Row(children: [
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => _addInitialCostRow(solutionIndex),
            icon: const Icon(Icons.add),
            label: const Text('Add row'),
          ),
        ]),
      ],
    );
  }

  void _applyContingency(int solutionIndex, int percent) {
    if (solutionIndex < 0 || solutionIndex >= _rowsPerSolution.length) return;
    final currentTotal = _solutionTotalCost(solutionIndex);
    final contingencyAmount = currentTotal * (percent / 100);

    // Add a new row for contingency
    final row = _CostRow(currencyProvider: () => _currency);
    _attachRowDirtyListeners(row);
    row.setHorizon(_npvHorizon);
    row.itemController.text = 'Contingency ($percent%)';
    row.costController.text =
        contingencyAmount.toStringAsFixed(contingencyAmount % 1 == 0 ? 0 : 2);
    row.assumptionsController.text =
        '$percent% contingency applied to current estimated cost total of ${_formatCurrencyValue(currentTotal)}';

    setState(() {
      _rowsPerSolution[solutionIndex].add(row);
    });
    _markDirty();
  }

  void _addInitialCostRow(int solutionIndex) {
    if (solutionIndex < 0 || solutionIndex >= _rowsPerSolution.length) return;
    final row = _CostRow(currencyProvider: () => _currency);
    _attachRowDirtyListeners(row);
    row.setHorizon(_npvHorizon);
    setState(() {
      _rowsPerSolution[solutionIndex].add(row);
    });
    _markDirty();
  }

  Future<void> _removeInitialCostRow(_CostRow row) async {
    // Locate the solution index containing this row
    int foundIndex = -1;
    for (int i = 0; i < _rowsPerSolution.length; i++) {
      if (_rowsPerSolution[i].contains(row)) {
        foundIndex = i;
        break;
      }
    }
    if (foundIndex == -1) return;

    bool hasMeaningfulData() {
      final name = row.itemController.text.trim();
      final desc = row.descriptionController.text.trim();
      final assumptions = row.assumptionsController.text.trim();
      final cost = row.currentCost();
      final hasName = name.isNotEmpty && name.toLowerCase() != 'name';
      final hasDesc =
          desc.isNotEmpty && !desc.toLowerCase().startsWith('lorem ipsum');
      final hasAssumptions = assumptions.isNotEmpty;
      return hasName || hasDesc || hasAssumptions || cost > 0;
    }

    bool proceed = true;
    if (hasMeaningfulData()) {
      proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete row?'),
              content: const Text(
                  'This will remove the selected cost row. This action cannot be undone.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete')),
              ],
            ),
          ) ??
          false;
    }
    if (!proceed) return;

    setState(() {
      _rowsPerSolution[foundIndex].remove(row);
    });
    // dispose controllers of the removed row
    row.dispose();
    _refreshJustificationFor(foundIndex, force: true);
    _markDirty();
  }

  Widget _buildCategoryIdeasSection(int solutionIndex) {
    final ideasMap = _categoryIdeasPerSolution[solutionIndex];
    final hasIdeas = ideasMap.values.any((list) => list.isNotEmpty);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('AI-generated Project Value category ideas',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const _AiTag(),
          const Spacer(),
          TextButton.icon(
            onPressed: _isGenerating
                ? null
                : () =>
                    _populateCategoriesFromAi(targetSolution: solutionIndex),
            icon: const Icon(Icons.refresh),
            label: const Text('Regenerate ideas'),
          ),
        ]),
        const SizedBox(height: 8),
        if (!hasIdeas)
          Text(
              'Use Populate categories (AI) to see tailored ideas derived from earlier steps.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]))
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final field in _projectValueFields) ...[
                if ((ideasMap[field.key] ?? const []).isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Text(field.value,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in ideasMap[field.key]!.take(20))
                        ActionChip(
                          label: Text(
                              '${item.item}${item.estimatedCost > 0 ? ' • ${_formatCurrencyValue(item.estimatedCost)}' : ''}',
                              style: const TextStyle(
                                  fontSize: 11.5, fontWeight: FontWeight.w600)),
                          avatar: const Icon(Icons.add, size: 16),
                          onPressed: () => _applyIdeaToCategory(
                              solutionIndex, field.key, item),
                        ),
                    ],
                  ),
                ]
              ],
            ],
          ),
      ]),
    );
  }

  // Step 3: Profitability analysis main table for all solutions
  Widget _buildProfitabilitySummaryTable() {
    final count = _rowsPerSolution.length;
    if (count == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2))),
        child: const Text(
            'Add one or more solutions to see ROI, NPV, IRR and DCFR results.'),
      );
    }
    final horizon = _npvHorizon;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Profitability analysis',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.35))),
          child: Row(children: [
            const Expanded(
                flex: 4,
                child: Text('Solution',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            const Expanded(
                flex: 2,
                child: Center(
                    child: Text('ROI',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)))),
            const SizedBox(width: 16),
            Expanded(
                flex: 2,
                child: Align(
                    alignment: Alignment.center,
                    child: Text('NPV ($horizon-yr)',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)))),
            const SizedBox(width: 16),
            const Expanded(
                flex: 2,
                child: Center(
                    child: Text('IRR',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)))),
            const SizedBox(width: 16),
            const Expanded(
                flex: 2,
                child: Center(
                    child: Text('DCFR',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)))),
          ]),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withOpacity(0.25))),
          child: Column(children: [
            for (int i = 0; i < count; i++) _profitabilityRow(i),
          ]),
        ),
      ]),
    );
  }

  Widget _profitabilityRow(int index) {
    final solutionLabel = _solutionTitle(index);
    // Only use benefits if Initial Project Value is set in Step 1
    final snapshot = _valueSetupInvestmentSnapshot();
    final double benefits = snapshot != null ? snapshot.totalBenefits : 0;
    final double cost = _initialCostEstimateTotalFor(index) > 0
        ? _initialCostEstimateTotalFor(index)
        : _solutionTotalCost(index);
    // Calculate ROI: ((Benefits - Cost) / Cost) * 100
    final double roiPct =
        (cost > 0 && benefits > 0) ? ((benefits - cost) / cost) * 100 : 0.0;

    // Calculate NPV properly using discount rate and time periods
    double npv = 0;
    if (benefits > 0 && cost > 0 && _npvHorizon > 0) {
      // Assume benefits are received evenly over the horizon period
      final annualBenefit = benefits / _npvHorizon;
      final cashflows = <double>[-cost]; // Initial investment (negative)
      for (int year = 1; year <= _npvHorizon; year++) {
        cashflows.add(annualBenefit); // Annual benefits
      }
      npv = Finance.npv(_discountRate, cashflows);
    } else {
      // Fallback to stored NPV from cost rows if available
      npv = _solutionTotalNpv(index);
    }

    // Calculate Payback Period: Time to recover initial investment
    double paybackPeriod = 0;
    if (cost > 0 && benefits > 0 && _npvHorizon > 0) {
      final annualBenefit = benefits / _npvHorizon;
      if (annualBenefit > 0) {
        paybackPeriod = cost / annualBenefit; // Years to payback
      }
    }
    // IRR using Finance utility with cashflows distributed over time
    // Only calculate if Initial Project Value is set
    double irr = 0;
    if (snapshot != null && cost > 0 && benefits > 0 && _npvHorizon > 0) {
      // Distribute benefits evenly over the horizon period
      final annualBenefit = benefits / _npvHorizon;
      final flows = <double>[-cost]; // Initial investment (negative)
      for (int year = 1; year <= _npvHorizon; year++) {
        flows.add(annualBenefit); // Annual benefits
      }
      final guess = benefits > cost ? 0.1 : -0.1;
      final r = Finance.irr(flows, guess: guess);
      if (r.isFinite && r.isFinite) {
        irr = r;
      } else {
        // Fallback to CAGR approximation if IRR didn't converge
        irr = math.pow(benefits / cost, 1 / _npvHorizon) - 1;
      }
    }
    // DCF is PV of benefits; with our inputs, approximate as NPV + upfront cost
    final double dcf = npv + cost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Colors.grey.withOpacity(index == 0 ? 0 : 0.2)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            flex: 4,
            child: Text(solutionLabel, style: const TextStyle(fontSize: 13))),
        Expanded(
            flex: 2,
            child: Align(
                alignment: Alignment.center,
                child: Text(_formatPercentValue(roiPct),
                    textAlign: TextAlign.center))),
        const SizedBox(width: 16),
        Expanded(
            flex: 2,
            child: Align(
                alignment: Alignment.center,
                child: Text(_formatCurrencyValue(npv)))),
        const SizedBox(width: 16),
        Expanded(
            flex: 2,
            child: Align(
                alignment: Alignment.center,
                child: Text(_formatPercentValue(irr * 100),
                    textAlign: TextAlign.center))),
        const SizedBox(width: 16),
        Expanded(
            flex: 2,
            child: Align(
                alignment: Alignment.center,
                child: Text(_formatCurrencyValue(dcf),
                    textAlign: TextAlign.center))),
      ]),
    );
  }

  Widget _valuesGainedCard(int index, double totalBenefits) {
    // Per requirement: use the total from the Initial cost estimate table (itemized rows)
    // for each solution. If there are no rows yet, fall back to any category total.
    final primaryCost = _solutionTotalCost(index);
    final fallbackCost = _initialCostEstimateTotalFor(index);
    final cost = primaryCost > 0 ? primaryCost : fallbackCost;
    // Only calculate net value if Initial Project Value is set
    final snapshot = _valueSetupInvestmentSnapshot();
    final double effectiveBenefits = snapshot != null ? totalBenefits : 0.0;
    final net = effectiveBenefits - cost;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_solutionTitle(index),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _summaryMetric(
                  label: 'Project Value',
                  value: _formatCurrencyValue(effectiveBenefits))),
          const SizedBox(width: 12),
          Expanded(
              child: _summaryMetric(
                  label: 'Initial cost', value: _formatCurrencyValue(cost))),
          const SizedBox(width: 12),
          Expanded(
              child: _summaryMetric(
                  label: 'Net value', value: _formatCurrencyValue(net))),
        ]),
      ]),
    );
  }

  Widget _savingsSuggestionTile(
      int index, AiBenefitSavingsSuggestion suggestion) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: Colors.grey.withOpacity(index == 0 ? 0 : 0.2))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${index + 1}. ${suggestion.lever}',
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${suggestion.confidence} confidence',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ]),
        const SizedBox(height: 4),
        Text(
          suggestion.recommendation,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            Chip(
              avatar: const Icon(Icons.savings_outlined, size: 16),
              label: Text(
                  'Projected savings: ${_formatCurrencyValue(suggestion.projectedSavings)}'),
            ),
            Chip(
              avatar: const Icon(Icons.schedule_outlined, size: 16),
              label: Text(
                  'Timeframe: ${suggestion.timeframe.isEmpty ? 'TBD' : suggestion.timeframe}'),
            ),
          ],
        ),
        if (suggestion.rationale.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            suggestion.rationale,
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          ),
        ],
      ]),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: ExpandingTextField(
        controller: _notesController,
        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        decoration: const InputDecoration(
          hintText:
              'Capture assumptions, discount rates, or stakeholder feedback here...',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        minLines: 1,
      ),
    );
  }

  Widget _buildMetricToolbar(
      {required bool isMobile, required String horizonLabel}) {
    final horizons = [1, 3, 5, 10];
    final toggleButtons = ToggleButtons(
      isSelected: horizons.map((year) => _npvHorizon == year).toList(),
      onPressed: (index) {
        final selectedYear = horizons[index];
        setState(() {
          _npvHorizon = selectedYear;
          for (final list in _rowsPerSolution) {
            for (final row in list) {
              row.setHorizon(selectedYear);
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      selectedColor: Colors.black,
      fillColor: const Color(0xFFFFD700),
      constraints: const BoxConstraints(minHeight: 34, minWidth: 54),
      children: horizons
          .map((year) => Text('$year yr', style: const TextStyle(fontSize: 13)))
          .toList(),
    );

    final generateButton = ElevatedButton.icon(
      onPressed: _isGenerating ? null : _generateCostBreakdown,
      icon: const Icon(Icons.bolt_outlined, size: 18),
      label: const Text('Regenerate with AI'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
    );

    if (isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Financial metric horizon',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          toggleButtons,
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Tooltip(
            message:
                'NPV values update for the selected horizon so each solution compares on equal time frames.',
            child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          generateButton,
        ]),
        const SizedBox(height: 6),
        Text('Current view: $horizonLabel cashflows across every solution.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Financial metric horizon',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        toggleButtons,
        const SizedBox(width: 12),
        const Tooltip(
          message:
              'NPV values update for the selected horizon so each solution compares on equal time frames.',
          child: Icon(Icons.info_outline, size: 18, color: Colors.grey),
        ),
        const Spacer(),
        generateButton,
      ]),
      const SizedBox(height: 6),
      Text('Current view: $horizonLabel cashflows across every solution.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ]);
  }

  Widget _buildSolutionSummaries({required bool isMobile}) {
    final cardCount = _rowsPerSolution.length;
    if (cardCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: const Text(
            'Add at least one potential solution to start modelling costs and benefits.'),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Solution cost snapshots',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        const _AiTag(),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'AI can populate or refresh the cost structure for each option; edit any line items directly in the breakdown below.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (context, constraints) {
        const spacing = 16.0;
        final viewportWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final safeWidth = viewportWidth <= 0
            ? MediaQuery.of(context).size.width
            : viewportWidth;
        final singleColumn = isMobile || safeWidth < 760;
        final computedColumns = (safeWidth / (340 + spacing)).floor();
        final int columns = singleColumn
            ? 1
            : computedColumns < 1
                ? 1
                : computedColumns > 3
                    ? 3
                    : computedColumns;
        final double tileWidth = singleColumn
            ? safeWidth
            : ((safeWidth - (spacing * (columns - 1))) / columns)
                .clamp(280.0, 400.0);
        return Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (int i = 0; i < cardCount; i++)
                SizedBox(width: tileWidth, child: _solutionSummaryCard(i)),
            ],
          ),
        );
      }),
    ]);
  }

  Widget _solutionSummaryCard(int index) {
    final hasSolutions = index < widget.solutions.length;
    final AiSolutionItem? solution =
        hasSolutions ? widget.solutions[index] : null;
    final title = (solution?.title ?? '').trim().isNotEmpty
        ? solution!.title
        : 'Potential Solution ${index + 1}';
    final description = (solution?.description ?? '').trim().isNotEmpty
        ? solution!.description
        : 'Describe how this solution creates value so ROI and NPV have clear context.';
    final valueSetupSnapshot = _valueSetupInvestmentSnapshot();
    // Per requirement: Estimated cost must reflect the sum of the 'Estimated cost'
    // values entered in the 'Initial cost estimate' table for this solution.
    // We therefore prioritise the itemized table total; if missing, fall back to
    // any legacy/category totals.
    final double initialItemsTotal = _solutionTotalCost(index);
    final double fallbackCategoryTotal = _initialCostEstimateTotalFor(index);
    final double totalCost =
        initialItemsTotal > 0 ? initialItemsTotal : fallbackCategoryTotal;
    // Only calculate NPV and ROI if Initial Project Value is set
    final double totalNpv =
        valueSetupSnapshot != null ? (valueSetupSnapshot.npv ?? 0) : 0;
    final double avgRoi =
        valueSetupSnapshot != null ? (valueSetupSnapshot.averageRoi ?? 0) : 0;
    final int summaryCount =
        valueSetupSnapshot?.benefitLineItemCount ?? _solutionItemCount(index);
    final bool usesValueSetup = valueSetupSnapshot != null;
    final bool hasValueSetupBenefits =
        valueSetupSnapshot?.hasBenefitSignals ?? false;
    final helper = usesValueSetup
        ? (hasValueSetupBenefits
            ? 'Derived from Project Value baseline and monetised benefit entries. Adjust Step 1 to update this snapshot.'
            : 'Project Value baseline anchors this snapshot. Add monetised benefits in Step 1 to unlock ROI and NPV context.')
        : totalCost > 0
            ? 'AI generated total based on the current cost items. Adjust any line item to update this summary.'
            : 'Use AI or add cost items below to build this investment profile.';
    final isLoading = _solutionLoading.contains(index);
    final contextData = _contextFor(index);
    final costRange =
        valueSetupSnapshot?.costRange ?? _solutionCostRange(index);
    final assumptionHighlights = _assumptionHighlights(index);
    final driverHighlights = _topCostDrivers(index);
    final justification = contextData.justificationController.text.trim();
    final totalRows = index >= 0 && index < _rowsPerSolution.length
        ? _rowsPerSolution[index].length
        : 0;
    final summaryLine = usesValueSetup
        ? (hasValueSetupBenefits
            ? '$summaryCount benefit line items captured • Update Step 1 to recalc ROI/NPV automatically.'
            : 'Project Value baseline captured • Add monetised benefits in Step 1 to enrich ROI and NPV context.')
        : '$summaryCount/$totalRows cost items tracked • ROI/NPV adjust automatically as you edit line items.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (isLoading)
            const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4)),
        ]),
        const SizedBox(height: 14),
        const Text('Estimated cost',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(_formatCurrencyValue(totalCost),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        if (costRange != null) ...[
          const SizedBox(height: 4),
          Text(
              'Range: ${_formatCurrencyValue(costRange.lower)} – ${_formatCurrencyValue(costRange.upper)}',
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 4),
        Text(helper, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: _summaryMetric(
                  label: 'NPV ($_npvHorizon-year)',
                  value: _formatCurrencyValue(totalNpv))),
          const SizedBox(width: 12),
          Expanded(
              child: _summaryMetric(
                  label: 'Average ROI', value: _formatPercentValue(avgRoi))),
        ]),
        const SizedBox(height: 10),
        Text(summaryLine,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 16),
        Divider(color: Colors.grey.withOpacity(0.2), height: 1),
        const SizedBox(height: 12),
        const Text('Cost assumptions',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final narrow = constraints.maxWidth < 540;
          final selectors = [
            _assumptionSelector(
              label: 'Resources',
              value: contextData.resourceIndex,
              options: _resourceOptions,
              onChanged: (value) {
                setState(() {
                  contextData.resourceIndex = value;
                  _refreshJustificationFor(index);
                });
                _markDirty();
              },
            ),
            _assumptionSelector(
              label: 'Timeline',
              value: contextData.timelineIndex,
              options: _timelineOptions,
              onChanged: (value) {
                setState(() {
                  contextData.timelineIndex = value;
                  _refreshJustificationFor(index);
                });
                _markDirty();
              },
            ),
            _assumptionSelector(
              label: 'Complexity',
              value: contextData.complexityIndex,
              options: _complexityOptions,
              onChanged: (value) {
                setState(() {
                  contextData.complexityIndex = value;
                  _refreshJustificationFor(index);
                });
                _markDirty();
              },
            ),
          ];
          if (narrow) {
            return Column(children: [
              for (final selector in selectors) ...[
                selector,
                const SizedBox(height: 10),
              ],
            ]);
          }
          // Use Flexible to prevent overflow in Row
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (int i = 0; i < selectors.length; i++) ...[
              Flexible(
                child: selectors[i],
                flex: 1,
              ),
              if (i != selectors.length - 1) const SizedBox(width: 12),
            ],
          ]);
        }),
        const SizedBox(height: 8),
        Text('AI uses these assumptions when refreshing the estimate.',
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 12),
        if (assumptionHighlights.isNotEmpty) ...[
          const Text('Assumption snapshot',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          for (final highlight in assumptionHighlights)
            _costDriverBullet(highlight),
          const SizedBox(height: 12),
        ],
        const Text('Drivers & justification',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (driverHighlights.isNotEmpty) ...[
          for (final driver in driverHighlights) _costDriverBullet(driver),
          if (justification.isNotEmpty) const SizedBox(height: 6),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
                'Add or regenerate cost items to surface AI-driven cost drivers.',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ),
        ExpandingTextField(
          controller: contextData.justificationController,
          minLines: 2,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          decoration: InputDecoration(
            hintText:
                'Explain why this investment level is appropriate (e.g., resourcing, integrations, governance).',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
        const SizedBox(height: 12),
        // Wrap buttons in Flexible/Expanded to prevent overflow
        LayoutBuilder(builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 300;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: (!hasSolutions || isLoading)
                      ? null
                      : () => _generateCostBreakdownForSolution(index),
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_fix_high_outlined, size: 18),
                  label: const Text('Refresh with AI'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _rowsPerSolution.isEmpty
                      ? null
                      : () => _showBreakdownFor(index),
                  child: const Text('Open breakdown'),
                ),
              ],
            );
          }
          return Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (!hasSolutions || isLoading)
                    ? null
                    : () => _generateCostBreakdownForSolution(index),
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_fix_high_outlined, size: 18),
                label: const Text('Refresh with AI'),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _rowsPerSolution.isEmpty
                  ? null
                  : () => _showBreakdownFor(index),
              child: const Text('Open breakdown'),
            ),
          ]);
        }),
      ]),
    );
  }

  void _showBreakdownFor(int index) {
    if (_rowsPerSolution.isEmpty) return;
    final safeIndex = index < 0
        ? 0
        : index >= _rowsPerSolution.length
            ? _rowsPerSolution.length - 1
            : index;
    setState(() {
      _activeTab = safeIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _tablesSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _summaryMetric(
      {required String label, required String value, String? helper}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      if (helper != null) ...[
        const SizedBox(height: 2),
        Text(helper, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    ]);
  }

  _SolutionCostContext _contextFor(int index) {
    var safeIndex = index;
    if (safeIndex < 0) safeIndex = 0;
    while (safeIndex >= _solutionContexts.length) {
      final context = _SolutionCostContext();
      context.justificationController.addListener(_markDirty);
      _solutionContexts.add(context);
    }
    return _solutionContexts[safeIndex];
  }

  int _boundedIndex(int value, int length) {
    if (length <= 0) return 0;
    if (value < 0) return 0;
    if (value >= length) return length - 1;
    return value;
  }

  Widget _assumptionSelector(
      {required String label,
      required int value,
      required List<_QualitativeOption> options,
      required ValueChanged<int> onChanged}) {
    final boundedValue = _boundedIndex(value, options.length);
    return DropdownButtonFormField<int>(
      initialValue: boundedValue,
      itemHeight: null, // allow multi-line menu entries without overflow
      menuMaxHeight: 320,
      isExpanded: true, // Prevent overflow by expanding to fill available space
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      items: [
        for (int i = 0; i < options.length; i++)
          DropdownMenuItem<int>(
            value: i,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(options[i].label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                const SizedBox(height: 2),
                Text(options[i].detail,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2),
              ],
            ),
          ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  Widget _costDriverBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.circle, size: 6, color: Colors.grey),
        ),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 11.5, color: Colors.grey[700]))),
      ]),
    );
  }

  List<String> _assumptionHighlights(int index) {
    if (index < 0 || index >= _solutionContexts.length) return const [];
    final context = _solutionContexts[index];
    final resource = _resourceOptions[
        _boundedIndex(context.resourceIndex, _resourceOptions.length)];
    final timeline = _timelineOptions[
        _boundedIndex(context.timelineIndex, _timelineOptions.length)];
    final complexity = _complexityOptions[
        _boundedIndex(context.complexityIndex, _complexityOptions.length)];
    return [
      'Resourcing: ${resource.label} — ${resource.detail}.',
      'Timeline: ${timeline.label} — ${timeline.detail}.',
      'Complexity: ${complexity.label} — ${complexity.detail}.',
    ];
  }

  _CostRange? _solutionCostRange(int index) {
    final total = _solutionTotalCost(index);
    if (total <= 0) return null;
    final lower = total * 0.85;
    final upper = total * 1.15;
    return _CostRange(lower: lower, upper: upper);
  }

  List<String> _topCostDrivers(int index) {
    if (index < 0 || index >= _rowsPerSolution.length) return const [];
    final rows = _rowsPerSolution[index];
    final entries = <MapEntry<String, double>>[];
    for (final row in rows) {
      final cost = row.currentCost();
      if (cost <= 0) continue;
      final name = row.itemController.text.trim();
      final label = name.isEmpty || name == 'Name' ? 'Item' : name;
      entries.add(MapEntry(label, cost));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(3)
        .map((e) => '${e.key} • ${_formatCurrencyValue(e.value)}')
        .toList();
  }

  void _refreshJustificationFor(int index, {bool force = false}) {
    if (index < 0 || index >= _solutionContexts.length) return;
    final context = _solutionContexts[index];
    final resource = _resourceOptions[
        _boundedIndex(context.resourceIndex, _resourceOptions.length)];
    final timeline = _timelineOptions[
        _boundedIndex(context.timelineIndex, _timelineOptions.length)];
    final complexity = _complexityOptions[
        _boundedIndex(context.complexityIndex, _complexityOptions.length)];
    final drivers = _topCostDrivers(index);
    final buffer = StringBuffer()
      ..write(
          'Resourcing requires ${resource.detail.toLowerCase()} (${resource.label.toLowerCase()}). ')
      ..write(
          'Delivery timeline: ${timeline.detail.toLowerCase()} (${timeline.label}). ')
      ..write(
          'Complexity: ${complexity.detail.toLowerCase()} (${complexity.label}).');
    if (drivers.isNotEmpty) {
      buffer.write(' Major cost drivers: ${drivers.join('; ')}.');
    }
    final narrative = buffer.toString().trim();
    final isEmpty = context.justificationController.text.trim().isEmpty;
    if (force || isEmpty || context.autoGenerated) {
      context.updateJustification(narrative);
    }
  }

  Widget _buildDetailedBreakdown(
      {required bool isMobile, required String horizonLabel}) {
    final tabsCount = _rowsPerSolution.length;
    final int activeIndex;
    if (tabsCount == 0) {
      activeIndex = 0;
    } else if (_activeTab >= tabsCount) {
      activeIndex = tabsCount - 1;
    } else if (_activeTab < 0) {
      activeIndex = 0;
    } else {
      activeIndex = _activeTab;
    }

    return Container(
      key: _tablesSectionKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header actions: currency only. Tabs removed per request.
        Row(children: [
          const Spacer(),
          _currencyDropdown(),
        ]),
        const SizedBox(height: 12),
        if (tabsCount > 0) ...[
          for (int i = 0; i < tabsCount; i++) ...[
            const SizedBox(height: 12),
            Text(_solutionTitle(i),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _tableForIndex(i, isMobile: isMobile, horizonLabel: horizonLabel),
          ]
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: const Text(
                'Add a solution to unlock the ROI and NPV breakdown.'),
          ),
        ],
      ]),
    );
  }

  Widget _errorBanner(String message, {VoidCallback? onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.red, fontSize: 12))),
        if (onRetry != null)
          TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(fontSize: 12))),
      ]),
    );
  }

  String _formatCurrencyValue(double value) {
    final prefix = value < 0 ? '-' : '';
    final formatted = _formatNumber(value.abs());
    return '$prefix$_currency $formatted';
  }

  String _formatNumber(double value) {
    final abs = value.abs();
    if (abs >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(2)}B';
    }
    if (abs >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (abs >= 1000) {
      return _formatWithGrouping(value, 0);
    }
    return _formatWithGrouping(value, 2);
  }

  String _formatWithGrouping(double value, int decimals) {
    final sign = value < 0 ? '-' : '';
    final abs = value.abs();
    final fixed = abs.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final reverseIndex = intPart.length - i - 1;
      buffer.write(intPart[i]);
      if (reverseIndex % 3 == 0 && i != intPart.length - 1) buffer.write(',');
    }
    final decimalPart = decimals > 0 ? '.${parts[1]}' : '';
    return '$sign$buffer$decimalPart';
  }

  String _formatPercentValue(double value) {
    if (!value.isFinite) return '0.0%';
    return '${value.toStringAsFixed(1)}%';
  }

  double _currencyFactor(String from, String to) {
    final fromRate = _currencyRates[from] ?? 1.0;
    final toRate = _currencyRates[to] ?? 1.0;
    if (fromRate <= 0) return 1.0;
    return toRate / fromRate;
  }

  void _applyCurrencyConversion(double factor) {
    if (factor == 1.0) return;
    // Project value baseline
    final pv = _projectValueAmountController.text.trim();
    if (pv.isNotEmpty) {
      final n = _parseCurrencyInput(pv) * factor;
      _projectValueAmountController.text =
          n.toStringAsFixed(n % 1 == 0 ? 0 : 2);
    }
    // Benefit line items (unit values only)
    for (final entry in _benefitLineItems) {
      final uv =
          _BenefitLineItemEntry._readDouble(entry.unitValueController.text) *
              factor;
      entry.unitValueController.text = uv.toStringAsFixed(uv % 1 == 0 ? 0 : 2);
    }
    // Category estimate costs
    for (final map in _categoryCostsPerSolution) {
      for (final entry in map.values) {
        final txt = entry.costController.text.trim();
        if (txt.isEmpty) continue;
        final n = _parseCurrencyInput(txt) * factor;
        entry.costController.text = n.toStringAsFixed(n % 1 == 0 ? 0 : 2);
      }
    }
    // Detailed line items and baselines
    for (final list in _rowsPerSolution) {
      for (final row in list) {
        row.convertCurrency(factor);
      }
    }
  }

  double _solutionTotalCost(int index) {
    if (index >= _rowsPerSolution.length) return 0;
    return _rowsPerSolution[index]
        .fold<double>(0, (sum, row) => sum + row.currentCost());
  }

  double _solutionTotalNpv(int index) {
    if (index >= _rowsPerSolution.length) return 0;
    return _rowsPerSolution[index]
        .fold<double>(0, (sum, row) => sum + row.currentNpv());
  }

  double _solutionAverageRoi(int index) {
    if (index >= _rowsPerSolution.length) return 0;
    double total = 0;
    int count = 0;
    for (final row in _rowsPerSolution[index]) {
      final roi = row.currentRoi();
      final hasData = row.currentCost() > 0 || roi != 0;
      if (roi.isFinite && hasData) {
        total += roi;
        count++;
      }
    }
    return count == 0 ? 0 : total / count;
  }

  int _solutionItemCount(int index) {
    if (index >= _rowsPerSolution.length) return 0;
    int count = 0;
    for (final row in _rowsPerSolution[index]) {
      final hasName = row.itemController.text.trim().isNotEmpty &&
          row.itemController.text.trim() != 'Name';
      final hasCost = row.currentCost() > 0;
      if (hasName || hasCost) count++;
    }
    return count;
  }

  String _buildCostContextNotes({int? forSolution}) {
    final buffer = StringBuffer();

    // Get project data from provider
    final provider = ProjectDataInherited.maybeOf(context);
    final projectData = provider?.projectData;

    // Add Business Case context
    if (projectData != null) {
      if (projectData.businessCase.isNotEmpty) {
        buffer.write('Business Case: ${projectData.businessCase}. ');
      }

      // Add Solution Title and Description
      if (projectData.solutionTitle.isNotEmpty) {
        buffer.write('Project: ${projectData.solutionTitle}. ');
      }
      if (projectData.solutionDescription.isNotEmpty) {
        buffer.write('Description: ${projectData.solutionDescription}. ');
      }

      // Add Project Objective
      if (projectData.projectObjective.isNotEmpty) {
        buffer.write('Objective: ${projectData.projectObjective}. ');
      }

      // Add Work Breakdown Structure items as potential cost categories
      final wbsItems = <String>[];
      for (final goalWorkList in projectData.goalWorkItems) {
        for (final workItem in goalWorkList) {
          if (workItem.description.isNotEmpty) {
            wbsItems.add(workItem.description);
          }
        }
      }
      if (wbsItems.isNotEmpty) {
        buffer.write('Work breakdown items: ${wbsItems.take(15).join(', ')}. ');
      }

      // Add Risks that might require mitigation costs
      final risks = <String>[];
      for (final solutionRisk in projectData.solutionRisks) {
        for (final risk in solutionRisk.risks) {
          if (risk.isNotEmpty) {
            risks.add('${solutionRisk.solutionTitle}: $risk');
          }
        }
      }
      if (risks.isNotEmpty) {
        buffer.write(
            'Risk considerations (may require mitigation costs): ${risks.take(10).join('; ')}. ');
      }

      // Add IT Considerations
      if (projectData.itConsiderationsData != null) {
        final itData = projectData.itConsiderationsData!;
        if (itData.notes.isNotEmpty) {
          buffer.write('IT considerations: ${itData.notes}. ');
        }
        for (final solutionIT in itData.solutionITData) {
          if (solutionIT.coreTechnology.isNotEmpty) {
            buffer.write(
                'Technology for ${solutionIT.solutionTitle}: ${solutionIT.coreTechnology}. ');
          }
        }
      }

      // Add Infrastructure Considerations
      if (projectData.infrastructureConsiderationsData != null) {
        final infraData = projectData.infrastructureConsiderationsData!;
        if (infraData.notes.isNotEmpty) {
          buffer.write('Infrastructure considerations: ${infraData.notes}. ');
        }
        for (final solutionInfra in infraData.solutionInfrastructureData) {
          if (solutionInfra.majorInfrastructure.isNotEmpty) {
            buffer.write(
                'Infrastructure for ${solutionInfra.solutionTitle}: ${solutionInfra.majorInfrastructure}. ');
          }
        }
      }

      // Add Core Stakeholders (external stakeholders may have associated costs)
      if (projectData.coreStakeholdersData != null) {
        final stakeholderData = projectData.coreStakeholdersData!;
        if (stakeholderData.notes.isNotEmpty) {
          buffer.write('Stakeholder notes: ${stakeholderData.notes}. ');
        }
        for (final solutionStakeholder
            in stakeholderData.solutionStakeholderData) {
          if (solutionStakeholder.notableStakeholders.isNotEmpty) {
            buffer.write(
                'Stakeholders for ${solutionStakeholder.solutionTitle}: ${solutionStakeholder.notableStakeholders}. ');
          }
        }
      }

      // Add Team Members (personnel costs)
      if (projectData.teamMembers.isNotEmpty) {
        final teamRoles = projectData.teamMembers
            .map((m) => m.role.isEmpty ? m.name : m.role)
            .where((r) => r.isNotEmpty)
            .toList();
        if (teamRoles.isNotEmpty) {
          buffer.write('Team composition: ${teamRoles.take(15).join(', ')}. ');
        }
      }

      // Add Front End Planning data
      final fepData = projectData.frontEndPlanning;
      final fepNotes = <String>[];
      if (fepData.requirements.isNotEmpty) {
        fepNotes.add('Requirements: ${fepData.requirements}');
      }
      if (fepData.risks.isNotEmpty) {
        fepNotes.add('Planning risks: ${fepData.risks}');
      }
      if (fepData.opportunities.isNotEmpty) {
        fepNotes.add('Opportunities: ${fepData.opportunities}');
      }
      if (fepData.technology.isNotEmpty) {
        fepNotes.add('Technology: ${fepData.technology}');
      }
      if (fepData.infrastructure.isNotEmpty) {
        fepNotes.add('Infrastructure: ${fepData.infrastructure}');
      }
      if (fepData.contracts.isNotEmpty) {
        fepNotes.add('Contracts: ${fepData.contracts}');
      }
      if (fepData.procurement.isNotEmpty) {
        fepNotes.add('Procurement: ${fepData.procurement}');
      }
      if (fepNotes.isNotEmpty) {
        buffer.write('Front-end planning: ${fepNotes.take(5).join('; ')}. ');
      }
    }

    // Add current cost analysis notes
    final amount = _projectValueAmountController.text.trim();
    if (amount.isNotEmpty) {
      buffer.write('Project value baseline: $amount $_currency. ');
    }
    final benefitSnippets = <String>[];
    for (final field in _projectValueFields) {
      final benefit = _projectValueBenefitControllers[field.key]?.text.trim();
      if (benefit != null && benefit.isNotEmpty) {
        benefitSnippets.add('${field.value}: $benefit');
      }
    }
    if (benefitSnippets.isNotEmpty) {
      buffer.write('Benefits: ${benefitSnippets.join(' | ')}. ');
    }
    final notes = _notesController.text.trim();
    if (notes.isNotEmpty) {
      buffer.write('Analyst notes: $notes. ');
    }

    // Add solution-specific context
    final indexes = <int>[];
    if (forSolution != null) {
      if (forSolution >= 0 &&
          forSolution < _solutionContexts.length &&
          forSolution < widget.solutions.length) {
        indexes.add(forSolution);
      }
    } else {
      for (int i = 0;
          i < widget.solutions.length && i < _solutionContexts.length;
          i++) {
        indexes.add(i);
      }
    }
    for (final idx in indexes) {
      final context = _contextFor(idx);
      final resource = _resourceOptions[
          _boundedIndex(context.resourceIndex, _resourceOptions.length)];
      final timeline = _timelineOptions[
          _boundedIndex(context.timelineIndex, _timelineOptions.length)];
      final complexity = _complexityOptions[
          _boundedIndex(context.complexityIndex, _complexityOptions.length)];
      final solutionTitle = _solutionTitle(idx);
      buffer.write(
          ' Solution "$solutionTitle": ${resource.aiHint} ${timeline.aiHint} ${complexity.aiHint}');
      final narrative = context.justificationController.text.trim();
      if (narrative.isNotEmpty) {
        buffer.write(' Cost drivers: $narrative');
      }
      buffer.write('.');
    }
    return buffer.toString().trim();
  }

  // Treat these five benefit pillar labels as non-items so they never appear
  // under the 'Item' column in Initial cost estimate.
  bool _isProjectValueCategoryLabel(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;
    for (final entry in _projectValueFields) {
      if (entry.value.toLowerCase() == t) return true;
    }
    return false;
  }

  void _applyCostItemsToRows(int index, List<AiCostItem> items) {
    if (index < 0 || index >= _rowsPerSolution.length) return;
    // Ensure we only place true cost items, not generic benefit pillar labels
    final filtered = items
        .where((it) => !_isProjectValueCategoryLabel(it.item))
        .toList(growable: false);
    // Ensure capacity up to number of items (cap at 20 for usability)
    final targetLen = filtered.length.clamp(0, 20);
    while (_rowsPerSolution[index].length < targetLen) {
      final newRow = _CostRow(currencyProvider: () => _currency);
      _attachRowDirtyListeners(newRow);
      _rowsPerSolution[index].add(newRow);
    }
    final rows = _rowsPerSolution[index];
    for (int j = 0; j < rows.length; j++) {
      final row = rows[j];
      if (j < targetLen) {
        final it = filtered[j];
        row.itemController.text = it.item.isEmpty ? 'Name' : it.item;
        row.descriptionController.text = it.description.isEmpty
            ? 'Lorem ipsum  Lorem ipsum  Lorem ipsum  Lorem ipsum  Lorem ipsum...'
            : it.description;
        row.applyBaseline(
            cost: it.estimatedCost,
            roiPercent: it.roiPercent,
            npvByYears: it.npvByYear);
        row.setHorizon(_npvHorizon);
      } else if (filtered.isNotEmpty) {
        row.applyBaseline(
            cost: 0,
            roiPercent: 0,
            npvByYears: const {3: 0.0, 5: 0.0, 10: 0.0});
        row.setHorizon(_npvHorizon);
      }
    }
    _refreshJustificationFor(index, force: true);
  }

  // Categorize a cost item into a Project Value category using simple keyword heuristics
  String _categoryForItem(AiCostItem it) {
    final text = ('${it.item} ${it.description}').toLowerCase();
    bool hasAny(List<String> keys) => keys.any((k) => text.contains(k));
    if (hasAny([
      'revenue',
      'sales',
      'uplift',
      'growth',
      'gross margin',
      'pricing',
      'income'
    ])) {
      return 'revenue';
    }
    if (hasAny(['saving', 'cost avoid', 'not buying', 'reduction'])) {
      return 'cost_saving';
    }
    if (hasAny([
      'efficien',
      'automation',
      'cycle',
      'throughput',
      'waste',
      'rework',
      'opex',
      'maintenance',
      'operational'
    ])) {
      return 'ops_efficiency';
    }
    if (hasAny([
      'manpower',
      'hours',
      'salary',
      'time sav',
      'productive',
      'headcount'
    ])) {
      return 'productivity';
    }
    if (hasAny([
      'regulator',
      'compliance',
      'audit',
      'gdpr',
      'hipaa',
      'sox',
      'policy',
      'penalty'
    ])) {
      return 'regulatory_compliance';
    }
    if (hasAny([
      'process',
      'workflow',
      'time-to-market',
      'quality',
      'error',
      'improvement'
    ])) {
      return 'process_improvement';
    }
    if (hasAny(
        ['brand', 'reputation', 'marketing', 'nps', 'image', 'perception'])) {
      return 'brand_image';
    }
    if (hasAny(['stakeholder', 'shareholder', 'commitment', 'investor'])) {
      return 'stakeholder_commitment';
    }
    return 'other';
  }

  void _applyCategoryEstimatesFromItems(
      int solutionIndex, List<AiCostItem> items) {
    if (solutionIndex < 0 ||
        solutionIndex >= _categoryCostsPerSolution.length) {
      return;
    }
    final map = _categoryCostsPerSolution[solutionIndex];
    // reset existing estimates only if empty to not clobber user edits
    final totals = <String, double>{
      for (final f in _projectValueFields) f.key: 0
    };
    final notes = <String, List<String>>{
      for (final f in _projectValueFields) f.key: []
    };
    final ideas = _categoryIdeasPerSolution[solutionIndex];
    // clear and repopulate ideas
    for (final k in ideas.keys.toList()) {
      ideas[k] = [];
    }
    for (final it in items) {
      final key = _categoryForItem(it);
      totals[key] = (totals[key] ?? 0) +
          (it.estimatedCost.isFinite ? it.estimatedCost : 0);
      notes[key] = [...(notes[key] ?? const []), it.item];
      ideas[key] = [...(ideas[key] ?? const []), it];
    }
    // apply into controllers if their fields are blank or numeric zero
    for (final entry in map.entries) {
      final key = entry.key;
      final costCtrl = entry.value.costController;
      final noteCtrl = entry.value.notesController;
      final hasUserCost = (costCtrl.text.trim().isNotEmpty) &&
          (_parseCurrencyInput(costCtrl.text.trim()) > 0);
      final hasUserNotes = noteCtrl.text.trim().isNotEmpty;
      final t = (totals[key] ?? 0);
      if (!hasUserCost && t > 0) {
        costCtrl.text = t.toStringAsFixed(t % 1 == 0 ? 0 : 2);
      }
    }
    setState(() {});
  }

  Future<void> _populateCategoriesFromAi({int? targetSolution}) async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final map = await _openAi.generateCostBreakdownForSolutions(
        widget.solutions,
        contextNotes: _buildCostContextNotes(),
        currency: _currency,
      );
      if (!mounted) return;
      if (targetSolution != null) {
        final sol = _solutionAt(targetSolution);
        if (sol != null) {
          final items = map[sol.title] ?? <AiCostItem>[];
          setState(() {
            _applyCostItemsToRows(targetSolution, items);
            _applyCategoryEstimatesFromItems(targetSolution, items);
          });
        }
      } else {
        for (int i = 0;
            i < _rowsPerSolution.length && i < widget.solutions.length;
            i++) {
          final title = widget.solutions[i].title;
          final items = map[title] ?? <AiCostItem>[];
          _applyCostItemsToRows(i, items);
          _applyCategoryEstimatesFromItems(i, items);
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _applyIdeaToCategory(
      int solutionIndex, String categoryKey, AiCostItem item) {
    if (solutionIndex < 0 || solutionIndex >= _rowsPerSolution.length) return;
    // Ignore generic benefit pillar labels as cost items
    if (_isProjectValueCategoryLabel(item.item)) return;
    // Add to Step 3 breakdown as a new row with baseline derived from AI
    final row = _CostRow(currencyProvider: () => _currency);
    _attachRowDirtyListeners(row);
    row.itemController.text = item.item.isEmpty ? 'Name' : item.item;
    row.descriptionController.text = item.description.isEmpty
        ? 'Lorem ipsum  Lorem ipsum  Lorem ipsum  Lorem ipsum  Lorem ipsum...'
        : item.description;
    row.applyBaseline(
        cost: item.estimatedCost,
        roiPercent: item.roiPercent,
        npvByYears: item.npvByYear);
    row.setHorizon(_npvHorizon);
    setState(() {
      _rowsPerSolution[solutionIndex].add(row);
    });
    // Also append to category notes and sum cost into the category estimate field
    final entry = _categoryCostsPerSolution[solutionIndex][categoryKey];
    if (entry != null) {
      final existing = entry.notesController.text.trim();
      final bullet = item.item.trim();
      final sep = existing.isEmpty ? '' : '\n';
      entry.notesController.text = '$existing$sep$kListBullet$bullet';
      final cur = _parseCurrencyInput(entry.costController.text.trim());
      final add = item.estimatedCost.isFinite ? item.estimatedCost : 0;
      final next = (cur + add);
      if (next > 0) {
        entry.costController.text = next.toStringAsFixed(next % 1 == 0 ? 0 : 2);
      }
    }
    _markDirty();
  }

  Widget _tabButton(
      {required String label,
      required bool isActive,
      required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFFFFD700) : Colors.grey[200],
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal),
      ),
    );
  }

  Widget _currencyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.35))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currency,
          items: const [
            DropdownMenuItem(value: 'USD', child: Text('USD')),
            DropdownMenuItem(value: 'EUR', child: Text('EUR')),
            DropdownMenuItem(value: 'GBP', child: Text('GBP')),
          ],
          onChanged: (v) {
            final selected = v ?? 'USD';
            final factor = _currencyFactor(_lastCurrency, selected);
            setState(() {
              _currency = selected;
              _applyCurrencyConversion(factor);
              _lastCurrency = selected;
            });
            _markDirty();
          },
        ),
      ),
    );
  }

  Widget _tableForIndex(int index,
      {required bool isMobile, required String horizonLabel}) {
    final rows = _rowsPerSolution[index];
    if (isMobile) {
      return Column(
          children: rows.map((r) => _mobileCard(r, horizonLabel)).toList());
    }
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.withOpacity(0.35))),
        child: Row(children: [
          const Expanded(
              flex: 2,
              child: Text('Potential Solution',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          const Expanded(
              flex: 5,
              child: Text('Description',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          const Expanded(
              flex: 2,
              child: Align(
                  alignment: Alignment.center,
                  child: Text('Return On Investment',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Net Present Value ($horizonLabel)',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
              flex: 2,
              child: Align(
                  alignment: Alignment.center,
                  child: Text('Estimated Cost',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 16),
          const Expanded(
              flex: 3,
              child: Text('Comments',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.withOpacity(0.35))),
        child: Column(children: rows.map((r) => _tableRow(r)).toList()),
      ),
    ]);
  }

  Widget _tableRow(_CostRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
          border:
              Border(top: BorderSide(color: Colors.grey.withOpacity(0.25)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 2,
          child: ExpandingTextField(
            controller: row.itemController,
            decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Name'),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            minLines: 1,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: ExpandingTextField(
            controller: row.descriptionController,
            decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Lorem ipsum  ...'),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            minLines: 1,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.topRight,
            child: TextField(
              controller: row.roiController,
              textAlign: TextAlign.right,
              readOnly: true,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: '0%'),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.topRight,
            child: TextField(
              controller: row.npvController,
              textAlign: TextAlign.right,
              readOnly: true,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: '0.00'),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.topRight,
            child: TextField(
              controller: row.costController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: '0.00'),
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: ExpandingTextField(
            controller: row.assumptionsController,
            minLines: 1,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: 'Assumptions or notes',
            ),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ]),
    );
  }

  Widget _mobileCard(_CostRow row, String horizonLabel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.35))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Potential Solution',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ExpandingTextField(
            controller: row.itemController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), isDense: true, hintText: 'Name'),
            minLines: 1),
        const SizedBox(height: 10),
        const Text('Description',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ExpandingTextField(
            controller: row.descriptionController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'Lorem ipsum...'),
            minLines: 2),
        const SizedBox(height: 10),
        const Text('Return On Investment',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
            controller: row.roiController,
            readOnly: true,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), isDense: true, hintText: '0%')),
        const SizedBox(height: 10),
        Text('Net Present Value ($horizonLabel)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
            controller: row.npvController,
            readOnly: true,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), isDense: true, hintText: '0.00')),
        const SizedBox(height: 10),
        const Text('Estimated Cost',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
            controller: row.costController,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), isDense: true, hintText: '0.00')),
        const SizedBox(height: 10),
        const Text('Comments',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ExpandingTextField(
          controller: row.assumptionsController,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              hintText: 'Assumptions or notes'),
          minLines: 2,
        ),
      ]),
    );
  }

  Widget _buildPhaseNavigation() {
    final phases = [
      'Initiation Phase',
      'Initiation: Front End Planning',
      'Workflow Roadmap',
      'Agile Roadmap',
      'Contracting',
      'Procurement'
    ];
    return Container(
      height: 80,
      color: Colors.white,
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () {
            _handleBackNavigation();
          },
        ),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: phases.length,
            itemBuilder: (context, index) {
              final isActive = index == 0;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                    color:
                        isActive ? const Color(0xFFFFD700) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20)),
                child: Center(
                  child: Text(
                    phases[index],
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? Colors.black : Colors.grey[600]),
                  ),
                ),
              );
            },
          ),
        ),
        IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () {}),
      ]),
    );
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _notesController.removeListener(_markDirty);
    _notesController.dispose();
    _projectValueAmountController.removeListener(_onProjectValueFieldChanged);
    _projectValueAmountController.dispose();
    for (final controller in _projectValueBenefitControllers.values) {
      controller.removeListener(_onProjectValueFieldChanged);
      controller.dispose();
    }
    _benefitCategoryTabController.dispose();
    for (final context in _solutionContexts) {
      context.justificationController.removeListener(_markDirty);
      context.dispose();
    }
    for (final list in _rowsPerSolution) {
      for (final r in list) {
        r.dispose();
      }
    }
    for (final map in _categoryCostsPerSolution) {
      for (final entry in map.values) {
        entry.dispose();
      }
    }
    for (final entry in _benefitLineItems) {
      entry.dispose();
    }
    _savingsNotesController.removeListener(_markDirty);
    _savingsNotesController.dispose();
    _savingsTargetController.removeListener(_markDirty);
    _savingsTargetController.dispose();
    super.dispose();
  }

  Future<void> _generateSavingsSuggestions() async {
    if (_isSavingsGenerating) return;
    final eligible = _benefitLineItems
        .where((entry) => entry.totalValue > 0 && entry.title.isNotEmpty)
        .toList();
    if (eligible.isEmpty) {
      setState(() {
        _savingsError =
            'Add at least one benefit with unit value and units before generating savings scenarios.';
        _savingsSuggestions = [];
      });
      return;
    }

    double? parsePercent(String value) {
      final sanitized = value.replaceAll(RegExp(r'[^0-9\.-]'), '');
      final parsed = double.tryParse(sanitized);
      if (parsed == null || parsed <= 0) return null;
      return parsed;
    }

    final targetPercent = parsePercent(_savingsTargetController.text.trim());

    setState(() {
      _isSavingsGenerating = true;
      _savingsError = null;
    });

    try {
      final payload = eligible.map((entry) => entry.toPayload()).toList();
      final suggestions = await _openAi.generateBenefitSavingsSuggestions(
        payload,
        currency: _currency,
        savingsTargetPercent: targetPercent,
        contextNotes: _savingsNotesController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _savingsSuggestions = suggestions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingsError = e.toString();
        _savingsSuggestions = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSavingsGenerating = false;
      });
    }
  }

  Future<void> _generateProjectValue() async {
    if (_isGeneratingValue) return;
    setState(() {
      _isGeneratingValue = true;
      _projectValueError = null;
    });
    try {
      final provider = ProjectDataHelper.getProvider(context);
      
      // Add current values to history before regenerating
      provider.addFieldToHistory('project_value_amount', _projectValueAmountController.text, isAiGenerated: true);
      for (final field in _projectValueFields) {
        final controller = _projectValueBenefitControllers[field.key];
        if (controller != null) {
          provider.addFieldToHistory('project_value_${field.key}', controller.text, isAiGenerated: true);
        }
      }
      
      final insights = await _openAi.generateProjectValueInsights(
        widget.solutions,
        contextNotes: _notesController.text.trim(),
      );
      if (!mounted) return;

      // Generate benefit line items with numeric values
      List<BenefitLineItemInput> benefitLineItems = [];
      if (insights.estimatedProjectValue > 0) {
        try {
          benefitLineItems = await _openAi.generateBenefitLineItems(
            solutions: widget.solutions,
            estimatedProjectValue: insights.estimatedProjectValue,
            contextNotes: _notesController.text.trim(),
            currency: _currency,
          );
        } catch (e) {
          debugPrint('Error generating benefit line items: $e');
          // Continue with project value even if benefit line items fail
        }
      }

      if (!mounted) return;
      setState(() {
        if (insights.estimatedProjectValue > 0) {
          _projectValueAmountController.text =
              insights.estimatedProjectValue.toStringAsFixed(0);
        }
        for (final field in _projectValueFields) {
          final value = insights.benefits[field.key] ??
              insights.benefits[field.key.replaceAll('_', ' ')] ??
              '';
          if (value.trim().isNotEmpty) {
            _projectValueBenefitControllers[field.key]!.text = value.trim();
          }
        }

        // Clear existing benefit line items and add generated ones
        for (final entry in _benefitLineItems) {
          entry.unbind();
          WidgetsBinding.instance.addPostFrameCallback((_) => entry.dispose());
        }
        _benefitLineItems.clear();

        // Add generated benefit line items
        final baseTimestamp = DateTime.now().microsecondsSinceEpoch;
        for (int i = 0; i < benefitLineItems.length; i++) {
          final item = benefitLineItems[i];
          final entry = _BenefitLineItemEntry(
            id: 'benefit-$baseTimestamp-$i',
            categoryKey: item.category,
            title: item.title,
            unitValue: item.unitValue,
            units: item.units,
            notes: item.notes,
          );
          entry.bind(_onBenefitEntryEdited);
          _benefitLineItems.add(entry);
        }
      });
      
      // Auto-save after regeneration
      await provider.saveToFirebase(checkpoint: 'cost_analysis_regenerated');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project value regenerated successfully')),
        );
      }
      
      _markDirty();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _projectValueError = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to regenerate project value: $e')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isGeneratingValue = false;
      });
    }
  }

  Future<void> _suggestUnitValueWithAI(_BenefitLineItemEntry entry) async {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      if (provider == null) return;

      final projectContext = ProjectDataHelper.buildFepContext(
        provider.projectData,
      );

      final benefitTitle = entry.titleController.text.trim();
      if (benefitTitle.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a benefit title first')),
        );
        return;
      }

      final suggestedValue = await _openAi.estimateCostForItem(
        itemName: benefitTitle,
        contextNotes: projectContext,
        currency: _currency,
      );

      if (mounted && suggestedValue > 0) {
        setState(() {
          entry.unitValueController.text = suggestedValue.toStringAsFixed(2);
          _onBenefitEntryEdited();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'AI suggested unit value: ${_formatCurrencyValue(suggestedValue)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to generate suggestion: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _generateCostBreakdownForSolution(int index) async {
    final solution = _solutionAt(index);
    if (solution == null || _solutionLoading.contains(index)) return;
    setState(() {
      _solutionLoading.add(index);
      _error = null;
    });
    try {
      final map = await _openAi.generateCostBreakdownForSolutions(
        [solution],
        contextNotes: _buildCostContextNotes(forSolution: index),
        currency: _currency,
      );
      if (!mounted) return;
      final items = map[solution.title] ?? <AiCostItem>[];
      setState(() {
        // Apply detailed items to the editable rows
        _applyCostItemsToRows(index, items);
        // Also roll up into Project Value categories and surface ideas
        _applyCategoryEstimatesFromItems(index, items);
        _solutionLoading.remove(index);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _solutionLoading.remove(index);
      });
    }
  }

  Future<void> _generateCostBreakdown() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final map = await _openAi.generateCostBreakdownForSolutions(
        widget.solutions,
        contextNotes: _buildCostContextNotes(),
        currency: _currency,
      );
      for (int i = 0;
          i < _rowsPerSolution.length && i < widget.solutions.length;
          i++) {
        final title = widget.solutions[i].title;
        final items = map[title] ?? <AiCostItem>[];
        // Seed editable rows
        _applyCostItemsToRows(i, items);
        // Auto-fill Project Value category estimates from the same AI items
        _applyCategoryEstimatesFromItems(i, items);
      }
    } catch (e) {
      print('Error generating cost breakdown: $e');
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _regenerateAllCostAnalysis() async {
    // Regenerate project value and benefit line items
    await _generateProjectValue();
  }
}

class _StepDefinition {
  final String shortLabel;
  final String title;
  final String subtitle;

  const _StepDefinition(
      {required this.shortLabel, required this.title, required this.subtitle});
}

class _ValueSetupInvestmentSnapshot {
  final double estimatedCost;
  final double? averageRoi;
  final double? npv;
  final _CostRange costRange;
  final int benefitLineItemCount;
  final double totalBenefits;

  const _ValueSetupInvestmentSnapshot({
    required this.estimatedCost,
    required this.averageRoi,
    required this.npv,
    required this.costRange,
    required this.benefitLineItemCount,
    required this.totalBenefits,
  });

  bool get hasBenefitSignals => totalBenefits > 0 && benefitLineItemCount > 0;
}

class _BenefitLineItemEntry {
  final String id;
  String categoryKey;
  final TextEditingController titleController;
  final TextEditingController unitValueController;
  final TextEditingController unitsController;
  final TextEditingController notesController;
  VoidCallback? _listener;

  _BenefitLineItemEntry({
    required this.id,
    required this.categoryKey,
    String title = '',
    double unitValue = 0,
    double units = 0,
    String notes = '',
  })  : titleController = TextEditingController(text: title),
        unitValueController = TextEditingController(
          text: unitValue == 0
              ? ''
              : unitValue.toStringAsFixed(unitValue % 1 == 0 ? 0 : 2),
        ),
        unitsController = TextEditingController(
          text: units == 0 ? '' : units.toStringAsFixed(units % 1 == 0 ? 0 : 2),
        ),
        notesController = TextEditingController(text: notes);

  String get title => titleController.text.trim();

  double get unitValue => _readDouble(unitValueController.text);

  double get units => _readDouble(unitsController.text);

  String get notes => notesController.text.trim();

  double get totalValue => unitValue * units;

  void bind(VoidCallback listener) {
    _listener = listener;
    titleController.addListener(listener);
    unitValueController.addListener(listener);
    unitsController.addListener(listener);
    notesController.addListener(listener);
  }

  void unbind() {
    if (_listener == null) return;
    titleController.removeListener(_listener!);
    unitValueController.removeListener(_listener!);
    unitsController.removeListener(_listener!);
    notesController.removeListener(_listener!);
    _listener = null;
  }

  BenefitLineItemInput toPayload() => BenefitLineItemInput(
        category: categoryKey,
        title: title,
        unitValue: unitValue,
        units: units,
        notes: notes,
      );

  void dispose() {
    unbind();
    titleController.dispose();
    unitValueController.dispose();
    unitsController.dispose();
    notesController.dispose();
  }

  static double _readDouble(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(sanitized) ?? 0;
  }
}

class _BenefitCategorySummary {
  int itemCount = 0;
  double unitTotal = 0;
  double valueTotal = 0;

  void add(_BenefitLineItemEntry entry) {
    itemCount += 1;
    unitTotal += entry.units;
    valueTotal += entry.totalValue;
  }
}

class _CostRow {
  final TextEditingController itemController =
      TextEditingController(text: 'Name');
  final TextEditingController descriptionController = TextEditingController(
      text:
          'Lorem ipsum  Lorem ipsum  Lorem ipsum  Lorem ipsum  Lorem ipsum...');
  final TextEditingController costController = TextEditingController();
  final TextEditingController roiController = TextEditingController();
  final TextEditingController npvController = TextEditingController();
  final TextEditingController assumptionsController = TextEditingController();
  bool aiLoading = false;

  // Baseline values used for recomputation
  double _baseCost = 0;
  double _baseRoiPct = 0;
  double _baseBenefit = 0; // derived from ROI% and cost
  Map<int, double> _baseNpvs = const {5: 0};
  int _selectedHorizon = 5;

  final String Function() currencyProvider;
  VoidCallback? _listener;

  _CostRow({required this.currencyProvider});

  void applyBaseline(
      {required double cost,
      required double roiPercent,
      required Map<int, double> npvByYears}) {
    _baseCost = cost;
    _baseRoiPct = roiPercent;
    _baseBenefit = _baseCost * (1 + _baseRoiPct / 100);
    _baseNpvs =
        npvByYears.isEmpty ? const {5: 0} : Map<int, double>.from(npvByYears);
    _selectedHorizon = _baseNpvs.containsKey(5) ? 5 : _baseNpvs.keys.first;

    costController.text = _num(cost);
    // Set initial computed fields
    roiController.text = _formatPercent(_baseRoiPct);
    npvController.text = _num(_baseNpvs[_selectedHorizon] ?? 0);

    // Re-attach listener for live recalculation
    if (_listener != null) costController.removeListener(_listener!);
    _listener = () {
      refreshComputed();
    };
    costController.addListener(_listener!);
  }

  void setHorizon(int years) {
    if (_selectedHorizon == years) return;
    _selectedHorizon = years;
    refreshComputed();
  }

  void refreshComputed() {
    final newCost = _parseCurrency(costController.text);
    final baseNpv = _baseNpvs[_selectedHorizon] ??
        (_baseNpvs.values.isNotEmpty ? _baseNpvs.values.first : 0);
    if (newCost <= 0) {
      roiController.text = _formatPercent(0);
      npvController.text = _num(baseNpv);
      return;
    }
    // Assume benefits remain constant at baseline benefit; recompute ROI given new cost
    final newRoiPct = ((_baseBenefit - newCost) / newCost) * 100;
    // Adjust NPV assuming only upfront cost changes (benefits unchanged)
    final newNpv = baseNpv - (newCost - _baseCost);
    roiController.text = _formatPercent(newRoiPct);
    npvController.text = _num(newNpv);
  }

  void convertCurrency(double factor) {
    // Scale baseline values
    _baseCost *= factor;
    _baseBenefit *= factor;
    _baseNpvs = _baseNpvs.map((k, v) => MapEntry(k, v * factor));

    // Scale current entered cost
    final curCost = _parseCurrency(costController.text);
    if (curCost != 0) {
      final n = curCost * factor;
      costController.text = _num(n);
    }
    // Scale current NPV field if present
    final curNpv = _parseCurrency(npvController.text);
    if (curNpv != 0) {
      final n = curNpv * factor;
      npvController.text = _num(n);
    }
    // Recompute ROI/NPV to keep relationships intact
    refreshComputed();
  }

  double currentCost() => _parseCurrency(costController.text);

  double currentNpv() => _parseCurrency(npvController.text);

  double currentRoi() => _parsePercent(roiController.text);

  double baselineNpvFor(int years) =>
      _baseNpvs[years] ??
      (_baseNpvs.values.isNotEmpty ? _baseNpvs.values.first : 0);

  double _parseCurrency(String v) {
    final s = v.replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(s) ?? 0;
  }

  double _parsePercent(String v) {
    final s = v.replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(s) ?? 0;
  }

  String _num(double v) => (v.isFinite ? v : 0).toStringAsFixed(2);

  String _formatCurrency(double v) {
    final formatted = _formatNumber(v);
    final code = currencyProvider();
    return '$code $formatted';
  }

  String _formatPercent(double v) {
    final n = v.isFinite ? v : 0;
    return '${n.toStringAsFixed(1)}%';
  }

  String _formatNumber(double v) {
    final abs = v.abs();
    String s;
    if (abs >= 1000000000) {
      s = '${(v / 1000000000).toStringAsFixed(2)}B';
    } else if (abs >= 1000000) {
      s = '${(v / 1000000).toStringAsFixed(2)}M';
    } else if (abs >= 1000) {
      s = _thousands(v);
    } else {
      s = v.toStringAsFixed(2);
    }
    return s;
  }

  String _thousands(double v) {
    final fixed = v.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final reverseIndex = intPart.length - i - 1;
      buffer.write(intPart[i]);
      if (reverseIndex % 3 == 0 && i != intPart.length - 1) buffer.write(',');
    }
    return '$buffer.$decPart';
  }

  void dispose() {
    itemController.dispose();
    descriptionController.dispose();
    costController.dispose();
    roiController.dispose();
    npvController.dispose();
    assumptionsController.dispose();
  }
}

class _SolutionCostContext {
  int resourceIndex = 0;
  int timelineIndex = 1;
  int complexityIndex = 0;
  final TextEditingController justificationController = TextEditingController();
  bool autoGenerated = true;
  bool _updating = false;

  _SolutionCostContext() {
    justificationController.addListener(_handleEdit);
  }

  void _handleEdit() {
    if (_updating) return;
    autoGenerated = false;
  }

  void updateJustification(String value) {
    _updating = true;
    justificationController.text = value;
    _updating = false;
    autoGenerated = true;
  }

  void dispose() {
    justificationController.dispose();
  }
}

class _QualitativeOption {
  final String label;
  final String detail;
  final String aiHint;

  const _QualitativeOption(
      {required this.label, required this.detail, required this.aiHint});
}

class _CostRange {
  final double lower;
  final double upper;

  const _CostRange({required this.lower, required this.upper});
}

class _AiTag extends StatelessWidget {
  const _AiTag();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
          color: Color(0xFFFFD700),
          borderRadius: BorderRadius.all(Radius.circular(4))),
      child: const Text('AI', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _BasisFrequencyToggleButton extends StatelessWidget {
  const _BasisFrequencyToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class _BasisFrequencyToggle extends StatelessWidget {
  const _BasisFrequencyToggle({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BasisFrequencyToggleButton(
            label: 'Annual',
            isSelected: value == 'Annual',
            onTap: () => onChanged('Annual'),
          ),
          _BasisFrequencyToggleButton(
            label: 'Monthly',
            isSelected: value == 'Monthly',
            onTap: () => onChanged('Monthly'),
          ),
        ],
      ),
    );
  }
}

class _CategoryCostEntry {
  final String categoryKey;
  final TextEditingController costController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  VoidCallback? _listener;
  bool aiLoading = false;

  _CategoryCostEntry({required this.categoryKey});

  void bind(VoidCallback listener) {
    _listener = listener;
    costController.addListener(listener);
    notesController.addListener(listener);
  }

  double get cost {
    final s = costController.text.replaceAll(RegExp(r'[^0-9\.-]'), '');
    return double.tryParse(s) ?? 0;
  }

  void dispose() {
    if (_listener != null) {
      costController.removeListener(_listener!);
      notesController.removeListener(_listener!);
    }
    costController.dispose();
    notesController.dispose();
  }
}
