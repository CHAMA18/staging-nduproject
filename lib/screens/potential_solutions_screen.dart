import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:shimmer/shimmer.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/expanding_text_field.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/screens/home_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/it_considerations_screen.dart';
import 'package:ndu_project/screens/infrastructure_considerations_screen.dart';
import 'package:ndu_project/screens/core_stakeholders_screen.dart';
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/business_case_header.dart';
import 'package:ndu_project/widgets/business_case_navigation_buttons.dart';
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/settings_screen.dart';
import 'package:ndu_project/screens/cost_analysis_screen.dart';
import 'package:ndu_project/screens/preferred_solution_analysis_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/access_policy.dart';

class PotentialSolutionsScreen extends StatefulWidget {
  const PotentialSolutionsScreen({super.key});

  @override
  State<PotentialSolutionsScreen> createState() => _PotentialSolutionsScreenState();
}

class _PotentialSolutionsScreenState extends State<PotentialSolutionsScreen> {
  static const List<_SidebarItem> _sidebarItems = [
    _SidebarItem(icon: Icons.home, title: 'Home', enabled: true),
    _SidebarItem(
      icon: Icons.flag_circle_outlined,
      title: 'Initiation Phase',
      isActive: true,
    ),
    _SidebarItem(icon: Icons.calendar_month_outlined, title: 'Initiation: Front End Planning'),
    _SidebarItem(icon: Icons.device_hub_outlined, title: 'Workflow Roadmap'),
    _SidebarItem(icon: Icons.alt_route_outlined, title: 'Agile Roadmap'),
    _SidebarItem(icon: Icons.handshake_outlined, title: 'Contracting'),
    _SidebarItem(icon: Icons.shopping_cart_outlined, title: 'Procurement'),
  ];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _notesController = TextEditingController();
  late final String _incomingBusinessCase;
  final List<SolutionRow> _solutions = [];
  final OpenAiServiceSecure _openAiService = OpenAiServiceSecure();
  bool _isLoadingSolutions = true;
  String? _loadingError;
  // Anchor to allow sidebar sub-item to scroll to the solutions section
  final GlobalKey _solutionsSectionKey = GlobalKey();
  bool _hintShown = false;
  // Expand/collapse state to mirror Cost Analysis sidebar
  bool _initiationExpanded = true;
  bool _businessCaseExpanded = true;
  bool _frontEndExpanded = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize API key manager
    ApiKeyManager.initializeApiKey();
    
    // Load data from provider and defer generation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final projectData = ProjectDataHelper.getData(context);
      _notesController.text = projectData.notes;
      _incomingBusinessCase = projectData.businessCase;
      
      // Load saved solutions if they exist
      if (projectData.potentialSolutions.isNotEmpty) {
        setState(() {
          _solutions.clear();
          for (final solution in projectData.potentialSolutions) {
            _solutions.add(
              SolutionRow(
                titleController: TextEditingController(text: solution.title),
                descriptionController: TextEditingController(text: solution.description),
                isAiGenerated: true,
              ),
            );
          }
          _isLoadingSolutions = false;
        });
      } else {
        _showHintDialogOnce();
        _generateInitialSolutions();
      }
      
