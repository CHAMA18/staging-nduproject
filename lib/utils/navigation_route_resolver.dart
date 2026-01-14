import 'package:flutter/material.dart';
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/potential_solutions_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/it_considerations_screen.dart';
import 'package:ndu_project/screens/infrastructure_considerations_screen.dart';
import 'package:ndu_project/screens/core_stakeholders_screen.dart';
import 'package:ndu_project/screens/cost_analysis_screen.dart';
import 'package:ndu_project/screens/preferred_solution_analysis_screen.dart';
import 'package:ndu_project/screens/front_end_planning_summary.dart';
import 'package:ndu_project/screens/front_end_planning_requirements_screen.dart';
import 'package:ndu_project/screens/front_end_planning_risks_screen.dart';
import 'package:ndu_project/screens/front_end_planning_opportunities_screen.dart';
import 'package:ndu_project/screens/front_end_planning_contract_vendor_quotes_screen.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/screens/front_end_planning_security.dart';
import 'package:ndu_project/screens/front_end_planning_allowance.dart';
import 'package:ndu_project/screens/project_charter_screen.dart';
import 'package:ndu_project/screens/project_framework_screen.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'package:ndu_project/screens/ssher_stacked_screen.dart';
import 'package:ndu_project/screens/change_management_screen.dart';
import 'package:ndu_project/screens/issue_management_screen.dart';
import 'package:ndu_project/screens/cost_estimate_screen.dart';
import 'package:ndu_project/screens/scope_tracking_plan_screen.dart';
import 'package:ndu_project/screens/front_end_planning_contracts_screen.dart';
import 'package:ndu_project/screens/project_plan_screen.dart';
import 'package:ndu_project/screens/execution_plan_screen.dart';
import 'package:ndu_project/screens/schedule_screen.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/screens/front_end_planning_technology_screen.dart';
import 'package:ndu_project/screens/interface_management_screen.dart';
import 'package:ndu_project/screens/startup_planning_screen.dart';
import 'package:ndu_project/screens/deliverables_roadmap_screen.dart';
import 'package:ndu_project/screens/project_baseline_screen.dart';
import 'package:ndu_project/screens/agile_project_baseline_screen.dart';
import 'package:ndu_project/screens/team_management_screen.dart';
import 'package:ndu_project/screens/stakeholder_management_screen.dart';
import 'package:ndu_project/screens/risk_assessment_screen.dart';
import 'package:ndu_project/screens/security_management_screen.dart';
import 'package:ndu_project/screens/quality_management_screen.dart';
import 'package:ndu_project/screens/ui_ux_design_screen.dart';
import 'package:ndu_project/screens/backend_design_screen.dart';
import 'package:ndu_project/screens/engineering_design_screen.dart';
import 'package:ndu_project/screens/technical_alignment_screen.dart';
import 'package:ndu_project/screens/development_set_up_screen.dart';
import 'package:ndu_project/screens/tools_integration_screen.dart';
import 'package:ndu_project/screens/long_lead_equipment_ordering_screen.dart';
import 'package:ndu_project/screens/specialized_design_screen.dart';
import 'package:ndu_project/screens/design_deliverables_screen.dart';
import 'package:ndu_project/screens/staff_team_screen.dart';
import 'package:ndu_project/screens/team_meetings_screen.dart';
import 'package:ndu_project/screens/progress_tracking_screen.dart';
import 'package:ndu_project/screens/contracts_tracking_screen.dart';
import 'package:ndu_project/screens/vendor_tracking_screen.dart';
import 'package:ndu_project/screens/detailed_design_screen.dart';
import 'package:ndu_project/screens/agile_development_iterations_screen.dart';
import 'package:ndu_project/screens/scope_tracking_implementation_screen.dart';
import 'package:ndu_project/screens/stakeholder_alignment_screen.dart';
import 'package:ndu_project/screens/update_ops_maintenance_plans_screen.dart';
import 'package:ndu_project/screens/launch_checklist_screen.dart';
import 'package:ndu_project/screens/risk_tracking_screen.dart';
import 'package:ndu_project/screens/scope_completion_screen.dart';
import 'package:ndu_project/screens/gap_analysis_scope_reconcillation_screen.dart';
import 'package:ndu_project/screens/punchlist_actions_screen.dart';
import 'package:ndu_project/screens/technical_debt_management_screen.dart';
import 'package:ndu_project/screens/identify_staff_ops_team_screen.dart';
import 'package:ndu_project/screens/salvage_disposal_team_screen.dart';
import 'package:ndu_project/screens/deliver_project_closure_screen.dart';
import 'package:ndu_project/screens/transition_to_prod_team_screen.dart';
import 'package:ndu_project/screens/contract_close_out_screen.dart';
import 'package:ndu_project/screens/vendor_account_close_out_screen.dart';
import 'package:ndu_project/screens/summarize_account_risks_screen.dart';
import 'package:ndu_project/screens/project_close_out_screen.dart';
import 'package:ndu_project/screens/demobilize_team_screen.dart';
import 'package:ndu_project/screens/requirements_implementation_screen.dart';
import 'package:ndu_project/screens/technical_development_screen.dart';
import 'package:ndu_project/screens/lessons_learned_screen.dart';
import 'package:ndu_project/screens/team_roles_responsibilities_screen.dart';
import 'package:ndu_project/screens/team_training_building_screen.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

