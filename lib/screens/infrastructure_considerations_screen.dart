import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart'; // provides AiSolutionItem model
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/business_case_header.dart';
import 'package:ndu_project/widgets/business_case_navigation_buttons.dart';
// Removed AppLogo from the top header for this screen per request
import 'package:ndu_project/screens/core_stakeholders_screen.dart';
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/potential_solutions_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/it_considerations_screen.dart';
import 'package:ndu_project/screens/settings_screen.dart';
import 'package:ndu_project/screens/cost_analysis_screen.dart';
import 'package:ndu_project/screens/preferred_solution_analysis_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/sidebar_navigation_service.dart';
import 'package:ndu_project/services/access_policy.dart';
import 'package:ndu_project/widgets/page_hint_dialog.dart';
import 'package:ndu_project/widgets/text_formatting_toolbar.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';
import 'package:ndu_project/widgets/field_regenerate_undo_buttons.dart';

class InfrastructureConsiderationsScreen extends StatefulWidget {
  final String notes;
  final List<AiSolutionItem> solutions;
  const InfrastructureConsiderationsScreen(
      {super.key, required this.notes, required this.solutions});

  @override
  State<InfrastructureConsiderationsScreen> createState() =>
      _InfrastructureConsiderationsScreenState();
}

class _InfrastructureConsiderationsScreenState
    extends State<InfrastructureConsiderationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _notesController;
  late List<TextEditingController>
      _infraControllers; // Made mutable for dynamic addition
  late final List<AiSolutionItem> _solutions; // Local mutable list
  bool _initiationExpanded = true;
  bool _businessCaseExpanded = true;
  bool _isAdmin = false;
  bool get _canUseAdminControls => _isAdmin && AccessPolicy.isRestrictedAdminHost();
  final OpenAiServiceSecure _openAi = OpenAiServiceSecure();
  bool _isGeneratingInfra = false;

  void _addNewItem() {
    if (!_canUseAdminControls) return;
    setState(() {
      _solutions.add(AiSolutionItem(title: '', description: ''));
      _infraControllers.add(TextEditingController());
    });
  }

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.notes);
    _solutions = List.from(widget.solutions); // Create mutable copy
    // Initialize with at least one empty item if solutions list is empty
    if (_solutions.isEmpty) {
      _solutions.add(AiSolutionItem(title: '', description: ''));
    }
    _infraControllers =
        List.generate(_solutions.length, (_) => TextEditingController());

    // Initialize API key manager
    ApiKeyManager.initializeApiKey();

    // Check admin status (controls Add Item visibility)
    UserService.isCurrentUserAdmin().then((isAdmin) {
      if (mounted) setState(() => _isAdmin = isAdmin);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadExistingData();
      PageHintDialog.showIfNeeded(
        context: context,
        pageId: 'infrastructure_considerations',
        title: 'Infrastructure Considerations',
        message:
            'List the main infrastructure considerations for each potential solution. If suggestions look repetitive, refine each entry to match the specific solution.',
      );
      _generateInfrastructureIfNeeded();
    });
  }

  void _loadExistingData() {
    try {
      final provider = ProjectDataInherited.of(context);
      final infraData = provider.projectData.infrastructureConsiderationsData;

      if (infraData == null) return;

      // Load notes
      if (infraData.notes.isNotEmpty) {
        _notesController.text = infraData.notes;
      }

      // Load infrastructure data for each solution
      // Ensure we have enough controllers and solutions
      while (_infraControllers.length <
          infraData.solutionInfrastructureData.length) {
        _solutions.add(AiSolutionItem(title: '', description: ''));
        _infraControllers.add(TextEditingController());
      }
      for (int i = 0;
          i < infraData.solutionInfrastructureData.length &&
              i < _infraControllers.length;
          i++) {
        final solutionInfra = infraData.solutionInfrastructureData[i];
        if (i < _solutions.length) {
          _solutions[i] = AiSolutionItem(
            title: solutionInfra.solutionTitle,
            description: '',
          );
        }
        _infraControllers[i].text = solutionInfra.majorInfrastructure;
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint(
          'Error loading existing infrastructure considerations data: $e');
    }
  }

  Future<void> _generateInfrastructureIfNeeded() async {
    if (!mounted) return;
    if (_isGeneratingInfra) return;

    // If any row already has content, do not overwrite.
    final hasAny = _infraControllers.any((c) => c.text.trim().isNotEmpty);
    if (hasAny) return;

    if (_solutions.isEmpty) return;
    setState(() => _isGeneratingInfra = true);

    try {
      final provider = ProjectDataHelper.getProvider(context);
      
      // Add current values to history before regenerating
      for (int i = 0; i < _solutions.length && i < _infraControllers.length; i++) {
        final fieldKey = 'infra_${_solutions[i].title}_$i';
        provider.addFieldToHistory(fieldKey, _infraControllers[i].text, isAiGenerated: true);
      }
      
      // Generate infrastructure suggestions (with tailored fallback if OpenAI not configured)
      final result = await _openAi.generateInfrastructureForSolutions(
        _solutions, 
        contextNotes: _notesController.text,
      );

      if (!mounted) return;
      for (int i = 0; i < _solutions.length && i < _infraControllers.length; i++) {
        final title = _solutions[i].title.trim();
        final items = result[title] ?? const <String>[];
        if (items.isEmpty) continue;
        _infraControllers[i].text = items.map((e) => '- $e').join('\n');
      }
      
      // Auto-save after regeneration
      await provider.saveToFirebase(checkpoint: 'infrastructure_regenerated');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Infrastructure considerations regenerated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error generating infrastructure considerations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to regenerate infrastructure: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingInfra = false);
    }
  }

  Future<void> _regenerateAllInfrastructure() async {
    if (_isGeneratingInfra) return;
    setState(() => _isGeneratingInfra = true);
    
    try {
      final provider = ProjectDataHelper.getProvider(context);
      
      // Add current values to history
      for (int i = 0; i < _solutions.length && i < _infraControllers.length; i++) {
        final fieldKey = 'infra_${_solutions[i].title}_$i';
        provider.addFieldToHistory(fieldKey, _infraControllers[i].text, isAiGenerated: true);
      }
      
      final result = await _openAi.generateInfrastructureForSolutions(
        _solutions,
        contextNotes: _notesController.text,
      );
      
      for (int i = 0; i < _solutions.length && i < _infraControllers.length; i++) {
        final title = _solutions[i].title.trim();
        final items = result[title] ?? const <String>[];
        _infraControllers[i].text = items.isEmpty ? '' : items.map((e) => '- $e').join('\n');
      }
      
      await provider.saveToFirebase(checkpoint: 'infrastructure_regenerated');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Infrastructure regenerated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to regenerate: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingInfra = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final controller in _infraControllers) {
      controller.dispose();
    }
    super.dispose();
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
          Column(children: [
            BusinessCaseHeader(scaffoldKey: _scaffoldKey),
            Expanded(
                child: Row(children: [
              DraggableSidebar(
                openWidth: sidebarWidth,
                child: const InitiationLikeSidebar(
                    activeItemLabel: 'Infrastructure Considerations'),
              ),
              Expanded(child: _buildMainContent()),
            ])),
          ]),
          const KazAiChatBubble(),
          const AdminEditToggle(),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTopHeader() {
    final isMobile = AppBreakpoints.isMobile(context);
    return Container(
      height: isMobile ? 88 : 110,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: Row(children: [
        Row(children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          // Top-left logo removed; keep only a back button on larger screens
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: () => Navigator.pop(context),
            ),
          // Forward chevron (>) removed per request
        ]),
        const Spacer(),
        if (!isMobile)
          const Text('Initiation Phase',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
        const Spacer(),
        Row(children: [
          Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: Colors.blue, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white, size: 20)),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            StreamBuilder<bool>(
              stream: UserService.watchAdminStatus(),
              builder: (context, snapshot) {
                final email = FirebaseAuth.instance.currentUser?.email ?? '';
                final isAdmin =
                    snapshot.data ?? UserService.isAdminEmail(email);
                final role = isAdmin ? 'Admin' : 'Member';
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FirebaseAuthService.displayNameOrEmail(fallback: 'User'),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black),
                    ),
                    Text(role,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ]),
      ]),
    );
  }

  // ignore: unused_element
  Widget _buildSidebar() {
    final isMobile = AppBreakpoints.isMobile(context);
    final double bannerHeight = isMobile ? 72 : 96;
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    return Container(
      width: sidebarWidth,
      color: Colors.white,
      child: Column(children: [
        // Full-width banner image above the "StackOne" text
        SizedBox(
          width: double.infinity,
          height: bannerHeight,
          child: Center(child: AppLogo(height: 64)),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
          child: const Row(children: [
            CircleAvatar(radius: 20, backgroundColor: Colors.grey),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('StackOne',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),
            ])
          ]),
        ),
        Expanded(
          child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildMenuItem(Icons.home_outlined, 'Home'),
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
                        isActive: true),
                    _buildNestedSubMenuItem('Core Stakeholders',
                        onTap: _openCoreStakeholders),
                    _buildNestedSubMenuItem(
                        'Cost Benefit Analysis & Financial Metrics',
                        onTap: _openCostAnalysis),
                    _buildNestedSubMenuItem('Preferred Solution Analysis',
                        onTap: _openPreferredSolutionAnalysis),
                  ],
                ],
                _buildMenuItem(
                    Icons.timeline_outlined, 'Initiation: Front End Planning'),
                _buildMenuItem(Icons.account_tree_outlined, 'Workflow Roadmap'),
                _buildMenuItem(Icons.bolt_outlined, 'Agile Roadmap'),
                _buildMenuItem(Icons.description_outlined, 'Contracting'),
                _buildMenuItem(Icons.shopping_cart_outlined, 'Procurement'),
                const SizedBox(height: 20),
                _buildMenuItem(Icons.settings_outlined, 'Settings'),
                _buildMenuItem(Icons.logout_outlined, 'LogOut'),
              ]),
        ),
      ]),
    );
  }

  Drawer _buildMobileDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(
                leading: CircleAvatar(radius: 18, backgroundColor: Colors.grey),
                title: Text('StackOne')),
            const Divider(height: 1),
            _buildMenuItem(Icons.home_outlined, 'Home'),
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
                    isActive: true),
                _buildNestedSubMenuItem('Core Stakeholders', onTap: () {
                  Navigator.of(context).maybePop();
                  _openCoreStakeholders();
                }),
                _buildNestedSubMenuItem(
                    'Cost Benefit Analysis & Financial Metrics', onTap: () {
                  Navigator.of(context).maybePop();
                  _openCostAnalysis();
                }),
                _buildNestedSubMenuItem('Preferred Solution Analysis',
                    onTap: () {
                  Navigator.of(context).maybePop();
                  _openPreferredSolutionAnalysis();
                }),
              ],
            ],
            _buildMenuItem(
                Icons.timeline_outlined, 'Initiation: Front End Planning'),
            _buildMenuItem(Icons.account_tree_outlined, 'Workflow Roadmap'),
            _buildMenuItem(Icons.bolt_outlined, 'Agile Roadmap'),
            _buildMenuItem(Icons.description_outlined, 'Contracting'),
            _buildMenuItem(Icons.shopping_cart_outlined, 'Procurement'),
            const Divider(height: 1),
            _buildMenuItem(Icons.settings_outlined, 'Settings'),
            _buildMenuItem(Icons.logout_outlined, 'LogOut'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool active = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: InkWell(
        onTap: () {
          if (title == 'LogOut') {
            AuthNav.signOutAndExit(context);
          } else if (title == 'Settings') {
            SettingsScreen.open(context);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: active
              ? BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Row(children: [
            Icon(icon,
                size: 20,
                color: active ? theme.colorScheme.primary : Colors.black87),
            const SizedBox(width: 16),
            Expanded(
                child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: active ? theme.colorScheme.primary : Colors.black87,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSubMenuItem(String title,
      {VoidCallback? onTap, bool isActive = false}) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
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
              child: Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      color: isActive ? primary : Colors.black87,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
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
          child: Row(children: [
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
          ]),
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

  void _openCostAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CostAnalysisScreen(
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const EditableContentText(
              contentKey: 'infrastructure_considerations_heading',
              fallback: 'Infrastructure Considerations ',
              category: 'business_case',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black)),
          Expanded(
            child: EditableContentText(
                contentKey: 'infrastructure_considerations_description',
                fallback:
                    '(List major required infrastructure considerations for each Potential Solution.)',
                category: 'business_case',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ),
          // Page-level Regenerate All button
          PageRegenerateAllButton(
            onRegenerateAll: () async {
              final confirmed = await showRegenerateAllConfirmation(context);
              if (confirmed && mounted) {
                await _regenerateAllInfrastructure();
              }
            },
            isLoading: _isGeneratingInfra,
            tooltip: 'Regenerate all infrastructure considerations',
          ),
        ]),
        const SizedBox(height: 16),
        const EditableContentText(
          contentKey: 'infrastructure_considerations_notes_heading',
          fallback: 'Notes',
          category: 'business_case',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
          child: TextField(
            controller: _notesController,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            decoration: InputDecoration(
                hintText: 'Input your notes here...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero),
            minLines: 1,
            maxLines: null,
          ),
        ),
        const SizedBox(height: 24),
        if (isMobile) ...[
          Text('Reminder: update text within each box.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Column(children: List.generate(_solutions.length, (i) => _row(i))),
        ] else ...[
          const Text('Main Infrastructure Consideration for each potential solution',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
          const SizedBox(height: 6),
          Text('Reminder: update text within each box.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.35))),
            child: const Row(children: [
              Expanded(
                  child: Text('Potential Solution',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(
                  child: Text('Major Infrastructure',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.35))),
            child: Column(
                children: List.generate(_solutions.length, (i) => _row(i))),
          ),
        ],
        if (_canUseAdminControls) ...[
          const SizedBox(height: 16),
          // Add Item button (admin-only)
          Row(children: [
            Tooltip(
              message: 'Add a new infrastructure consideration entry manually',
              child: const Icon(Icons.lightbulb_outline, color: Colors.black87),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addNewItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),
          ]),
          const SizedBox(height: 24),
        ],

        // Navigation Buttons
        BusinessCaseNavigationButtons(
          currentScreen: 'Infrastructure Considerations',
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
          onNext: _handleNextPressed,
        ),
      ]),
    );
  }

  Future<void> _handleNextPressed() async {
    // 1. Save data FIRST before validation
    await _saveInfrastructureConsiderationsData();
    if (!mounted) return;

    // 2. Validate data completeness
    final provider = ProjectDataInherited.of(context);
    final projectData = provider.projectData;
    final hasInfraData = projectData.infrastructureConsiderationsData != null &&
        projectData.infrastructureConsiderationsData!.solutionInfrastructureData
            .isNotEmpty &&
        projectData.infrastructureConsiderationsData!.solutionInfrastructureData
            .any((item) => item.majorInfrastructure.trim().isNotEmpty);

    if (!hasInfraData) {
      if (mounted) {
        ProjectDataHelper.showMissingDataMessage(context,
            'Please add infrastructure considerations for at least one solution before proceeding.');
      }
      return;
    }

    // 3. Smart checkpoint check
    final nextCheckpoint = SidebarNavigationService.instance
        .getNextItem('infrastructure_considerations');
    if (nextCheckpoint?.checkpoint != 'core_stakeholders') {
      // Use standard lock check for non-sequential navigation
      final isLocked =
          ProjectDataHelper.isDestinationLocked(context, 'core_stakeholders');
      if (isLocked) {
        ProjectDataHelper.showLockedDestinationMessage(
            context, 'Core Stakeholders');
        return;
      }
    }

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
                Text('Processing infrastructure considerations data...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Reduced delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.of(context).pop();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoreStakeholdersScreen(
          notes: _notesController.text,
          solutions: widget.solutions,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _nextButton({required bool expand}) {
    final button = ElevatedButton(
      onPressed: _handleNextPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        minimumSize: expand ? const Size.fromHeight(52) : null,
      ),
      child: const Text('Next',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Future<void> _saveInfrastructureConsiderationsData() async {
    try {
      final provider = ProjectDataInherited.of(context);

      // Collect all infrastructure data from all solutions (including manually added items)
      final solutionInfrastructureData = <SolutionInfrastructureData>[];
      for (int i = 0;
          i < _solutions.length && i < _infraControllers.length;
          i++) {
        final solutionTitle = _solutions[i].title.isNotEmpty
            ? _solutions[i].title
            : 'Potential Solution ${i + 1}';
        final majorInfrastructure = _infraControllers[i].text.trim();

        // Only add if there's actual content (majorInfrastructure is not empty)
        if (majorInfrastructure.isNotEmpty) {
          solutionInfrastructureData.add(SolutionInfrastructureData(
            solutionTitle: solutionTitle,
            majorInfrastructure: majorInfrastructure,
          ));
        }
      }

      final infrastructureConsiderationsData = InfrastructureConsiderationsData(
        notes: _notesController.text,
        solutionInfrastructureData: solutionInfrastructureData,
      );

      provider.updateProjectData(
        provider.projectData.copyWith(
            infrastructureConsiderationsData: infrastructureConsiderationsData),
      );

      // Save to Firebase with checkpoint
      await provider.saveToFirebase(
          checkpoint: 'infrastructure_considerations');
    } catch (e) {
      debugPrint('Error saving infrastructure considerations data: $e');
    }
  }

  Widget _row(int index) {
    final isMobile = AppBreakpoints.isMobile(context);
    // Handle cases where we have more controllers than initial solutions (user added items)
    final s = index < _solutions.length
        ? _solutions[index]
        : AiSolutionItem(title: '', description: '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: Colors.grey.withValues(alpha: 0.25)))),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                s.title.isEmpty ? 'Potential Solution ${index + 1}' : s.title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (s.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(s.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 10),
              _infraTextArea(_infraControllers[index], index: index),
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _numberBadge(index + 1),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s.title.isEmpty
                                      ? 'Potential Solution ${index + 1}'
                                      : s.title,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ]),
                        if (s.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(s.description,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              maxLines: 5,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis),
                        ]
                      ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _infraTextArea(_infraControllers[index], index: index)),
            ]),
    );
  }

  Widget _numberBadge(int number) {
    final theme = Theme.of(context);
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$number',
        style: const TextStyle(
            fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _infraTextArea(TextEditingController controller, {required int index}) {
    final provider = ProjectDataHelper.getProvider(context);
    final solutionTitle = index < _solutions.length ? _solutions[index].title : '';
    final fieldKey = 'infra_${solutionTitle}_$index';
    final canUndo = provider.canUndoField(fieldKey);

    return HoverableFieldControls(
      isAiGenerated: true,
      isLoading: false,
      canUndo: canUndo,
      onRegenerate: () async {
        // Add current value to history
        provider.addFieldToHistory(fieldKey, controller.text, isAiGenerated: true);
        // Regenerate this specific infrastructure field
        await _regenerateSingleInfraField(controller, index);
      },
      onUndo: () async {
        final previousValue = provider.projectData.undoField(fieldKey);
        if (previousValue != null) {
          controller.text = previousValue;
          await provider.saveToFirebase(checkpoint: 'infra_undo');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormattingToolbar(
            controller: controller,
            onBeforeUndo: () => _saveInfrastructureConsiderationsData(),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.25))),
            child: TextField(
              controller: controller,
              minLines: 2,
              maxLines: null,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Enter main infrastructure considerations for Solution ${index + 1}...',
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateSingleInfraField(TextEditingController controller, int index) async {
    if (index >= _solutions.length) return;

    final provider = ProjectDataHelper.getProvider(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final solution = _solutions[index];
      final solutionsToUse = [solution];
      
      final result = await _openAi.generateInfrastructureForSolutions(
        solutionsToUse,
        contextNotes: _notesController.text,
      );
      if (!mounted) return;
      
      final items = result[solution.title] ?? const <String>[];
      controller.text = items.isEmpty ? '' : items.map((e) => '- $e').join('\n');
      
      await provider.saveToFirebase(checkpoint: 'infra_field_regenerated');
      
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Infrastructure field regenerated')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to regenerate: $e')),
        );
      }
    }
  }
}
