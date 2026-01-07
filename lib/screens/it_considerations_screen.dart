import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/screens/infrastructure_considerations_screen.dart';
import 'package:ndu_project/screens/core_stakeholders_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/widgets/business_case_header.dart';
import 'package:ndu_project/widgets/business_case_navigation_buttons.dart';
// Removed AppLogo to match updated header pattern
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/potential_solutions_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/settings_screen.dart';
import 'package:ndu_project/screens/cost_analysis_screen.dart';
import 'package:ndu_project/screens/preferred_solution_analysis_screen.dart';
import 'package:ndu_project/screens/home_screen.dart';

class ITConsiderationsScreen extends StatefulWidget {
  final String notes;
  final List<AiSolutionItem> solutions;
  const ITConsiderationsScreen({super.key, required this.notes, required this.solutions});

  @override
  State<ITConsiderationsScreen> createState() => _ITConsiderationsScreenState();
}

class _ITConsiderationsScreenState extends State<ITConsiderationsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _notesController;
  late final List<TextEditingController> _techControllers; // one per solution
  final OpenAiServiceSecure _openAi = OpenAiServiceSecure();
  bool _isGenerating = false;
  String? _error;
  bool _initiationExpanded = true;
  bool _businessCaseExpanded = true;
  bool _frontEndExpanded = true;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.notes);
    _techControllers = List.generate(widget.solutions.length, (_) => TextEditingController());
    ApiKeyManager.initializeApiKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadExistingData();
      if (widget.solutions.isNotEmpty) _generateTechnologies();
    });
  }
  
  void _loadExistingData() {
    try {
      final provider = ProjectDataInherited.of(context);
      final itData = provider.projectData.itConsiderationsData;
      
      if (itData == null) return;
      
      // Load notes
      if (itData.notes.isNotEmpty) {
        _notesController.text = itData.notes;
      }
      
      // Load IT data for each solution
      for (int i = 0; i < itData.solutionITData.length && i < _techControllers.length; i++) {
        final solutionIT = itData.solutionITData[i];
        _techControllers[i].text = solutionIT.coreTechnology;
      }
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading existing IT considerations data: $e');
    }
  }

  Future<void> _generateTechnologies() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final map = await _openAi.generateTechnologiesForSolutions(
        widget.solutions,
        contextNotes: _notesController.text.trim(),
      );
      for (int i = 0; i < widget.solutions.length; i++) {
        final title = widget.solutions[i].title;
        final tech = map[title] ?? const <String>[];
        _techControllers[i].text = tech.isEmpty ? '' : tech.map((e) => '- $e').join('\n');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isGenerating = false);
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
                child: const InitiationLikeSidebar(activeItemLabel: 'IT Considerations'),
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
      height: isMobile ? 72 : 88,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: Row(children: [
        Row(children: [
          if (isMobile)
            IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          if (!isMobile)
            IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16), onPressed: () => Navigator.pop(context)),
        ]),
        const Spacer(),
        if (!isMobile) const Text('Initiation Phase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
        const Spacer(),
        Row(children: [
          Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle), child: const Icon(Icons.person, color: Colors.white, size: 20)),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(FirebaseAuthService.displayNameOrEmail(fallback: 'User'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
              const Text('Owner', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ]),
      ]),
    );
  }

  Widget _buildSidebar() {
    final isMobile = AppBreakpoints.isMobile(context);
    final double bannerHeight = isMobile ? 72 : 96;
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.withValues(alpha: 0.25), width: 0.8),
        ),
      ),
      child: Column(children: [
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
              bottom: BorderSide(color: Color(0xFFFFD700), width: 1),
            ),
          ),
          child: const Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFFFD700),
              child: Icon(Icons.person_outline, color: Colors.black87),
            ),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('StackOne', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
            ])
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.symmetric(vertical: 20), children: [
            _buildMenuItem(Icons.home_outlined, 'Home', onTap: () => HomeScreen.open(context)),
            _buildExpandableHeader(
              Icons.flag_outlined,
              'Initiation Phase',
              expanded: _initiationExpanded,
              onTap: () => setState(() => _initiationExpanded = !_initiationExpanded),
              isActive: true,
            ),
            if (_initiationExpanded) ...[
              _buildExpandableHeader(
                Icons.business_center_outlined,
                'Business Case',
                expanded: _businessCaseExpanded,
                onTap: () => setState(() => _businessCaseExpanded = !_businessCaseExpanded),
                isActive: false,
              ),
              if (_businessCaseExpanded) ...[
                _buildNestedSubMenuItem('Potential Solutions', onTap: _openPotentialSolutions),
                _buildNestedSubMenuItem('Risk Identification', onTap: _openRiskIdentification),
                _buildNestedSubMenuItem('IT Considerations', isActive: true),
                _buildNestedSubMenuItem('Infrastructure Considerations', onTap: _openInfrastructureConsiderations),
                _buildNestedSubMenuItem('Core Stakeholders', onTap: _openCoreStakeholders),
                _buildNestedSubMenuItem('Cost Benefit Analysis & Financial Metrics', onTap: _openCostAnalysis),
                _buildNestedSubMenuItem('Preferred Solution Analysis', onTap: _openPreferredSolutionAnalysis),
              ],
              _buildExpandableHeader(
                Icons.timeline,
                'Initiation: Front End Planning',
                expanded: _frontEndExpanded,
                onTap: () => setState(() => _frontEndExpanded = !_frontEndExpanded),
                isActive: false,
              ),
              if (_frontEndExpanded) ...[
                _buildNestedSubMenuItem('Project Requirements'),
                _buildNestedSubMenuItem('Project Risks'),
                _buildNestedSubMenuItem('Project Opportunities'),
              ],
            ],
            _buildMenuItem(Icons.account_tree_outlined, 'Workflow Roadmap'),
            _buildMenuItem(Icons.flash_on, 'Agile Roadmap'),
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
            const ListTile(leading: CircleAvatar(radius: 18, backgroundColor: Color(0xFFFFD700), child: Icon(Icons.person_outline, color: Colors.black87)), title: Text('StackOne')),
            const Divider(height: 1),
            _buildMenuItem(Icons.home_outlined, 'Home', onTap: () {
              Navigator.of(context).maybePop();
              HomeScreen.open(context);
            }),
            _buildExpandableHeader(
              Icons.flag_outlined,
              'Initiation Phase',
              expanded: _initiationExpanded,
              onTap: () => setState(() => _initiationExpanded = !_initiationExpanded),
              isActive: true,
            ),
            if (_initiationExpanded) ...[
              _buildExpandableHeader(
                Icons.business_center_outlined,
                'Business Case',
                expanded: _businessCaseExpanded,
                onTap: () => setState(() => _businessCaseExpanded = !_businessCaseExpanded),
                isActive: false,
              ),
              if (_businessCaseExpanded) ...[
                _buildNestedSubMenuItem('Potential Solutions', onTap: () {
                  Navigator.of(context).maybePop();
                  _openPotentialSolutions();
                }),
                _buildNestedSubMenuItem('Risk Identification', onTap: () {
                  Navigator.of(context).maybePop();
                  _openRiskIdentification();
                }),
                _buildNestedSubMenuItem('IT Considerations', isActive: true),
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
              _buildExpandableHeader(
                Icons.timeline,
                'Initiation: Front End Planning',
                expanded: _frontEndExpanded,
                onTap: () => setState(() => _frontEndExpanded = !_frontEndExpanded),
                isActive: false,
              ),
              if (_frontEndExpanded) ...[
                _buildNestedSubMenuItem('Project Requirements', onTap: () => Navigator.of(context).maybePop()),
                _buildNestedSubMenuItem('Project Risks', onTap: () => Navigator.of(context).maybePop()),
                _buildNestedSubMenuItem('Project Opportunities', onTap: () => Navigator.of(context).maybePop()),
              ],
            ],
            _buildMenuItem(Icons.account_tree_outlined, 'Workflow Roadmap'),
            _buildMenuItem(Icons.bolt_outlined, 'Agile Roadmap'),
            _buildMenuItem(Icons.description_outlined, 'Contracting'),
            _buildMenuItem(Icons.shopping_cart_outlined, 'Procurement'),
            const Divider(height: 1),
            _buildMenuItem(Icons.settings_outlined, 'Settings', onTap: () {
              Navigator.of(context).maybePop();
              SettingsScreen.open(context);
            }),
            _buildMenuItem(Icons.logout_outlined, 'LogOut', onTap: () {
              Navigator.of(context).maybePop();
              AuthNav.signOutAndExit(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap, bool selected = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: InkWell(
        onTap: onTap ?? () {
          if (title == 'LogOut') {
            AuthNav.signOutAndExit(context);
          } else if (title == 'Settings') {
            SettingsScreen.open(context);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: selected
              ? BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: primary, width: 3)),
                )
              : null,
          child: Row(children: [
            Icon(icon, size: 20, color: selected ? primary : Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, color: selected ? primary : Colors.black87, fontWeight: FontWeight.w600),
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
              child: Text(title, style: TextStyle(fontSize: 13, color: isActive ? primary : Colors.black87, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ]),
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
          child: Row(children: [
            Icon(Icons.circle, size: 6, color: isActive ? primary : Colors.grey[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 12, color: isActive ? primary : Colors.black87, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal), maxLines: 2, overflow: TextOverflow.ellipsis),
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
              Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey[700], size: 20),
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

  Future<void> _openInfrastructureConsiderations() async {
    // Save IT considerations data
    await _saveITConsiderationsData();
    
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
                Text('Processing IT considerations data...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog
    
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
  
  Future<void> _saveITConsiderationsData() async {
    try {
      final provider = ProjectDataInherited.of(context);
      
      // Collect all IT data from all solutions
      final solutionITData = <SolutionITData>[];
      for (int i = 0; i < widget.solutions.length; i++) {
        final solutionTitle = widget.solutions[i].title;
        final coreTechnology = i < _techControllers.length 
            ? _techControllers[i].text 
            : '';
        
        solutionITData.add(SolutionITData(
          solutionTitle: solutionTitle,
          coreTechnology: coreTechnology,
        ));
      }
      
      final itConsiderationsData = ITConsiderationsData(
        notes: _notesController.text,
        solutionITData: solutionITData,
      );
      
      provider.updateProjectData(
        provider.projectData.copyWith(itConsiderationsData: itConsiderationsData),
      );
      
      // Save to Firebase with checkpoint
      await provider.saveToFirebase(checkpoint: 'it_considerations');
    } catch (e) {
      debugPrint('Error saving IT considerations data: $e');
    }
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
    final firstLabel = widget.solutions.isNotEmpty ? _potentialSolutionLabel(0) : 'Potential Solution 1';
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const EditableContentText(contentKey: 'it_considerations_heading', fallback: 'IT Considerations ', category: 'business_case', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black)),
          EditableContentText(contentKey: 'it_considerations_description', fallback: '(List core IT considerations for each Potential Solution)', category: 'business_case', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ]),
        SizedBox(height: AppBreakpoints.fieldGap(context)),
        const EditableContentText(
          contentKey: 'it_considerations_notes_heading',
          fallback: 'Notes',
          category: 'business_case',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
        ),
        const SizedBox(height: 8),
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
        const SizedBox(height: 16),
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
            child: Row(children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
              TextButton(onPressed: _isGenerating ? null : _generateTechnologies, child: const Text('Retry')),
            ]),
          ),
        const SizedBox(height: 8),
        const Text('IT Considerations for each potential solution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 12),
        if (isMobile) ...[
          Column(children: List.generate(widget.solutions.length, (i) => _row(i))),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.withValues(alpha: 0.35))),
            child: const Row(children: [
              Expanded(child: Text('Potential Solution', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(child: Text('Core Technology', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.withValues(alpha: 0.35))),
            child: Column(children: List.generate(widget.solutions.length, (i) => _row(i))),
          ),
        ],
        const SizedBox(height: 24),
        Row(children: [
          Tooltip(
            message:
                'While AI suggestions are helpful, we strongly encourage you to make the required adjustments for the best possible results',
            child: Icon(Icons.lightbulb_outline, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: _isGenerating ? null : _generateTechnologies, icon: const Icon(Icons.auto_awesome), label: Text(_isGenerating ? 'Generating...' : 'Generate technologies')),
          const SizedBox(width: 12),
        ]),
        const SizedBox(height: 24),
        
        // Navigation Buttons
        BusinessCaseNavigationButtons(
          currentScreen: 'IT Considerations',
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
          onNext: _openInfrastructureConsiderations,
        ),
      ]),
    );
  }

  String _potentialSolutionLabel(int index) {
    final number = index + 1;
    if (index < 0 || index >= widget.solutions.length) {
      return 'Potential Solution $number';
    }
    final title = widget.solutions[index].title.trim();
    if (title.isEmpty) {
      return 'Potential Solution $number';
    }
    return 'Potential Solution $number: $title';
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
                Expanded(child: Text(_potentialSolutionLabel(index), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
              ]),
              if (s.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(s.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 10),
              _techTextArea(_techControllers[index]),
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
                        child: Text(
                          _potentialSolutionLabel(index),
                          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600),
                        ),
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
              Expanded(child: _techTextArea(_techControllers[index])),
            ]),
    );
  }

  Widget _numberBadge(int number) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primary.withValues(alpha: 0.6), width: 1),
      ),
      child: Text('$number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primary)),
    );
  }

  Widget _techTextArea(TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.withValues(alpha: 0.25))),
      child: TextField(
        controller: controller,
        minLines: 2,
        maxLines: null,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: 'Enter core technologies specific to this solution (e.g., platforms, frameworks, databases, tools)...',
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _techControllers) {
      c.dispose();
    }
    super.dispose();
  }
}