/// Utility that maps checkpoint strings to screen widgets for dynamic routing
class NavigationRouteResolver {
  NavigationRouteResolver._();

  /// Resolve a checkpoint string to a Widget screen
  /// Returns null if checkpoint is invalid or unknown
  static Widget? resolveCheckpointToScreen(String? checkpoint, BuildContext context) {
    if (checkpoint == null || checkpoint.isEmpty || checkpoint == 'initiation') {
      return const InitiationPhaseScreen();
    }

    final provider = ProjectDataInherited.maybeOf(context);
    final projectData = provider?.projectData;

    // Helper to build solution items
    List<AiSolutionItem> buildSolutionItems(ProjectDataModel? data) {
      if (data == null) return [];
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

    switch (checkpoint) {
      // Initiation Phase
      case 'business_case':
        return const InitiationPhaseScreen(scrollToBusinessCase: true);
      case 'potential_solutions':
        return const PotentialSolutionsScreen();
      case 'risk_identification':
        return RiskIdentificationScreen(
          notes: projectData?.notes ?? '',
          solutions: buildSolutionItems(projectData),
          businessCase: projectData?.businessCase ?? '',
        );
      case 'it_considerations':
        return ITConsiderationsScreen(
          notes: projectData?.itConsiderationsData?.notes ?? projectData?.notes ?? '',
          solutions: buildSolutionItems(projectData),
        );
      case 'infrastructure_considerations':
        return InfrastructureConsiderationsScreen(
          notes: projectData?.infrastructureConsiderationsData?.notes ?? projectData?.notes ?? '',
          solutions: buildSolutionItems(projectData),
        );
      case 'core_stakeholders':
        return CoreStakeholdersScreen(
          notes: projectData?.coreStakeholdersData?.notes ?? projectData?.notes ?? '',
          solutions: buildSolutionItems(projectData),
        );
      case 'cost_analysis':
        return CostAnalysisScreen(
          notes: projectData?.notes ?? '',
          solutions: buildSolutionItems(projectData),
        );
      case 'preferred_solution_analysis':
        return PreferredSolutionAnalysisScreen(
          notes: projectData?.preferredSolutionAnalysis?.workingNotes ?? '',
          solutions: buildSolutionItems(projectData),
          businessCase: projectData?.businessCase ?? '',
        );

      // Front End Planning
      case 'fep_summary':
        return const FrontEndPlanningSummaryScreen();
      case 'fep_requirements':
        return const FrontEndPlanningRequirementsScreen();
      case 'fep_risks':
        return const FrontEndPlanningRisksScreen();
      case 'fep_opportunities':
        return const FrontEndPlanningOpportunitiesScreen();
      case 'fep_contract_vendor_quotes':
        return const FrontEndPlanningContractVendorQuotesScreen();
      case 'fep_procurement':
        return const FrontEndPlanningProcurementScreen();
      case 'fep_security':
        return const FrontEndPlanningSecurityScreen();
      case 'fep_allowance':
        return const FrontEndPlanningAllowanceScreen();
      case 'project_charter':
        return const ProjectCharterScreen();

      // Planning Phase
      case 'project_framework':
        return const ProjectFrameworkScreen();
      case 'work_breakdown_structure':
        return const WorkBreakdownStructureScreen();
      case 'ssher':
        return const SsherStackedScreen();
      case 'change_management':
        return ChangeManagementScreen();
      case 'issue_management':
        return const IssueManagementScreen();
      case 'cost_estimate':
        return const CostEstimateScreen();
      case 'scope_tracking_plan':
        return const ScopeTrackingPlanScreen();
      case 'contracts':
        return const FrontEndPlanningContractsScreen();
      case 'project_plan':
        return const ProjectPlanScreen();
      case 'execution_plan':
        return const ExecutionPlanScreen();
      case 'schedule':
        return const ScheduleScreen();
      case 'design':
      case 'design_management':
        return const DesignPhaseScreen(activeItemLabel: 'Design');
      case 'technology':
        return const FrontEndPlanningTechnologyScreen();
      case 'interface_management':
        return const InterfaceManagementScreen();
      case 'startup_planning':
        return const StartUpPlanningScreen();
      case 'deliverable_roadmap':
        return const DeliverablesRoadmapScreen();
      case 'agile_project_baseline':
        return const AgileProjectBaselineScreen();
      case 'project_baseline':
        return const ProjectBaselineScreen();
      case 'organization_roles_responsibilities':
        return const TeamRolesResponsibilitiesScreen();
      case 'organization_staffing_plan':
        return const StaffTeamScreen();
      case 'team_training':
        return const TeamTrainingAndBuildingScreen();
      case 'stakeholder_management':
        return const StakeholderManagementScreen();
      case 'lessons_learned':
        return const LessonsLearnedScreen();
      case 'team_management':
        return const TeamManagementScreen();
      case 'risk_assessment':
        return const RiskAssessmentScreen();
      case 'security_management':
        return const SecurityManagementScreen();
      case 'quality_management':
        return const QualityManagementScreen();

      // Design Phase
      case 'requirements_implementation':
        return const RequirementsImplementationScreen();
      case 'technical_alignment':
        return const TechnicalAlignmentScreen();
      case 'development_set_up':
        return const DevelopmentSetUpScreen();
      case 'ui_ux_design':
        return const UiUxDesignScreen();
      case 'backend_design':
        return const BackendDesignScreen();
      case 'engineering_design':
        return const EngineeringDesignScreen();
      case 'technical_development':
        return const TechnicalDevelopmentScreen();
      case 'tools_integration':
        return const ToolsIntegrationScreen();
      case 'long_lead_equipment_ordering':
        return const LongLeadEquipmentOrderingScreen();
      case 'specialized_design':
        return const SpecializedDesignScreen();
      case 'design_deliverables':
        return const DesignDeliverablesScreen();

      // Execution Phase
      case 'staff_team':
        return const StaffTeamScreen();
      case 'team_meetings':
        return const TeamMeetingsScreen();
      case 'progress_tracking':
        return const ProgressTrackingScreen();
      case 'contracts_tracking':
        return const ContractsTrackingScreen();
      case 'vendor_tracking':
        return const VendorTrackingScreen();
      case 'detailed_design':
        return const DetailedDesignScreen();
      case 'agile_development_iterations':
        return const AgileDevelopmentIterationsScreen();
      case 'scope_tracking_implementation':
        return const ScopeTrackingImplementationScreen();
      case 'stakeholder_alignment':
        return const StakeholderAlignmentScreen();
      case 'update_ops_maintenance_plans':
        return const UpdateOpsMaintenancePlansScreen();
      case 'launch_checklist':
        return const LaunchChecklistScreen();
      case 'risk_tracking':
        return const RiskTrackingScreen();
      case 'scope_completion':
        return const ScopeCompletionScreen();
      case 'gap_analysis_scope_reconcillation':
        return const GapAnalysisScopeReconcillationScreen(activeItemLabel: 'Gap Analysis and Scope Reconciliation');
      case 'punchlist_actions':
        return const PunchlistActionsScreen();
      case 'technical_debt_management':
        return const TechnicalDebtManagementScreen();
      case 'identify_staff_ops_team':
        return const IdentifyStaffOpsTeamScreen();
      case 'salvage_disposal_team':
        return const SalvageDisposalTeamScreen();

      // Launch Phase
      case 'deliver_project_closure':
        return const DeliverProjectClosureScreen();
      case 'transition_to_prod_team':
        return const TransitionToProdTeamScreen();
      case 'contract_close_out':
        return const ContractCloseOutScreen();
      case 'vendor_account_close_out':
        return const VendorAccountCloseOutScreen();
      case 'summarize_account_risks':
        return const SummarizeAccountRisksScreen();
      case 'project_close_out':
        return const ProjectCloseOutScreen();
      case 'demobilize_team':
        return const DemobilizeTeamScreen();

      default:
        debugPrint('⚠️ Unknown checkpoint: $checkpoint, defaulting to InitiationPhaseScreen');
        return const InitiationPhaseScreen();
    }
  }
}
