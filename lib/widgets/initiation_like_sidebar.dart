import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:ndu_project/screens/home_screen.dart';
import 'package:ndu_project/screens/settings_screen.dart';
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/potential_solutions_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/it_considerations_screen.dart';
import 'package:ndu_project/screens/infrastructure_considerations_screen.dart';
import 'package:ndu_project/screens/core_stakeholders_screen.dart';
import 'package:ndu_project/screens/cost_analysis_screen.dart';
import 'package:ndu_project/screens/cost_estimate_screen.dart';
import 'package:ndu_project/screens/front_end_planning_requirements_screen.dart';
import 'package:ndu_project/screens/front_end_planning_risks_screen.dart';
import 'package:ndu_project/screens/front_end_planning_opportunities_screen.dart';
import 'package:ndu_project/screens/front_end_planning_contract_vendor_quotes_screen.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/screens/front_end_planning_security.dart';
import 'package:ndu_project/screens/front_end_planning_allowance.dart';
import 'package:ndu_project/screens/front_end_planning_summary.dart';
import 'package:ndu_project/screens/front_end_planning_screen.dart';
import 'package:ndu_project/screens/project_charter_screen.dart';
import 'package:ndu_project/screens/ssher_stacked_screen.dart';
import 'package:ndu_project/screens/front_end_planning_screen.dart';
import 'package:ndu_project/screens/execution_plan_screen.dart';
import 'package:ndu_project/screens/front_end_planning_technology_screen.dart';
import 'package:ndu_project/screens/team_management_screen.dart';
import 'package:ndu_project/screens/front_end_planning_contracts_screen.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/screens/change_management_screen.dart';
import 'package:ndu_project/screens/project_plan_screen.dart';
import 'package:ndu_project/screens/project_baseline_screen.dart';
import 'package:ndu_project/screens/stakeholder_management_screen.dart';
import 'package:ndu_project/screens/lessons_learned_screen.dart';
import 'package:ndu_project/screens/team_training_building_screen.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/screens/engineering_design_screen.dart';
import 'package:ndu_project/screens/schedule_screen.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/widgets/header_banner_image.dart';
import 'package:ndu_project/screens/issue_management_screen.dart';
import 'package:ndu_project/screens/risk_assessment_screen.dart';
import 'package:ndu_project/screens/staff_team_screen.dart';
import 'package:ndu_project/screens/team_meetings_screen.dart';
import 'package:ndu_project/screens/progress_tracking_screen.dart';
import 'package:ndu_project/screens/gap_analysis_scope_reconcillation_screen.dart';
import 'package:ndu_project/screens/execution_plan_interface_management_overview_screen.dart';
import 'package:ndu_project/screens/project_decision_summary_screen.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/screens/security_management_screen.dart';
import '../screens/quality_management_screen.dart';
import 'package:ndu_project/screens/deliverables_roadmap_screen.dart';
import 'package:ndu_project/screens/preferred_solution_analysis_screen.dart';
import 'package:ndu_project/screens/launch_checklist_screen.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'package:ndu_project/screens/project_framework_screen.dart';
import 'package:ndu_project/screens/punchlist_actions_screen.dart';
import 'package:ndu_project/screens/tools_integration_screen.dart';
import 'package:ndu_project/screens/salvage_disposal_team_screen.dart';
import 'package:ndu_project/screens/deliver_project_closure_screen.dart';
import 'package:ndu_project/screens/transition_to_prod_team_screen.dart';
import 'package:ndu_project/screens/contract_close_out_screen.dart';
import 'package:ndu_project/screens/vendor_account_close_out_screen.dart';
import 'package:ndu_project/screens/ui_ux_design_screen.dart';
import 'package:ndu_project/screens/project_close_out_screen.dart';
import 'package:ndu_project/screens/demobilize_team_screen.dart';
import 'package:ndu_project/screens/actual_vs_planned_gap_analysis_screen.dart';
import 'package:ndu_project/screens/commerce_viability_screen.dart';
import 'package:ndu_project/screens/technical_alignment_screen.dart';
import 'package:ndu_project/screens/long_lead_equipment_ordering_screen.dart';
import 'package:ndu_project/screens/specialized_design_screen.dart';
import 'package:ndu_project/screens/technical_development_screen.dart';
import 'package:ndu_project/screens/summarize_account_risks_screen.dart';
import 'package:ndu_project/screens/agile_development_iterations_screen.dart';
import 'package:ndu_project/screens/scope_completion_screen.dart';
import 'package:ndu_project/screens/requirements_implementation_screen.dart';

 /// Sidebar styled to match InitiationPhaseScreen's sidebar.
 class InitiationLikeSidebar extends StatefulWidget {
   const InitiationLikeSidebar({super.key, this.showHeader = true, this.activeItemLabel});

   final bool showHeader;
   /// Optional: label of the item that should appear highlighted (active)
   final String? activeItemLabel;

  @override
  State<InitiationLikeSidebar> createState() => _InitiationLikeSidebarState();
}

class _InitiationLikeSidebarState extends State<InitiationLikeSidebar> {
  // Shared expansion and scroll state across all instances so navigation
  // doesn't reset the sidebar UI state.
  static bool? _sharedInitiationExpanded;
  static bool? _sharedBusinessCaseExpanded;
  static bool? _sharedFrontEndExpanded;
  static bool? _sharedExecutionPlanExpanded;
  static bool? _sharedPlanningPhaseExpanded;
  static bool? _sharedDesignPhaseExpanded;
  static bool? _sharedExecutionPhaseExpanded;
  static bool? _sharedLaunchPhaseExpanded;
  static bool? _sharedExecutiveSummaryExpanded;
  static bool? _sharedProgressTrackingExpanded;
  static bool? _sharedTeamMeetingsExpanded;
  static double _sharedScrollOffset = 0;

