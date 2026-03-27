import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
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
import 'package:ndu_project/screens/cost_analysis_screen.dart';
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/potential_solutions_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/it_considerations_screen.dart';
import 'package:ndu_project/screens/infrastructure_considerations_screen.dart';
import 'package:ndu_project/screens/settings_screen.dart';
import 'package:ndu_project/screens/preferred_solution_analysis_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/sidebar_navigation_service.dart';
import 'package:ndu_project/utils/auto_bullet_text_controller.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/services/access_policy.dart';
import 'package:ndu_project/widgets/page_hint_dialog.dart';
import 'package:ndu_project/widgets/page_regenerate_all_button.dart';
import 'package:ndu_project/widgets/field_regenerate_undo_buttons.dart';
import 'package:ndu_project/utils/rich_text_editing_controller.dart';
import 'package:ndu_project/widgets/text_formatting_toolbar.dart';

enum _MissingStakeholderAction { manual, autoFill, skip }

class _StakeholderAutoFillPreviewRow {
  const _StakeholderAutoFillPreviewRow({
    required this.title,
    required this.internalItems,
    required this.externalItems,
  });

  final String title;
  final List<String> internalItems;
  final List<String> externalItems;
}

class CoreStakeholdersScreen extends StatefulWidget {
  final String notes;
  final List<AiSolutionItem> solutions;
  const CoreStakeholdersScreen(
      {super.key, required this.notes, required this.solutions});

  @override
  State<CoreStakeholdersScreen> createState() => _CoreStakeholdersScreenState();
}