      if (mounted) setState(() {});
    });
  }

  void _showHintDialogOnce() {
    if (_hintShown) return;
    _hintShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Colors.blue, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Notification',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Although AI-generated outputs can provide valuable insights, please review and refine them as needed to ensure they align with your project requirements.',
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateInitialSolutions() async {
    if (_incomingBusinessCase.trim().isEmpty) {
      setState(() {
        _isLoadingSolutions = false;
      });
      return;
    }

    try {
      final aiSolutions = await _openAiService.generateSolutionsFromBusinessCase(_incomingBusinessCase);
      _applySolutions(aiSolutions);
    } catch (e) {
      print('Error generating solutions: $e');
      _applyFallback(e.toString());
    }
  }

  void _applySolutions(List<AiSolutionItem> aiSolutions) {
    final isAdmin = AccessPolicy.isRestrictedAdminHost();
    final targetCount = isAdmin ? 5 : 3;
    
    setState(() {
      _solutions.clear();
      final solutionsToUse = aiSolutions.take(targetCount).toList();
      
      for (final aiSolution in solutionsToUse) {
        _solutions.add(
          SolutionRow(
            titleController: TextEditingController(text: aiSolution.title),
            descriptionController: TextEditingController(text: aiSolution.description),
            isAiGenerated: true,
          ),
        );
      }
      _loadingError = null;
      _isLoadingSolutions = false;
    });
  }

  void _applyFallback(String errorMessage) {
    final isAdmin = AccessPolicy.isRestrictedAdminHost();
    final targetCount = isAdmin ? 5 : 3;
    
    setState(() {
      _loadingError = errorMessage;
      _solutions.clear();
      for (int i = 0; i < targetCount; i++) {
        _solutions.add(
          SolutionRow(
            titleController: TextEditingController(text: 'Proposed Solution ${i + 1}'),
            descriptionController: TextEditingController(
              text: 'Describe how this option addresses the project\'s needs, assumptions, constraints, and expected benefits.',
            ),
            isAiGenerated: true,
          ),
        );
      }
      _isLoadingSolutions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: Stack(
        children: [
          Column(
            children: [
              // Top Header
              BusinessCaseHeader(scaffoldKey: _scaffoldKey),
              Expanded(
                child: Row(
                  children: [
                    DraggableSidebar(
                      openWidth: sidebarWidth,
                      child: const InitiationLikeSidebar(activeItemLabel: 'Potential Solutions'),
                    ),
                    Expanded(
                      child: _buildMainContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const KazAiChatBubble(),
          const AdminEditToggle(),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    final isMobile = AppBreakpoints.isMobile(context);
    return Container(
      height: isMobile ? 88 : 110,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      child: Row(
        children: [
          // Navigation
          Row(
            children: [
              if (isMobile)
                IconButton(
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.menu),
                )
              else
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios),
                  color: Colors.grey[600],
                ),
            ],
          ),
          const Spacer(),
          // Page Title
          if (!isMobile)
            const Text(
              'Initiation Phase',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          const Spacer(),
          // User Profile
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue[400],
                    child: Text(
                      FirebaseAuthService.displayNameOrEmail(fallback: 'U').characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        FirebaseAuthService.displayNameOrEmail(fallback: 'User'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Owner',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                ],
              ),
            )
          else
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[400],
              child: Text(
                FirebaseAuthService.displayNameOrEmail(fallback: 'U').characters.first.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    final double bannerHeight = AppBreakpoints.isMobile(context) ? 72 : 96;
    // Match RiskIdentificationScreen sidebar styling and structure
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Full-width logo banner above the "StackOne" text
          SizedBox(
            width: double.infinity,
            height: bannerHeight,
            child: Center(child: AppLogo(height: 64)),
          ),
          // Header with brand divider (gold)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFFFD700), width: 1),
              ),
            ),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFFFD700),
                  child: Icon(Icons.person_outline, color: Colors.black87),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('StackOne', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                  ],
                )
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildMenuItemLikeRisk(Icons.home_outlined, 'Home', onTap: () => HomeScreen.open(context)),
                _buildExpandableHeaderLikeCost(
                  Icons.flag_outlined,
                  'Initiation Phase',
                  expanded: _initiationExpanded,
                  onTap: () => setState(() => _initiationExpanded = !_initiationExpanded),
                  isActive: true,
                ),
                if (_initiationExpanded) ...[
                  _buildExpandableHeaderLikeCost(
                    Icons.business_center_outlined,
                    'Business Case',
                    expanded: _businessCaseExpanded,
                    onTap: () => setState(() => _businessCaseExpanded = !_businessCaseExpanded),
                    isActive: false,
                  ),
                  if (_businessCaseExpanded) ...[
                    _buildNestedSubMenuItem('Potential Solutions', onTap: _scrollToSolutions, isActive: true),
                    _buildNestedSubMenuItem('Risk Identification', onTap: _openRiskIdentification),
                    _buildNestedSubMenuItem('IT Considerations', onTap: _openITConsiderations),
                    _buildNestedSubMenuItem('Infrastructure Considerations', onTap: _openInfrastructureConsiderations),
                    _buildNestedSubMenuItem('Core Stakeholders', onTap: _openCoreStakeholders),
                    _buildNestedSubMenuItem('Cost Benefit Analysis & Financial Metrics', onTap: _openCostAnalysis),
                    _buildNestedSubMenuItem('Preferred Solution Analysis', onTap: _openPreferredSolutionAnalysis),
                  ],
                  _buildExpandableHeaderLikeCost(Icons.timeline, 'Initiation: Front End Planning', expanded: _frontEndExpanded, onTap: () {
                    setState(() => _frontEndExpanded = !_frontEndExpanded);
                  }, isActive: false),
                  if (_frontEndExpanded) ...[
                    _buildNestedSubMenuItem('Project Requirements'),
                    _buildNestedSubMenuItem('Project Risks'),
                    _buildNestedSubMenuItem('Project Opportunities'),
                  ],
                ],
                _buildMenuItemLikeRisk(Icons.account_tree_outlined, 'Workflow Roadmap'),
                _buildMenuItemLikeRisk(Icons.flash_on, 'Agile Roadmap'),
                _buildMenuItemLikeRisk(Icons.description_outlined, 'Contracting'),
                _buildMenuItemLikeRisk(Icons.shopping_cart_outlined, 'Procurement'),
                const SizedBox(height: 20),
                _buildMenuItemLikeRisk(Icons.settings_outlined, 'Settings', onTap: () => SettingsScreen.open(context)),
                _buildMenuItemLikeRisk(Icons.logout_outlined, 'LogOut', onTap: () => AuthNav.signOutAndExit(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildMobileDrawer() {
    // Match the RiskIdentificationScreen drawer look
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
            _buildMenuItemLikeRisk(Icons.home_outlined, 'Home', onTap: () => HomeScreen.open(context)),
            _buildExpandableHeaderLikeCost(
              Icons.flag_outlined,
              'Initiation Phase',
              expanded: _initiationExpanded,
              onTap: () => setState(() => _initiationExpanded = !_initiationExpanded),
              isActive: true,
            ),
            if (_initiationExpanded) ...[
              _buildExpandableHeaderLikeCost(
                Icons.business_center_outlined,
                'Business Case',
                expanded: _businessCaseExpanded,
                onTap: () => setState(() => _businessCaseExpanded = !_businessCaseExpanded),
                isActive: false,
              ),
              if (_businessCaseExpanded) ...[
                _buildNestedSubMenuItem('Potential Solutions', onTap: () {
                  Navigator.of(context).maybePop();
                  _scrollToSolutions();
                }, isActive: true),
                _buildNestedSubMenuItem('Risk Identification', onTap: () {
                  Navigator.of(context).maybePop();
                  _openRiskIdentification();
                }),
                _buildNestedSubMenuItem('IT Considerations', onTap: () {
                  Navigator.of(context).maybePop();
                  _openITConsiderations();
                }),
                _buildNestedSubMenuItem('Infrastructure Considerations', onTap: () {
                  Navigator.of(context).maybePop();
                  _openInfrastructureConsiderations();
                }),
                _buildNestedSubMenuItem('Core Stakeholders', onTap: () {
                  Navigator.of(context).maybePop();
                  _openCoreStakeholders();
                }),
                _buildNestedSubMenuItem('Cost Benefit Analysis & Financial Metrics', onTap: () {
                  Navigator.of(context).maybePop();
                  _openCostAnalysis();
                }),
                _buildNestedSubMenuItem('Preferred Solution Analysis', onTap: () {
                  Navigator.of(context).maybePop();
                  _openPreferredSolutionAnalysis();
                }),
              ],
              _buildExpandableHeaderLikeCost(Icons.timeline, 'Initiation: Front End Planning', expanded: _frontEndExpanded, onTap: () {
                setState(() => _frontEndExpanded = !_frontEndExpanded);
              }, isActive: false),
              if (_frontEndExpanded) ...[
                _buildNestedSubMenuItem('Project Requirements', onTap: () => Navigator.of(context).maybePop()),
                _buildNestedSubMenuItem('Project Risks', onTap: () => Navigator.of(context).maybePop()),
                _buildNestedSubMenuItem('Project Opportunities', onTap: () => Navigator.of(context).maybePop()),
              ],
            ],
            _buildMenuItemLikeRisk(Icons.account_tree_outlined, 'Workflow Roadmap'),
            _buildMenuItemLikeRisk(Icons.flash_on, 'Agile Roadmap'),
            _buildMenuItemLikeRisk(Icons.description_outlined, 'Contracting'),
            _buildMenuItemLikeRisk(Icons.shopping_cart_outlined, 'Procurement'),
            const Divider(height: 1),
            _buildMenuItemLikeRisk(Icons.settings_outlined, 'Settings', onTap: () {
              Navigator.of(context).maybePop();
              SettingsScreen.open(context);
            }),
            _buildMenuItemLikeRisk(Icons.logout_outlined, 'LogOut', onTap: () => AuthNav.signOutAndExit(context)),
          ],
        ),
      ),
    );
  }

  // Sidebar tile that mimics RiskIdentificationScreen's _buildMenuItem
  Widget _buildMenuItemLikeRisk(IconData icon, String title, {VoidCallback? onTap, bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primary.withValues(alpha: 0.12) : Colors.transparent,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuItemLikeRisk(String title, {VoidCallback? onTap, bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 24, top: 2, bottom: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primary.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, size: 8, color: isActive ? primary : Colors.grey[500]),
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

  // Third-level nested menu item (under Business Case)
  Widget _buildNestedSubMenuItem(String title, {VoidCallback? onTap, bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 24, top: 2, bottom: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primary.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.circle, size: 6, color: isActive ? primary : Colors.grey[400]),
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
            ],
          ),
        ),
      ),
    );
  }

  // Expandable header matching Cost Analysis look and behavior
  Widget _buildExpandableHeaderLikeCost(IconData icon, String title,
      {required bool expanded, required VoidCallback onTap, bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primary.withValues(alpha: 0.12) : Colors.transparent,
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
              Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[700], size: 20),
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

  List<AiSolutionItem> _collectSolutions() {
    return _solutions
        .map((s) => AiSolutionItem(
              title: s.titleController.text.trim(),
              description: s.descriptionController.text.trim(),
            ))
        .where((item) => item.title.isNotEmpty || item.description.isNotEmpty)
        .toList();
  }

  void _openRiskIdentification() {
    final notes = _notesController.text.trim();
    final solutions = _collectSolutions();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiskIdentificationScreen(
          notes: notes,
          solutions: solutions,
          businessCase: _incomingBusinessCase,
        ),
      ),
    );
  }

  void _openITConsiderations() {
    final notes = _notesController.text.trim();
    final solutions = _collectSolutions();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ITConsiderationsScreen(
          notes: notes,
          solutions: solutions,
        ),
      ),
    );
  }

  void _openInfrastructureConsiderations() {
    final notes = _notesController.text.trim();
    final solutions = _collectSolutions();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InfrastructureConsiderationsScreen(
          notes: notes,
          solutions: solutions,
        ),
      ),
    );
  }

  void _openCoreStakeholders() {
    final notes = _notesController.text.trim();
    final solutions = _collectSolutions();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CoreStakeholdersScreen(
          notes: notes,
          solutions: solutions,
        ),
      ),
    );
  }

  void _openCostAnalysis() {
    final notes = _notesController.text.trim();
    final solutions = _collectSolutions();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CostAnalysisScreen(
          notes: notes,
          solutions: solutions,
        ),
      ),
    );
  }

  void _openPreferredSolutionAnalysis() {
    final notes = _notesController.text.trim();
    final solutions = _collectSolutions();
    final businessCase = _incomingBusinessCase.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreferredSolutionAnalysisScreen(
          notes: notes,
          solutions: solutions,
          businessCase: businessCase,
        ),
      ),
    );
  }

  void _scrollToSolutions() {
    final ctx = _solutionsSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        alignment: 0.1,
      );
    }
  }

  void _handleMenuTap(String title) {
    if (title == 'Home') {
      HomeScreen.open(context);
    } else if (title == 'LogOut') {
      AuthNav.signOutAndExit(context);
    }
  }

  Widget _buildMainContent() {
    final isMobile = AppBreakpoints.isMobile(context);
    final pagePadding = AppBreakpoints.pagePadding(context);
    final sectionGap = AppBreakpoints.sectionGap(context);
    final fieldGap = AppBreakpoints.fieldGap(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(pagePadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EditableContentText(
                  contentKey: 'potential_solutions_phase_title',
                  fallback: 'Initiation Phase',
                  category: 'business_case',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                const EditableContentText(
                  contentKey: 'potential_solutions_notes_heading',
                  fallback: 'Notes',
                  category: 'business_case',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ExpandingTextField(
                    controller: _notesController,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    minLines: 1,
                  ),
                ),
                SizedBox(height: sectionGap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    EditableContentText(
                      contentKey: 'potential_solutions_heading',
                      fallback: 'Potential Solution(s) ',
                      category: 'business_case',
                      key: _solutionsSectionKey,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: EditableContentText(
                        contentKey: 'potential_solutions_description',
                        fallback: AccessPolicy.isRestrictedAdminHost()
                            ? '(5 AI-generated solutions + add more as needed)'
                            : '(Maximum 3 solutions)',
                        category: 'business_case',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: fieldGap),
                _buildSolutionsSection(),
                const SizedBox(height: 20),
                // Navigation Buttons
                BusinessCaseNavigationButtons(
                  currentScreen: 'Potential Solutions',
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
                  onNext: _handleNextPressed,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSolutionsSection() {
    if (_isLoadingSolutions) {
      return _buildShimmerLoader();
    }

    if (_solutions.isEmpty) {
      return _buildEmptyState();
    }

    if (AppBreakpoints.isMobile(context)) {
      return Column(
        children: [
          for (int i = 0; i < _solutions.length; i++) _buildSolutionCardMobile(_solutions[i], i),
          if (AccessPolicy.isRestrictedAdminHost())
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton.icon(
                onPressed: _isLoadingSolutions ? null : _addSolution,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Solution'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade400),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
        ],
      );
    }

    return _buildDesktopSolutionsTable();
  }

  Widget _buildDesktopSolutionsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'Solution Title',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _solutions.length; i++)
                _buildSolutionRow(
                  _solutions[i],
                  index: i,
                  isLast: i == _solutions.length - 1,
                ),
            ],
          ),
        ),
        if (AccessPolicy.isRestrictedAdminHost())
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('0/230', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _isLoadingSolutions ? null : _addSolution,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Solution'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade400),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(3, (index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          const Text(
            'No solutions yet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your own or let AI suggest options.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _isLoadingSolutions ? null : _addSolution,
                icon: const Icon(Icons.add),
                label: const Text('Add Solution'),
              ),
              FilledButton.icon(
                onPressed: _isLoadingSolutions
                    ? null
                    : () {
                        setState(() {
                          _loadingError = null;
                          _isLoadingSolutions = true;
                        });
                        _generateInitialSolutions();
                      },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate with AI'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionRow(SolutionRow solution, {required int index, bool isLast = false}) {
    final isAdmin = AccessPolicy.isRestrictedAdminHost();
    final canDelete = isAdmin && !solution.isAiGenerated;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ExpandingTextField(
                      controller: solution.titleController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      minLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ExpandingTextField(
                controller: solution.descriptionController,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                minLines: 1,
              ),
            ),
          ),
          if (canDelete)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
              onPressed: () => _deleteSolution(index),
              tooltip: 'Delete solution',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildSolutionCardMobile(SolutionRow solution, int index) {
    final isAdmin = AccessPolicy.isRestrictedAdminHost();
    final canDelete = isAdmin && !solution.isAiGenerated;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Solution ${index + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54)),
              if (canDelete)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                  onPressed: () => _deleteSolution(index),
                  tooltip: 'Delete solution',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Solution Title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ExpandingTextField(
            controller: solution.titleController,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            minLines: 1,
          ),
          const SizedBox(height: 10),
          const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ExpandingTextField(
            controller: solution.descriptionController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            minLines: 2,
          ),
        ],
      ),
    );
  }

  Future<void> _handleNextPressed() async {
    if (_isLoadingSolutions) return;

    final trimmedNotes = _notesController.text.trim();
    final solutions = _solutions
        .map(
          (s) => AiSolutionItem(
            title: s.titleController.text.trim(),
            description: s.descriptionController.text.trim(),
          ),
        )
        .where((item) => item.title.isNotEmpty || item.description.isNotEmpty)
        .toList();

    if (solutions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one solution option before continuing.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    // Save solutions to provider
    final provider = ProjectDataHelper.getProvider(context);
    final potentialSolutions = _solutions.map((s) => PotentialSolution(
      title: s.titleController.text.trim(),
      description: s.descriptionController.text.trim(),
    )).toList();
    
    provider.updateInitiationData(
      notes: trimmedNotes,
      potentialSolutions: potentialSolutions,
    );
    
    // Save to Firebase
    await provider.saveToFirebase(checkpoint: 'potential_solutions');

    // Show 3-second loading dialog
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => const _LoadingDialog(),
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiskIdentificationScreen(
          notes: trimmedNotes,
          solutions: solutions,
          businessCase: _incomingBusinessCase,
        ),
      ),
    );
  }

  void _addSolution() {
    setState(() {
      _solutions.add(
        SolutionRow(
          titleController: TextEditingController(),
          descriptionController: TextEditingController(),
          isAiGenerated: false,
        ),
      );
    });
  }

  void _deleteSolution(int index) {
    if (index < 0 || index >= _solutions.length) return;
    final solution = _solutions[index];
    
    // Only allow deletion of user-added solutions on admin host
    if (!AccessPolicy.isRestrictedAdminHost() || solution.isAiGenerated) return;
    
    setState(() {
      solution.titleController.dispose();
      solution.descriptionController.dispose();
      _solutions.removeAt(index);
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (var solution in _solutions) {
      solution.titleController.dispose();
      solution.descriptionController.dispose();
    }
    super.dispose();
  }
}

class SolutionRow {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final bool isAiGenerated;

  SolutionRow({
    required this.titleController,
    required this.descriptionController,
    this.isAiGenerated = false,
  });
}

class _SidebarItem {
  final IconData icon;
  final String title;
  final bool enabled;
  final bool isActive;

  const _SidebarItem({
    required this.icon,
    required this.title,
    this.enabled = false,
    this.isActive = false,
  });
}

class _LoadingDialog extends StatefulWidget {
  const _LoadingDialog();

  @override
  State<_LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<_LoadingDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _controller,
                child: const Icon(
                  Icons.sync,
                  color: Color(0xFFFFD700),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Saving Solutions...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Preparing data for next phase',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