  late bool _initiationExpanded = _sharedInitiationExpanded ?? true;
  late bool _businessCaseExpanded = _sharedBusinessCaseExpanded ?? true;
  late bool _frontEndExpanded = _sharedFrontEndExpanded ?? true;
  late bool _executionPlanExpanded = _sharedExecutionPlanExpanded ?? false;
  late bool _planningPhaseExpanded = _sharedPlanningPhaseExpanded ?? false;
  late bool _designPhaseExpanded = _sharedDesignPhaseExpanded ?? false;
  late bool _executionPhaseExpanded = _sharedExecutionPhaseExpanded ?? false;
  late bool _launchPhaseExpanded = _sharedLaunchPhaseExpanded ?? false;
  late bool _executiveSummaryExpanded = _sharedExecutiveSummaryExpanded ?? true;
  late bool _progressTrackingExpanded = _sharedProgressTrackingExpanded ?? false;
  late bool _teamMeetingsExpanded = _sharedTeamMeetingsExpanded ?? false;
  late final ScrollController _scrollController =
      ScrollController(initialScrollOffset: _sharedScrollOffset);
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Keep the shared state in sync as the user scrolls.
    _scrollController.addListener(() {
      _sharedScrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _sharedScrollOffset = _scrollController.offset;
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Navigation helper that saves checkpoint before navigating
  Future<void> _navigateWithCheckpoint(String checkpoint, Widget screen) async {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      if (provider != null && provider.projectData.projectId != null) {
        await provider.saveToFirebase(checkpoint: checkpoint);
      }
    } catch (e) {
      debugPrint('Checkpoint save error: $e');
    }
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  // Navigation helpers (lightweight routes, pass empty data where required)
  void _openBusinessCase() {
    _navigateWithCheckpoint(
      'business_case',
      const InitiationPhaseScreen(scrollToBusinessCase: true),
    );
  }

  void _openPotentialSolutions() {
    _navigateWithCheckpoint('potential_solutions', const PotentialSolutionsScreen());
  }

  void _openRiskIdentification() {
    _navigateWithCheckpoint('risk_identification', const RiskIdentificationScreen(notes: '', solutions: [], businessCase: ''));
  }

  void _openITConsiderations() {
    _navigateWithCheckpoint('it_considerations', const ITConsiderationsScreen(notes: '', solutions: []));
  }

  void _openInfrastructureConsiderations() {
    _navigateWithCheckpoint('infrastructure_considerations', const InfrastructureConsiderationsScreen(notes: '', solutions: []));
  }

  void _openCoreStakeholders() {
    _navigateWithCheckpoint('core_stakeholders', const CoreStakeholdersScreen(notes: '', solutions: []));
  }

  void _openCostAnalysis() {
    _navigateWithCheckpoint('cost_analysis', const CostAnalysisScreen(notes: '', solutions: []));
  }

  void _openFrontEndRequirements() {
    _navigateWithCheckpoint('fep_requirements', const FrontEndPlanningRequirementsScreen());
  }

  void _openFrontEndRisks() {
    _navigateWithCheckpoint('fep_risks', const FrontEndPlanningRisksScreen());
  }

  void _openFrontEndOpportunities() {
    _navigateWithCheckpoint('fep_opportunities', const FrontEndPlanningOpportunitiesScreen());
  }

  void _openContractVendorQuotes() {
    _navigateWithCheckpoint('fep_contract_vendor_quotes', const FrontEndPlanningContractVendorQuotesScreen());
  }

  void _openSecurity() {
    _navigateWithCheckpoint('fep_security', const FrontEndPlanningSecurityScreen());
  }

  void _openAllowance() {
    _navigateWithCheckpoint('fep_allowance', const FrontEndPlanningAllowanceScreen());
  }

  Future<void> _openSummary() async {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      if (provider != null && provider.projectData.projectId != null) {
        await provider.saveToFirebase(checkpoint: 'fep_summary');
      }
    } catch (e) {
      debugPrint('Checkpoint save error: $e');
    }
    if (mounted) {
      FrontEndPlanningSummaryScreen.open(context);
    }
  }

  Future<void> _openProjectCharter() async {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      if (provider != null && provider.projectData.projectId != null) {
        await provider.saveToFirebase(checkpoint: 'project_charter');
      }
    } catch (e) {
      debugPrint('Checkpoint save error: $e');
    }
    if (mounted) {
      ProjectCharterScreen.open(context);
    }
  }

  void _openProcurement() {
    _navigateWithCheckpoint('fep_procurement', const FrontEndPlanningProcurementScreen());
  }

  void _openSSHER() {
    _navigateWithCheckpoint('ssher', const SsherStackedScreen());
  }

  void _openDesign() {
    _navigateWithCheckpoint('design', const FrontEndPlanningScreen());
  }

  void _openDesignManagement() {
    _navigateWithCheckpoint('design_management', const DesignPhaseScreen());
  }

  void _openExecutionPlan() {
    _navigateWithCheckpoint('execution_plan', const ExecutionPlanScreen());
  }

  void _openExecutionPlanStrategy() {
    _navigateWithCheckpoint('execution_plan_strategy', const ExecutionPlanSolutionsScreen());
  }

  void _openExecutionPlanDetails() {
    _navigateWithCheckpoint('execution_plan_details', const ExecutionPlanDetailsScreen());
  }

  void _openExecutionEarlyWorks() {
    _navigateWithCheckpoint('execution_early_works', const ExecutionPlanDetailsScreen());
  }

  void _openExecutionEnablingWorkPlan() {
    _navigateWithCheckpoint('execution_enabling_work_plan', const ExecutionEnablingWorkPlanScreen());
  }

  void _openExecutionIssueManagement() {
    _navigateWithCheckpoint('execution_issue_management', const ExecutionIssueManagementScreen());
  }

  void _openExecutionPlanLessonsLearned() {
    _navigateWithCheckpoint('execution_plan_lessons_learned', const ExecutionPlanLessonsLearnedScreen());
  }

  void _openExecutionPlanBestPractices() {
    _navigateWithCheckpoint('execution_plan_best_practices', const ExecutionPlanBestPracticesScreen());
  }

  void _openExecutionPlanConstructionPlan() {
    _navigateWithCheckpoint('execution_plan_construction_plan', const ExecutionPlanConstructionPlanScreen());
  }

  void _openExecutionPlanInfrastructurePlan() {
    _navigateWithCheckpoint('execution_plan_infrastructure_plan', const ExecutionPlanInfrastructurePlanScreen());
  }

  void _openExecutionPlanInterfaceManagement() {
    _navigateWithCheckpoint('execution_plan_interface_management', const ExecutionPlanInterfaceManagementScreen());
  }

  void _openExecutionPlanCommunicationPlan() {
    _navigateWithCheckpoint('execution_plan_communication_plan', const ExecutionPlanCommunicationPlanScreen());
  }

  void _openExecutionPlanInterfaceManagementPlan() {
    _navigateWithCheckpoint('execution_plan_interface_management_plan', const ExecutionPlanInterfaceManagementPlanScreen());
  }

  void _openExecutionPlanInterfaceManagementOverview() {
    _navigateWithCheckpoint('execution_plan_interface_management_overview', const ExecutionPlanInterfaceManagementOverviewScreen());
  }

  void _openExecutionPlanStakeholderIdentification() {
    _navigateWithCheckpoint('execution_plan_stakeholder_identification', const ExecutionPlanStakeholderIdentificationScreen());
  }

  void _openTechnology() {
    _navigateWithCheckpoint('technology', const FrontEndPlanningTechnologyScreen());
  }

  void _openTeamManagement() {
    _navigateWithCheckpoint('team_management', const TeamManagementScreen());
  }

  void _openSecurityManagement() {
    _navigateWithCheckpoint('security_management', const SecurityManagementScreen());
  }

  void _openQualityManagement() {
    _navigateWithCheckpoint('quality_management', const QualityManagementScreen());
  }

  void _openContract() {
    _navigateWithCheckpoint('contracts', const FrontEndPlanningContractsScreen());
  }

  void _openSchedule() {
    _navigateWithCheckpoint('schedule', const ScheduleScreen());
  }

  void _openCostEstimate() {
    _navigateWithCheckpoint('cost_estimate', const CostEstimateScreen());
  }

  void _openChangeManagement() {
    _navigateWithCheckpoint('change_management', const ChangeManagementScreen());
  }

  void _openProjectPlan() {
    _navigateWithCheckpoint('project_plan', const ProjectPlanScreen());
  }

  void _openProjectBaseline() {
    _navigateWithCheckpoint('project_baseline', const ProjectBaselineScreen());
  }

  void _openStakeholderManagement() {
    _navigateWithCheckpoint('stakeholder_management', const StakeholderManagementScreen());
  }

  void _openRiskAssessment() {
    _navigateWithCheckpoint('risk_assessment', const RiskAssessmentScreen());
  }

  void _openIssueManagement() {
    _navigateWithCheckpoint('issue_management', const IssueManagementScreen());
  }

  void _openLessonsLearned() {
    _navigateWithCheckpoint('lessons_learned', const LessonsLearnedScreen());
  }

  void _openTeamTraining() {
    _navigateWithCheckpoint('team_training', const TeamTrainingAndBuildingScreen());
  }

  void _openStaffTeam() {
    _navigateWithCheckpoint('staff_team', const StaffTeamScreen());
  }

  void _openTeamMeetings() {
    _navigateWithCheckpoint('team_meetings', const TeamMeetingsScreen());
  }

  void _openProgressTracking() {
    _navigateWithCheckpoint('progress_tracking', const ProgressTrackingScreen());
  }

  void _openGapAnalysisAndScopeReconcillation() {
    _navigateWithCheckpoint('gap_analysis_scope_reconcillation', const GapAnalysisScopeReconcillationScreen());
  }

  void _openLaunchChecklist() {
    _navigateWithCheckpoint('launch_checklist', const LaunchChecklistScreen());
  }