class _CoreStakeholdersScreenState extends State<CoreStakeholdersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _notesController;
  late List<TextEditingController>
      _internalStakeholderControllers; // Made mutable for dynamic addition
  late List<TextEditingController>
      _externalStakeholderControllers; // Made mutable for dynamic addition
  late final List<AiSolutionItem> _solutions; // Local mutable list
  late final OpenAiServiceSecure _openAi;
  bool _isGenerating = false;
  String? _error;
  bool _initiationExpanded = true;
  bool _businessCaseExpanded = true;
  bool _isAdmin = false;
  bool _didInitFromProvider = false;
  bool get _canUseAdminControls =>
      _isAdmin && AccessPolicy.isRestrictedAdminHost();

  TextEditingController _createStakeholderController({String text = ''}) {
    return RichAutoBulletTextController(text: text);
  }

  // ignore: unused_field
  static const List<_SidebarEntry> _navItems = [
    _SidebarEntry(icon: Icons.home_outlined, title: 'Home'),
    _SidebarEntry(
        icon: Icons.flag_outlined, title: 'Initiation Phase', isActive: true),
    _SidebarEntry(
        icon: Icons.timeline_outlined, title: 'Initiation: Front End Planning'),
    _SidebarEntry(icon: Icons.account_tree_outlined, title: 'Workflow Roadmap'),
    _SidebarEntry(icon: Icons.bolt_outlined, title: 'Agile Roadmap'),
    _SidebarEntry(icon: Icons.description_outlined, title: 'Contracting'),
    _SidebarEntry(icon: Icons.shopping_cart_outlined, title: 'Procurement'),
    _SidebarEntry(icon: Icons.settings_outlined, title: 'Settings'),
    _SidebarEntry(icon: Icons.logout_outlined, title: 'LogOut'),
  ];

  @override
  void initState() {
    super.initState();
    // IMPORTANT: don't read inherited widgets in initState (causes dependOnInheritedWidget errors).
    // We'll hydrate from provider in didChangeDependencies.
    _notesController = RichTextEditingController(text: widget.notes);
    // Notes = prose; no auto-bullet

    _solutions = List.from(widget.solutions); // Create mutable copy
    // Initialize with at least one empty item if solutions list is empty
    if (_solutions.isEmpty) {
      _solutions.add(AiSolutionItem(title: '', description: ''));
    }

    // Initialize controllers lists to match solutions length
    _internalStakeholderControllers = List.generate(
      _solutions.length,
      (index) => _createStakeholderController(),
    );
    _externalStakeholderControllers = List.generate(
      _solutions.length,
      (index) => _createStakeholderController(),
    );

    ApiKeyManager.initializeApiKey();
    _openAi = OpenAiServiceSecure();

    // Check admin status
    UserService.isCurrentUserAdmin().then((isAdmin) {
      if (mounted) setState(() => _isAdmin = isAdmin);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadExistingData();
      PageHintDialog.showIfNeeded(
        context: context,
        pageId: 'core_stakeholders',
        title: 'Core Stakeholders',
        message:
            'Identify key stakeholders for each potential solution. Separate internal stakeholders (team members, departments) from external stakeholders (regulatory bodies, vendors, government agencies).',
      );
      // Only auto-generate if we have actual solutions (not empty placeholder)
      if (widget.solutions.isNotEmpty) {
        _generateStakeholders();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromProvider) return;
    _didInitFromProvider = true;

    final provider = ProjectDataInherited.maybeOf(context);
    final existingNotes = provider?.projectData.coreStakeholdersData?.notes;
    if (existingNotes != null && existingNotes.trim().isNotEmpty) {
      _notesController.text = existingNotes;
    }
  }

  void _addNewItem() {
    // Only allow admins to add items, and enforce 3-item limit for non-admins
    if (!_canUseAdminControls) return;
    if (_solutions.length >= 3) return;

    setState(() {
      _solutions.add(AiSolutionItem(title: '', description: ''));
      final newInternalController = _createStakeholderController();
      _internalStakeholderControllers.add(newInternalController);
      final newExternalController = _createStakeholderController();
      _externalStakeholderControllers.add(newExternalController);
    });
  }

  void _loadExistingData() {
    try {
      final provider = ProjectDataInherited.read(context);
      final stakeholdersData = provider.projectData.coreStakeholdersData;

      if (stakeholdersData == null) return;

      // Load notes
      if (stakeholdersData.notes.isNotEmpty) {
        _notesController.text = stakeholdersData.notes;
      }

      // Load stakeholder data for each solution
      // Ensure we have enough controllers and solutions
      final requiredLength = stakeholdersData.solutionStakeholderData.length;
      while (_internalStakeholderControllers.length < requiredLength) {
        _solutions.add(AiSolutionItem(title: '', description: ''));
        final newInternalController = _createStakeholderController();
        _internalStakeholderControllers.add(newInternalController);
        final newExternalController = _createStakeholderController();
        _externalStakeholderControllers.add(newExternalController);
      }
      // Limit to 3 items for non-admins
      final itemsToLoad = _isAdmin
          ? stakeholdersData.solutionStakeholderData.length
          : (stakeholdersData.solutionStakeholderData.length > 3
              ? 3
              : stakeholdersData.solutionStakeholderData.length);

      for (int i = 0;
          i < itemsToLoad &&
              i < _internalStakeholderControllers.length &&
              i < _externalStakeholderControllers.length;
          i++) {
        final solutionStakeholder = stakeholdersData.solutionStakeholderData[i];
        if (i < _solutions.length) {
          _solutions[i] = AiSolutionItem(
            title: solutionStakeholder.solutionTitle,
            description: '',
          );
        }
        // Load internal and external stakeholders separately
        _internalStakeholderControllers[i].text =
            solutionStakeholder.internalStakeholders;
        _externalStakeholderControllers[i].text =
            solutionStakeholder.externalStakeholders;
        // Backward compatibility: if internal/external are empty but notableStakeholders has content, put it in external
        if (_internalStakeholderControllers[i].text.trim().isEmpty &&
            _externalStakeholderControllers[i].text.trim().isEmpty &&
            solutionStakeholder.notableStakeholders.trim().isNotEmpty) {
          _externalStakeholderControllers[i].text =
              solutionStakeholder.notableStakeholders;
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading existing core stakeholders data: $e');
    }
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
                    activeItemLabel: 'Core Stakeholders'),
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
                onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          // Removed top-left logo per request
          if (!isMobile) ...[
            const SizedBox(width: 20),
            IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                onPressed: () => Navigator.pop(context)),
            // Removed forward (">") icon per request
          ],
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
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(FirebaseAuthService.displayNameOrEmail(fallback: 'User'),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                  Text(FirebaseAuth.instance.currentUser?.email ?? 'User',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ]),
      ]),
    );
  }

  // ignore: unused_element
  Widget _buildSidebar() {
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    final bannerHeight = AppBreakpoints.isMobile(context) ? 72.0 : 96.0;
    return Container(
      width: sidebarWidth,
      color: Colors.white,
      child: Column(children: [
        // Full-width logo banner above the "StackOne" text
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
                  _buildNestedSubMenuItem('Core Stakeholders', isActive: true),
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
            ],
          ),
        ),
      ]),
    );
  }

  void _handleMenuTap(String title) {
    if (title == 'LogOut') {
      AuthNav.signOutAndExit(context);
    } else if (title == 'Settings') {
      SettingsScreen.open(context);
    }
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: InkWell(
        onTap: () => _handleMenuTap(title),
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
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ignore: unused_element
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
          child: Row(children: [
            Icon(Icons.circle,
                size: 8, color: isActive ? primary : Colors.grey[500]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      color: isActive ? primary : Colors.black87,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500),
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
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const EditableContentText(
                  contentKey: 'core_stakeholders_heading',
                  fallback: 'Core Stakeholders ',
                  category: 'business_case',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black)),
              EditableContentText(
                  contentKey: 'core_stakeholders_description',
                  fallback:
                      '(Identify key stakeholders especially if External, Regulatory, Governmental, etc.)',
                  category: 'business_case',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ]),
          ),
          // Page-level Regenerate All button
          PageRegenerateAllButton(
            onRegenerateAll: () async {
              final confirmed = await showRegenerateAllConfirmation(context);
              if (confirmed && mounted) {
                await _regenerateAllStakeholders();
              }
            },
            isLoading: _isGenerating,
            tooltip: 'Regenerate all stakeholders',
          ),
        ]),
        const SizedBox(height: 16),
        const EditableContentText(
          contentKey: 'core_stakeholders_notes_heading',
          fallback: 'Notes',
          category: 'business_case',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: 8),
        if (_error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis)),
              TextButton(
                  onPressed: _isGenerating ? null : _generateStakeholders,
                  child: const Text('Retry')),
            ]),
          ),
        ],
        if (_isGenerating) const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 8),
        TextFormattingToolbar(
          controller: _notesController,
          onBeforeUndo: () {
            _saveCoreStakeholdersData();
          },
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
          child: TextField(
            controller: _notesController,
            keyboardType: TextInputType.multiline,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            decoration: InputDecoration(
                hintText: 'Input your notes here...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero),
            minLines: 4,
            maxLines: null,
          ),
        ),
        const SizedBox(height: 24),
        const EditableContentText(
            contentKey: 'core_stakeholders_table_heading',
            fallback: 'Core Stakeholders',
            category: 'business_case',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
        const SizedBox(height: 6),
        Text('Reminder: update text within each box.',
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        // External (moved to top)
        const EditableContentText(
            contentKey: 'external_stakeholders_subheading',
            fallback: 'External',
            category: 'business_case',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 12),
        if (isMobile) ...[
          Column(
              children: List.generate(
                  _solutions.length, (i) => _buildExternalRow(i))),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.35))),
            child: const Row(children: [
              Expanded(
                  flex: 2,
                  child: Center(
                    child: EditableContentText(
                        contentKey: 'stakeholders_table_header_solution',
                        fallback: 'Potential Solution',
                        category: 'business_case',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  )),
              Expanded(
                  flex: 3,
                  child: Center(
                    child: EditableContentText(
                        contentKey: 'stakeholders_table_header_external',
                        fallback: 'External Stakeholders',
                        category: 'business_case',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  )),
            ]),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.35))),
            child: Column(
                children: List.generate(
                    _solutions.length, (i) => _buildExternalRow(i))),
          ),
        ],
        const SizedBox(height: 32),
        // Internal (moved to bottom)
        const EditableContentText(
            contentKey: 'internal_stakeholders_subheading',
            fallback: 'Internal',
            category: 'business_case',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 12),
        if (isMobile) ...[
          Column(
              children: List.generate(
                  _solutions.length, (i) => _buildInternalRow(i))),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.35))),
            child: const Row(children: [
              Expanded(
                  flex: 2,
                  child: Center(
                    child: EditableContentText(
                        contentKey: 'stakeholders_table_header_solution',
                        fallback: 'Potential Solution',
                        category: 'business_case',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  )),
              Expanded(
                  flex: 3,
                  child: Center(
                    child: EditableContentText(
                        contentKey: 'stakeholders_table_header_internal',
                        fallback: 'Internal Stakeholders',
                        category: 'business_case',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  )),
            ]),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.35))),
            child: Column(
                children: List.generate(
                    _solutions.length, (i) => _buildInternalRow(i))),
          ),
        ],
        const SizedBox(height: 16),
        // Add Item button
        Row(children: [
          Tooltip(
            message: 'Add a new stakeholder entry manually',
            child: const Icon(Icons.lightbulb_outline, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          // Only show Add Item button to admins (admin host only)
          if (_canUseAdminControls)
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

        // Navigation Buttons
        BusinessCaseNavigationButtons(
          currentScreen: 'Core Stakeholders',
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
          onNext: _handleNextPressed,
        ),
      ]),
    );
  }

  bool _hasRequiredStakeholderData(ProjectDataModel projectData) {
    final data = projectData.coreStakeholdersData;
    if (data == null || data.solutionStakeholderData.isEmpty) return false;
    return data.solutionStakeholderData.any(
      (item) =>
          item.internalStakeholders.trim().isNotEmpty ||
          item.externalStakeholders.trim().isNotEmpty,
    );
  }

  Future<_MissingStakeholderAction?> _showMissingStakeholderDialog() {
    return showDialog<_MissingStakeholderAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Core Stakeholders Incomplete'),
        content: const Text(
          'No stakeholder details were found. Add them manually, let AI generate them, or continue and complete later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(_MissingStakeholderAction.manual),
            child: const Text('Add Manually'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(_MissingStakeholderAction.autoFill),
            child: const Text('Auto Fill with AI'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_MissingStakeholderAction.skip),
            child: const Text('Skip for Now'),
          ),
        ],
      ),
    );
  }

  List<AiSolutionItem> _resolveStakeholderSolutionsForAutofill(
    ProjectDataModel projectData,
  ) {
    final solutions = _solutions
        .where(
            (s) => s.title.trim().isNotEmpty || s.description.trim().isNotEmpty)
        .toList(growable: true);
    if (solutions.isEmpty && projectData.projectName.trim().isNotEmpty) {
      solutions.add(
        AiSolutionItem(
          title: projectData.projectName.trim(),
          description: projectData.solutionDescription.trim(),
        ),
      );
    }
    return solutions;
  }

  Future<List<_StakeholderAutoFillPreviewRow>>
      _buildStakeholderAutofillPreview() async {
    final provider = ProjectDataHelper.getProvider(context);
    final projectData = provider.projectData;
    final solutionsToUse = _resolveStakeholderSolutionsForAutofill(projectData);
    if (solutionsToUse.isEmpty) return const <_StakeholderAutoFillPreviewRow>[];

    var contextNotes = _notesController.text.trim();
    if (contextNotes.isEmpty && projectData.projectName.trim().isNotEmpty) {
      contextNotes = 'Project: ${projectData.projectName.trim()}';
      if (projectData.solutionDescription.trim().isNotEmpty) {
        contextNotes +=
            '\nDescription: ${projectData.solutionDescription.trim()}';
      }
    }

    final generated = await _openAi.generateStakeholdersForSolutions(
      solutionsToUse,
      contextNotes: contextNotes,
    );
    final internalMap = generated['internal'] ?? const <String, List<String>>{};
    final externalMap = generated['external'] ?? const <String, List<String>>{};

    final preview = <_StakeholderAutoFillPreviewRow>[];
    for (var i = 0; i < solutionsToUse.length; i++) {
      final sourceTitle = solutionsToUse[i].title.trim();
      final title = sourceTitle.isEmpty ? 'Solution ${i + 1}' : sourceTitle;
      final internal = (internalMap[sourceTitle] ?? const <String>[])
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
      final external = (externalMap[sourceTitle] ?? const <String>[])
          .map((entry) => entry.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
      if (internal.isEmpty && external.isEmpty) continue;
      preview.add(
        _StakeholderAutoFillPreviewRow(
          title: title,
          internalItems: internal,
          externalItems: external,
        ),
      );
    }
    return preview;
  }

  Future<bool> _showStakeholderAutofillPreviewDialog(
    List<_StakeholderAutoFillPreviewRow> previewRows,
  ) async {
    if (previewRows.isEmpty) return false;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm AI Autofill'),
        content: SizedBox(
          width: 640,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 460),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review what AI will add before applying:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < previewRows.length; i++) ...[
                    Text(
                      previewRows[i].title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (previewRows[i].internalItems.isNotEmpty) ...[
                      const Text(
                        'Internal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        previewRows[i]
                            .internalItems
                            .map((item) => '- $item')
                            .join('\n'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (previewRows[i].externalItems.isNotEmpty) ...[
                      const Text(
                        'External',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        previewRows[i]
                            .externalItems
                            .map((item) => '- $item')
                            .join('\n'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                    if (i != previewRows.length - 1) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Apply AI Suggestions'),
          ),
        ],
      ),
    );
    return approved == true;
  }

  Future<bool> _autoFillStakeholdersWithConfirmation() async {
    if (_isGenerating) return false;
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final previewRows = await _buildStakeholderAutofillPreview();
      if (!mounted) return false;
      if (previewRows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI could not generate stakeholder suggestions. Add an entry manually or try again.',
            ),
          ),
        );
        return false;
      }

      final approved = await _showStakeholderAutofillPreviewDialog(previewRows);
      if (!mounted || !approved) return false;

      final provider = ProjectDataHelper.getProvider(context);
      setState(() {
        while (_solutions.length < previewRows.length) {
          _solutions.add(
            AiSolutionItem(
              title: previewRows[_solutions.length].title,
              description: '',
            ),
          );
        }
        while (_internalStakeholderControllers.length < previewRows.length) {
          _internalStakeholderControllers.add(_createStakeholderController());
        }
        while (_externalStakeholderControllers.length < previewRows.length) {
          _externalStakeholderControllers.add(_createStakeholderController());
        }

        for (var i = 0; i < previewRows.length; i++) {
          final row = previewRows[i];
          provider.addFieldToHistory(
            'stakeholder_internal_${row.title}',
            _internalStakeholderControllers[i].text,
            isAiGenerated: true,
          );
          provider.addFieldToHistory(
            'stakeholder_external_${row.title}',
            _externalStakeholderControllers[i].text,
            isAiGenerated: true,
          );

          _solutions[i] = AiSolutionItem(
            title: row.title,
            description: _solutions[i].description,
          );
          _internalStakeholderControllers[i].text =
              row.internalItems.map((item) => '- $item').join('\n');
          _externalStakeholderControllers[i].text =
              row.externalItems.map((item) => '- $item').join('\n');
        }
      });

      await provider.saveToFirebase(checkpoint: 'stakeholders_regenerated');
      await _saveCoreStakeholdersData();
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI stakeholder suggestions applied.')),
      );
      return true;
    } catch (e) {
      _error = e.toString();
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI autofill failed: $e')),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _handleNextPressed() async {
    // 1. Save data FIRST before validation check
    await _saveCoreStakeholdersData();

    if (!mounted) return;

    // 2. Validate data completeness
    var hasCoreStakeholders = _hasRequiredStakeholderData(
        ProjectDataInherited.read(context).projectData);

    if (!hasCoreStakeholders) {
      final action = await _showMissingStakeholderDialog();
      if (!mounted || action == null) return;

      if (action == _MissingStakeholderAction.manual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Continuing without stakeholder details. You can complete this later or let AI fill it in later.',
            ),
          ),
        );
      }

      if (action == _MissingStakeholderAction.autoFill) {
        final applied = await _autoFillStakeholdersWithConfirmation();
        if (!mounted || !applied) return;
        if (!mounted) return;
        hasCoreStakeholders = _hasRequiredStakeholderData(
          ProjectDataInherited.read(context).projectData,
        );
        if (!hasCoreStakeholders) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'AI could not generate stakeholder details right now. Continuing anyway so you can complete this later.',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Continuing without stakeholder details. You can complete this later.',
            ),
          ),
        );
      }
    }

    // 3. Smart checkpoint check: If destination is the immediate next checkpoint, allow it (if data is valid)
    final nextCheckpoint =
        SidebarNavigationService.instance.getNextItem('core_stakeholders');
    if (nextCheckpoint?.checkpoint != 'cost_analysis') {
      // Use standard lock check for non-sequential navigation
      final isLocked =
          ProjectDataHelper.isDestinationLocked(context, 'cost_analysis');
      if (isLocked) {
        ProjectDataHelper.showLockedDestinationMessage(
            context, 'Cost Benefit Analysis');
        return;
      }
    }

    final nav = Navigator.of(context);
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
                Text('Processing core stakeholders data...'),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(
        seconds: 1)); // Reduced delay from 3s to 1s for better UX

    if (!mounted) return;
    nav.pop();

    nav.push(
      MaterialPageRoute(
        builder: (context) => CostAnalysisScreen(
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

  Future<void> _saveCoreStakeholdersData() async {
    try {
      final provider = ProjectDataInherited.read(context);

      // Collect all stakeholder data from all solutions (including manually added items)
      final solutionStakeholderData = <SolutionStakeholderData>[];
      for (int i = 0;
          i < _solutions.length &&
              i < _internalStakeholderControllers.length &&
              i < _externalStakeholderControllers.length;
          i++) {
        final solutionTitle = _solutions[i].title.isNotEmpty
            ? _solutions[i].title
            : 'Stakeholder Entry ${i + 1}';
        final internalStakeholders =
            _internalStakeholderControllers[i].text.trim();
        final externalStakeholders =
            _externalStakeholderControllers[i].text.trim();

        // Add if there's actual content in either internal or external
        if (internalStakeholders.isNotEmpty ||
            externalStakeholders.isNotEmpty) {
          solutionStakeholderData.add(SolutionStakeholderData(
            solutionTitle: solutionTitle,
            notableStakeholders:
                '', // Deprecated but kept for backward compatibility
            internalStakeholders: internalStakeholders,
            externalStakeholders: externalStakeholders,
          ));
        }
      }

      final coreStakeholdersData = CoreStakeholdersData(
        notes: _notesController.text,
        solutionStakeholderData: solutionStakeholderData,
      );

      provider.updateProjectData(
        provider.projectData
            .copyWith(coreStakeholdersData: coreStakeholdersData),
      );

      // Save to Firebase with checkpoint
      await provider.saveToFirebase(checkpoint: 'core_stakeholders');
    } catch (e) {
      debugPrint('Error saving core stakeholders data: $e');
    }
  }

  Widget _buildInternalRow(int index) {
    return _buildStakeholderRow(
      index,
      _internalStakeholderControllers[index],
      'Enter internal stakeholders for Solution ${index + 1}...',
      isInternal: true,
    );
  }

  Widget _buildExternalRow(int index) {
    return _buildStakeholderRow(
      index,
      _externalStakeholderControllers[index],
      'Enter external stakeholders for Solution ${index + 1}...',
      isInternal: false,
    );
  }

  Widget _buildStakeholderRow(
      int index, TextEditingController controller, String hintText,
      {bool isInternal = true}) {
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
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _numberBadge(index + 1),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.title.isEmpty ? 'Potential Solution' : s.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ]),
              if (s.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(s.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 10),
              _stakeholderTextArea(controller, hintText, index, isInternal),
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 2,
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
                                        ? 'Potential Solution'
                                        : s.title,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600)),
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
              Expanded(
                  flex: 3,
                  child: _stakeholderTextArea(
                      controller, hintText, index, isInternal)),
            ]),
    );
  }

  Widget _numberBadge(int number) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text('$number',
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Drawer _buildMobileDrawer() {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.88,
      child: const SafeArea(
        child: InitiationLikeSidebar(
          activeItemLabel: 'Core Stakeholders',
        ),
      ),
    );
  }

  Widget _stakeholderTextArea(TextEditingController controller, String hintText,
      int index, bool isInternal) {
    final provider = ProjectDataHelper.getProvider(context);
    final solutionTitle =
        index < _solutions.length ? _solutions[index].title : '';
    final fieldKey =
        'stakeholder_${isInternal ? 'internal' : 'external'}_${solutionTitle}_$index';
    final canUndo = provider.canUndoField(fieldKey);
    final canRedo = provider.canRedoField(fieldKey);

    return HoverableFieldControls(
      isAiGenerated: true,
      isLoading: false,
      canUndo: canUndo,
      canRedo: canRedo,
      onRegenerate: () async {
        // Add current value to history
        provider.addFieldToHistory(fieldKey, controller.text,
            isAiGenerated: true);
        // Regenerate this specific stakeholder field
        await _regenerateSingleStakeholderField(controller, index, isInternal);
      },
      onUndo: () async {
        final previousValue = provider.projectData.undoField(fieldKey);
        if (previousValue != null) {
          controller.text = previousValue;
          await provider.saveToFirebase(checkpoint: 'stakeholder_undo');
        }
      },
      onRedo: () async {
        final nextValue = provider.projectData.redoField(fieldKey);
        if (nextValue != null) {
          controller.text = nextValue;
          await provider.saveToFirebase(checkpoint: 'stakeholder_redo');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormattingToolbar(controller: controller),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: null,
              onChanged: (value) {
                provider.addFieldToHistory(fieldKey, value,
                    isAiGenerated: true);
              },
              decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero),
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _regenerateSingleStakeholderField(
      TextEditingController controller, int index, bool isInternal) async {
    final provider = ProjectDataHelper.getProvider(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (index >= _solutions.length) return;

      final solution = _solutions[index];
      final solutionsToUse = [solution];
      final contextNotes = _notesController.text.trim();

      final result = await _openAi.generateStakeholdersForSolutions(
        solutionsToUse,
        contextNotes: contextNotes,
      );

      if (!mounted) return;

      final internalMap = result['internal'] ?? <String, List<String>>{};
      final externalMap = result['external'] ?? <String, List<String>>{};

      if (isInternal) {
        final internalStakeholders = internalMap[solution.title] ?? <String>[];
        controller.text = internalStakeholders.isEmpty
            ? ''
            : internalStakeholders.map((e) => '- $e').join('\n');
      } else {
        final externalStakeholders = externalMap[solution.title] ?? <String>[];
        controller.text = externalStakeholders.isEmpty
            ? ''
            : externalStakeholders.map((e) => '- $e').join('\n');
      }

      await provider.saveToFirebase(
          checkpoint: 'stakeholder_field_regenerated');

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Stakeholder field regenerated')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger
          .showSnackBar(SnackBar(content: Text('Failed to regenerate: $e')));
    }
  }

  Future<void> _generateStakeholders() async {
    if (_isGenerating) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final provider = ProjectDataHelper.getProvider(context);

      // Add current values to history before regenerating
      for (int i = 0; i < _solutions.length; i++) {
        if (i < _internalStakeholderControllers.length) {
          final fieldKey = 'stakeholder_internal_${_solutions[i].title}';
          provider.addFieldToHistory(
              fieldKey, _internalStakeholderControllers[i].text,
              isAiGenerated: true);
        }
        if (i < _externalStakeholderControllers.length) {
          final fieldKey = 'stakeholder_external_${_solutions[i].title}';
          provider.addFieldToHistory(
              fieldKey, _externalStakeholderControllers[i].text,
              isAiGenerated: true);
        }
      }

      // Get project context for fallback if solutions are empty
      final projectData = provider.projectData;
      final projectName = projectData.projectName;
      final projectDescription = projectData.solutionDescription;

      // Use solutions if available, otherwise create a placeholder from project name
      final solutionsToUse = _solutions
          .where((s) => s.title.isNotEmpty || s.description.isNotEmpty)
          .toList();
      if (solutionsToUse.isEmpty && projectName.isNotEmpty) {
        solutionsToUse.add(AiSolutionItem(
          title: projectName,
          description: projectDescription,
        ));
        // Ensure we have controllers for this
        if (_internalStakeholderControllers.isEmpty) {
          final newInternalController = _createStakeholderController();
          _internalStakeholderControllers.add(newInternalController);
          final newExternalController = _createStakeholderController();
          _externalStakeholderControllers.add(newExternalController);
        }
        if (_solutions.isEmpty) {
          _solutions.addAll(solutionsToUse);
        }
      }

      if (solutionsToUse.isEmpty) {
        setState(() {
          _error =
              'Please add at least one solution or project name to generate stakeholders.';
          _isGenerating = false;
        });
        return;
      }

      // Build context notes with project info if available
      String contextNotes = _notesController.text.trim();
      if (contextNotes.isEmpty && projectName.isNotEmpty) {
        contextNotes = 'Project: $projectName';
        if (projectDescription.isNotEmpty) {
          contextNotes += '\nDescription: $projectDescription';
        }
      }

      final result = await _openAi.generateStakeholdersForSolutions(
        solutionsToUse,
        contextNotes: contextNotes,
      );

      if (!mounted) return;

      // Apply generated data to controllers (separate internal and external)
      final internalMap = result['internal'] ?? <String, List<String>>{};
      final externalMap = result['external'] ?? <String, List<String>>{};

      for (int i = 0;
          i < solutionsToUse.length &&
              i < _internalStakeholderControllers.length &&
              i < _externalStakeholderControllers.length;
          i++) {
        final title = solutionsToUse[i].title;
        final internalStakeholders = internalMap[title] ?? <String>[];
        final externalStakeholders = externalMap[title] ?? <String>[];

        _internalStakeholderControllers[i].text = internalStakeholders.isEmpty
            ? ''
            : internalStakeholders.map((e) => '- $e').join('\n');
        _externalStakeholderControllers[i].text = externalStakeholders.isEmpty
            ? ''
            : externalStakeholders.map((e) => '- $e').join('\n');
      }

      // Auto-save after regeneration
      await provider.saveToFirebase(checkpoint: 'stakeholders_regenerated');

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Stakeholders regenerated successfully')),
      );
    } catch (e) {
      _error = e.toString();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to regenerate stakeholders: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
        // Auto-save after generation
        _saveCoreStakeholdersData();
      }
    }
  }

  Future<void> _regenerateAllStakeholders() async {
    await _generateStakeholders();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _internalStakeholderControllers) {
      c.dispose();
    }
    for (final c in _externalStakeholderControllers) {
      c.dispose();
    }
    super.dispose();
  }
}

class _SidebarEntry {
  final IconData icon;
  final String title;
  final bool isActive;
  const _SidebarEntry(
      {required this.icon, required this.title, this.isActive = false});
}
