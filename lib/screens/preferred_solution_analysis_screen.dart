import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/header_banner_image.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/business_case_header.dart';
import 'package:ndu_project/widgets/business_case_navigation_buttons.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/screens/project_decision_summary_screen.dart';
import 'package:ndu_project/screens/front_end_planning_summary.dart';
import 'package:ndu_project/services/project_service.dart';
import 'package:ndu_project/screens/home_screen.dart';
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/potential_solutions_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/it_considerations_screen.dart';
import 'package:ndu_project/screens/settings_screen.dart';
import 'package:ndu_project/screens/infrastructure_considerations_screen.dart';
import 'package:ndu_project/screens/core_stakeholders_screen.dart';
import 'package:ndu_project/screens/cost_analysis_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/select_project_kaz_button.dart';

class PreferredSolutionAnalysisScreen extends StatefulWidget {
  final String notes;
  final List<AiSolutionItem> solutions;
  final String businessCase;
  const PreferredSolutionAnalysisScreen({super.key, required this.notes, required this.solutions, this.businessCase = ''});

  @override
  State<PreferredSolutionAnalysisScreen> createState() => _PreferredSolutionAnalysisScreenState();
}

class _PreferredSolutionAnalysisScreenState extends State<PreferredSolutionAnalysisScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TextEditingController _notesController;
  late List<AiSolutionItem> _solutions;
  late final OpenAiServiceSecure _openAi;
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  bool _initiationExpanded = true;
  bool _businessCaseExpanded = true;
  List<_SolutionAnalysisData> _analysis = const [];
  int? _selectedSolutionIndex;
  late final TextEditingController _projectNameController;
  String? _projectNameError;

  @override
  void initState() {
    super.initState();
    ApiKeyManager.initializeApiKey();
    _openAi = OpenAiServiceSecure();
    _solutions = widget.solutions.isNotEmpty
        ? widget.solutions.map((s) => AiSolutionItem(title: s.title, description: s.description)).toList()
        : _fallbackSolutions();
    _tabController = TabController(length: _solutions.length, vsync: this);
    _notesController = TextEditingController(text: widget.notes);
    _projectNameController = TextEditingController();
    _analysis = _solutions
        .map((s) => _SolutionAnalysisData(
              solution: s,
              stakeholders: const [],
              risks: const [],
              technologies: const [],
              infrastructure: const [],
              costs: const [],
            ))
        .toList(growable: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFeasibilityStudy();
      _loadExistingDataAndAnalysis();
    });
  }

  /// Check if user already has a feasibility study and offer fast track
  Future<void> _checkFeasibilityStudy() async {
    final provider = ProjectDataHelper.getProvider(context);
    final projectData = provider.projectData;
    final projectId = projectData.projectId;

    // Check if already marked as having feasibility study
    if (projectId != null) {
      try {
        final projectRecord = await ProjectService.getProjectById(projectId);
        // Check if there's a custom field indicating feasibility study exists
        // For now, we'll show the dialog on first visit
      } catch (e) {
        debugPrint('Error checking feasibility study status: $e');
      }
    }

    // Show dialog asking about feasibility study
    if (!mounted) return;
    
    final hasFeasibility = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.assignment_outlined, color: Color(0xFFFFD700), size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Feasibility Study')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you already have a Feasibility Study for this project?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Text(
              'If yes, you can skip the Preferred Solution Analysis and proceed directly to Risk Identification.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No, I need to create one'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
            ),
            child: const Text('Yes, I have one'),
          ),
        ],
      ),
    );

    if (hasFeasibility == true && mounted) {
      // Update Firestore and skip to Risk Identification
      final provider = ProjectDataHelper.getProvider(context);
      final projectId = provider.projectData.projectId;
      
      if (projectId != null) {
        try {
          await FirebaseFirestore.instance.collection('projects').doc(projectId).update({
            'hasFeasibilityStudy': true,
            'checkpointRoute': 'risk_identification',
            'checkpointAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          // Update provider
          provider.updateField((data) => data.copyWith(
            currentCheckpoint: 'risk_identification',
          ));
          
          // Navigate to Risk Identification
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RiskIdentificationScreen(
                  notes: projectData.notes ?? '',
                  solutions: widget.solutions,
                  businessCase: projectData.businessCase ?? '',
                ),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error updating feasibility study status: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}')),
            );
          }
        }
      }
    }
    // If false, continue with normal Preferred Solution Analysis flow
  }

  Future<void> _loadExistingDataAndAnalysis() async {
    try {
      final provider = ProjectDataHelper.getProvider(context);
      final existingData = provider.projectData.preferredSolutionAnalysis;
      
      if (existingData != null && existingData.solutionAnalyses.isNotEmpty) {
        _notesController.text = existingData.workingNotes;
        
        final loadedAnalyses = existingData.solutionAnalyses.map((item) {
          return _SolutionAnalysisData(
            solution: AiSolutionItem(title: item.solutionTitle, description: item.solutionDescription),
            stakeholders: item.stakeholders,
            risks: item.risks,
            technologies: item.technologies,
            infrastructure: item.infrastructure,
            costs: item.costs.map((c) => AiCostItem(
              item: c.item,
              description: c.description,
              estimatedCost: c.estimatedCost,
              roiPercent: c.roiPercent,
              npvByYear: c.npvByYear,
            )).toList(),
          );
        }).toList();
        
        if (mounted) {
          setState(() {
            _analysis = loadedAnalyses;
            _isLoading = false;
          });
        }
      } else {
        await _loadAnalysis();
      }
    } catch (e) {
      await _loadAnalysis();
    }
  }

  @override
  void didUpdateWidget(covariant PreferredSolutionAnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.solutions != widget.solutions || oldWidget.notes != widget.notes) {
      final updatedSolutions = widget.solutions.isNotEmpty
          ? widget.solutions.map((s) => AiSolutionItem(title: s.title, description: s.description)).toList()
          : _fallbackSolutions();
      _tabController.dispose();
      setState(() {
        _solutions = updatedSolutions;
        _tabController = TabController(length: _solutions.length, vsync: this);
        _analysis = _solutions
            .map((s) => _SolutionAnalysisData(
                  solution: s,
                  stakeholders: const [],
                  risks: const [],
                  technologies: const [],
                  infrastructure: const [],
                  costs: const [],
                ))
            .toList(growable: false);
        _notesController.text = widget.notes;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAnalysis());
    }
  }

  List<AiSolutionItem> _fallbackSolutions() {
    return [
      AiSolutionItem(title: 'Potential Opportunity', description: 'Discipline'),
      AiSolutionItem(title: 'Potential Opportunity', description: 'Discipline'),
      AiSolutionItem(title: 'Potential Opportunity', description: 'Discipline'),
    ];
  }

  Future<void> _loadAnalysis() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notes = _notesController.text.trim();
      final results = await Future.wait([
        _openAi.generateStakeholdersForSolutions(_solutions, contextNotes: notes),
        _openAi.generateRisksForSolutions(_solutions, contextNotes: notes),
        _openAi.generateTechnologiesForSolutions(_solutions, contextNotes: notes),
        _openAi.generateInfrastructureForSolutions(_solutions, contextNotes: notes),
        _openAi.generateCostBreakdownForSolutions(_solutions, contextNotes: notes),
      ]);

      final stakeholdersMap = results[0] as Map<String, List<String>>;
      final risksMap = results[1] as Map<String, List<String>>;
      final technologiesMap = results[2] as Map<String, List<String>>;
      final infrastructureMap = results[3] as Map<String, List<String>>;
      final costsMap = results[4] as Map<String, List<AiCostItem>>;

      final data = <_SolutionAnalysisData>[];
      for (var i = 0; i < _solutions.length; i++) {
        final solution = _solutions[i];
        final key = solution.title;
        data.add(
          _SolutionAnalysisData(
            solution: solution,
            stakeholders: List<String>.from(stakeholdersMap[key] ?? const <String>[]),
            risks: List<String>.from(risksMap[key] ?? const <String>[]),
            technologies: List<String>.from(technologiesMap[key] ?? const <String>[]),
            infrastructure: List<String>.from(infrastructureMap[key] ?? const <String>[]),
            costs: List<AiCostItem>.from(costsMap[key] ?? const <AiCostItem>[]),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _analysis = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: isMobile ? const Drawer(child: InitiationLikeSidebar(activeItemLabel: 'Preferred Solution Analysis')) : null,
      body: Stack(
        children: [
          Column(children: [
            BusinessCaseHeader(scaffoldKey: _scaffoldKey),
            Expanded(child: Row(children: [
              DraggableSidebar(
                openWidth: sidebarWidth,
                child: const InitiationLikeSidebar(activeItemLabel: 'Preferred Solution Analysis'),
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
          if (isMobile) IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          if (!isMobile) ...[
            IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16), onPressed: () => Navigator.pop(context)),
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
    // Match CostAnalysisScreen sidebar styling and structure
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
            child: const HeaderBannerImage(),
          ),
          Builder(
            builder: (builderContext) {
              final provider = ProjectDataHelper.getProvider(builderContext);
              final projectName = provider.projectData.projectName;
              final displayName = (projectName.isNotEmpty) ? projectName : 'Untitled Project';
              
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFFFD700), width: 1)),
                ),
                child: Text(
                  displayName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildMenuItem(Icons.home_outlined, 'Home', onTap: () => HomeScreen.open(context)),
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
                    _buildNestedSubMenuItem('Core Stakeholders', onTap: _openCoreStakeholders),
                    _buildNestedSubMenuItem('Cost Benefit Analysis & Financial Metrics', onTap: _openCostAnalysis),
                    _buildNestedSubMenuItem('Preferred Solution Analysis', isActive: true),
                  ],
                ],
                _buildMenuItem(Icons.timeline, 'Initiation: Front End Planning'),
                _buildMenuItem(Icons.account_tree_outlined, 'Workflow Roadmap'),
                _buildMenuItem(Icons.flash_on, 'Agile Roadmap'),
                _buildMenuItem(Icons.description_outlined, 'Contracting'),
                _buildMenuItem(Icons.shopping_cart_outlined, 'Procurement'),
                const SizedBox(height: 20),
                _buildMenuItem(Icons.settings_outlined, 'Settings', onTap: () => SettingsScreen.open(context)),
                _buildMenuItem(Icons.logout_outlined, 'LogOut', onTap: () => AuthNav.signOutAndExit(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Drawer _buildMobileDrawer() {
    // Match CostAnalysisScreen drawer look and behavior
    return Drawer(
      child: SafeArea(
        child: Builder(
          builder: (builderContext) {
            final provider = ProjectDataHelper.getProvider(builderContext);
            final projectName = provider.projectData.projectName;
            final displayName = (projectName.isNotEmpty) ? projectName : 'Untitled Project';

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                _buildNestedSubMenuItem('Core Stakeholders', onTap: () {
                  Navigator.of(context).maybePop();
                  _openCoreStakeholders();
                }),
                _buildNestedSubMenuItem('Cost Benefit Analysis & Financial Metrics', onTap: () {
                  Navigator.of(context).maybePop();
                  _openCostAnalysis();
                }),
                _buildNestedSubMenuItem('Preferred Solution Analysis', isActive: true),
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
                _buildMenuItem(Icons.logout_outlined, 'LogOut', onTap: () => AuthNav.signOutAndExit(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool disabled = false, VoidCallback? onTap, bool isActive = false}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(icon, size: 20, color: isActive ? primary : (disabled ? Colors.grey[400] : Colors.black87)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isActive ? primary : (disabled ? Colors.grey[500] : Colors.black87),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
          solutions: _solutions,
          businessCase: widget.businessCase,
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
          solutions: _solutions,
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
          solutions: _solutions,
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
          solutions: _solutions,
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
          solutions: _solutions,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final isMobile = AppBreakpoints.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Initiation Phase', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildHeaderRow(),
        const SizedBox(height: 16),
        _buildNotesField(),
        const SizedBox(height: 20),
        if (_isLoading) _buildLoadingBlock(),
        if (!_isLoading && _error != null) ...[
          _buildErrorBanner(),
          const SizedBox(height: 16),
        ],
        if (!_isLoading) ...[
          _buildComparativeView(),
          const SizedBox(height: 16),
          // Select Project button (KAZ)
          _buildSelectProjectButton(),
          const SizedBox(height: 12),
          BusinessCaseNavigationButtons(
            currentScreen: 'Preferred Solution Analysis',
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
            onNext: _handleNextStep,
          ),
          const SizedBox(height: 24),
        ],
        if (_isLoading) const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildNextButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _handleNextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text(
            'Next',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<void> _handleNextStep() async {
    // Save all data to Firebase
    await _saveAnalysisData();

    // Show 3-second loading dialog
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFFFD700)),
            SizedBox(height: 16),
            Text(
              'Saving your progress...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FrontEndPlanningSummaryScreen(),
      ),
    );
  }

  Widget _buildHeaderRow() {
    final isMobile = AppBreakpoints.isMobile(context);
    final heading = Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Text('Preferred Solution Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      SizedBox(height: 6),
      Text('Review stakeholders, risks, and costs together so you can back a preferred path with confidence.', style: TextStyle(fontSize: 13, color: Colors.black54)),
    ]);

    if (isMobile) {
      return heading;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: heading),
      ],
    );
  }

  Widget _buildNotesField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withValues(alpha: 0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Working notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          decoration: const InputDecoration(hintText: 'Capture rationale, assumptions, or follow-ups here...', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
          minLines: 1,
          maxLines: null,
        ),
      ]),
    );
  }

  Widget _buildLoadingBlock() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
      child: Row(children: const [
        SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3)),
        SizedBox(width: 16),
        Expanded(child: Text('Gathering stakeholders, risks, and cost insights for each solution...', style: TextStyle(fontSize: 14))),
      ]),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.2))),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_error ?? 'Unable to refresh analysis details right now.', style: const TextStyle(fontSize: 13, color: Colors.red))),
        TextButton(onPressed: _isLoading ? null : _loadAnalysis, child: const Text('Retry')),
      ]),
    );
  }

  Widget _buildTabSection() {
    if (_analysis.isEmpty) {
      return _buildEmptyState();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withValues(alpha: 0.25))),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFFFFD700),
          indicatorWeight: 3,
          tabs: List.generate(_analysis.length, (index) {
            final solution = _analysis[index].solution;
            final label = solution.title.isNotEmpty ? solution.title : 'Solution ${index + 1}';
            return Tab(text: label);
          }),
        ),
      ),
      const SizedBox(height: 18),
      AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final safeIndex = (_analysis.isEmpty ? 0 : _tabController.index).clamp(0, _analysis.length - 1);
          final data = _analysis[safeIndex];
          return _buildSolutionDetail(data: data, index: safeIndex);
        },
      ),
    ]);
  }

  Widget _buildSolutionDetail({required _SolutionAnalysisData data, required int index}) {
    final title = data.solution.title.isNotEmpty ? data.solution.title : 'Solution ${index + 1}';
    final description = data.solution.description.isNotEmpty ? data.solution.description : 'Discipline';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ])),
          const _AiTag(),
        ]),
        const SizedBox(height: 20),
        _buildSectionBlock(title: 'Key stakeholders', items: data.stakeholders),
        const SizedBox(height: 20),
        _buildSectionBlock(title: 'Top risks', items: data.risks),
        const SizedBox(height: 20),
        _buildCostsSection(data.costs),
      ]),
    );
  }

  Widget _buildSectionBlock({required String title, required List<String> items}) {
    final hasContent = items.any((e) => e.trim().isNotEmpty);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      hasContent
          ? _buildBulletList(items)
          : const Text('No insights captured yet. Add notes or rerun AI to populate this section.', style: TextStyle(fontSize: 13, color: Colors.black45)),
    ]);
  }

  Widget _buildBulletList(List<String> items) {
    final filtered = items.where((e) => e.trim().isNotEmpty).toList();
    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filtered
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('- ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 14, color: Colors.black87))),
                ]),
              ))
          .toList(),
    );
  }

  Widget _buildCostsSection(List<AiCostItem> items) {
    if (items.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Investment overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        SizedBox(height: 10),
        Text('No cost analysis generated yet. Capture financial assumptions before finalizing.', style: TextStyle(fontSize: 13, color: Colors.black45)),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Investment overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.take(4).map((item) {
          final metrics = <Widget>[
            _buildCostBadge('Est. cost', _formatCurrency(item.estimatedCost)),
            _buildCostBadge('ROI', '${item.roiPercent.toStringAsFixed(1)}%'),
            _buildCostBadge('NPV', _formatCurrency(item.npv)),
          ];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF9FBFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.withValues(alpha: 0.15))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.item.isNotEmpty ? item.item : 'Cost item', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(item.description, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: metrics),
            ]),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildCostBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFFFF7CC), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ]),
    );
  }

  Widget _buildComparativeView() {
    if (_analysis.isEmpty) {
      return _buildEmptyState();
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _buildComparisonMatrix(),
    ]);
  }


  Widget _buildComparisonMatrix() {
    final headers = [
      for (var i = 0; i < _analysis.length; i++)
        '${i + 1}. '
        '${_analysis[i].solution.title.isNotEmpty ? _analysis[i].solution.title : 'Solution ${i + 1}'}',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Side-by-side Solution Comparison',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            // Make columns evenly share width when there are few columns; still allow horizontal scroll if needed
            final available = constraints.maxWidth - 32; // minus padding below
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildMatrixTable(headers, availableWidth: available),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildMatrixTable(List<String> headers, {double? availableWidth}) {
    // Use fixed widths so the table lays out correctly and can scroll horizontally
    const leftCol = 240.0;
    final columnWidths = <int, TableColumnWidth>{};
    columnWidths[0] = const FixedColumnWidth(leftCol);
    // Compute equal widths for value columns to keep spacing even
    final count = headers.length;
    double perCol = 320; // default, slightly wider for better readability
    if (availableWidth != null && availableWidth > leftCol + 100) {
      final remain = availableWidth - leftCol;
      perCol = (remain / count).clamp(260, 450);
    }
    for (var i = 1; i <= count; i++) {
      columnWidths[i] = FixedColumnWidth(perCol);
    }
    final summaryRows = <TableRow>[];

    // Get project data for enhanced comparison
    final provider = ProjectDataHelper.getProvider(context);
    final projectData = provider.projectData;

    summaryRows.add(
      TableRow(children: [
        _buildMatrixCellText('Category', isHeader: true),
        for (final header in headers) _buildMatrixCellText(header, isHeader: true),
      ]),
    );

    summaryRows.add(
      TableRow(children: [
        _buildMatrixCellText('Solution Description', emphasize: true),
        for (final data in _analysis)
          _buildMatrixCellText(data.solution.description.isNotEmpty ? data.solution.description : 'N/A')
      ]),
    );

    summaryRows.add(
      TableRow(children: [
        _buildMatrixCellText('Risk Identification', emphasize: true),
        for (final data in _analysis) _buildMatrixCellText(_getRiskDataForSolution(projectData, data.solution.title))
      ]),
    );

    summaryRows.add(
      TableRow(children: [
        _buildMatrixCellText('IT Considerations', emphasize: true),
        for (final data in _analysis) _buildMatrixCellText(_getITDataForSolution(projectData, data.solution.title))
      ]),
    );

    summaryRows.add(
      TableRow(children: [
        _buildMatrixCellText('Infrastructure Considerations', emphasize: true),
        for (final data in _analysis) _buildMatrixCellText(_getInfrastructureDataForSolution(projectData, data.solution.title))
      ]),
    );

    summaryRows.add(
      TableRow(children: [
        _buildMatrixCellText('Core Stakeholders', emphasize: true),
        for (final data in _analysis) _buildMatrixCellText(_getStakeholderDataForSolution(projectData, data.solution.title))
      ]),
    );

    summaryRows.add(
      TableRow(children: [
        _buildMatrixCellText('Cost Benefit Analysis Overview', emphasize: true),
        for (final data in _analysis) _buildMatrixCellText(_getCostBenefitDataForSolution(projectData, data.solution.title))
      ]),
    );

    return Table(
      border: TableBorder.all(color: Colors.grey.withValues(alpha: 0.3), width: 0.7),
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: summaryRows,
    );
  }

  Widget _buildMatrixCellText(String text, {bool isHeader = false, bool emphasize = false}) {
    final style = TextStyle(
      fontSize: 12,
      fontWeight: isHeader
          ? FontWeight.w700
          : emphasize
              ? FontWeight.w600
              : FontWeight.w400,
      color: Colors.black87,
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text.isNotEmpty ? text : 'N/A',
        style: style,
        softWrap: true,
      ),
    );
  }

  Widget _buildInlineSelection(List<String> headers) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a project to progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Pick the solution you want to advance and give your project a memorable name.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (int i = 0; i < _analysis.length; i++)
                ChoiceChip(
                  label: Text(_analysis[i].solution.title.isNotEmpty ? _analysis[i].solution.title : 'Solution ${i + 1}'),
                  selected: _selectedSolutionIndex == i,
                  onSelected: (_) => _onInlineSelect(i),
                  selectedColor: const Color(0xFFFFF8DC),
                  labelStyle: const TextStyle(color: Colors.black87),
                  side: BorderSide(color: _selectedSolutionIndex == i ? const Color(0xFFFFD700) : Colors.grey.withValues(alpha: 0.3)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _projectNameController,
            onChanged: (_) {
              if (_projectNameError != null) {
                setState(() => _projectNameError = null);
              }
            },
            decoration: InputDecoration(
              labelText: 'Project name',
              hintText: _selectedSolutionIndex != null && _selectedSolutionIndex! < _analysis.length
                  ? _analysis[_selectedSolutionIndex!].solution.title
                  : 'People Operations Transformation',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              errorText: _projectNameError,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              ElevatedButton(
                onPressed: _handleInlineContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Save & Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Add KAZ Select Project button below the inline selection container
  Widget _buildSelectProjectButton() {
    final options = _analysis
        .map((d) => SolutionOption(title: d.solution.title, description: d.solution.description, projectName: null))
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SelectProjectKazButton(
        solutions: options,
        onSolutionSelected: (selected) async {
          await _createProjectAndNavigate(
            selectedSolution: AiSolutionItem(title: selected.title, description: selected.description),
            projectName: selected.projectName ?? selected.title,
          );
        },
      ),
    );
  }

  String _formatListForMatrix(List<String> items, {int maxItems = 4}) {
    final trimmed = items.where((e) => e.trim().isNotEmpty).take(maxItems).toList();
    if (trimmed.isEmpty) return 'N/A';
    return trimmed.map((value) => '- ${value.trim()}').join('\n');
  }

  List<String> _topStrings(List<String> source, {int maxItems = 4}) {
    return source.where((e) => e.trim().isNotEmpty).map((e) => e.trim()).take(maxItems).toList();
  }

  String _financialSummaryText(_SolutionAnalysisData data) {
    final costs = data.costs;
    if (costs.isEmpty) {
      return 'No financial insights available yet.';
    }
    final totalCost = costs.fold<double>(0.0, (sum, item) => sum + item.estimatedCost);
    final avgRoi = costs.map((item) => item.roiPercent).reduce((a, b) => a + b) / costs.length;
    final bestNpv = costs.map((item) => item.npv).reduce(math.max);
    return 'Total: ${_formatCurrency(totalCost)}\nAvg ROI: ${avgRoi.toStringAsFixed(1)}%\nBest NPV: ${_formatCurrency(bestNpv)}';
  }

  Widget _buildFooterActions({required bool isMobile}) {
    final info = Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(color: Color(0xFFB3D9FF), shape: BoxShape.circle),
      child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
    );

    final buttonChild = const Text('Next', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black));
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFD700),
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    );

    if (isMobile) {
      return Row(
        children: [
          info,
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _canNavigateToComparison ? _openComparisonPage : null,
                style: buttonStyle,
                child: buttonChild,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        info,
        const Spacer(),
        ElevatedButton(
          onPressed: _canNavigateToComparison ? _openComparisonPage : null,
          style: buttonStyle,
          child: buttonChild,
        ),
      ],
    );
  }

  bool get _canNavigateToComparison => !_isLoading && _error == null && _analysis.isNotEmpty;

  Future<void> _openComparisonPage() async {
    if (!_canNavigateToComparison) {
      if (_isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hold on while we finish preparing the comparison.')));
        return;
      }
      if (_error != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resolve the analysis error before continuing.')));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add solution details to view the comparison.')));
      return;
    }

    // Save analysis data to Firebase
    await _saveAnalysisData();

    // Show 3-second loading dialog
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    final analysis = _analysis
        .map(
          (item) => _SolutionAnalysisData(
            solution: AiSolutionItem(title: item.solution.title, description: item.solution.description),
            stakeholders: List<String>.from(item.stakeholders),
            risks: List<String>.from(item.risks),
            technologies: List<String>.from(item.technologies),
            infrastructure: List<String>.from(item.infrastructure),
            costs: item.costs
                .map(
                  (e) => AiCostItem(
                    item: e.item,
                    description: e.description,
                    estimatedCost: e.estimatedCost,
                    roiPercent: e.roiPercent,
                    npvByYear: Map<int, double>.from(e.npvByYear),
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreferredSolutionComparisonScreen(
          notes: _notesController.text,
          analysis: analysis,
          solutions: _solutions
              .map((solution) => AiSolutionItem(title: solution.title, description: solution.description))
              .toList(growable: false),
          businessCase: widget.businessCase,
        ),
      ),
    );
  }

  Future<void> _saveAnalysisData() async {
    try {
      final provider = ProjectDataHelper.getProvider(context);
      
      final analysisData = PreferredSolutionAnalysis(
        workingNotes: _notesController.text.trim(),
        solutionAnalyses: _analysis.map((item) {
          return SolutionAnalysisItem(
            solutionTitle: item.solution.title,
            solutionDescription: item.solution.description,
            stakeholders: item.stakeholders,
            risks: item.risks,
            technologies: item.technologies,
            infrastructure: item.infrastructure,
            costs: item.costs.map((c) => CostItem(
              item: c.item,
              description: c.description,
              estimatedCost: c.estimatedCost,
              roiPercent: c.roiPercent,
              npvByYear: c.npvByYear,
            )).toList(),
          );
        }).toList(),
      );

      provider.updateField((data) => data.copyWith(
        preferredSolutionAnalysis: analysisData,
      ));

      await provider.saveToFirebase(checkpoint: 'preferred_solution_analysis');
    } catch (e) {
      // Silent fail - navigation continues
      debugPrint('Error saving analysis data: $e');
    }
  }

  void _onInlineSelect(int index) {
    setState(() {
      _selectedSolutionIndex = index;
      if (_projectNameController.text.trim().isEmpty) {
        _projectNameController
          ..text = _analysis[index].solution.title
          ..selection = TextSelection.collapsed(offset: _projectNameController.text.length);
      }
      _projectNameError = null;
    });
  }

  Future<void> _handleInlineContinue() async {
    final index = _selectedSolutionIndex;
    if (index == null) {
      setState(() => _projectNameError = 'Select a project first.');
      return;
    }

    final name = _projectNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _projectNameError = 'Give your project a name to continue.');
      return;
    }

    final selected = AiSolutionItem(
      title: _analysis[index].solution.title,
      description: _analysis[index].solution.description,
    );

    await _createProjectAndNavigate(selectedSolution: selected, projectName: name);
  }

  Future<void> _createProjectAndNavigate({
    required AiSolutionItem selectedSolution,
    required String projectName,
  }) async {
    final filteredSolutions = _solutions
        .map((solution) => AiSolutionItem(title: solution.title.trim(), description: solution.description.trim()))
        .where((item) => item.title.isNotEmpty || item.description.isNotEmpty)
        .toList();

    if (filteredSolutions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one solution option before continuing.')),
      );
      return;
    }

    final trimmedNotes = _notesController.text.trim();
    final trimmedBusinessCase = widget.businessCase.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to save your project.')));
      return;
    }

    final ownerName = FirebaseAuthService.displayNameOrEmail(fallback: 'Leader');
    final tags = {
      'Initiation',
      if (selectedSolution.title.trim().isNotEmpty) selectedSolution.title.trim(),
    }.toList();

    // Check for duplicate project name before proceeding
    final existing = await ProjectService.projectNameExists(ownerId: user.uid, name: projectName.trim());
    if (existing) {
      if (mounted) {
        setState(() => _projectNameError = 'A project with this name already exists. Choose a different name.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project name already exists. Please choose a different name.')),
        );
      }
      return;
    }

    bool dialogShown = false;
    if (mounted) {
      dialogShown = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await ProjectService.createProject(
        ownerId: user.uid,
        ownerName: ownerName,
        name: projectName,
        solutionTitle: selectedSolution.title.trim(),
        solutionDescription: selectedSolution.description.trim(),
        businessCase: trimmedBusinessCase,
        notes: trimmedNotes,
        ownerEmail: user.email,
        tags: tags,
        checkpointRoute: 'project_decision_summary',
      );
    } catch (error, stack) {
      // ignore: avoid_print
      print('Failed to create project: $error\n$stack');
      if (dialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to save project. Try again.')));
      return;
    }

    if (dialogShown && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectDecisionSummaryScreen(
          projectName: projectName,
          selectedSolution: selectedSolution,
          allSolutions: filteredSolutions,
          businessCase: trimmedBusinessCase,
          notes: trimmedNotes,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('No solutions available yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text('Add potential solutions to see their stakeholders, risks, and cost signals in one place.', style: TextStyle(fontSize: 13, color: Colors.black54)),
      ]),
    );
  }

  // ignore: unused_element
  String _formatCurrencyLegacy(double value) {
    if (value == 0) return ' 24 30';
    final absValue = value.abs();
    final decimals = absValue >= 1000 ? 0 : absValue >= 100 ? 1 : 2;
    var text = absValue.toStringAsFixed(decimals);
    final parts = text.split('.');
    final whole = parts.first;
    final withCommas = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    final hasDecimals = parts.length > 1 && int.tryParse(parts[1]) != 0;
    final decimalPart = hasDecimals ? '.${parts[1]}' : '';
    final symbol = value < 0 ? '- 24' : ' 24';
    return '$symbol$withCommas$decimalPart';
  }

  String _formatCurrency(double value) {
    if (value == 0) return r'$0';
    final absValue = value.abs();
    final decimals = absValue >= 1000 ? 0 : absValue >= 100 ? 1 : 2;
    final text = absValue.toStringAsFixed(decimals);
    final parts = text.split('.');
    final whole = parts.first;
    final withCommas = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    final hasDecimals = parts.length > 1 && int.tryParse(parts[1]) != 0;
    final decimalPart = hasDecimals ? '.${parts[1]}' : '';
    final symbol = value < 0 ? '-\$' : '\$';
    return '$symbol$withCommas$decimalPart';
  }

  // Helper methods to extract data from project model for each solution
  String _getRiskDataForSolution(ProjectDataModel projectData, String solutionTitle) {
    final solutionRisk = projectData.solutionRisks.firstWhere(
      (risk) => risk.solutionTitle.trim().toLowerCase() == solutionTitle.trim().toLowerCase(),
      orElse: () => SolutionRisk(solutionTitle: solutionTitle),
    );
    
    final risks = solutionRisk.risks.where((r) => r.trim().isNotEmpty).toList();
    if (risks.isEmpty) return 'No risks identified';
    
    return risks.take(4).map((risk) => '- $risk').join('\n');
  }

  String _getITDataForSolution(ProjectDataModel projectData, String solutionTitle) {
    if (projectData.itConsiderationsData == null) return 'No IT considerations recorded';
    
    final itData = projectData.itConsiderationsData!.solutionITData.firstWhere(
      (it) => it.solutionTitle.trim().toLowerCase() == solutionTitle.trim().toLowerCase(),
      orElse: () => SolutionITData(solutionTitle: solutionTitle),
    );
    
    if (itData.coreTechnology.trim().isEmpty) return 'No IT considerations recorded';
    return itData.coreTechnology;
  }

  String _getInfrastructureDataForSolution(ProjectDataModel projectData, String solutionTitle) {
    if (projectData.infrastructureConsiderationsData == null) return 'No infrastructure considerations recorded';
    
    final infraData = projectData.infrastructureConsiderationsData!.solutionInfrastructureData.firstWhere(
      (infra) => infra.solutionTitle.trim().toLowerCase() == solutionTitle.trim().toLowerCase(),
      orElse: () => SolutionInfrastructureData(solutionTitle: solutionTitle),
    );
    
    if (infraData.majorInfrastructure.trim().isEmpty) return 'No infrastructure considerations recorded';
    return infraData.majorInfrastructure;
  }

  String _getStakeholderDataForSolution(ProjectDataModel projectData, String solutionTitle) {
    if (projectData.coreStakeholdersData == null) return 'No stakeholders identified';
    
    final stakeholderData = projectData.coreStakeholdersData!.solutionStakeholderData.firstWhere(
      (sh) => sh.solutionTitle.trim().toLowerCase() == solutionTitle.trim().toLowerCase(),
      orElse: () => SolutionStakeholderData(solutionTitle: solutionTitle),
    );
    
    if (stakeholderData.notableStakeholders.trim().isEmpty) return 'No stakeholders identified';
    return stakeholderData.notableStakeholders;
  }

  String _getCostBenefitDataForSolution(ProjectDataModel projectData, String solutionTitle) {
    if (projectData.costAnalysisData == null) return 'No cost analysis available';
    
    final costData = projectData.costAnalysisData!.solutionCosts.firstWhere(
      (cost) => cost.solutionTitle.trim().toLowerCase() == solutionTitle.trim().toLowerCase(),
      orElse: () => SolutionCostData(solutionTitle: solutionTitle),
    );
    
    if (costData.costRows.isEmpty) return 'No cost analysis available';
    
    final lines = <String>[];
    
    // Add project value if available
    if (projectData.costAnalysisData!.projectValueAmount.trim().isNotEmpty) {
      lines.add('Project Value: ${projectData.costAnalysisData!.projectValueAmount}');
    }
    
    // Add top cost items
    final topCosts = costData.costRows.take(3).where((row) => row.itemName.trim().isNotEmpty);
    for (final cost in topCosts) {
      final costStr = cost.cost.trim().isNotEmpty ? cost.cost : 'TBD';
      lines.add('- ${cost.itemName}: $costStr');
    }
    
    return lines.isEmpty ? 'No cost analysis available' : lines.join('\n');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _projectNameController.dispose();
    super.dispose();
  }
}

