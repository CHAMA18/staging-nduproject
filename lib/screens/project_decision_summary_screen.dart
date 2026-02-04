import 'package:flutter/material.dart';
import 'package:ndu_project/screens/front_end_planning_summary.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/content_text.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/project_service.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';

class ProjectDecisionSummaryScreen extends StatefulWidget {
  final String projectName;
  final AiSolutionItem selectedSolution;
  final List<AiSolutionItem> allSolutions;
  final String businessCase;
  final String notes;

  const ProjectDecisionSummaryScreen({
    super.key,
    required this.projectName,
    required this.selectedSolution,
    required this.allSolutions,
    required this.businessCase,
    required this.notes,
  });

  @override
  State<ProjectDecisionSummaryScreen> createState() =>
      _ProjectDecisionSummaryScreenState();
}

class _ProjectDecisionSummaryScreenState
    extends State<ProjectDecisionSummaryScreen> {
  String? _selectedSolutionTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadExistingSelection());
  }

  String get _safeProjectName => widget.projectName.trim().isEmpty
      ? widget.selectedSolution.title
      : widget.projectName.trim();

  Future<void> _loadExistingSelection() async {
    try {
      final provider = ProjectDataHelper.getProvider(context);
      final existingData = provider.projectData.preferredSolutionAnalysis;
      if (existingData?.selectedSolutionTitle != null && mounted) {
        setState(() {
          _selectedSolutionTitle = existingData!.selectedSolutionTitle;
        });
      }
    } catch (e) {
      debugPrint('Error loading existing selection: $e');
    }
  }

  Future<void> _handleSelectSolution(String solutionTitle) async {
    setState(() {
      _selectedSolutionTitle = solutionTitle;
    });

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
              'Saving your selection...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );

    await _saveComparisonData(solutionTitle);
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _saveComparisonData(String selectedSolutionTitle) async {
    try {
      final provider = ProjectDataHelper.getProvider(context);
      final currentAnalysis = provider.projectData.preferredSolutionAnalysis;

      final updatedAnalysis = PreferredSolutionAnalysis(
        workingNotes: currentAnalysis?.workingNotes ?? '',
        solutionAnalyses: currentAnalysis?.solutionAnalyses ?? [],
        selectedSolutionTitle: selectedSolutionTitle,
      );

      final updatedData = provider.projectData.copyWith(
        preferredSolutionAnalysis: updatedAnalysis,
        projectName: selectedSolutionTitle,
        currentCheckpoint: 'preferred_solution_comparison',
      );

      provider.updateProjectData(updatedData);

      if (provider.projectData.projectId != null) {
        await ProjectService.updateCheckpoint(
          projectId: provider.projectData.projectId!,
          checkpointRoute: 'preferred_solution_comparison',
        );
      }
    } catch (e) {
      debugPrint('Error saving comparison data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isMobile = AppBreakpoints.isMobile(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Preferred Solutions'),
            ),
            Expanded(
              child: Stack(
                children: [
                  Column(
                    children: [
                      _Header(projectName: _safeProjectName),
                      Expanded(
                        child: _MainContent(
                          projectName: _safeProjectName,
                          businessCase: widget.businessCase.trim(),
                          notes: widget.notes.trim(),
                          selectedSolution: widget.selectedSolution,
                          allSolutions: widget.allSolutions,
                          selectedSolutionTitle: _selectedSolutionTitle,
                          onSelectSolution: _handleSelectSolution,
                          onNext: _handleNextNavigation,
                        ),
                      ),
                    ],
                  ),
                  const KazAiChatBubble(),
                  const AdminEditToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNextNavigation() async {
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

    // Save checkpoint
    try {
      final provider = ProjectDataHelper.getProvider(context);
      final updatedData = provider.projectData.copyWith(
        currentCheckpoint: 'fep_summary',
      );
      provider.updateProjectData(updatedData);

      if (provider.projectData.projectId != null) {
        await ProjectService.updateCheckpoint(
          projectId: provider.projectData.projectId!,
          checkpointRoute: 'fep_summary',
        );
      }
    } catch (e) {
      debugPrint('Error saving checkpoint: $e');
    }

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    // Navigate to Front End Planning Summary
    if (!mounted) return;
    FrontEndPlanningSummaryScreen.open(context);
  }
}

class _Header extends StatelessWidget {
  final String projectName;

  const _Header({required this.projectName});

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    return Container(
      height: isMobile ? 56 : 70,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
            ),
          if (!isMobile) ...[
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          const Spacer(),
          if (!isMobile)
            const Text(
              'Preferred Solution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue[400],
                  child: Text(
                    FirebaseAuthService.displayNameOrEmail(fallback: 'U')
                        .characters
                        .first
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        FirebaseAuthService.displayNameOrEmail(
                            fallback: 'User'),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Text('Owner',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: Colors.grey),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Replaced custom sidebar with InitiationLikeSidebar for consistency with InitiationPhaseScreen.

class _MainContent extends StatefulWidget {
  final String projectName;
  final String businessCase;
  final String notes;
  final AiSolutionItem selectedSolution;
  final List<AiSolutionItem> allSolutions;
  final String? selectedSolutionTitle;
  final Function(String) onSelectSolution;
  final Future<void> Function() onNext;

  const _MainContent({
    required this.projectName,
    required this.businessCase,
    required this.notes,
    required this.selectedSolution,
    required this.allSolutions,
    required this.selectedSolutionTitle,
    required this.onSelectSolution,
    required this.onNext,
  });

  @override
  State<_MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<_MainContent> {
  int _activeTab =
      0; // 0=Business Case, 1=Preferred Solution, 2=Risk Identification, 3=Core Stakeholders
  String? _riskSummary;
  String? _stakeholderSummary;
  bool _loadingRisks = false;
  bool _loadingStakeholders = false;
  String? _riskError;
  String? _stakeholderError;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _ensureRiskSummary() async {
    if (_riskSummary != null || _loadingRisks) return;
    setState(() => _loadingRisks = true);
    try {
      final openAi = OpenAiServiceSecure();
      final map = await openAi.generateRisksForSolutions([
        AiSolutionItem(
            title: widget.selectedSolution.title,
            description: widget.selectedSolution.description),
      ], contextNotes: widget.notes);
      final risks = map[widget.selectedSolution.title] ?? const <String>[];
      final text = risks.isEmpty
          ? 'No risks captured yet.'
          : 'Top risks: ${risks.join('; ')}.';
      setState(() {
        _riskSummary = text;
        _riskError = null;
      });
    } catch (e) {
      setState(() {
        _riskError = e.toString();
        _riskSummary = null;
      });
    } finally {
      if (mounted) setState(() => _loadingRisks = false);
    }
  }

  Future<void> _ensureStakeholderSummary() async {
    if (_stakeholderSummary != null || _loadingStakeholders) return;
    setState(() => _loadingStakeholders = true);
    try {
      final openAi = OpenAiServiceSecure();
      final map = await openAi.generateStakeholdersForSolutions([
        AiSolutionItem(
            title: widget.selectedSolution.title,
            description: widget.selectedSolution.description),
      ], contextNotes: widget.notes);
      final internal =
          map['internal']?[widget.selectedSolution.title] ?? const <String>[];
      final external =
          map['external']?[widget.selectedSolution.title] ?? const <String>[];
      final combined = <String>[...internal, ...external];
      final text = combined.isEmpty
          ? 'No stakeholders captured yet.'
          : 'Key stakeholders: ${combined.join('; ')}.';
      setState(() {
        _stakeholderSummary = text;
        _stakeholderError = null;
      });
    } catch (e) {
      setState(() {
        _stakeholderError = e.toString();
        _stakeholderSummary = null;
      });
    } finally {
      if (mounted) setState(() => _loadingStakeholders = false);
    }
  }

  // ignore: unused_element
  void _onTabSelected(int index) {
    setState(() => _activeTab = index);
    if (index == 2) {
      _ensureRiskSummary();
    } else if (index == 3) {
      _ensureStakeholderSummary();
    }
  }

  void _showPrintTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Print Tips'),
        content: const Text(
          'To print or export this comparison:\n\n'
          '1. Use your browser\'s print function (Ctrl+P or Cmd+P)\n'
          '2. Select "Save as PDF" as your printer\n'
          '3. Adjust margins and layout as needed\n'
          '4. Save or print the document',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCards() {
    // Show ONLY the selected preferred solution.
    final solutions = <AiSolutionItem>[widget.selectedSolution];

    if (solutions.isEmpty) {
      return const Center(
          child: Text('No solutions available for comparison.'));
    }

    // Get analysis data from context
    SolutionAnalysisItem? getAnalysisForSolution(String title) {
      try {
        final provider = ProjectDataHelper.getProvider(context);
        final analysis = provider.projectData.preferredSolutionAnalysis;
        if (analysis != null) {
          for (var item in analysis.solutionAnalyses) {
            if (item.solutionTitle == title) {
              return item;
            }
          }
        }
      } catch (e) {
        debugPrint('Error getting analysis: $e');
      }
      return null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: solutions
          .map((solution) => _buildSolutionCard(
                solution,
                analysisData: getAnalysisForSolution(solution.title),
                isSelected: true,
              ))
          .toList(),
    );
  }

  Widget _buildSolutionCard(AiSolutionItem solution,
      {required bool isSelected, required SolutionAnalysisItem? analysisData}) {
    final solutionTitle =
        solution.title.isNotEmpty ? solution.title : 'Potential Opportunity';

    // Check if THIS specific solution is the selected one
    final isThisSolutionSelected =
        widget.selectedSolutionTitle == solutionTitle;

    // Use actual data if available, otherwise use placeholder
    final stakeholders = analysisData?.stakeholders.isNotEmpty == true
        ? analysisData!.stakeholders
        : [
            'Regulatory authority (industry-specific)',
            'Data protection authority / privacy office',
            'Government procurement or finance oversight',
            'External vendors / systems integrators',
            'Compliance & internal audit',
          ];

    final risks = analysisData?.risks.isNotEmpty == true
        ? analysisData!.risks
        : [
            'Scope creep increases delivery time and cost.',
            'Integration challenges with existing systems and data.',
            'Resource constraints or skill gaps delay milestones.',
          ];

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isThisSolutionSelected
                ? const Color(0xFFFFD700)
                : Colors.grey.withValues(alpha: 0.2),
            width: isThisSolutionSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isThisSolutionSelected ? 0.08 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    solutionTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14),
                      SizedBox(width: 4),
                      Text('AI',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              solution.description.isNotEmpty
                  ? solution.description
                  : 'Discipline',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            _buildComparisonSection('Engage these stakeholders', stakeholders),
            const SizedBox(height: 20),
            _buildComparisonSection('Risks to monitor', risks),
            const SizedBox(height: 20),
            _buildITConsiderationsSection(analysisData),
            const SizedBox(height: 20),
            _buildInfrastructureSection(analysisData),
            const SizedBox(height: 20),
            _buildFinancialSignals(analysisData),
            const SizedBox(height: 20),
            if (analysisData?.costs != null &&
                analysisData!.costs.isNotEmpty) ...[
              for (var cost in analysisData.costs.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPhaseFromCost(cost),
                ),
            ] else ...[
              _buildPhase(
                  'Discovery & Planning',
                  'Workshops, requirements, roadmap and governance setup',
                  '\$25,000',
                  '12.0%',
                  '\$8,000'),
              const SizedBox(height: 16),
              _buildPhase(
                  'MVP Build',
                  'Design, engineering, testing for initial release',
                  '\$120,000',
                  '16.3%',
                  '\$24,000'),
            ],
            const SizedBox(height: 24),
            // Selection happens in Preferred Solution Analysis; this page is read-only.
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- ', style: TextStyle(fontSize: 13)),
                  Expanded(
                      child: Text(item,
                          style: const TextStyle(fontSize: 13, height: 1.4))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildITConsiderationsSection(SolutionAnalysisItem? analysisData) {
    final itItems = <String>[];
    
    if (analysisData?.technologies.isNotEmpty == true) {
      // Use the technologies list
      itItems.addAll(analysisData!.technologies);
    } else {
      // Placeholder if no data
      itItems.add('No IT considerations recorded.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.computer, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            const Text('IT Considerations',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        ...itItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- ', style: TextStyle(fontSize: 13)),
                  Expanded(
                      child: Text(item,
                          style: const TextStyle(fontSize: 13, height: 1.4))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildInfrastructureSection(SolutionAnalysisItem? analysisData) {
    final infraItems = <String>[];
    
    if (analysisData?.infrastructure.isNotEmpty == true) {
      // Use the infrastructure list
      infraItems.addAll(analysisData!.infrastructure);
    } else {
      // Placeholder if no data
      infraItems.add('No infrastructure considerations recorded.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.construction, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            const Text('Infrastructure Considerations',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        ...infraItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- ', style: TextStyle(fontSize: 13)),
                  Expanded(
                      child: Text(item,
                          style: const TextStyle(fontSize: 13, height: 1.4))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildFinancialSignals(SolutionAnalysisItem? analysisData) {
    if (analysisData?.costs == null || analysisData!.costs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Financial signals',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFinancialChip('Total investment: \$190,000'),
              _buildFinancialChip('Avg ROI 16.3%'),
              _buildFinancialChip('Best NPV (5yr) \$24,000'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFinancialChip('Largest cost driver: MVP Build - \$120,000'),
            ],
          ),
        ],
      );
    }

    final costs = analysisData.costs;
    final totalInvestment =
        costs.fold<double>(0, (sum, cost) => sum + cost.estimatedCost);
    final avgRoi = costs.fold<double>(0, (sum, cost) => sum + cost.roiPercent) /
        costs.length;

    // Calculate best NPV from year 5 across all costs
    double bestNpv = 0;
    for (var cost in costs) {
      if (cost.npvByYear.containsKey(5)) {
        final npv = cost.npvByYear[5]!;
        if (npv > bestNpv) bestNpv = npv;
      }
    }

    final largestCost =
        costs.reduce((a, b) => a.estimatedCost > b.estimatedCost ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Financial signals',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFinancialChip(
                'Total investment: \$${totalInvestment.toStringAsFixed(0)}'),
            _buildFinancialChip('Avg ROI ${avgRoi.toStringAsFixed(1)}%'),
            _buildFinancialChip(
                'Best NPV (5yr) \$${bestNpv.toStringAsFixed(0)}'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFinancialChip(
                'Largest cost driver: ${largestCost.item} - \$${largestCost.estimatedCost.toStringAsFixed(0)}'),
          ],
        ),
      ],
    );
  }

  Widget _buildPhaseFromCost(CostItem cost) {
    final npv5yr = cost.npvByYear.containsKey(5) ? cost.npvByYear[5]! : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(cost.item,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(cost.description,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFinancialChip(
                'Est. cost \$${cost.estimatedCost.toStringAsFixed(0)}'),
            _buildFinancialChip('ROI ${cost.roiPercent.toStringAsFixed(1)}%'),
            _buildFinancialChip('NPV (5yr) \$${npv5yr.toStringAsFixed(0)}'),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBE6),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPhase(
      String title, String description, String cost, String roi, String npv) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(description,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFinancialChip('Est. cost $cost'),
            _buildFinancialChip('ROI $roi'),
            _buildFinancialChip('NPV (5yr) $npv'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = AppBreakpoints.pagePadding(context);
    // ignore: unused_local_variable
    final sectionGap = AppBreakpoints.sectionGap(context);
    final displayBusinessCase = widget.businessCase.isNotEmpty
        ? widget.businessCase
        : 'Describe the overarching business case for the "${widget.projectName}" initiative to keep the team aligned on why it matters.';
    final preferredSolution = widget.selectedSolution.description.isNotEmpty
        ? widget.selectedSolution.description
        : 'Summarize how this chosen solution unlocks the expected outcomes and the primary tradeoffs to track.';
    // ignore: unused_local_variable
    final infoCallout = widget.notes.isNotEmpty
        ? widget.notes
        : 'Capture lessons, open questions, or action items to revisit during the next phase review.';

    // ignore: unused_element
    String contentForActiveTab() {
      switch (_activeTab) {
        case 0:
          return displayBusinessCase;
        case 1:
          return preferredSolution;
        case 2:
          if (_loadingRisks) return 'Summarizing risks...';
          if (_riskError != null) {
            return 'Unable to summarize risks. Tap to retry.';
          }
          return _riskSummary ?? 'No risks captured yet.';
        case 3:
          if (_loadingStakeholders) return 'Summarizing stakeholders...';
          if (_stakeholderError != null) {
            return 'Unable to summarize stakeholders. Tap to retry.';
          }
          return _stakeholderSummary ?? 'No stakeholders captured yet.';
        case 4:
          return 'Outline infrastructure constraints, dependencies, environments, and rollout considerations.';
        case 5:
          return 'Capture IT architecture, security, integrations, and support requirements.';
        default:
          return displayBusinessCase;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EditableContentText(
                  contentKey: 'executive_summary_heading',
                  fallback: 'Preferred Solution',
                  category: 'business_case',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const EditableContentText(
                  contentKey: 'executive_summary_subtitle1',
                  fallback:
                      'Side-by-side comparison ready for export or print.',
                  category: 'business_case',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                const EditableContentText(
                  contentKey: 'executive_summary_subtitle2',
                  fallback:
                      'Confirm the best approach with the full picture in view.',
                  category: 'business_case',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.print_outlined, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Side-by-side comparison ready for export or print. Confirm the best approach with the full picture in view.',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _showPrintTips,
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Print tips'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          side: const BorderSide(color: Colors.black87),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildComparisonCards(),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerRight,
                  child: _NextButton(onPressed: widget.onNext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ignore: unused_element
class _SummaryCard extends StatelessWidget {
  final String text;

  const _SummaryCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        style:
            const TextStyle(fontSize: 14.5, height: 1.5, color: Colors.black87),
      ),
    );
  }
}

// ignore: unused_element
class _SummaryTabs extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onSelected;

  const _SummaryTabs({required this.activeIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Business Case',
      'Preferred Solution',
      'Risk Identification',
      'Core Stakeholders',
      'Infrastructure Considerations',
      'IT Considerations',
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        for (int i = 0; i < labels.length; i++)
          GestureDetector(
            onTap: () => onSelected(i),
            child: _TabButton(
              label: labels[i],
              isActive: i == activeIndex,
            ),
          ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TabButton({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFFFFD700);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isActive ? activeColor : Colors.grey.withValues(alpha: 0.2)),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.black : Colors.grey[700],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _InfoBadge extends StatelessWidget {
  final String text;

  const _InfoBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFE0F0FF),
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Tooltip(
        message: text,
        child:
            const Icon(Icons.info_outline, size: 28, color: Color(0xFF0B77D0)),
      ),
    );
  }
}

// ignore: unused_element
class _AiCallout extends StatelessWidget {
  final String solutionTitle;

  const _AiCallout({required this.solutionTitle});

  @override
  Widget build(BuildContext context) {
    final focusText = solutionTitle.trim().isEmpty
        ? 'this potential solution'
        : solutionTitle.trim();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF0B77D0),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child:
                const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B77D0),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Focus on major risks associated with $focusText.',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NextButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        elevation: 2,
      ),
      child: const Text(
        'Next',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