  void _openPunchlistActions() {
    _navigateWithCheckpoint('punchlist_actions', const PunchlistActionsScreen());
  }

  void _openToolsIntegration() {
    _navigateWithCheckpoint('tools_integration', const ToolsIntegrationScreen());
  }

  void _openSalvageDisposalTeam() {
    _navigateWithCheckpoint('salvage_disposal_team', const SalvageDisposalTeamScreen());
  }

  void _openDeliverProjectClosure() {
    _navigateWithCheckpoint('deliver_project_closure', const DeliverProjectClosureScreen());
  }

  void _openTransitionToProdTeam() {
    _navigateWithCheckpoint('transition_to_prod_team', const TransitionToProdTeamScreen());
  }

  void _openContractCloseOut() {
    _navigateWithCheckpoint('contract_close_out', const ContractCloseOutScreen());
  }

  void _openVendorAccountCloseOut() {
    _navigateWithCheckpoint('vendor_account_close_out', const VendorAccountCloseOutScreen());
  }

  void _openUiUxDesign() {
    _navigateWithCheckpoint('ui_ux_design', const UiUxDesignScreen());
  }

  void _openTechnicalAlignment() {
    _navigateWithCheckpoint('technical_alignment', const TechnicalAlignmentScreen());
  }

  void _openLongLeadEquipmentOrdering() {
    _navigateWithCheckpoint('long_lead_equipment_ordering', const LongLeadEquipmentOrderingScreen());
  }

  void _openSpecializedDesign() {
    _navigateWithCheckpoint('specialized_design', const SpecializedDesignScreen());
  }

  void _openTechnicalDevelopment() {
    _navigateWithCheckpoint('technical_development', const TechnicalDevelopmentScreen());
  }

  void _openEngineeringDesign() {
    _navigateWithCheckpoint('engineering_design', const EngineeringDesignScreen());
  }

  void _openProjectCloseOut() {
    _navigateWithCheckpoint('project_close_out', const ProjectCloseOutScreen());
  }

  void _openDemobilizeTeam() {
    _navigateWithCheckpoint('demobilize_team', const DemobilizeTeamScreen());
  }

  void _openActualVsPlannedGapAnalysis() {
    _navigateWithCheckpoint('actual_vs_planned_gap_analysis', const ActualVsPlannedGapAnalysisScreen());
  }

  void _openCommerceViability() {
    _navigateWithCheckpoint('commerce_viability', const CommerceViabilityScreen());
  }

  void _openSummarizeAccountRisks() {
    _navigateWithCheckpoint('summarize_account_risks', const SummarizeAccountRisksScreen());
  }

  void _openAgileDevelopmentIterations() {
    _navigateWithCheckpoint('agile_development_iterations', const AgileDevelopmentIterationsScreen());
  }

  void _openScopeCompletion() {
    _navigateWithCheckpoint('scope_completion', const ScopeCompletionScreen());
  }

  void _openRequirementsImplementation() {
    _navigateWithCheckpoint('requirements_implementation', const RequirementsImplementationScreen());
  }

  void _openDeliverableRoadmap() {
    _navigateWithCheckpoint('deliverable_roadmap', const DeliverablesRoadmapScreen());
  }

  Future<void> _openExecutiveSummary() async {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      if (provider != null && provider.projectData.projectId != null) {
        await provider.saveToFirebase(checkpoint: 'executive_summary');
      }
    } catch (e) {
      debugPrint('Checkpoint save error: $e');
    }
    if (mounted) {
      final provider = ProjectDataInherited.maybeOf(context);
      final projectData = provider?.projectData;
      final preferredAnalysis = projectData?.preferredSolutionAnalysis;
      
      // Get the selected solution from potential solutions
      final potentialSolutions = projectData?.potentialSolutions ?? [];
      if (potentialSolutions.isEmpty) {
        // No solutions available, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No solutions available. Please complete the Potential Solutions step first.')),
        );
        return;
      }
      
      // Convert PotentialSolution to AiSolutionItem
      final solutions = potentialSolutions.map((s) => AiSolutionItem(
        title: s.title,
        description: s.description,
      )).toList();
      
