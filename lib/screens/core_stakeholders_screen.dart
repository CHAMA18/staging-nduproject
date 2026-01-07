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

class CoreStakeholdersScreen extends StatefulWidget {
  final String notes;
  final List<AiSolutionItem> solutions;
  const CoreStakeholdersScreen({super.key, required this.notes, required this.solutions});

  @override
  State<CoreStakeholdersScreen> createState() => _CoreStakeholdersScreenState();
}

class _CoreStakeholdersScreenState extends State<CoreStakeholdersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _notesController;
  late final List<TextEditingController> _stakeholderControllers;
  late final OpenAiServiceSecure _openAi;
  bool _isGenerating = false;
  String? _error;
  bool _initiationExpanded = true;
  bool _businessCaseExpanded = true;

  static const List<_SidebarEntry> _navItems = [
    _SidebarEntry(icon: Icons.home_outlined, title: 'Home'),
    _SidebarEntry(icon: Icons.flag_outlined, title: 'Initiation Phase', isActive: true),
    _SidebarEntry(icon: Icons.timeline_outlined, title: 'Initiation: Front End Planning'),
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
    _notesController = TextEditingController(text: widget.notes);
    _stakeholderControllers = List.generate(widget.solutions.length, (_) => TextEditingController());
    ApiKeyManager.initializeApiKey();
    _openAi = OpenAiServiceSecure();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadExistingData();
      if (widget.solutions.isNotEmpty) _generateStakeholders();
    });
  }
  
  void _loadExistingData() {
    try {
      final provider = ProjectDataInherited.of(context);
      final stakeholdersData = provider.projectData.coreStakeholdersData;
      
      if (stakeholdersData == null) return;
      
      // Load notes
      if (stakeholdersData.notes.isNotEmpty) {
        _notesController.text = stakeholdersData.notes;
      }
      
      // Load stakeholder data for each solution
      for (int i = 0; i < stakeholdersData.solutionStakeholderData.length && i < _stakeholderControllers.length; i++) {
        final solutionStakeholder = stakeholdersData.solutionStakeholderData[i];
        _stakeholderControllers[i].text = solutionStakeholder.notableStakeholders;
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
            Expanded(child: Row(children: [
              DraggableSidebar(
                openWidth: sidebarWidth,
                child: const InitiationLikeSidebar(activeItemLabel: 'Core Stakeholders'),
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

  Widget _buildTopHeader() {
    final isMobile = AppBreakpoints.isMobile(context);
    return Container(
      height: isMobile ? 88 : 110,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: Row(children: [
        Row(children: [
          if (isMobile)
            IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          // Removed top-left logo per request
          if (!isMobile) ...[
            const SizedBox(width: 20),
            IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16), onPressed: () => Navigator.pop(context)),
            // Removed forward (">") icon per request
          ],
        ]),
        const Spacer(),
        if (!isMobile)
          const Text('Initiation Phase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
        const Spacer(),
        Row(children: [
          Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white, size: 20)),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(FirebaseAuthService.displayNameOrEmail(fallback: 'User'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
              Text(FirebaseAuth.instance.currentUser?.email ?? 'User', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ]),
      ]),
    );
  }

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
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))),
          child: const Row(children: [
            CircleAvatar(radius: 20, backgroundColor: Colors.grey),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('StackOne', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
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
                  _buildNestedSubMenuItem('Business Case', onTap: _openBusinessCase),
                  _buildNestedSubMenuItem('Potential Solutions', onTap: _openPotentialSolutions),
                  _buildNestedSubMenuItem('Risk Identification', onTap: _openRiskIdentification),
                  _buildNestedSubMenuItem('IT Considerations', onTap: _openITConsiderations),
                  _buildNestedSubMenuItem('Infrastructure Considerations', onTap: _openInfrastructureConsiderations),
                  _buildNestedSubMenuItem('Core Stakeholders', isActive: true),
                  _buildNestedSubMenuItem('Cost Benefit Analysis & Financial Metrics', onTap: _openCostAnalysis),
                  _buildNestedSubMenuItem('Preferred Solution Analysis', onTap: _openPreferredSolutionAnalysis),
                ],
              ],
              _buildMenuItem(Icons.timeline_outlined, 'Initiation: Front End Planning'),
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
            color: isActive ? primary.withValues(alpha: 0.12) : Colors.transparent,
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

  Widget _buildSubMenuItem(String title, {VoidCallback? onTap, bool isActive = false}) {
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
          child: Row(children: [
            Icon(Icons.circle, size: 8, color: isActive ? primary : Colors.grey[500]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 13, color: isActive ? primary : Colors.black87, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildExpandableHeader(IconData icon, String title, {required bool expanded, required VoidCallback onTap, bool isActive = false}) {
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
            Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey[700], size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildExpandableHeaderLikeCost(IconData icon, String title, {required bool expanded, required VoidCallback onTap, bool isActive = false}) {
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
          child: Row(children: [
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
            Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey[600], size: 18),
          ]),
        ),
      ),
    );
  }

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
          child: Row(children: [
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
          const EditableContentText(contentKey: 'core_stakeholders_heading', fallback: 'Core Stakeholders ', category: 'business_case', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black)),
          EditableContentText(contentKey: 'core_stakeholders_description', fallback: '(Identify key stakeholders especially if External, Regulatory, Governmental, etc.)', category: 'business_case', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ]),
        const SizedBox(height: 16),
        const EditableContentText(
          contentKey: 'core_stakeholders_notes_heading',
          fallback: 'Notes',
          category: 'business_case',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: 8),
        if (_error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
              TextButton(onPressed: _isGenerating ? null : _generateStakeholders, child: const Text('Retry')),
            ]),
          ),
        ],
        if (_isGenerating) const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.withValues(alpha: 0.3))),
          child: TextField(
            controller: _notesController,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            decoration: InputDecoration(hintText: 'Input your notes here...', hintStyle: TextStyle(color: Colors.grey[400]), border: InputBorder.none, contentPadding: EdgeInsets.zero),
            minLines: 1,
            maxLines: null,
          ),
        ),
        const SizedBox(height: 24),
        const EditableContentText(contentKey: 'internal_stakeholders_heading', fallback: 'Internal Stakeholders', category: 'business_case', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
        const SizedBox(height: 12),
        if (isMobile) ...[
          Column(children: List.generate(widget.solutions.length, (i) => _row(i))),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.withValues(alpha: 0.35))),
            child: const Row(children: [
              Expanded(child: EditableContentText(contentKey: 'stakeholders_table_header_solution', fallback: 'Potential Solution', category: 'business_case', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(child: EditableContentText(contentKey: 'stakeholders_table_header_notable', fallback: 'Notable Stakeholders', category: 'business_case', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.withValues(alpha: 0.35))),
            child: Column(children: List.generate(widget.solutions.length, (i) => _row(i))),
          ),
        ],
        const SizedBox(height: 24),
        if (isMobile) ...[
          Row(children: [
            Tooltip(
              message:
                  'While AI suggestions are helpful, we strongly encourage you to make the required adjustments for the best possible results',
              child: const Icon(Icons.lightbulb_outline, color: Colors.black87),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isGenerating ? null : _generateStakeholders,
                icon: const Icon(Icons.auto_awesome),
                label: Text(_isGenerating ? 'Generating...' : 'Generate stakeholders'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ),
          ]),
        ] else ...[
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Tooltip(
              message:
                  'While AI suggestions are helpful, we strongly encourage you to make the required adjustments for the best possible results',
              child: const Icon(Icons.lightbulb_outline, color: Colors.black87),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generateStakeholders,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Generating...' : 'Generate stakeholders'),
            ),
          ]),
        ],
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

  Future<void> _handleNextPressed() async {
    await _saveCoreStakeholdersData();

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
                Text('Processing core stakeholders data...'),
              ],
            ),
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    Navigator.of(context).pop();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CostAnalysisScreen(
          notes: _notesController.text,
          solutions: widget.solutions,
        ),
      ),
    );
  }

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
      child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
  
  Future<void> _saveCoreStakeholdersData() async {
    try {
      final provider = ProjectDataInherited.of(context);
      
      // Collect all stakeholder data from all solutions
      final solutionStakeholderData = <SolutionStakeholderData>[];
      for (int i = 0; i < widget.solutions.length; i++) {
        final solutionTitle = widget.solutions[i].title;
        final notableStakeholders = i < _stakeholderControllers.length 
            ? _stakeholderControllers[i].text 
            : '';
        
        solutionStakeholderData.add(SolutionStakeholderData(
          solutionTitle: solutionTitle,
          notableStakeholders: notableStakeholders,
        ));
      }
      
      final coreStakeholdersData = CoreStakeholdersData(
        notes: _notesController.text,
        solutionStakeholderData: solutionStakeholderData,
      );
      
      provider.updateProjectData(
        provider.projectData.copyWith(coreStakeholdersData: coreStakeholdersData),
      );
      
      // Save to Firebase with checkpoint
      await provider.saveToFirebase(checkpoint: 'core_stakeholders');
    } catch (e) {
      debugPrint('Error saving core stakeholders data: $e');
    }
  }

  Widget _row(int index) {
    final isMobile = AppBreakpoints.isMobile(context);
    final s = widget.solutions[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.25)))),
      child: isMobile
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _numberBadge(index + 1),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.title.isEmpty ? 'Potential Solution' : s.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ]),
              if (s.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(s.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 10),
              _stakeholderTextArea(_stakeholderControllers[index]),
            ])
          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _numberBadge(index + 1),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(s.title.isEmpty ? 'Potential Solution' : s.title, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    if (s.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(s.description, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ]
                  ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _stakeholderTextArea(_stakeholderControllers[index])),
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
      child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Drawer _buildMobileDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(leading: CircleAvatar(radius: 18, backgroundColor: Colors.grey), title: Text('StackOne')),
            const Divider(height: 1),
            _buildMenuItem(Icons.home_outlined, 'Home'),
            _buildExpandableHeader(
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
                _buildNestedSubMenuItem('Infrastructure Considerations', onTap: () {
                  Navigator.of(context).maybePop();
                  _openInfrastructureConsiderations();
                }),
                _buildNestedSubMenuItem('Core Stakeholders', isActive: true),
                _buildNestedSubMenuItem('Cost Benefit Analysis & Financial Metrics', onTap: () {
                  Navigator.of(context).maybePop();
                  _openCostAnalysis();
                }),
                _buildNestedSubMenuItem('Preferred Solution Analysis', onTap: () {
                  Navigator.of(context).maybePop();
                  _openPreferredSolutionAnalysis();
                }),
              ],
            ],
            _buildMenuItem(Icons.timeline_outlined, 'Initiation: Front End Planning'),
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

  Widget _stakeholderTextArea(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.withValues(alpha: 0.25))),
      child: TextField(
        controller: controller,
        minLines: 2,
        maxLines: null,
        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  Future<void> _generateStakeholders() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final map = await _openAi.generateStakeholdersForSolutions(
        widget.solutions,
        contextNotes: _notesController.text.trim(),
      );
      for (int i = 0; i < widget.solutions.length; i++) {
        final title = widget.solutions[i].title;
        final stakeholders = map[title] ?? const <String>[];
        _stakeholderControllers[i].text = stakeholders.isEmpty ? '' : stakeholders.map((e) => '- $e').join('\n');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _stakeholderControllers) {
      c.dispose();
    }
    super.dispose();
  }
}

class _SidebarEntry {
  final IconData icon;
  final String title;
  final bool isActive;
  const _SidebarEntry({required this.icon, required this.title, this.isActive = false});
}