class _SolutionAnalysisData {
  final AiSolutionItem solution;
  final List<String> stakeholders;
  final List<String> risks;
  final List<String> technologies;
  final List<String> infrastructure;
  final List<AiCostItem> costs;

  const _SolutionAnalysisData({
    required this.solution,
    required this.stakeholders,
    required this.risks,
    required this.technologies,
    required this.infrastructure,
    required this.costs,
  });
}

class _ProjectSelectionResult {
  final AiSolutionItem solution;
  final String projectName;

  const _ProjectSelectionResult({required this.solution, required this.projectName});
}

class _ProjectSelectionDialog extends StatefulWidget {
  final List<AiSolutionItem> solutions;

  const _ProjectSelectionDialog({required this.solutions});

  @override
  State<_ProjectSelectionDialog> createState() => _ProjectSelectionDialogState();
}

class _ProjectSelectionDialogState extends State<_ProjectSelectionDialog> {
  int? _selectedIndex;
  late final TextEditingController _nameController;
  String? _error;
  bool _nameManuallyEdited = false;
  bool _suppressNameChange = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Choose a project to progress',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Pick the solution you want to advance and give your project a memorable name.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: widget.solutions.length >= 3 ? 360 : 280,
                ),
                child: Scrollbar(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (int i = 0; i < widget.solutions.length; i++)
                        _ProjectOptionCard(
                          solution: widget.solutions[i],
                          isSelected: _selectedIndex == i,
                          onTap: () => _onSelect(i),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                onChanged: (_) {
                  if (_suppressNameChange) return;
                  setState(() {
                    _nameManuallyEdited = true;
                    if (_error != null) _error = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Project name',
                  hintText: 'e.g. ${_selectedIndex != null ? widget.solutions[_selectedIndex!].title : 'People Operations Transformation'}',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _confirmSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Save & Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelect(int index) {
    setState(() {
      _selectedIndex = index;
      _error = null;
      if (!_nameManuallyEdited || _nameController.text.trim().isEmpty) {
        _suppressNameChange = true;
        _nameController
          ..text = widget.solutions[index].title
          ..selection = TextSelection.collapsed(offset: _nameController.text.length);
        _suppressNameChange = false;
        _nameManuallyEdited = false;
      }
    });
  }

  void _confirmSelection() {
    final index = _selectedIndex;
    if (index == null) {
      setState(() => _error = 'Select a project first.');
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give your project a name to continue.');
      return;
    }

    Navigator.of(context).pop(
      _ProjectSelectionResult(
        solution: widget.solutions[index],
        projectName: name,
      ),
    );
  }
}

class _ProjectOptionCard extends StatelessWidget {
  final AiSolutionItem solution;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProjectOptionCard({
    required this.solution,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? const Color(0xFFFFD700) : Colors.grey.withOpacity(0.2);
    final background = isSelected ? const Color(0xFFFFF8DC) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFFFFD700) : Colors.grey[200],
                ),
                alignment: Alignment.center,
                child: Icon(
                  isSelected ? Icons.check : Icons.lightbulb_outline,
                  color: isSelected ? Colors.black : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      solution.title.isNotEmpty ? solution.title : 'Untitled Solution',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      solution.description.isNotEmpty
                          ? solution.description
                          : 'Describe the outcomes, value proposition, and key enablers for this option.',
                      style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
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
}

class PreferredSolutionComparisonScreen extends StatelessWidget {
  final String notes;
  final List<_SolutionAnalysisData> analysis;
  final List<AiSolutionItem> solutions;
  final String businessCase;

  const PreferredSolutionComparisonScreen({
    super.key,
    required this.notes,
    required this.analysis,
    required this.solutions,
    required this.businessCase,
  });

  @override
  Widget build(BuildContext context) {
    final pagePadding = AppBreakpoints.pagePadding(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Preferred Solution Comparison',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Side-by-side comparison ready for export or print.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Confirm the best approach with the full picture in view.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _ComparisonContent(
              analysis: analysis,
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Front End Planning Summary Screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FrontEndPlanningSummaryScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Next', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonContent extends StatelessWidget {
  final List<_SolutionAnalysisData> analysis;

  const _ComparisonContent({required this.analysis});

  @override
  Widget build(BuildContext context) {
    if (analysis.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPrintToolbar(context),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final canDisplayColumns = constraints.maxWidth >= 900 && analysis.length <= 3;
            if (canDisplayColumns) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < analysis.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == analysis.length - 1 ? 0 : 16),
                        child: _buildComparisonCard(context, data: analysis[i], index: i),
                      ),
                    ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < analysis.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == analysis.length - 1 ? 0 : 16),
                    child: _buildComparisonCard(context, data: analysis[i], index: i),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  static Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('No solutions available yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
            'Add potential solutions to see their stakeholders, risks, and cost signals in one place.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  static Widget _buildPrintToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.compare_arrows, color: Colors.black54),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Side-by-side comparison ready for export or print. Confirm the best approach with the full picture in view.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Opens printer-friendly guidance',
            waitDuration: const Duration(milliseconds: 200),
            child: OutlinedButton.icon(
              onPressed: () => _showPrintDialog(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.print_outlined, size: 18),
              label: const Text('Print tips', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  static void _showPrintDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Print this comparison'),
          content: const Text(
            'Use your browser\'s print shortcut (Ctrl/Cmd + P) to export this consolidated view. For best fidelity choose landscape orientation and reduce margins so each solution column fits on a single page.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildComparisonCard(BuildContext context, {required _SolutionAnalysisData data, required int index}) {
    final title = data.solution.title.isNotEmpty ? data.solution.title : 'Solution ${index + 1}';
    final description = data.solution.description.isNotEmpty ? data.solution.description : 'Discipline';
    final stakeholders = _topStrings(data.stakeholders, maxItems: 5);
    final risks = _topStrings(data.risks, maxItems: 5);
    final costs = data.costs;
    final hasCosts = costs.isNotEmpty;
    final totalCost = hasCosts ? costs.fold<double>(0.0, (sum, item) => sum + item.estimatedCost) : 0.0;
    final averageRoi = hasCosts ? costs.map((item) => item.roiPercent).reduce((a, b) => a + b) / costs.length : 0.0;
    final bestNpv = hasCosts ? costs.map((item) => item.npv).reduce(math.max) : 0.0;
    final strongestCost = hasCosts ? costs.reduce((prev, next) => next.estimatedCost > prev.estimatedCost ? next : prev) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(description, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                ),
                const _AiTag(),
              ],
            ),
            const SizedBox(height: 18),
            _buildCardSection(
              title: 'Engage these stakeholders',
              child: stakeholders.isEmpty ? _buildCardPlaceholder('No stakeholder insights yet.') : _buildCardList(stakeholders),
            ),
            const SizedBox(height: 18),
            _buildCardSection(
              title: 'Risks to monitor',
              child: risks.isEmpty ? _buildCardPlaceholder('No risk considerations generated.') : _buildCardList(risks),
            ),
            const SizedBox(height: 18),
            _buildCardSection(
              title: 'Financial signals',
              child: hasCosts
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFinancialHighlights(totalCost: totalCost, averageRoi: averageRoi, bestNpv: bestNpv, strongestCost: strongestCost),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: costs.take(5).map((item) {
                            final label = item.item.isNotEmpty ? item.item : 'Cost item';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FBFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  if (item.description.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(item.description, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _buildCostBadge('Est. cost', _formatCurrency(item.estimatedCost)),
                                      _buildCostBadge('ROI', '${item.roiPercent.toStringAsFixed(1)}%'),
                                      _buildCostBadge('NPV (5yr)', _formatCurrency(item.npvForYear(5))),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  : _buildCardPlaceholder('No cost analysis generated yet.'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCardSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  static Widget _buildCardPlaceholder(String message) {
    return Text(message, style: const TextStyle(fontSize: 12, color: Colors.black38));
  }

  static Widget _buildCardList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  static Widget _buildFinancialHighlights({required double totalCost, required double averageRoi, required double bestNpv, AiCostItem? strongestCost}) {
    final badges = <Widget>[
      _buildCostBadge('Total investment', _formatCurrency(totalCost)),
      _buildCostBadge('Avg ROI', '${averageRoi.toStringAsFixed(1)}%'),
      _buildCostBadge('Best NPV (5yr)', _formatCurrency(bestNpv)),
    ];

    if (strongestCost != null) {
      final label = strongestCost.item.isNotEmpty ? strongestCost.item : 'Cost item';
      badges.add(_buildCostBadge('Largest cost driver', '$label - ${_formatCurrency(strongestCost.estimatedCost)}'));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: badges,
    );
  }

  static Widget _buildCostBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7CC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }

  static Widget _buildComparisonMatrix(BuildContext context, List<_SolutionAnalysisData> analysis) {
    final headers = [
      for (var i = 0; i < analysis.length; i++)
        '${i + 1}. ${analysis[i].solution.title.isNotEmpty ? analysis[i].solution.title : 'Solution ${i + 1}'}',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Text(
              'Side-by-side summary',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final available = constraints.maxWidth - 32;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildMatrixTable(analysis, headers, availableWidth: available),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Table _buildMatrixTable(List<_SolutionAnalysisData> analysis, List<String> headers, {double? availableWidth}) {
    const leftCol = 220.0;
    final columnWidths = <int, TableColumnWidth>{0: const FixedColumnWidth(leftCol)};
    final count = headers.length;
    double perCol = 300;
    if (availableWidth != null && availableWidth > leftCol + 100) {
      final remain = availableWidth - leftCol;
      perCol = (remain / count).clamp(240, 420);
    }
    for (var i = 1; i <= count; i++) {
      columnWidths[i] = FixedColumnWidth(perCol);
    }

    final rows = <TableRow>[];

    rows.add(
      TableRow(
        children: [
          _buildMatrixCellText('Category', isHeader: true),
          for (final header in headers) _buildMatrixCellText(header, isHeader: true),
        ],
      ),
    );

    rows.add(
      TableRow(
        children: [
          _buildMatrixCellText('Focus summary', emphasize: true),
          for (final data in analysis) _buildMatrixCellText(_formatListForMatrix([data.solution.description])),
        ],
      ),
    );

    rows.add(
      TableRow(
        children: [
          _buildMatrixCellText('Core stakeholders', emphasize: true),
          for (final data in analysis) _buildMatrixCellText(_formatListForMatrix(_topStrings(data.stakeholders, maxItems: 6))),
        ],
      ),
    );

    rows.add(
      TableRow(
        children: [
          _buildMatrixCellText('Risk identification', emphasize: true),
          for (final data in analysis) _buildMatrixCellText(_formatListForMatrix(_topStrings(data.risks, maxItems: 6))),
        ],
      ),
    );

    rows.add(
      TableRow(
        children: [
          _buildMatrixCellText('IT considerations', emphasize: true),
          for (final data in analysis) _buildMatrixCellText(_formatListForMatrix(_topStrings(data.technologies, maxItems: 6))),
        ],
      ),
    );

    rows.add(
      TableRow(
        children: [
          _buildMatrixCellText('Infrastructure considerations', emphasize: true),
          for (final data in analysis) _buildMatrixCellText(_formatListForMatrix(_topStrings(data.infrastructure, maxItems: 6))),
        ],
      ),
    );

    rows.add(
      TableRow(
        children: [
          _buildMatrixCellText('Cost-benefit & financial metrics', emphasize: true),
          for (final data in analysis) _buildMatrixCellText(_financialSummaryText(data)),
        ],
      ),
    );

    rows.add(
      TableRow(
        children: [
          _buildMatrixCellText('Cost drivers', emphasize: true),
          for (final data in analysis)
            _buildMatrixCellText(
              _formatListForMatrix(
                data.costs
                    .map((e) => '${e.item.isNotEmpty ? e.item : 'Cost item'} - ${_formatCurrency(e.estimatedCost)}')
                    .toList(),
                maxItems: 5,
              ),
            ),
        ],
      ),
    );

    return Table(
      border: TableBorder.all(color: Colors.grey.withValues(alpha: 0.3), width: 0.7),
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: rows,
    );
  }

  static Widget _buildMatrixCellText(String text, {bool isHeader = false, bool emphasize = false}) {
    final style = TextStyle(
      fontSize: 12,
      fontWeight: isHeader
          ? FontWeight.w700
          : emphasize
              ? FontWeight.w600
              : FontWeight.w400,
      color: Colors.black87,
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(text.isNotEmpty ? text : 'N/A', style: style, softWrap: true),
    );
  }

  static String _formatListForMatrix(List<String> items, {int maxItems = 4}) {
    final trimmed = items.where((e) => e.trim().isNotEmpty).take(maxItems).toList();
    if (trimmed.isEmpty) return 'N/A';
    return trimmed.map((value) => '- ${value.trim()}').join('\n');
  }

  static List<String> _topStrings(List<String> source, {int maxItems = 4}) {
    return source.where((e) => e.trim().isNotEmpty).map((e) => e.trim()).take(maxItems).toList();
  }

  static String _financialSummaryText(_SolutionAnalysisData data) {
    final costs = data.costs;
    if (costs.isEmpty) {
      return 'No financial insights available yet.';
    }
    final totalCost = costs.fold<double>(0.0, (sum, item) => sum + item.estimatedCost);
    final avgRoi = costs.map((item) => item.roiPercent).reduce((a, b) => a + b) / costs.length;
    final bestNpv = costs.map((item) => item.npv).reduce(math.max);
    return 'Total: ${_formatCurrency(totalCost)}\nAvg ROI: ${avgRoi.toStringAsFixed(1)}%\nBest NPV: ${_formatCurrency(bestNpv)}';
  }

  static String _formatCurrency(double value) {
    if (value == 0) return r'$0';
    final absValue = value.abs();
    final decimals = absValue >= 1000 ? 0 : absValue >= 100 ? 1 : 2;
    final text = absValue.toStringAsFixed(decimals);
    final parts = text.split('.');
    final whole = parts.first;
    final withCommas = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    final hasDecimals = parts.length > 1 && int.tryParse(parts[1]) != 0;
    final decimalPart = hasDecimals ? '.${parts[1]}' : '';
    final symbol = value < 0 ? '-\$' : '\$';
    return '$symbol$withCommas$decimalPart';
  }
}

class _AiTag extends StatelessWidget {
  const _AiTag();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(color: Color(0xFFFFD700), borderRadius: BorderRadius.all(Radius.circular(4))),
      child: const Text('AI', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