      // Find the selected solution or use the first one
      AiSolutionItem selectedSolution;
      if (preferredAnalysis?.selectedSolutionTitle != null) {
        selectedSolution = solutions.firstWhere(
          (s) => s.title == preferredAnalysis!.selectedSolutionTitle,
          orElse: () => solutions.first,
        );
      } else {
        selectedSolution = solutions.first;
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDecisionSummaryScreen(
            projectName: projectData?.projectName ?? 'Untitled Project',
            selectedSolution: selectedSolution,
            allSolutions: solutions,
            businessCase: projectData?.businessCase ?? '',
            notes: preferredAnalysis?.workingNotes ?? '',
          ),
        ),
      );
    }
  }

  void _openPreferredSolutionAnalysis() {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      final projectData = provider?.projectData;
      final potentialSolutions = projectData?.potentialSolutions ?? [];
      final solutions = potentialSolutions
          .map((s) => AiSolutionItem(title: s.title, description: s.description))
          .toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreferredSolutionAnalysisScreen(
            notes: projectData?.preferredSolutionAnalysis?.workingNotes ?? '',
            solutions: solutions,
            businessCase: projectData?.businessCase ?? '',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Navigation error (Preferred Solution Analysis): $e');
    }
  }

  void _openWorkBreakdownStructure() {
    _navigateWithCheckpoint('work_breakdown_structure', const WorkBreakdownStructureScreen());
  }

  void _openProjectFramework() {
    _navigateWithCheckpoint('project_framework', const ProjectFrameworkScreen());
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap, bool isActive = false}) {
    final primary = const Color(0xFFFFD700);
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

  Widget _buildSubMenuItem(String title, {VoidCallback? onTap, bool isActive = false}) {
    final primary = const Color(0xFFFFD700);
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

  Widget _buildSubExpandableHeader(String title, {required bool expanded, required VoidCallback onTap, bool isActive = false}) {
    final primary = const Color(0xFFFFD700);
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
              Icon(expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey[600], size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubSubMenuItem(String title, {VoidCallback? onTap, bool isActive = false}) {
    final primary = const Color(0xFFFFD700);
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 24, top: 2, bottom: 2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? primary.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive ? primary : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
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

  Widget _buildExpandableHeader(IconData icon, String title, {required bool expanded, required VoidCallback onTap, bool isActive = false}) {
    final primary = const Color(0xFFFFD700);
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

  @override
  Widget build(BuildContext context) {
    final double bannerHeight = AppBreakpoints.isMobile(context) ? 72 : 96;
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.withValues(alpha: 0.25), width: 0.8),
        ),
      ),
      child: Column(
        children: [
          if (widget.showHeader) ...[
            // Full-width banner image above "StackOne"
            SizedBox(
              width: double.infinity,
              height: bannerHeight,
              child: const HeaderBannerImage(
                height: null, // SizedBox will constrain height
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFFFD700), width: 1),
                ),
              ),
              child: Builder(
                builder: (context) {
                  final provider = ProjectDataInherited.maybeOf(context);
                  final projectData = provider?.projectData;
                  final projectName = projectData?.projectName.trim().isNotEmpty == true 
                      ? projectData!.projectName 
                      : 'Untitled Project';
                  return Text(
                    projectName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Color(0xFF1A1D1F), fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Search menu...',
                    hintStyle: TextStyle(color: const Color(0xFF6B7280).withValues(alpha: 0.6), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: const Color(0xFF6B7280).withValues(alpha: 0.7), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: const Color(0xFF6B7280).withValues(alpha: 0.7), size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
          Expanded(
            child: _searchQuery.isEmpty
                ? ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: _buildAllMenuItems(),
                  )
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAllMenuItems() {
    return [
                _buildMenuItem(
                  Icons.home_outlined,
                  'Home',
                  onTap: () => HomeScreen.open(context),
                  isActive: widget.activeItemLabel == 'Home',
                ),
                _buildExpandableHeader(
                  Icons.flag_outlined,
                  'Initiation Phase',
                  expanded: _initiationExpanded,
                  onTap: () => setState(() {
                    _initiationExpanded = !_initiationExpanded;
                    _sharedInitiationExpanded = _initiationExpanded;
                  }),
                  isActive: widget.activeItemLabel == 'Initiation Phase',
                ),
                if (_initiationExpanded) ...[
                  _buildSubExpandableHeader(
                    'Business Case',
                    expanded: _businessCaseExpanded,
                    onTap: () => setState(() {
                      _businessCaseExpanded = !_businessCaseExpanded;
                      _sharedBusinessCaseExpanded = _businessCaseExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Business Case',
                  ),
                  if (_businessCaseExpanded) ...[
                    _buildSubSubMenuItem('Scope Statement', onTap: _openBusinessCase, isActive: widget.activeItemLabel == 'Business Case Detail'),
                    _buildSubSubMenuItem('Potential Solutions', onTap: _openPotentialSolutions, isActive: widget.activeItemLabel == 'Potential Solutions'),
                    _buildSubSubMenuItem('Risk Identification', onTap: _openRiskIdentification, isActive: widget.activeItemLabel == 'Risk Identification'),
                    _buildSubSubMenuItem('IT Considerations', onTap: _openITConsiderations, isActive: widget.activeItemLabel == 'IT Considerations'),
                    _buildSubSubMenuItem('Infrastructure Considerations', onTap: _openInfrastructureConsiderations, isActive: widget.activeItemLabel == 'Infrastructure Considerations'),
                    _buildSubSubMenuItem('Core Stakeholders', onTap: _openCoreStakeholders, isActive: widget.activeItemLabel == 'Core Stakeholders'),
                    _buildSubSubMenuItem('Cost Benefit Analysis & Financial Metrics', onTap: _openCostAnalysis, isActive: widget.activeItemLabel == 'Cost Benefit Analysis & Financial Metrics'),
                    _buildSubExpandableHeader(
                      'Executive Summary',
                      expanded: _executiveSummaryExpanded,
                      onTap: () => setState(() {
                        _executiveSummaryExpanded = !_executiveSummaryExpanded;
                        _sharedExecutiveSummaryExpanded = _executiveSummaryExpanded;
                      }),
                      isActive: widget.activeItemLabel == 'Executive Summary' || widget.activeItemLabel == 'Preferred Solution Analysis',
                    ),
                    if (_executiveSummaryExpanded) ...[
                      _buildSubSubMenuItem('Preferred Solution Analysis', onTap: _openPreferredSolutionAnalysis, isActive: widget.activeItemLabel == 'Preferred Solution Analysis'),
                    ],
                  ],
                  _buildSubExpandableHeader(
                    'Front End Planning',
                    expanded: _frontEndExpanded,
                    onTap: () => setState(() {
                      _frontEndExpanded = !_frontEndExpanded;
                      _sharedFrontEndExpanded = _frontEndExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Front End Planning',
                  ),
                  if (_frontEndExpanded) ...[
                    _buildSubSubMenuItem('Summary', onTap: _openSummary, isActive: widget.activeItemLabel == 'Summary'),
                    _buildSubSubMenuItem('Project Requirements', onTap: _openFrontEndRequirements, isActive: widget.activeItemLabel == 'Project Requirements'),
                    _buildSubSubMenuItem('Project Risks', onTap: _openFrontEndRisks, isActive: widget.activeItemLabel == 'Project Risks'),
                    _buildSubSubMenuItem('Project Opportunities', onTap: _openFrontEndOpportunities, isActive: widget.activeItemLabel == 'Project Opportunities'),
                    _buildSubSubMenuItem('Contract & Vendor Quotes', onTap: _openContractVendorQuotes, isActive: widget.activeItemLabel == 'Contract & Vendor Quotes'),
                    _buildSubSubMenuItem('Procurement', onTap: _openProcurement, isActive: widget.activeItemLabel == 'Procurement'),
                    _buildSubSubMenuItem('Security', onTap: _openSecurity, isActive: widget.activeItemLabel == 'Security'),
                    _buildSubSubMenuItem('Allowance', onTap: _openAllowance, isActive: widget.activeItemLabel == 'Allowance'),
                    _buildSubSubMenuItem('Project Charter', onTap: _openProjectCharter, isActive: widget.activeItemLabel == 'Project Charter'),
                  ],
                ],
                _buildExpandableHeader(
                  Icons.lightbulb_outline,
                  'Planning Phase',
                  expanded: _planningPhaseExpanded,
                  onTap: () => setState(() {
                    _planningPhaseExpanded = !_planningPhaseExpanded;
                    _sharedPlanningPhaseExpanded = _planningPhaseExpanded;
                  }),
                  isActive: widget.activeItemLabel == 'Planning Phase',
                ),
                if (_planningPhaseExpanded) ...[
                  _buildSubMenuItem('Work Breakdown Structure', onTap: _openWorkBreakdownStructure, isActive: widget.activeItemLabel == 'Work Breakdown Structure'),
                  _buildSubMenuItem('Project Management Framework', onTap: _openProjectFramework, isActive: widget.activeItemLabel == 'Project Management Framework'),
                  _buildSubMenuItem('SSHER', onTap: _openSSHER, isActive: widget.activeItemLabel == 'SSHER'),
                  _buildSubMenuItem('Change Management', onTap: _openChangeManagement, isActive: widget.activeItemLabel == 'Change Management'),
                  _buildSubMenuItem('Issue Management', onTap: _openIssueManagement, isActive: widget.activeItemLabel == 'Issue Management'),
                  _buildSubMenuItem('Cost Estimate', onTap: _openCostEstimate, isActive: widget.activeItemLabel == 'Cost Estimate'),
                  _buildSubMenuItem('Contract', onTap: _openContract, isActive: widget.activeItemLabel == 'Contract'),
                  _buildSubMenuItem('Procurement', onTap: _openProcurement, isActive: widget.activeItemLabel == 'Procurement'),
                  _buildSubMenuItem('Project Plan', onTap: _openProjectPlan, isActive: widget.activeItemLabel == 'Project Plan'),
                  _buildSubExpandableHeader(
                    'Execution Plan',
                    expanded: _executionPlanExpanded,
                    onTap: () => setState(() {
                      _executionPlanExpanded = !_executionPlanExpanded;
                      _sharedExecutionPlanExpanded = _executionPlanExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Execution Plan',
                  ),
                  if (_executionPlanExpanded) ...[
                    _buildSubSubMenuItem('Executive Plan Outline', onTap: _openExecutionPlan, isActive: widget.activeItemLabel == 'Executive Plan Outline'),
                    _buildSubSubMenuItem('Executive Plan Strategy', onTap: _openExecutionPlanStrategy, isActive: widget.activeItemLabel == 'Executive Plan Strategy'),
                    _buildSubSubMenuItem('Execution Plan Details', onTap: _openExecutionPlanDetails, isActive: widget.activeItemLabel == 'Execution Plan Details'),
                    _buildSubSubMenuItem('Execution Early Works', onTap: _openExecutionEarlyWorks, isActive: widget.activeItemLabel == 'Execution Early Works'),
                    _buildSubSubMenuItem('Execution Enabling Work Plan', onTap: _openExecutionEnablingWorkPlan, isActive: widget.activeItemLabel == 'Execution Enabling Work Plan'),
                    _buildSubSubMenuItem('Execution Issue Management', onTap: _openExecutionIssueManagement, isActive: widget.activeItemLabel == 'Execution Issue Management'),
                    _buildSubSubMenuItem('Execution Plan - Lesson Learned', onTap: _openExecutionPlanLessonsLearned, isActive: widget.activeItemLabel == 'Execution Plan - Lesson Learned'),
                    _buildSubSubMenuItem('Execution Plan - Best Practices', onTap: _openExecutionPlanBestPractices, isActive: widget.activeItemLabel == 'Execution Plan - Best Practices'),
                    _buildSubSubMenuItem('Execution Plan - Construction Plan', onTap: _openExecutionPlanConstructionPlan, isActive: widget.activeItemLabel == 'Execution Plan - Construction Plan'),
                    _buildSubSubMenuItem('Execution Plan - Infrastructure Plan', onTap: _openExecutionPlanInfrastructurePlan, isActive: widget.activeItemLabel == 'Execution Plan - Infrastructure Plan'),
                    _buildSubSubMenuItem('Execution Plan - Stakeholder Identification', onTap: _openExecutionPlanStakeholderIdentification, isActive: widget.activeItemLabel == 'Execution Plan - Stakeholder Identification'),
                    _buildSubSubMenuItem('Execution Plan - Interface Management', onTap: _openExecutionPlanInterfaceManagement, isActive: widget.activeItemLabel == 'Execution Plan - Interface Management'),
                    _buildSubSubMenuItem('Execution Plan - Communication Plan', onTap: _openExecutionPlanCommunicationPlan, isActive: widget.activeItemLabel == 'Execution Plan - Communication Plan'),
                    _buildSubSubMenuItem('Execution Plan - Interface Management Plan', onTap: _openExecutionPlanInterfaceManagementPlan, isActive: widget.activeItemLabel == 'Execution Plan - Interface Management Plan'),
                    _buildSubSubMenuItem('Execution Plan - Interface Management Overview', onTap: _openExecutionPlanInterfaceManagementOverview, isActive: widget.activeItemLabel == 'Execution Plan - Interface Management Overview'),
                  ],
                  _buildSubMenuItem('Schedule', onTap: _openSchedule, isActive: widget.activeItemLabel == 'Schedule'),
                  _buildSubMenuItem('Design', onTap: _openDesign, isActive: widget.activeItemLabel == 'Design'),
                  _buildSubMenuItem('Technology', onTap: _openTechnology, isActive: widget.activeItemLabel == 'Technology'),
                  _buildSubMenuItem('Interface Management', isActive: widget.activeItemLabel == 'Interface Management'),
                  _buildSubMenuItem('Start-Up Planning', isActive: widget.activeItemLabel == 'Start-Up Planning'),
                  _buildSubMenuItem('Deliverable Roadmap', onTap: _openDeliverableRoadmap, isActive: widget.activeItemLabel == 'Deliverable Roadmap'),
                  _buildSubMenuItem('Agile Project Wireframe', isActive: widget.activeItemLabel == 'Agile Project Wireframe'),
                  _buildSubMenuItem('Project Baseline', onTap: _openProjectBaseline, isActive: widget.activeItemLabel == 'Project Baseline'),
                  _buildSubMenuItem('Organization Plan', isActive: widget.activeItemLabel == 'Organization Plan'),
                  _buildSubSubMenuItem('Team Training and Team Building', onTap: _openTeamTraining, isActive: widget.activeItemLabel == 'Team Training and Team Building'),
                  _buildSubMenuItem('Lessons Learned', onTap: _openLessonsLearned, isActive: widget.activeItemLabel == 'Lessons Learned'),
                  _buildSubMenuItem('Team Management', onTap: _openTeamManagement, isActive: widget.activeItemLabel == 'Team Management'),
                  _buildSubMenuItem('Stakeholder Management', onTap: _openStakeholderManagement, isActive: widget.activeItemLabel == 'Stakeholder Management'),
                  _buildSubMenuItem('Risk Assessment', onTap: _openRiskAssessment, isActive: widget.activeItemLabel == 'Risk Assessment'),
                  _buildSubMenuItem('Security Management', onTap: _openSecurityManagement, isActive: widget.activeItemLabel == 'Security Management'),
                  _buildSubMenuItem('Quality Management', onTap: _openQualityManagement, isActive: widget.activeItemLabel == 'Quality Management'),
                ],
                _buildExpandableHeader(
                  Icons.design_services_outlined,
                  'Design Phase',
                  expanded: _designPhaseExpanded,
                  onTap: () => setState(() {
                    _designPhaseExpanded = !_designPhaseExpanded;
                    _sharedDesignPhaseExpanded = _designPhaseExpanded;
                  }),
                  isActive: widget.activeItemLabel == 'Design Phase',
                ),
                if (_designPhaseExpanded) ...[
                  _buildSubMenuItem('Design Management', onTap: _openDesignManagement, isActive: widget.activeItemLabel == 'Design Management'),
                  _buildSubMenuItem('Requirements Implementation', onTap: _openRequirementsImplementation, isActive: widget.activeItemLabel == 'Requirements Implementation'),
                  _buildSubMenuItem('Technical Alignment', onTap: _openTechnicalAlignment, isActive: widget.activeItemLabel == 'Technical Alignment'),
                  _buildSubMenuItem('Development Set Up', isActive: widget.activeItemLabel == 'Development Set Up'),
                  _buildSubMenuItem('UI/UX Design', onTap: _openUiUxDesign, isActive: widget.activeItemLabel == 'UI/UX Design'),
                  _buildSubMenuItem('Backend Design', isActive: widget.activeItemLabel == 'Backend Design'),
                  _buildSubMenuItem('Engineering', onTap: _openEngineeringDesign, isActive: widget.activeItemLabel == 'Engineering'),
                  _buildSubMenuItem('Technical Development', onTap: _openTechnicalDevelopment, isActive: widget.activeItemLabel == 'Technical Development'),
                  _buildSubMenuItem('Tools Integration', onTap: _openToolsIntegration, isActive: widget.activeItemLabel == 'Tools Integration'),
                  _buildSubMenuItem('Long Lead Equipment Ordering', onTap: _openLongLeadEquipmentOrdering, isActive: widget.activeItemLabel == 'Long Lead Equipment Ordering'),
                  _buildSubMenuItem('Specialized Design', onTap: _openSpecializedDesign, isActive: widget.activeItemLabel == 'Specialized Design'),
                  _buildSubMenuItem('Design Deliverables', isActive: widget.activeItemLabel == 'Design Deliverables'),
                ],
                _buildExpandableHeader(
                  Icons.play_circle_outline,
                  'Execution Phase',
                  expanded: _executionPhaseExpanded,
                  onTap: () => setState(() {
                    _executionPhaseExpanded = !_executionPhaseExpanded;
                    _sharedExecutionPhaseExpanded = _executionPhaseExpanded;
                  }),
                  isActive: widget.activeItemLabel == 'Execution Phase',
                ),
                if (_executionPhaseExpanded) ...[
                  _buildSubMenuItem('Staff Team', onTap: _openStaffTeam, isActive: widget.activeItemLabel == 'Staff Team'),
                  _buildSubExpandableHeader(
                    'Team Meetings',
                    expanded: _teamMeetingsExpanded,
                    onTap: () => setState(() {
                      _teamMeetingsExpanded = !_teamMeetingsExpanded;
                      _sharedTeamMeetingsExpanded = _teamMeetingsExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Team Meetings' || widget.activeItemLabel == 'Calendar & Schedule' || widget.activeItemLabel == 'Meeting Details & Agenda' || widget.activeItemLabel == 'Active Meeting Workspace' || widget.activeItemLabel == 'Action Items Tracker' || widget.activeItemLabel == 'Decisions & Outcomes',
                  ),
                  if (_teamMeetingsExpanded) ...[
                    _buildSubSubMenuItem('Calendar & Schedule', onTap: _openTeamMeetings, isActive: widget.activeItemLabel == 'Calendar & Schedule'),
                    _buildSubSubMenuItem('Meeting Details & Agenda', onTap: _openTeamMeetings, isActive: widget.activeItemLabel == 'Meeting Details & Agenda'),
                    _buildSubSubMenuItem('Active Meeting Workspace', onTap: _openTeamMeetings, isActive: widget.activeItemLabel == 'Active Meeting Workspace'),
                    _buildSubSubMenuItem('Action Items Tracker', onTap: _openTeamMeetings, isActive: widget.activeItemLabel == 'Action Items Tracker'),
                    _buildSubSubMenuItem('Decisions & Outcomes', onTap: _openTeamMeetings, isActive: widget.activeItemLabel == 'Decisions & Outcomes'),
                  ],
                  _buildSubExpandableHeader(
                    'Progress Tracking',
                    expanded: _progressTrackingExpanded,
                    onTap: () => setState(() {
                      _progressTrackingExpanded = !_progressTrackingExpanded;
                      _sharedProgressTrackingExpanded = _progressTrackingExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Progress Tracking' || widget.activeItemLabel == 'Deliverable Status Updates' || widget.activeItemLabel == 'Recurring Deliverables' || widget.activeItemLabel == 'Status Reports',
                  ),
                  if (_progressTrackingExpanded) ...[                    _buildSubSubMenuItem('Deliverable Status Updates', onTap: _openProgressTracking, isActive: widget.activeItemLabel == 'Deliverable Status Updates'),
                    _buildSubSubMenuItem('Recurring Deliverables', onTap: _openProgressTracking, isActive: widget.activeItemLabel == 'Recurring Deliverables'),
                    _buildSubSubMenuItem('Status Reports', onTap: _openProgressTracking, isActive: widget.activeItemLabel == 'Status Reports'),
                  ],
                  _buildSubMenuItem('Contracts Tracking', isActive: widget.activeItemLabel == 'Contracts Tracking'),
                  _buildSubMenuItem('Vendor Tracking', isActive: widget.activeItemLabel == 'Vendor Tracking'),
                  _buildSubMenuItem('Detailed Design', isActive: widget.activeItemLabel == 'Detailed Design'),
                  _buildSubMenuItem('Agile Development Iterations', onTap: _openAgileDevelopmentIterations, isActive: widget.activeItemLabel == 'Agile Development Iterations'),
                  _buildSubMenuItem('Scope Tracking Implementation', isActive: widget.activeItemLabel == 'Scope Tracking Implementation'),
                  _buildSubMenuItem('Stakeholder Alignment', isActive: widget.activeItemLabel == 'Stakeholder Alignment'),
                  _buildSubMenuItem('Update Ops and Maintenance Plans', isActive: widget.activeItemLabel == 'Update Ops and Maintenance Plans'),
                  _buildSubMenuItem('Technical Debt Management', isActive: widget.activeItemLabel == 'Technical Debt Management'),
                  _buildSubMenuItem('Start-up or Launch Checklist', onTap: _openLaunchChecklist, isActive: widget.activeItemLabel == 'Start-up or Launch Checklist'),
                  _buildSubMenuItem('Risk Tracking', isActive: widget.activeItemLabel == 'Risk Tracking'),
                  _buildSubMenuItem('Scope Completion', onTap: _openScopeCompletion, isActive: widget.activeItemLabel == 'Scope Completion'),
                  _buildSubMenuItem('Gap Analysis and Scope Reconciliation', onTap: _openGapAnalysisAndScopeReconcillation, isActive: widget.activeItemLabel == 'Gap Analysis and Scope Reconciliation'),
                  _buildSubMenuItem('Punchlist Actions', onTap: _openPunchlistActions, isActive: widget.activeItemLabel == 'Punchlist Actions'),
                  _buildSubMenuItem('Identify and Staff Ops Team', isActive: widget.activeItemLabel == 'Identify and Staff Ops Team'),
                  _buildSubMenuItem('Salvage and/or Disposal Plan', onTap: _openSalvageDisposalTeam, isActive: widget.activeItemLabel == 'Salvage and/or Disposal Plan'),
                  _buildSubMenuItem('Finalize Project', isActive: widget.activeItemLabel == 'Finalize Project'),
                ],
                _buildExpandableHeader(
                  Icons.rocket_launch_outlined,
                  'Launch Phase',
                  expanded: _launchPhaseExpanded,
                  onTap: () => setState(() {
                    _launchPhaseExpanded = !_launchPhaseExpanded;
                    _sharedLaunchPhaseExpanded = _launchPhaseExpanded;
                  }),
                  isActive: widget.activeItemLabel == 'Launch Phase',
                ),
                if (_launchPhaseExpanded) ...[
                  _buildSubMenuItem('Deliver Project', onTap: _openDeliverProjectClosure, isActive: widget.activeItemLabel == 'Deliver Project'),
                  _buildSubMenuItem('Transition To Production Team', onTap: _openTransitionToProdTeam, isActive: widget.activeItemLabel == 'Transition To Production Team'),
                  _buildSubMenuItem('Contract Close Out', onTap: _openContractCloseOut, isActive: widget.activeItemLabel == 'Contract Close Out'),
                  _buildSubMenuItem('Vendor Account Close Out', onTap: _openVendorAccountCloseOut, isActive: widget.activeItemLabel == 'Vendor Account Close Out'),
                  _buildSubMenuItem('Summarize Account Of All Section Including Risks', onTap: _openSummarizeAccountRisks, isActive: widget.activeItemLabel == 'Summarize Account Of All Section Including Risks'),
                  _buildSubMenuItem('Commerce Warranty', onTap: _openCommerceViability, isActive: widget.activeItemLabel == 'Commerce Warranty'),
                  _buildSubMenuItem('Actual vs Planned Gap Analysis', onTap: _openActualVsPlannedGapAnalysis, isActive: widget.activeItemLabel == 'Actual vs Planned Gap Analysis'),
                  _buildSubMenuItem('Demobilize Team', onTap: _openDemobilizeTeam, isActive: widget.activeItemLabel == 'Demobilize Team'),
                  _buildSubMenuItem('Project Close Out', onTap: _openProjectCloseOut, isActive: widget.activeItemLabel == 'Project Close Out'),
                ],
                const SizedBox(height: 20),
                _buildMenuItem(Icons.settings_outlined, 'Settings', onTap: () => SettingsScreen.open(context), isActive: widget.activeItemLabel == 'Settings'),
                _buildMenuItem(Icons.logout_outlined, 'LogOut', onTap: () => AuthNav.signOutAndExit(context), isActive: widget.activeItemLabel == 'LogOut'),
              ];
  }

  Widget _buildSearchResults() {
    final query = _searchQuery.toLowerCase();
    final results = <Widget>[];

    // Search through all menu items
    if ('home'.contains(query)) {
      results.add(_buildMenuItem(Icons.home_outlined, 'Home', onTap: () => HomeScreen.open(context), isActive: widget.activeItemLabel == 'Home'));
    }
    if ('business case'.contains(query)) {
      results.add(_buildMenuItem(Icons.description_outlined, 'Business Case', onTap: _openBusinessCase, isActive: widget.activeItemLabel == 'Business Case'));
    }
    if ('potential solutions'.contains(query)) {
      results.add(_buildMenuItem(Icons.lightbulb_outline, 'Potential Solutions', onTap: _openPotentialSolutions, isActive: widget.activeItemLabel == 'Potential Solutions'));
    }
    if ('risk identification'.contains(query)) {
      results.add(_buildMenuItem(Icons.warning_amber_outlined, 'Risk Identification', onTap: _openRiskIdentification, isActive: widget.activeItemLabel == 'Risk Identification'));
    }
    if ('it considerations'.contains(query)) {
      results.add(_buildMenuItem(Icons.computer_outlined, 'IT Considerations', onTap: _openITConsiderations, isActive: widget.activeItemLabel == 'IT Considerations'));
    }
    if ('infrastructure considerations'.contains(query)) {
      results.add(_buildMenuItem(Icons.foundation_outlined, 'Infrastructure Considerations', onTap: _openInfrastructureConsiderations, isActive: widget.activeItemLabel == 'Infrastructure Considerations'));
    }
    if ('core stakeholders'.contains(query)) {
      results.add(_buildMenuItem(Icons.groups_outlined, 'Core Stakeholders', onTap: _openCoreStakeholders, isActive: widget.activeItemLabel == 'Core Stakeholders'));
    }
    if ('cost benefit analysis'.contains(query) || 'financial metrics'.contains(query)) {
      results.add(_buildMenuItem(Icons.analytics_outlined, 'Cost Benefit Analysis & Financial Metrics', onTap: _openCostAnalysis, isActive: widget.activeItemLabel == 'Cost Benefit Analysis & Financial Metrics'));
    }
    if ('executive summary'.contains(query)) {
      results.add(_buildMenuItem(Icons.summarize_outlined, 'Executive Summary', onTap: _openExecutiveSummary, isActive: widget.activeItemLabel == 'Executive Summary'));
    }
    if ('preferred solution analysis'.contains(query) || 'preferred'.contains(query)) {
      results.add(_buildMenuItem(Icons.fact_check_outlined, 'Preferred Solution Analysis', onTap: _openPreferredSolutionAnalysis, isActive: widget.activeItemLabel == 'Preferred Solution Analysis'));
    }
    if ('work breakdown structure'.contains(query) || 'wbs'.contains(query) || 'breakdown'.contains(query)) {
      results.add(_buildMenuItem(Icons.account_tree_outlined, 'Work Breakdown Structure', onTap: _openWorkBreakdownStructure, isActive: widget.activeItemLabel == 'Work Breakdown Structure'));
    }
    if ('project management framework'.contains(query) || 'framework'.contains(query) || 'management framework'.contains(query)) {
      results.add(_buildMenuItem(Icons.widgets_outlined, 'Project Management Framework', onTap: _openProjectFramework, isActive: widget.activeItemLabel == 'Project Management Framework'));
    }
    if ('summary'.contains(query) || 'front end'.contains(query)) {
      results.add(_buildMenuItem(Icons.summarize_outlined, 'Summary', onTap: _openSummary, isActive: widget.activeItemLabel == 'Summary'));
    }
    if ('project requirements'.contains(query) || 'requirements'.contains(query)) {
      results.add(_buildMenuItem(Icons.checklist_outlined, 'Project Requirements', onTap: _openFrontEndRequirements, isActive: widget.activeItemLabel == 'Project Requirements'));
    }
    if ('project risks'.contains(query) || 'risks'.contains(query)) {
      results.add(_buildMenuItem(Icons.error_outline, 'Project Risks', onTap: _openFrontEndRisks, isActive: widget.activeItemLabel == 'Project Risks'));
    }
    if ('project opportunities'.contains(query) || 'opportunities'.contains(query)) {
      results.add(_buildMenuItem(Icons.stars_outlined, 'Project Opportunities', onTap: _openFrontEndOpportunities, isActive: widget.activeItemLabel == 'Project Opportunities'));
    }
    if ('contract'.contains(query) || 'vendor quotes'.contains(query)) {
      results.add(_buildMenuItem(Icons.description_outlined, 'Contract & Vendor Quotes', onTap: _openContractVendorQuotes, isActive: widget.activeItemLabel == 'Contract & Vendor Quotes'));
    }
    if ('procurement'.contains(query)) {
      results.add(_buildMenuItem(Icons.shopping_cart_outlined, 'Procurement', onTap: _openProcurement, isActive: widget.activeItemLabel == 'Procurement'));
    }
    if ('security'.contains(query)) {
      results.add(_buildMenuItem(Icons.security_outlined, 'Security', onTap: _openSecurity, isActive: widget.activeItemLabel == 'Security'));
    }
    if ('allowance'.contains(query)) {
      results.add(_buildMenuItem(Icons.account_balance_wallet_outlined, 'Allowance', onTap: _openAllowance, isActive: widget.activeItemLabel == 'Allowance'));
    }
    if ('project charter'.contains(query) || 'charter'.contains(query)) {
      results.add(_buildMenuItem(Icons.description_outlined, 'Project Charter', onTap: _openProjectCharter, isActive: widget.activeItemLabel == 'Project Charter'));
    }
    if ('ssher'.contains(query)) {
      results.add(_buildMenuItem(Icons.shield_outlined, 'SSHER', onTap: _openSSHER, isActive: widget.activeItemLabel == 'SSHER'));
    }
    if ('change management'.contains(query)) {
      results.add(_buildMenuItem(Icons.change_circle_outlined, 'Change Management', onTap: _openChangeManagement, isActive: widget.activeItemLabel == 'Change Management'));
    }
    if ('issue management'.contains(query)) {
      results.add(_buildMenuItem(Icons.report_problem_outlined, 'Issue Management', onTap: _openIssueManagement, isActive: widget.activeItemLabel == 'Issue Management'));
    }
    if ('cost estimate'.contains(query)) {
      results.add(_buildMenuItem(Icons.attach_money_outlined, 'Cost Estimate', onTap: _openCostEstimate, isActive: widget.activeItemLabel == 'Cost Estimate'));
    }
    if ('project plan'.contains(query)) {
      results.add(_buildMenuItem(Icons.assignment_outlined, 'Project Plan', onTap: _openProjectPlan, isActive: widget.activeItemLabel == 'Project Plan'));
    }
    if ('project baseline'.contains(query) || 'baseline'.contains(query)) {
      results.add(_buildMenuItem(Icons.flag_circle_outlined, 'Project Baseline', onTap: _openProjectBaseline, isActive: widget.activeItemLabel == 'Project Baseline'));
    }
    if ('execution plan'.contains(query)) {
      results.add(_buildMenuItem(Icons.play_arrow_outlined, 'Executive Plan Outline', onTap: _openExecutionPlan, isActive: widget.activeItemLabel == 'Executive Plan Outline'));
    }
    if ('schedule'.contains(query)) {
      results.add(_buildMenuItem(Icons.calendar_today_outlined, 'Schedule', onTap: _openSchedule, isActive: widget.activeItemLabel == 'Schedule'));
    }
    if ('design'.contains(query)) {
      results.add(_buildMenuItem(Icons.design_services_outlined, 'Design', onTap: _openDesign, isActive: widget.activeItemLabel == 'Design'));
    }
    if ('technology'.contains(query)) {
      results.add(_buildMenuItem(Icons.computer_outlined, 'Technology', onTap: _openTechnology, isActive: widget.activeItemLabel == 'Technology'));
    }
    if ('team training'.contains(query) || 'team building'.contains(query)) {
      results.add(_buildMenuItem(Icons.school_outlined, 'Team Training and Team Building', onTap: _openTeamTraining, isActive: widget.activeItemLabel == 'Team Training and Team Building'));
    }
    if ('lessons learned'.contains(query)) {
      results.add(_buildMenuItem(Icons.history_edu_outlined, 'Lessons Learned', onTap: _openLessonsLearned, isActive: widget.activeItemLabel == 'Lessons Learned'));
    }
    if ('team management'.contains(query)) {
      results.add(_buildMenuItem(Icons.groups_outlined, 'Team Management', onTap: _openTeamManagement, isActive: widget.activeItemLabel == 'Team Management'));
    }
    if ('security management'.contains(query)) {
      results.add(_buildMenuItem(Icons.security_outlined, 'Security Management', onTap: _openSecurityManagement, isActive: widget.activeItemLabel == 'Security Management'));
    }
    if ('quality management'.contains(query) || 'quality'.contains(query)) {
      results.add(_buildMenuItem(Icons.verified_outlined, 'Quality Management', onTap: _openQualityManagement, isActive: widget.activeItemLabel == 'Quality Management'));
    }
    if ('stakeholder management'.contains(query) || 'stakeholder'.contains(query)) {
      results.add(_buildMenuItem(Icons.people_outline, 'Stakeholder Management', onTap: _openStakeholderManagement, isActive: widget.activeItemLabel == 'Stakeholder Management'));
    }
    if ('risk assessment'.contains(query)) {
      results.add(_buildMenuItem(Icons.assessment_outlined, 'Risk Assessment', onTap: _openRiskAssessment, isActive: widget.activeItemLabel == 'Risk Assessment'));
    }
    if ('design management'.contains(query)) {
      results.add(_buildMenuItem(Icons.design_services_outlined, 'Design Management', onTap: _openDesignManagement, isActive: widget.activeItemLabel == 'Design Management'));
    }
    if ('requirements implementation'.contains(query) || 'requirements'.contains(query) || 'implementation'.contains(query)) {
      results.add(_buildMenuItem(Icons.checklist_rtl_outlined, 'Requirements Implementation', onTap: _openRequirementsImplementation, isActive: widget.activeItemLabel == 'Requirements Implementation'));
    }
    if ('ui/ux design'.contains(query) || 'ui ux'.contains(query) || 'ux design'.contains(query) || 'user interface'.contains(query) || 'user experience'.contains(query)) {
      results.add(_buildMenuItem(Icons.palette_outlined, 'UI/UX Design', onTap: _openUiUxDesign, isActive: widget.activeItemLabel == 'UI/UX Design'));
    }
    if ('staff team'.contains(query)) {
      results.add(_buildMenuItem(Icons.badge_outlined, 'Staff Team', onTap: _openStaffTeam, isActive: widget.activeItemLabel == 'Staff Team'));
    }
    if ('engineering'.contains(query) || 'engineering design'.contains(query) || 'system architecture'.contains(query) || 'technical blueprint'.contains(query)) {
      results.add(_buildMenuItem(Icons.architecture_outlined, 'Engineering Design', onTap: _openEngineeringDesign, isActive: widget.activeItemLabel == 'Engineering'));
    }
    if ('team meetings'.contains(query) || 'meetings'.contains(query)) {
      results.add(_buildMenuItem(Icons.meeting_room_outlined, 'Team Meetings', onTap: _openTeamMeetings, isActive: widget.activeItemLabel == 'Team Meetings'));
    }
    if ('progress tracking'.contains(query)) {
      results.add(_buildMenuItem(Icons.track_changes_outlined, 'Progress Tracking', onTap: _openProgressTracking, isActive: widget.activeItemLabel == 'Progress Tracking'));
    }
    if ('gap analysis'.contains(query) || 'scope reconciliation'.contains(query) || 'scope reconcillation'.contains(query)) {
      results.add(_buildMenuItem(Icons.compare_arrows_outlined, 'Gap Analysis And Scope Reconcillation', onTap: _openGapAnalysisAndScopeReconcillation, isActive: widget.activeItemLabel == 'Gap Analysis And Scope Reconcillation'));
    }
    if ('punchlist actions'.contains(query) || 'punch list'.contains(query) || 'technical debt'.contains(query)) {
      results.add(_buildMenuItem(Icons.fact_check_outlined, 'Punchlist Actions', onTap: _openPunchlistActions, isActive: widget.activeItemLabel == 'Punchlist Actions'));
    }
    if ('launch checklist'.contains(query) || 'launch'.contains(query)) {
      results.add(_buildMenuItem(Icons.rocket_launch_outlined, 'Launch Checklist', onTap: _openLaunchChecklist, isActive: widget.activeItemLabel == 'Launch Checklist'));
    }
    if ('deliverable roadmap'.contains(query) || 'deliverables'.contains(query) || 'roadmap'.contains(query)) {
      results.add(_buildMenuItem(Icons.map_outlined, 'Deliverable Roadmap', onTap: _openDeliverableRoadmap, isActive: widget.activeItemLabel == 'Deliverable Roadmap'));
    }
    if ('tools integration'.contains(query) || 'integration'.contains(query) || 'figma'.contains(query) || 'miro'.contains(query)) {
      results.add(_buildMenuItem(Icons.extension_outlined, 'Tools Integration', onTap: _openToolsIntegration, isActive: widget.activeItemLabel == 'Tools Integration'));
    }
    if ('salvage disposal team'.contains(query) || 'salvage'.contains(query) || 'disposal'.contains(query)) {
      results.add(_buildMenuItem(Icons.recycling_outlined, 'Salvage Disposal Team', onTap: _openSalvageDisposalTeam, isActive: widget.activeItemLabel == 'Salvage Disposal Team'));
    }
    if ('deliver project'.contains(query) || 'closure'.contains(query) || 'close out'.contains(query)) {
      results.add(_buildMenuItem(Icons.delivery_dining_outlined, 'Deliver Project', onTap: _openDeliverProjectClosure, isActive: widget.activeItemLabel == 'Deliver Project'));
    }
    if ('contract close out'.contains(query) || 'contract closure'.contains(query) || 'contracts'.contains(query)) {
      results.add(_buildMenuItem(Icons.description_outlined, 'Contract Close Out', onTap: _openContractCloseOut, isActive: widget.activeItemLabel == 'Contract Close Out'));
    }
    if ('vendor account close out'.contains(query) || 'vendor close'.contains(query) || 'vendor account'.contains(query)) {
      results.add(_buildMenuItem(Icons.business_outlined, 'Vendor Account Close Out', onTap: _openVendorAccountCloseOut, isActive: widget.activeItemLabel == 'Vendor Account Close Out'));
    }
    if ('transition'.contains(query) || 'production team'.contains(query) || 'prod team'.contains(query) || 'handover'.contains(query)) {
      results.add(_buildMenuItem(Icons.swap_horiz_outlined, 'Transition To Production Team', onTap: _openTransitionToProdTeam, isActive: widget.activeItemLabel == 'Transition To Production Team'));
    }
    if ('project close out'.contains(query) || 'project closure'.contains(query) || 'close out'.contains(query) || 'closeout'.contains(query)) {
      results.add(_buildMenuItem(Icons.task_alt_outlined, 'Project Close Out', onTap: _openProjectCloseOut, isActive: widget.activeItemLabel == 'Project Close Out'));
    }
    if ('demobilize team'.contains(query) || 'demobilize'.contains(query) || 'team ramp down'.contains(query) || 'wind down'.contains(query)) {
      results.add(_buildMenuItem(Icons.groups_outlined, 'Demobilize Team', onTap: _openDemobilizeTeam, isActive: widget.activeItemLabel == 'Demobilize Team'));
    }
    if ('actual vs planned'.contains(query) || 'gap analysis'.contains(query)) {
      results.add(_buildMenuItem(Icons.compare_arrows_outlined, 'Actual vs Planned Gap Analysis', onTap: _openActualVsPlannedGapAnalysis, isActive: widget.activeItemLabel == 'Actual vs Planned Gap Analysis'));
    }
    if ('commerce warranty'.contains(query) || 'commerce viability'.contains(query) || 'commercial'.contains(query) || 'viability'.contains(query)) {
      results.add(_buildMenuItem(Icons.monetization_on_outlined, 'Commerce Warranty', onTap: _openCommerceViability, isActive: widget.activeItemLabel == 'Commerce Warranty'));
    }
    if ('summarize account'.contains(query) || 'account risks'.contains(query) || 'summarize'.contains(query) || 'account summary'.contains(query)) {
      results.add(_buildMenuItem(Icons.summarize_outlined, 'Summarize Account Of All Section Including Risks', onTap: _openSummarizeAccountRisks, isActive: widget.activeItemLabel == 'Summarize Account Of All Section Including Risks'));
    }
    if ('settings'.contains(query)) {
      results.add(_buildMenuItem(Icons.settings_outlined, 'Settings', onTap: () => SettingsScreen.open(context), isActive: widget.activeItemLabel == 'Settings'));
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, color: const Color(0xFF6B7280).withValues(alpha: 0.4), size: 40),
              const SizedBox(height: 12),
              Text(
                'No results found',
                style: TextStyle(color: const Color(0xFF6B7280).withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: results,
    );
  }
}
