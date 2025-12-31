import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/responsive.dart';
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
import 'package:ndu_project/screens/scope_tracking_plan_screen.dart';
import 'package:ndu_project/screens/front_end_planning_requirements_screen.dart';
import 'package:ndu_project/screens/front_end_planning_risks_screen.dart';
import 'package:ndu_project/screens/front_end_planning_opportunities_screen.dart';
import 'package:ndu_project/screens/front_end_planning_contract_vendor_quotes_screen.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/screens/front_end_planning_security.dart';
import 'package:ndu_project/screens/front_end_planning_allowance.dart';
import 'package:ndu_project/screens/front_end_planning_summary.dart';
import 'package:ndu_project/screens/project_charter_screen.dart';
import 'package:ndu_project/screens/ssher_stacked_screen.dart';
import 'package:ndu_project/screens/execution_plan_screen.dart';
import 'package:ndu_project/screens/front_end_planning_technology_screen.dart';
import 'package:ndu_project/screens/team_management_screen.dart';
import 'package:ndu_project/screens/front_end_planning_contracts_screen.dart';
import 'package:ndu_project/screens/change_management_screen.dart';
import 'package:ndu_project/screens/project_plan_screen.dart';
import 'package:ndu_project/screens/project_plan_subsections_screen.dart';
import 'package:ndu_project/screens/project_baseline_screen.dart';
import 'package:ndu_project/screens/agile_project_baseline_screen.dart';
import 'package:ndu_project/screens/stakeholder_management_screen.dart';
import 'package:ndu_project/screens/lessons_learned_screen.dart';
import 'package:ndu_project/screens/team_training_building_screen.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/screens/engineering_design_screen.dart';
import 'package:ndu_project/screens/schedule_screen.dart';
import 'package:ndu_project/screens/interface_management_screen.dart';
import 'package:ndu_project/screens/startup_planning_screen.dart';
import 'package:ndu_project/screens/design_deliverables_screen.dart';
import 'package:ndu_project/screens/startup_planning_subsections_screen.dart';
import 'package:ndu_project/screens/deliverable_roadmap_subsections_screen.dart';
import 'package:ndu_project/screens/organization_plan_subsections_screen.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/models/project_data_model.dart';
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
import 'package:ndu_project/screens/development_set_up_screen.dart';
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
import 'package:ndu_project/screens/backend_design_screen.dart';
import 'package:ndu_project/screens/technical_debt_management_screen.dart';
import 'package:ndu_project/screens/risk_tracking_screen.dart';
import 'package:ndu_project/screens/identify_staff_ops_team_screen.dart';
import 'package:ndu_project/screens/contracts_tracking_screen.dart';
import 'package:ndu_project/screens/vendor_tracking_screen.dart';
import 'package:ndu_project/screens/detailed_design_screen.dart';
import 'package:ndu_project/screens/scope_tracking_implementation_screen.dart';
import 'package:ndu_project/screens/stakeholder_alignment_screen.dart';
import 'package:ndu_project/screens/update_ops_maintenance_plans_screen.dart';

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
  static bool? _sharedActualVsPlannedExpanded;
  static bool? _sharedProjectCloseOutExpanded;
  static bool? _sharedExecutiveSummaryExpanded;
  static bool? _sharedProgressTrackingExpanded;
  static bool? _sharedStartUpPlanningExpanded;
  static bool? _sharedDeliverableRoadmapExpanded;
  static bool? _sharedOrganizationPlanExpanded;
  static bool? _sharedProjectPlanExpanded;
  static bool? _sharedPunchlistExpanded;
  static bool? _sharedCostEstimateExpanded;
  static bool? _sharedProjectServicesExpanded;
  static double _sharedScrollOffset = 0;

  late bool _initiationExpanded = _sharedInitiationExpanded ?? true;
  late bool _businessCaseExpanded = _sharedBusinessCaseExpanded ?? true;
  late bool _frontEndExpanded = _sharedFrontEndExpanded ?? true;
  late bool _executionPlanExpanded = _sharedExecutionPlanExpanded ?? false;
  late bool _planningPhaseExpanded = _sharedPlanningPhaseExpanded ?? false;
  late bool _designPhaseExpanded = _sharedDesignPhaseExpanded ?? false;
  late bool _executionPhaseExpanded = _sharedExecutionPhaseExpanded ?? false;
  late bool _launchPhaseExpanded = _sharedLaunchPhaseExpanded ?? false;
  late bool _actualVsPlannedExpanded = _sharedActualVsPlannedExpanded ?? false;
  late bool _projectCloseOutExpanded = _sharedProjectCloseOutExpanded ?? false;
  late bool _executiveSummaryExpanded = _sharedExecutiveSummaryExpanded ?? true;
  late bool _progressTrackingExpanded = _sharedProgressTrackingExpanded ?? false;
  late bool _startUpPlanningExpanded = _sharedStartUpPlanningExpanded ?? false;
  late bool _deliverableRoadmapExpanded = _sharedDeliverableRoadmapExpanded ?? false;
  late bool _organizationPlanExpanded = _sharedOrganizationPlanExpanded ?? false;
  late bool _projectPlanExpanded = _sharedProjectPlanExpanded ?? false;
  late bool _punchlistExpanded = _sharedPunchlistExpanded ?? false;
  late bool _costEstimateExpanded = _sharedCostEstimateExpanded ?? false;
  late bool _projectServicesExpanded = _sharedProjectServicesExpanded ?? false;
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
    final data = ProjectDataInherited.of(context).projectData;
    _navigateWithCheckpoint(
      'risk_identification',
      RiskIdentificationScreen(
        notes: data.notes,
        solutions: _buildSolutionItems(data),
        businessCase: data.businessCase,
      ),
    );
  }

  void _openITConsiderations() {
    final data = ProjectDataInherited.of(context).projectData;
    _navigateWithCheckpoint(
      'it_considerations',
      ITConsiderationsScreen(
        notes: data.itConsiderationsData?.notes ?? data.notes,
        solutions: _buildSolutionItems(data),
      ),
    );
  }

  void _openInfrastructureConsiderations() {
    final data = ProjectDataInherited.of(context).projectData;
    _navigateWithCheckpoint(
      'infrastructure_considerations',
      InfrastructureConsiderationsScreen(
        notes: data.infrastructureConsiderationsData?.notes ?? data.notes,
        solutions: _buildSolutionItems(data),
      ),
    );
  }

  void _openCoreStakeholders() {
    final data = ProjectDataInherited.of(context).projectData;
    _navigateWithCheckpoint(
      'core_stakeholders',
      CoreStakeholdersScreen(
        notes: data.coreStakeholdersData?.notes ?? data.notes,
        solutions: _buildSolutionItems(data),
      ),
    );
  }

  void _openCostAnalysis() {
    _navigateWithCheckpoint('cost_analysis', const CostAnalysisScreen(notes: '', solutions: []));
  }

  List<AiSolutionItem> _buildSolutionItems(ProjectDataModel data) {
    final potential = data.potentialSolutions
        .map((s) => AiSolutionItem(title: s.title.trim(), description: s.description.trim()))
        .where((s) => s.title.isNotEmpty || s.description.isNotEmpty)
        .toList();
    if (potential.isNotEmpty) return potential;

    final preferred = data.preferredSolutionAnalysis?.solutionAnalyses
            .map((s) => AiSolutionItem(title: s.solutionTitle.trim(), description: s.solutionDescription.trim()))
            .where((s) => s.title.isNotEmpty || s.description.isNotEmpty)
            .toList() ??
        [];
    if (preferred.isNotEmpty) return preferred;

    final fallbackTitle = data.solutionTitle.trim();
    final fallbackDescription = data.solutionDescription.trim();
    if (fallbackTitle.isNotEmpty || fallbackDescription.isNotEmpty) {
      return [AiSolutionItem(title: fallbackTitle, description: fallbackDescription)];
    }

    return [];
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
    _navigateWithCheckpoint('design', const DesignPhaseScreen(activeItemLabel: 'Design'));
  }

  void _openDesignManagement() {
    _navigateWithCheckpoint('design_management', const DesignPhaseScreen(activeItemLabel: 'Design Management'));
  }

  void _openExecutionPlan() {
    _navigateWithCheckpoint('execution_plan', const ExecutionPlanScreen());
  }

  void _openExecutionPlanStrategy() {
    _navigateWithCheckpoint('execution_plan_strategy', const ExecutionPlanSolutionsScreen());
  }

  void _openExecutionPlanDetails() {
    _navigateWithCheckpoint(
      'execution_plan_details',
      const ExecutionPlanDetailsScreen(
        activeItemLabel: 'Execution Plan Details',
        showPlanDetails: true,
        showEarlyWorks: false,
      ),
    );
  }

  void _openExecutionEarlyWorks() {
    _navigateWithCheckpoint(
      'execution_early_works',
      const ExecutionPlanDetailsScreen(
        activeItemLabel: 'Execution Early Works',
        showPlanDetails: false,
        showEarlyWorks: true,
      ),
    );
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

  void _openExecutionPlanAgileDeliveryPlan() {
    _navigateWithCheckpoint('execution_plan_agile_delivery_plan', const ExecutionPlanAgileDeliveryPlanScreen());
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

  void _openInterfaceManagement() {
    _navigateWithCheckpoint('interface_management', const InterfaceManagementScreen());
  }

  void _openStartUpPlanning() {
    _navigateWithCheckpoint('startup_planning', const StartUpPlanningScreen());
  }

  void _openStartUpPlanningOperations() {
    _navigateWithCheckpoint(
      'startup_planning_operations',
      const StartUpPlanningOperationsScreen(),
    );
  }

  void _openStartUpPlanningHypercare() {
    _navigateWithCheckpoint(
      'startup_planning_hypercare',
      const StartUpPlanningHypercareScreen(),
    );
  }

  void _openStartUpPlanningDevOps() {
    _navigateWithCheckpoint(
      'startup_planning_devops',
      const StartUpPlanningDevOpsScreen(),
    );
  }

  void _openStartUpPlanningCloseOut() {
    _navigateWithCheckpoint(
      'startup_planning_closeout',
      const StartUpPlanningCloseOutPlanScreen(),
    );
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

  void _openScopeTrackingPlan() {
    _navigateWithCheckpoint('scope_tracking_plan', const ScopeTrackingPlanScreen());
  }

  void _openChangeManagement() {
    _navigateWithCheckpoint('change_management', const ChangeManagementScreen());
  }

  void _openProjectPlan() {
    _navigateWithCheckpoint('project_plan', const ProjectPlanScreen());
  }

  void _openProjectPlanLevel1Schedule() {
    _navigateWithCheckpoint('project_plan_level1_schedule', const ProjectPlanLevel1ScheduleScreen());
  }

  void _openProjectPlanDetailedSchedule() {
    _navigateWithCheckpoint('project_plan_detailed_schedule', const ProjectPlanDetailedScheduleScreen());
  }

  void _openProjectPlanCondensedSummary() {
    _navigateWithCheckpoint('project_plan_condensed_summary', const ProjectPlanCondensedSummaryScreen());
  }

  void _openProjectBaseline() {
    _navigateWithCheckpoint('project_baseline', const ProjectBaselineScreen());
  }

  void _openAgileProjectBaseline() {
    _navigateWithCheckpoint('agile_project_baseline', const AgileProjectBaselineScreen());
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

  void _openOrganizationRolesResponsibilities() {
    _navigateWithCheckpoint('organization_roles_responsibilities', const OrganizationRolesResponsibilitiesScreen());
  }

  void _openOrganizationStaffingPlan() {
    _navigateWithCheckpoint('organization_staffing_plan', const OrganizationStaffingPlanScreen());
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

  void _openDevelopmentSetUp() {
    _navigateWithCheckpoint('development_set_up', const DevelopmentSetUpScreen());
  }

  void _openDesignDeliverables() {
    _navigateWithCheckpoint('design_deliverables', const DesignDeliverablesScreen());
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

  void _openBackendDesign() {
    _navigateWithCheckpoint('backend_design', const BackendDesignScreen());
  }

  void _openEngineeringDesign() {
    _navigateWithCheckpoint('engineering_design', const EngineeringDesignScreen());
  }

  void _openProjectCloseOut() {
    _navigateWithCheckpoint('project_close_out', const ProjectCloseOutScreen());
  }

  void _openProjectCloseOutLongForm() {
    _navigateWithCheckpoint(
      'project_close_out',
      const ProjectCloseOutScreen(
        summarized: false,
        activeItemLabel: 'Project Close Out - Long Form',
      ),
    );
  }

  void _openProjectCloseOutSummarized() {
    _navigateWithCheckpoint(
      'project_close_out',
      const ProjectCloseOutScreen(
        summarized: true,
        activeItemLabel: 'Project Close Out - Summarized Form',
      ),
    );
  }

  void _openDemobilizeTeam() {
    _navigateWithCheckpoint('demobilize_team', const DemobilizeTeamScreen());
  }

  void _openActualVsPlannedGapAnalysis() {
    _navigateWithCheckpoint('actual_vs_planned_gap_analysis', const ActualVsPlannedGapAnalysisScreen());
  }

  void _openActualVsPlannedScopeReconcillation() {
    _navigateWithCheckpoint(
      'actual_vs_planned_gap_analysis',
      const GapAnalysisScopeReconcillationScreen(
        activeItemLabel: 'Actual vs Planned Gap Analysis - Scope Reconcillation',
      ),
    );
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

  void _openTechnicalDebtManagement() {
    _navigateWithCheckpoint('technical_debt_management', const TechnicalDebtManagementScreen());
  }

  void _openRiskTracking() {
    _navigateWithCheckpoint('risk_tracking', const RiskTrackingScreen());
  }

  void _openIdentifyStaffOpsTeam() {
    _navigateWithCheckpoint('identify_staff_ops_team', const IdentifyStaffOpsTeamScreen());
  }

  void _openContractsTracking() {
    _navigateWithCheckpoint('contracts_tracking', const ContractsTrackingScreen());
  }

  void _openVendorTracking() {
    _navigateWithCheckpoint('vendor_tracking', const VendorTrackingScreen());
  }

  void _openDetailedDesign() {
    _navigateWithCheckpoint('detailed_design', const DetailedDesignScreen());
  }

  void _openScopeTrackingImplementation() {
    _navigateWithCheckpoint('scope_tracking_implementation', const ScopeTrackingImplementationScreen());
  }

  void _openStakeholderAlignment() {
    _navigateWithCheckpoint('stakeholder_alignment', const StakeholderAlignmentScreen());
  }

  void _openUpdateOpsMaintenancePlans() {
    _navigateWithCheckpoint('update_ops_maintenance_plans', const UpdateOpsMaintenancePlansScreen());
  }

  void _openRequirementsImplementation() {
    _navigateWithCheckpoint('requirements_implementation', const RequirementsImplementationScreen());
  }

  void _openDeliverableRoadmap() {
    _navigateWithCheckpoint('deliverable_roadmap', const DeliverablesRoadmapScreen());
  }

  void _openDeliverableRoadmapAgileMapOut() {
    _navigateWithCheckpoint('deliverable_roadmap_agile_map_out', const DeliverableRoadmapAgileMapOutScreen());
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
                  _buildSubExpandableHeader(
                    'Cost Estimate',
                    expanded: _costEstimateExpanded,
                    onTap: () => setState(() {
                      _costEstimateExpanded = !_costEstimateExpanded;
                      _sharedCostEstimateExpanded = _costEstimateExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Cost Estimate',
                  ),
                  if (_costEstimateExpanded) ...[
                    _buildSubSubMenuItem('Cost Estimate Overview', onTap: _openCostEstimate, isActive: widget.activeItemLabel == 'Cost Estimate'),
                  ],
                  _buildSubExpandableHeader(
                    'Project Services',
                    expanded: _projectServicesExpanded,
                    onTap: () => setState(() {
                      _projectServicesExpanded = !_projectServicesExpanded;
                      _sharedProjectServicesExpanded = _projectServicesExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Scope Tracking Plan',
                  ),
                  if (_projectServicesExpanded) ...[
                    _buildSubSubMenuItem('Scope Tracking Plan', onTap: _openScopeTrackingPlan, isActive: widget.activeItemLabel == 'Scope Tracking Plan'),
                  ],
                  _buildSubMenuItem('Contract', onTap: _openContract, isActive: widget.activeItemLabel == 'Contract'),
                  _buildSubMenuItem('Procurement', onTap: _openProcurement, isActive: widget.activeItemLabel == 'Procurement'),
                  _buildSubExpandableHeader(
                    'Project Plan',
                    expanded: _projectPlanExpanded,
                    onTap: () => setState(() {
                      _projectPlanExpanded = !_projectPlanExpanded;
                      _sharedProjectPlanExpanded = _projectPlanExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Project Plan' ||
                        widget.activeItemLabel == 'Project Plan - Level 1 - Project Schedule' ||
                        widget.activeItemLabel == 'Project Plan - Detailed Project Schedule' ||
                        widget.activeItemLabel == 'Project Plan - Condensed Project Summary',
                  ),
                  if (_projectPlanExpanded) ...[
                    _buildSubSubMenuItem('Project Plan Overview', onTap: _openProjectPlan, isActive: widget.activeItemLabel == 'Project Plan'),
                    _buildSubSubMenuItem(
                      'Level 1 - Project Schedule',
                      onTap: _openProjectPlanLevel1Schedule,
                      isActive: widget.activeItemLabel == 'Project Plan - Level 1 - Project Schedule',
                    ),
                    _buildSubSubMenuItem(
                      'Detailed Project Schedule',
                      onTap: _openProjectPlanDetailedSchedule,
                      isActive: widget.activeItemLabel == 'Project Plan - Detailed Project Schedule',
                    ),
                    _buildSubSubMenuItem(
                      'Condensed Project Summary',
                      onTap: _openProjectPlanCondensedSummary,
                      isActive: widget.activeItemLabel == 'Project Plan - Condensed Project Summary',
                    ),
                  ],
                  _buildSubExpandableHeader(
                    'Execution Plan',
                    expanded: _executionPlanExpanded,
                    onTap: () => setState(() {
                      _executionPlanExpanded = !_executionPlanExpanded;
                      _sharedExecutionPlanExpanded = _executionPlanExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Execution Plan' ||
                        widget.activeItemLabel == 'Execution Plan - Construction Plan' ||
                        widget.activeItemLabel == 'Execution Plan - Infrastructure Plan' ||
                        widget.activeItemLabel == 'Execution Plan - Agile Delivery Plan',
                  ),
                  if (_executionPlanExpanded) ...[
                    _buildSubSubMenuItem('Construction Plan', onTap: _openExecutionPlanConstructionPlan, isActive: widget.activeItemLabel == 'Execution Plan - Construction Plan'),
                    _buildSubSubMenuItem('Infrastructure Plan', onTap: _openExecutionPlanInfrastructurePlan, isActive: widget.activeItemLabel == 'Execution Plan - Infrastructure Plan'),
                    _buildSubSubMenuItem('Agile Delivery Plan', onTap: _openExecutionPlanAgileDeliveryPlan, isActive: widget.activeItemLabel == 'Execution Plan - Agile Delivery Plan'),
                  ],
                  _buildSubMenuItem('Schedule', onTap: _openSchedule, isActive: widget.activeItemLabel == 'Schedule'),
                  _buildSubMenuItem('Design', onTap: _openDesign, isActive: widget.activeItemLabel == 'Design'),
                  _buildSubMenuItem('Technology', onTap: _openTechnology, isActive: widget.activeItemLabel == 'Technology'),
                  _buildSubMenuItem('Interface Management', onTap: _openInterfaceManagement, isActive: widget.activeItemLabel == 'Interface Management'),
                  _buildSubExpandableHeader(
                    'Start-Up Planning',
                    expanded: _startUpPlanningExpanded,
                    onTap: () => setState(() {
                      _startUpPlanningExpanded = !_startUpPlanningExpanded;
                      _sharedStartUpPlanningExpanded = _startUpPlanningExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Start-Up Planning' ||
                        widget.activeItemLabel == 'Start-Up Planning - Operations Plan and Manual' ||
                        widget.activeItemLabel == 'Start-Up Planning - Hypercare Plan' ||
                        widget.activeItemLabel == 'Start-Up Planning - DevOps' ||
                        widget.activeItemLabel == 'Start-Up Planning - Close Out Plan',
                  ),
                  if (_startUpPlanningExpanded) ...[
                    _buildSubSubMenuItem(
                      'Operations Plan and Manual',
                      onTap: _openStartUpPlanningOperations,
                      isActive: widget.activeItemLabel == 'Start-Up Planning - Operations Plan and Manual',
                    ),
                    _buildSubSubMenuItem(
                      'Hypercare Plan',
                      onTap: _openStartUpPlanningHypercare,
                      isActive: widget.activeItemLabel == 'Start-Up Planning - Hypercare Plan',
                    ),
                    _buildSubSubMenuItem(
                      'DevOps',
                      onTap: _openStartUpPlanningDevOps,
                      isActive: widget.activeItemLabel == 'Start-Up Planning - DevOps',
                    ),
                    _buildSubSubMenuItem(
                      'Close Out Plan',
                      onTap: _openStartUpPlanningCloseOut,
                      isActive: widget.activeItemLabel == 'Start-Up Planning - Close Out Plan',
                    ),
                  ],
                  _buildSubExpandableHeader(
                    'Deliverable Roadmap',
                    expanded: _deliverableRoadmapExpanded,
                    onTap: () => setState(() {
                      _deliverableRoadmapExpanded = !_deliverableRoadmapExpanded;
                      _sharedDeliverableRoadmapExpanded = _deliverableRoadmapExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Deliverable Roadmap' || widget.activeItemLabel == 'Deliverable Roadmap - Agile Map Out',
                  ),
                  if (_deliverableRoadmapExpanded) ...[
                    _buildSubSubMenuItem('Roadmap Overview', onTap: _openDeliverableRoadmap, isActive: widget.activeItemLabel == 'Deliverable Roadmap'),
                    _buildSubSubMenuItem('Agile Map Out', onTap: _openDeliverableRoadmapAgileMapOut, isActive: widget.activeItemLabel == 'Deliverable Roadmap - Agile Map Out'),
                  ],
                  _buildSubMenuItem('Agile Project Baseline', onTap: _openAgileProjectBaseline, isActive: widget.activeItemLabel == 'Agile Project Baseline'),
                  _buildSubMenuItem('Project Baseline', onTap: _openProjectBaseline, isActive: widget.activeItemLabel == 'Project Baseline'),
                  _buildSubExpandableHeader(
                    'Organization Plan',
                    expanded: _organizationPlanExpanded,
                    onTap: () => setState(() {
                      _organizationPlanExpanded = !_organizationPlanExpanded;
                      _sharedOrganizationPlanExpanded = _organizationPlanExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Organization Plan' ||
                        widget.activeItemLabel == 'Organization Plan - Roles & Responsibilities' ||
                        widget.activeItemLabel == 'Organization Plan - Staffing Plan' ||
                        widget.activeItemLabel == 'Team Training and Team Building' ||
                        widget.activeItemLabel == 'Stakeholder Management',
                  ),
                  if (_organizationPlanExpanded) ...[
                    _buildSubSubMenuItem('Roles & Responsibilities', onTap: _openOrganizationRolesResponsibilities, isActive: widget.activeItemLabel == 'Organization Plan - Roles & Responsibilities'),
                    _buildSubSubMenuItem('Staffing Plan', onTap: _openOrganizationStaffingPlan, isActive: widget.activeItemLabel == 'Organization Plan - Staffing Plan'),
                    _buildSubSubMenuItem('Training & Team Building', onTap: _openTeamTraining, isActive: widget.activeItemLabel == 'Team Training and Team Building'),
                    _buildSubSubMenuItem('Stakeholder Management', onTap: _openStakeholderManagement, isActive: widget.activeItemLabel == 'Stakeholder Management'),
                  ],
                  _buildSubMenuItem('Lessons Learned', onTap: _openLessonsLearned, isActive: widget.activeItemLabel == 'Lessons Learned'),
                  _buildSubMenuItem('Team Management', onTap: _openTeamManagement, isActive: widget.activeItemLabel == 'Team Management'),
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
                  _buildSubMenuItem('Development Set Up', onTap: _openDevelopmentSetUp, isActive: widget.activeItemLabel == 'Development Set Up'),
                  _buildSubMenuItem('UI/UX Design', onTap: _openUiUxDesign, isActive: widget.activeItemLabel == 'UI/UX Design'),
                  _buildSubMenuItem('Backend Design', onTap: _openBackendDesign, isActive: widget.activeItemLabel == 'Backend Design'),
                  _buildSubMenuItem('Engineering', onTap: _openEngineeringDesign, isActive: widget.activeItemLabel == 'Engineering'),
                  _buildSubMenuItem('Technical Development', onTap: _openTechnicalDevelopment, isActive: widget.activeItemLabel == 'Technical Development'),
                  _buildSubMenuItem('Tools Integration', onTap: _openToolsIntegration, isActive: widget.activeItemLabel == 'Tools Integration'),
                  _buildSubMenuItem('Long Lead Equipment Ordering', onTap: _openLongLeadEquipmentOrdering, isActive: widget.activeItemLabel == 'Long Lead Equipment Ordering'),
                  _buildSubMenuItem('Specialized Design', onTap: _openSpecializedDesign, isActive: widget.activeItemLabel == 'Specialized Design'),
                  _buildSubMenuItem('Design Deliverables', onTap: _openDesignDeliverables, isActive: widget.activeItemLabel == 'Design Deliverables'),
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
                  _buildSubMenuItem('Team Meetings', onTap: _openTeamMeetings, isActive: widget.activeItemLabel == 'Team Meetings'),
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
                  _buildSubMenuItem('Contracts Tracking', onTap: _openContractsTracking, isActive: widget.activeItemLabel == 'Contracts Tracking'),
                  _buildSubMenuItem('Vendor Tracking', onTap: _openVendorTracking, isActive: widget.activeItemLabel == 'Vendor Tracking'),
                  _buildSubMenuItem('Detailed Design', onTap: _openDetailedDesign, isActive: widget.activeItemLabel == 'Detailed Design'),
                  _buildSubMenuItem('Agile Development Iterations', onTap: _openAgileDevelopmentIterations, isActive: widget.activeItemLabel == 'Agile Development Iterations'),
                  _buildSubMenuItem('Scope Tracking Implementation', onTap: _openScopeTrackingImplementation, isActive: widget.activeItemLabel == 'Scope Tracking Implementation'),
                  _buildSubMenuItem('Stakeholder Alignment', onTap: _openStakeholderAlignment, isActive: widget.activeItemLabel == 'Stakeholder Alignment'),
                  _buildSubMenuItem('Update Ops and Maintenance Plans', onTap: _openUpdateOpsMaintenancePlans, isActive: widget.activeItemLabel == 'Update Ops and Maintenance Plans'),
                  _buildSubMenuItem('Start-up or Launch Checklist', onTap: _openLaunchChecklist, isActive: widget.activeItemLabel == 'Start-up or Launch Checklist'),
                  _buildSubMenuItem('Risk Tracking', onTap: _openRiskTracking, isActive: widget.activeItemLabel == 'Risk Tracking'),
                  _buildSubMenuItem('Scope Completion', onTap: _openScopeCompletion, isActive: widget.activeItemLabel == 'Scope Completion'),
                  _buildSubMenuItem('Gap Analysis and Scope Reconciliation', onTap: _openGapAnalysisAndScopeReconcillation, isActive: widget.activeItemLabel == 'Gap Analysis and Scope Reconciliation'),
                  _buildSubExpandableHeader(
                    'Punchlist Actions',
                    expanded: _punchlistExpanded,
                    onTap: () => setState(() {
                      _punchlistExpanded = !_punchlistExpanded;
                      _sharedPunchlistExpanded = _punchlistExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Punchlist Actions' || widget.activeItemLabel == 'Technical Debt Management',
                  ),
                  if (_punchlistExpanded) ...[
                    _buildSubSubMenuItem('Punchlist Overview', onTap: _openPunchlistActions, isActive: widget.activeItemLabel == 'Punchlist Actions'),
                    _buildSubSubMenuItem('Tech Debt Management', onTap: _openTechnicalDebtManagement, isActive: widget.activeItemLabel == 'Technical Debt Management'),
                  ],
                  _buildSubMenuItem('Identify and Staff Ops Team', onTap: _openIdentifyStaffOpsTeam, isActive: widget.activeItemLabel == 'Identify and Staff Ops Team'),
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
                  _buildSubExpandableHeader(
                    'Actual vs Planned Gap Analysis',
                    expanded: _actualVsPlannedExpanded,
                    onTap: () => setState(() {
                      _actualVsPlannedExpanded = !_actualVsPlannedExpanded;
                      _sharedActualVsPlannedExpanded = _actualVsPlannedExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Actual vs Planned Gap Analysis' ||
                        widget.activeItemLabel == 'Actual vs Planned Gap Analysis - Scope Reconcillation',
                  ),
                  if (_actualVsPlannedExpanded) ...[
                    _buildSubSubMenuItem(
                      'Gap Analysis',
                      onTap: _openActualVsPlannedGapAnalysis,
                      isActive: widget.activeItemLabel == 'Actual vs Planned Gap Analysis',
                    ),
                    _buildSubSubMenuItem(
                      'Scope Reconcillation',
                      onTap: _openActualVsPlannedScopeReconcillation,
                      isActive: widget.activeItemLabel == 'Actual vs Planned Gap Analysis - Scope Reconcillation',
                    ),
                  ],
                  _buildSubMenuItem('Demobilize Team', onTap: _openDemobilizeTeam, isActive: widget.activeItemLabel == 'Demobilize Team'),
                  _buildSubExpandableHeader(
                    'Project Close Out',
                    expanded: _projectCloseOutExpanded,
                    onTap: () => setState(() {
                      _projectCloseOutExpanded = !_projectCloseOutExpanded;
                      _sharedProjectCloseOutExpanded = _projectCloseOutExpanded;
                    }),
                    isActive: widget.activeItemLabel == 'Project Close Out' ||
                        widget.activeItemLabel == 'Project Close Out - Long Form' ||
                        widget.activeItemLabel == 'Project Close Out - Summarized Form',
                  ),
                  if (_projectCloseOutExpanded) ...[
                    _buildSubSubMenuItem(
                      'Long Form',
                      onTap: _openProjectCloseOutLongForm,
                      isActive: widget.activeItemLabel == 'Project Close Out - Long Form',
                    ),
                    _buildSubSubMenuItem(
                      'Summarized Form',
                      onTap: _openProjectCloseOutSummarized,
                      isActive: widget.activeItemLabel == 'Project Close Out - Summarized Form',
                    ),
                  ],
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
    if ('project services'.contains(query) || 'scope tracking plan'.contains(query) || 'scope tracking'.contains(query)) {
      results.add(_buildMenuItem(Icons.track_changes_outlined, 'Scope Tracking Plan', onTap: _openScopeTrackingPlan, isActive: widget.activeItemLabel == 'Scope Tracking Plan'));
    }
    if ('project plan'.contains(query)) {
      results.add(_buildMenuItem(Icons.assignment_outlined, 'Project Plan', onTap: _openProjectPlan, isActive: widget.activeItemLabel == 'Project Plan'));
    }
    if ('level 1 project schedule'.contains(query) || 'level 1 - project schedule'.contains(query) || 'level 1 schedule'.contains(query)) {
      results.add(_buildMenuItem(Icons.timeline_outlined, 'Level 1 - Project Schedule', onTap: _openProjectPlanLevel1Schedule, isActive: widget.activeItemLabel == 'Project Plan - Level 1 - Project Schedule'));
    }
    if ('detailed project schedule'.contains(query) || 'detailed schedule'.contains(query)) {
      results.add(_buildMenuItem(Icons.event_note_outlined, 'Detailed Project Schedule', onTap: _openProjectPlanDetailedSchedule, isActive: widget.activeItemLabel == 'Project Plan - Detailed Project Schedule'));
    }
    if ('condensed project summary'.contains(query) || 'condensed summary'.contains(query) || 'project summary'.contains(query)) {
      results.add(_buildMenuItem(Icons.summarize_outlined, 'Condensed Project Summary', onTap: _openProjectPlanCondensedSummary, isActive: widget.activeItemLabel == 'Project Plan - Condensed Project Summary'));
    }
    if ('agile project baseline'.contains(query)) {
      results.add(_buildMenuItem(Icons.grid_view_outlined, 'Agile Project Baseline', onTap: _openAgileProjectBaseline, isActive: widget.activeItemLabel == 'Agile Project Baseline'));
    }
    if ('project baseline'.contains(query) || 'baseline'.contains(query)) {
      results.add(_buildMenuItem(Icons.flag_circle_outlined, 'Project Baseline', onTap: _openProjectBaseline, isActive: widget.activeItemLabel == 'Project Baseline'));
    }
    if ('execution plan'.contains(query) || 'construction plan'.contains(query)) {
      results.add(_buildMenuItem(Icons.home_repair_service_outlined, 'Construction Plan', onTap: _openExecutionPlanConstructionPlan, isActive: widget.activeItemLabel == 'Execution Plan - Construction Plan'));
    }
    if ('execution plan'.contains(query) || 'infrastructure plan'.contains(query)) {
      results.add(_buildMenuItem(Icons.domain_outlined, 'Infrastructure Plan', onTap: _openExecutionPlanInfrastructurePlan, isActive: widget.activeItemLabel == 'Execution Plan - Infrastructure Plan'));
    }
    if ('execution plan'.contains(query) || 'agile delivery plan'.contains(query) || 'agile delivery'.contains(query)) {
      results.add(_buildMenuItem(Icons.route_outlined, 'Agile Delivery Plan', onTap: _openExecutionPlanAgileDeliveryPlan, isActive: widget.activeItemLabel == 'Execution Plan - Agile Delivery Plan'));
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
    if ('interface management'.contains(query) || 'interfaces'.contains(query)) {
      results.add(_buildMenuItem(Icons.device_hub_outlined, 'Interface Management', onTap: _openInterfaceManagement, isActive: widget.activeItemLabel == 'Interface Management'));
    }
    if ('start-up planning'.contains(query) || 'startup planning'.contains(query) || 'start up planning'.contains(query)) {
      results.add(_buildMenuItem(Icons.rocket_launch_outlined, 'Start-Up Planning', onTap: _openStartUpPlanning, isActive: widget.activeItemLabel == 'Start-Up Planning'));
    }
    if ('operations plan'.contains(query) || 'manual'.contains(query)) {
      results.add(_buildMenuItem(Icons.menu_book_outlined, 'Operations Plan and Manual', onTap: _openStartUpPlanningOperations, isActive: widget.activeItemLabel == 'Start-Up Planning - Operations Plan and Manual'));
    }
    if ('hypercare'.contains(query)) {
      results.add(_buildMenuItem(Icons.health_and_safety_outlined, 'Hypercare Plan', onTap: _openStartUpPlanningHypercare, isActive: widget.activeItemLabel == 'Start-Up Planning - Hypercare Plan'));
    }
    if ('devops'.contains(query) || 'ci/cd'.contains(query) || 'pipeline'.contains(query)) {
      results.add(_buildMenuItem(Icons.settings_suggest_outlined, 'DevOps', onTap: _openStartUpPlanningDevOps, isActive: widget.activeItemLabel == 'Start-Up Planning - DevOps'));
    }
    if ('close out plan'.contains(query) || 'closeout plan'.contains(query)) {
      results.add(_buildMenuItem(Icons.fact_check_outlined, 'Close Out Plan', onTap: _openStartUpPlanningCloseOut, isActive: widget.activeItemLabel == 'Start-Up Planning - Close Out Plan'));
    }
    if ('team training'.contains(query) || 'team building'.contains(query)) {
      results.add(_buildMenuItem(Icons.school_outlined, 'Team Training and Team Building', onTap: _openTeamTraining, isActive: widget.activeItemLabel == 'Team Training and Team Building'));
    }
    if ('roles and responsibilities'.contains(query) || 'roles & responsibilities'.contains(query) || 'roles responsibilities'.contains(query)) {
      results.add(_buildMenuItem(Icons.assignment_ind_outlined, 'Roles & Responsibilities', onTap: _openOrganizationRolesResponsibilities, isActive: widget.activeItemLabel == 'Organization Plan - Roles & Responsibilities'));
    }
    if ('staffing plan'.contains(query) || 'staffing'.contains(query) || 'resource plan'.contains(query)) {
      results.add(_buildMenuItem(Icons.badge_outlined, 'Staffing Plan', onTap: _openOrganizationStaffingPlan, isActive: widget.activeItemLabel == 'Organization Plan - Staffing Plan'));
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
    if ('design deliverables'.contains(query) || 'deliverables'.contains(query)) {
      results.add(_buildMenuItem(Icons.inventory_2_outlined, 'Design Deliverables', onTap: _openDesignDeliverables, isActive: widget.activeItemLabel == 'Design Deliverables'));
    }
    if ('requirements implementation'.contains(query) || 'requirements'.contains(query) || 'implementation'.contains(query)) {
      results.add(_buildMenuItem(Icons.checklist_rtl_outlined, 'Requirements Implementation', onTap: _openRequirementsImplementation, isActive: widget.activeItemLabel == 'Requirements Implementation'));
    }
    if ('development set up'.contains(query) || 'development setup'.contains(query) || 'setup'.contains(query)) {
      results.add(_buildMenuItem(Icons.build_outlined, 'Development Set Up', onTap: _openDevelopmentSetUp, isActive: widget.activeItemLabel == 'Development Set Up'));
    }
    if ('ui/ux design'.contains(query) || 'ui ux'.contains(query) || 'ux design'.contains(query) || 'user interface'.contains(query) || 'user experience'.contains(query)) {
      results.add(_buildMenuItem(Icons.palette_outlined, 'UI/UX Design', onTap: _openUiUxDesign, isActive: widget.activeItemLabel == 'UI/UX Design'));
    }
    if ('backend design'.contains(query) || 'backend'.contains(query) || 'database'.contains(query)) {
      results.add(_buildMenuItem(Icons.storage_outlined, 'Backend Design', onTap: _openBackendDesign, isActive: widget.activeItemLabel == 'Backend Design'));
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
    if ('contracts tracking'.contains(query) || 'contracts tracking'.contains(query) || 'contracts'.contains(query)) {
      results.add(_buildMenuItem(Icons.description_outlined, 'Contracts Tracking', onTap: _openContractsTracking, isActive: widget.activeItemLabel == 'Contracts Tracking'));
    }
    if ('vendor tracking'.contains(query) || 'vendors'.contains(query) || 'vendor'.contains(query)) {
      results.add(_buildMenuItem(Icons.storefront_outlined, 'Vendor Tracking', onTap: _openVendorTracking, isActive: widget.activeItemLabel == 'Vendor Tracking'));
    }
    if ('detailed design'.contains(query) || 'detail design'.contains(query)) {
      results.add(_buildMenuItem(Icons.design_services_outlined, 'Detailed Design', onTap: _openDetailedDesign, isActive: widget.activeItemLabel == 'Detailed Design'));
    }
    if ('scope tracking implementation'.contains(query) || 'scope tracking'.contains(query)) {
      results.add(_buildMenuItem(Icons.track_changes_outlined, 'Scope Tracking Implementation', onTap: _openScopeTrackingImplementation, isActive: widget.activeItemLabel == 'Scope Tracking Implementation'));
    }
    if ('stakeholder alignment'.contains(query) || 'alignment'.contains(query)) {
      results.add(_buildMenuItem(Icons.group_work_outlined, 'Stakeholder Alignment', onTap: _openStakeholderAlignment, isActive: widget.activeItemLabel == 'Stakeholder Alignment'));
    }
    if ('update ops and maintenance plans'.contains(query) || 'ops maintenance'.contains(query) || 'maintenance plans'.contains(query)) {
      results.add(_buildMenuItem(Icons.handyman_outlined, 'Update Ops and Maintenance Plans', onTap: _openUpdateOpsMaintenancePlans, isActive: widget.activeItemLabel == 'Update Ops and Maintenance Plans'));
    }
    if ('technical debt management'.contains(query) || 'tech debt'.contains(query)) {
      results.add(_buildMenuItem(Icons.rule_folder_outlined, 'Technical Debt Management', onTap: _openTechnicalDebtManagement, isActive: widget.activeItemLabel == 'Technical Debt Management'));
    }
    if ('risk tracking'.contains(query) || 'risk'.contains(query)) {
      results.add(_buildMenuItem(Icons.assessment_outlined, 'Risk Tracking', onTap: _openRiskTracking, isActive: widget.activeItemLabel == 'Risk Tracking'));
    }
    if ('identify and staff ops team'.contains(query) || 'ops team'.contains(query) || 'staff ops'.contains(query)) {
      results.add(_buildMenuItem(Icons.groups_outlined, 'Identify and Staff Ops Team', onTap: _openIdentifyStaffOpsTeam, isActive: widget.activeItemLabel == 'Identify and Staff Ops Team'));
    }
    if ('launch checklist'.contains(query) || 'launch'.contains(query)) {
      results.add(_buildMenuItem(Icons.rocket_launch_outlined, 'Launch Checklist', onTap: _openLaunchChecklist, isActive: widget.activeItemLabel == 'Launch Checklist'));
    }
    if ('deliverable roadmap'.contains(query) || 'deliverables'.contains(query) || 'roadmap'.contains(query)) {
      results.add(_buildMenuItem(Icons.map_outlined, 'Deliverable Roadmap', onTap: _openDeliverableRoadmap, isActive: widget.activeItemLabel == 'Deliverable Roadmap'));
    }
    if ('agile map out'.contains(query) || 'agile map'.contains(query) || 'map out'.contains(query)) {
      results.add(_buildMenuItem(Icons.timeline_outlined, 'Agile Map Out', onTap: _openDeliverableRoadmapAgileMapOut, isActive: widget.activeItemLabel == 'Deliverable Roadmap - Agile Map Out'));
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
    if ('project close out'.contains(query) || 'project closure'.contains(query) || 'closeout'.contains(query)) {
      results.add(_buildMenuItem(Icons.task_alt_outlined, 'Project Close Out - Long Form', onTap: _openProjectCloseOutLongForm, isActive: widget.activeItemLabel == 'Project Close Out - Long Form'));
    }
    if ('close out long form'.contains(query) || 'long form'.contains(query)) {
      results.add(_buildMenuItem(Icons.task_alt_outlined, 'Project Close Out - Long Form', onTap: _openProjectCloseOutLongForm, isActive: widget.activeItemLabel == 'Project Close Out - Long Form'));
    }
    if ('close out summarized form'.contains(query) || 'summarized form'.contains(query) || 'summary form'.contains(query) || 'close out summary'.contains(query)) {
      results.add(_buildMenuItem(Icons.task_alt_outlined, 'Project Close Out - Summarized Form', onTap: _openProjectCloseOutSummarized, isActive: widget.activeItemLabel == 'Project Close Out - Summarized Form'));
    }
    if ('demobilize team'.contains(query) || 'demobilize'.contains(query) || 'team ramp down'.contains(query) || 'wind down'.contains(query)) {
      results.add(_buildMenuItem(Icons.groups_outlined, 'Demobilize Team', onTap: _openDemobilizeTeam, isActive: widget.activeItemLabel == 'Demobilize Team'));
    }
    if ('actual vs planned'.contains(query) || 'gap analysis'.contains(query)) {
      results.add(_buildMenuItem(Icons.compare_arrows_outlined, 'Actual vs Planned Gap Analysis', onTap: _openActualVsPlannedGapAnalysis, isActive: widget.activeItemLabel == 'Actual vs Planned Gap Analysis'));
    }
    if ('scope reconcillation'.contains(query) || 'scope reconciliation'.contains(query)) {
      results.add(_buildMenuItem(Icons.compare_arrows_outlined, 'Scope Reconcillation', onTap: _openActualVsPlannedScopeReconcillation, isActive: widget.activeItemLabel == 'Actual vs Planned Gap Analysis - Scope Reconcillation'));
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
