
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

// Screens
import 'package:ndu_project/screens/landing_screen.dart';
import 'package:ndu_project/screens/sign_in_screen.dart';
import 'package:ndu_project/screens/create_account_screen.dart';
import 'package:ndu_project/screens/pricing_screen.dart';
import 'package:ndu_project/screens/settings_screen.dart';
import 'package:ndu_project/screens/project_dashboard_screen.dart';
import 'package:ndu_project/screens/program_dashboard_screen.dart';
import 'package:ndu_project/screens/portfolio_dashboard_screen.dart';
import 'package:ndu_project/screens/launch_checklist_screen.dart';
import 'package:ndu_project/screens/home_screen.dart';
import 'package:ndu_project/screens/lessons_learned_screen.dart';
import 'package:ndu_project/screens/management_level_screen.dart';
import 'package:ndu_project/screens/stakeholder_management_screen.dart';
import 'package:ndu_project/screens/core_stakeholders_screen.dart';

// Front-end planning cluster
import 'package:ndu_project/screens/front_end_planning_screen.dart';
import 'package:ndu_project/screens/front_end_planning_workspace_screen.dart';
import 'package:ndu_project/screens/front_end_planning_requirements_screen.dart';
import 'package:ndu_project/screens/front_end_planning_personnel_screen.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/screens/front_end_planning_contracts_screen.dart';
import 'package:ndu_project/screens/front_end_planning_contract_vendor_quotes_screen.dart';
import 'package:ndu_project/screens/front_end_planning_infrastructure_screen.dart';
import 'package:ndu_project/screens/front_end_planning_technology_screen.dart';
import 'package:ndu_project/screens/front_end_planning_technology_personnel_screen.dart';
import 'package:ndu_project/screens/front_end_planning_risks_screen.dart';
import 'package:ndu_project/screens/front_end_planning_allowance.dart';
import 'package:ndu_project/screens/front_end_planning_opportunities_screen.dart';
import 'package:ndu_project/screens/front_end_planning_summary.dart';
import 'package:ndu_project/screens/front_end_planning_summary_end.dart';
import 'package:ndu_project/screens/front_end_planning_security.dart';

// Project/Process cluster
import 'package:ndu_project/screens/project_plan_screen.dart';
import 'package:ndu_project/screens/project_framework_next_screen.dart';
import 'package:ndu_project/screens/project_charter_screen.dart';
import 'package:ndu_project/screens/project_decision_summary_screen.dart';
import 'package:ndu_project/screens/progress_tracking_screen.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'package:ndu_project/screens/execution_plan_screen.dart';
import 'package:ndu_project/screens/execution_plan_interface_management_overview_screen.dart';
import 'package:ndu_project/screens/cost_estimate_screen.dart';
import 'package:ndu_project/screens/cost_analysis_screen.dart';
import 'package:ndu_project/screens/potential_solutions_screen.dart';
import 'package:ndu_project/screens/preferred_solution_analysis_screen.dart';
import 'package:ndu_project/screens/risk_assessment_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/issue_management_screen.dart';
import 'package:ndu_project/screens/change_management_screen.dart';
import 'package:ndu_project/screens/schedule_screen.dart';
import 'package:ndu_project/screens/contract_details_dashboard_screen.dart';
import 'package:ndu_project/screens/schedule_management_board_screen.dart';

// Team cluster
import 'package:ndu_project/screens/team_management_screen.dart';
import 'package:ndu_project/screens/team_meetings_screen.dart';
import 'package:ndu_project/screens/team_roles_responsibilities_screen.dart';
import 'package:ndu_project/screens/team_training_building_screen.dart';
import 'package:ndu_project/screens/training_project_tasks_screen.dart';
import 'package:ndu_project/screens/staff_team_screen.dart';
import 'package:ndu_project/screens/infrastructure_considerations_screen.dart';
import 'package:ndu_project/screens/it_considerations_screen.dart';
import 'package:ndu_project/screens/security_management_screen.dart';

// Program basics / templates
import 'package:ndu_project/screens/program_basics_screen.dart';
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/screens/deliverables_roadmap_screen.dart';
import 'package:ndu_project/screens/deliver_project_closure_screen.dart';
import 'package:ndu_project/screens/transition_to_prod_team_screen.dart';
import 'package:ndu_project/screens/contract_close_out_screen.dart';
import 'package:ndu_project/screens/vendor_account_close_out_screen.dart';
import 'package:ndu_project/screens/ui_ux_design_screen.dart';
import 'package:ndu_project/screens/development_set_up_screen.dart';
import 'package:ndu_project/screens/technical_alignment_screen.dart';
import 'package:ndu_project/screens/long_lead_equipment_ordering_screen.dart';
import 'package:ndu_project/screens/technical_development_screen.dart';
import 'package:ndu_project/screens/tools_integration_screen.dart';
import 'package:ndu_project/screens/project_close_out_screen.dart';
import 'package:ndu_project/screens/demobilize_team_screen.dart';
import 'package:ndu_project/screens/summarize_account_risks_screen.dart';
import 'package:ndu_project/screens/agile_development_iterations_screen.dart';
import 'package:ndu_project/screens/engineering_design_screen.dart';
import 'package:ndu_project/screens/scope_completion_screen.dart';
import 'package:ndu_project/screens/requirements_implementation_screen.dart';
import 'package:ndu_project/screens/privacy_policy_screen.dart';
import 'package:ndu_project/screens/terms_conditions_screen.dart';
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

// SSHER suite
import 'package:ndu_project/screens/ssher_stacked_screen.dart';
import 'package:ndu_project/screens/ssher_screen_1.dart';
import 'package:ndu_project/screens/ssher_screen_2.dart';
import 'package:ndu_project/screens/ssher_screen_3.dart';
import 'package:ndu_project/screens/ssher_screen_4.dart';

// Admin (used in admin main entry)
import 'package:ndu_project/screens/admin/admin_home_screen.dart';
import 'package:ndu_project/screens/admin/admin_auth_wrapper.dart';

import 'package:ndu_project/screens/admin/admin_projects_screen.dart';
import 'package:ndu_project/screens/admin/admin_users_screen.dart';
import 'package:ndu_project/screens/admin/admin_coupons_screen.dart';
import 'package:ndu_project/screens/admin/admin_subscription_lookup_screen.dart';
import 'package:ndu_project/services/access_policy.dart';

/// Named route constants for consistency.
class AppRoutes {
  static const landing = 'landing';
  static const signIn = 'sign-in';
  static const createAccount = 'create-account';
  static const pricing = 'pricing';
  static const settings = 'settings';

  static const dashboard = 'dashboard';
  static const programDashboard = 'program-dashboard';
  static const portfolioDashboard = 'portfolio-dashboard';
  static const launchChecklist = 'launch-checklist';

  // FEP cluster
  static const fep = 'front-end-planning';
  static const fepWorkspace = 'fep-workspace';
  static const fepRequirements = 'fep-requirements';
  static const fepPersonnel = 'fep-personnel';
  static const fepProcurement = 'fep-procurement';
  static const fepContracts = 'fep-contracts';
  static const fepVendorQuotes = 'fep-contract-vendor-quotes';
  static const fepInfrastructure = 'fep-infrastructure';
  static const fepTechnology = 'fep-technology';
  static const fepTechnologyPersonnel = 'fep-technology-personnel';
  static const fepRisks = 'fep-risks';
  static const fepAllowance = 'fep-allowance';
  static const fepOpportunities = 'fep-opportunities';
  static const fepSummary = 'fep-summary';
  static const fepSummaryEnd = 'fep-summary-end';

  // Process cluster
  static const projectPlan = 'project-plan';
  static const projectFramework = 'project-framework';
  static const projectFrameworkNext = 'project-framework-next';
  static const projectCharter = 'project-charter';
  static const projectDecisionSummary = 'project-decision-summary';
  static const progressTracking = 'progress-tracking';
  static const wbs = 'work-breakdown-structure';
  static const executionPlan = 'execution-plan';
  static const executionPlanInterface = 'execution-plan-interface-management';
  static const costEstimate = 'cost-estimate';
  static const costAnalysis = 'cost-analysis';
  static const potentialSolutions = 'potential-solutions';
  static const preferredSolutionAnalysis = 'preferred-solution-analysis';
  static const riskAssessment = 'risk-assessment';
  static const riskIdentification = 'risk-identification';
  static const issueManagement = 'issue-management';
  static const changeManagement = 'change-management';
  static const schedule = 'schedule';
  static const contractDetails = 'contract-details';
  static const scheduleManagementBoard = 'schedule-management';

  // Team cluster
  static const teamManagement = 'team-management';
  static const teamMeetings = 'team-meetings';
  static const teamRoles = 'team-roles-responsibilities';
  static const teamTraining = 'team-training-building';
  static const trainingTasks = 'training-project-tasks';
  static const staffTeam = 'staff-team';
  static const infrastructureConsiderations = 'infrastructure-considerations';
  static const itConsiderations = 'it-considerations';
  static const securityManagement = 'security-management';

  // Program basics
  static const programBasics = 'program-basics';
  static const initiationPhase = 'initiation-phase';
  static const designPhase = 'design-phase';
  static const deliverablesRoadmap = 'deliverables-roadmap';
  static const managementLevel = 'management-level';
  static const home = 'home';
  static const lessonsLearned = 'lessons-learned';
  static const stakeholderManagement = 'stakeholder-management';
  static const coreStakeholders = 'core-stakeholders';
  static const fepSecurity = 'fep-security';
  static const deliverProjectClosure = 'deliver-project-closure';
  static const transitionToProdTeam = 'transition-to-prod-team';
  static const contractCloseOut = 'contract-close-out';
  static const vendorAccountCloseOut = 'vendor-account-close-out';
  static const uiUxDesign = 'ui-ux-design';
  static const developmentSetUp = 'development-set-up';
  static const technicalAlignment = 'technical-alignment';
  static const backendDesign = 'backend-design';
  static const longLeadEquipmentOrdering = 'long-lead-equipment-ordering';
  static const technicalDebtManagement = 'technical-debt-management';
  static const riskTracking = 'risk-tracking';
  static const identifyStaffOpsTeam = 'identify-staff-ops-team';
  static const contractsTracking = 'contracts-tracking';
  static const vendorTracking = 'vendor-tracking';
  static const detailedDesign = 'detailed-design';
  static const scopeTrackingImplementation = 'scope-tracking-implementation';
  static const stakeholderAlignment = 'stakeholder-alignment';
  static const updateOpsMaintenancePlans = 'update-ops-maintenance-plans';
  static const projectCloseOut = 'project-close-out';
  static const demobilizeTeam = 'demobilize-team';
  static const technicalDevelopment = 'technical-development';
  static const toolsIntegration = 'tools-integration';
  static const summarizeAccountRisks = 'summarize-account-risks';
  static const agileDevelopmentIterations = 'agile-development-iterations';
  static const engineeringDesign = 'engineering-design';
  static const scopeCompletion = 'scope-completion';
  static const requirementsImplementation = 'requirements-implementation';
  static const privacyPolicy = 'privacy-policy';
  static const termsConditions = 'terms-conditions';

  // SSHER suite
  static const ssherStacked = 'ssher-stacked';
  static const ssher1 = 'ssher-1';
  static const ssher2 = 'ssher-2';
  static const ssher3 = 'ssher-3';
  static const ssher4 = 'ssher-4';
  static const ssherFull = 'ssher-full';

  // Admin
  static const adminHome = 'admin-home';
  static const adminProjects = 'admin-projects';
  static const adminUsers = 'admin-users';
  static const adminCoupons = 'admin-coupons';
  static const adminSubscriptionLookup = 'admin-subscription-lookup';
}

/// A common redirect that checks web host policy when necessary.
String? _adminHostGuard(User? user) {
  if (AccessPolicy.isRestrictedAdminHost()) {
    final allowed = AccessPolicy.isEmailAllowedForAdmin(user?.email);
    if (!allowed) {
      // Block navigation by sending them to a neutral landing page
      return '/${AppRoutes.landing}';
    }
  }
  return null;
}

class AppRouter {
  // The primary router for the end-user app
  static final GoRouter main = GoRouter(
    debugLogDiagnostics: kDebugMode,
    initialLocation: '/',
    redirect: (context, state) {
      // Enforce admin-host policy if a user is present
      final user = FirebaseAuth.instance.currentUser;
      final blocked = _adminHostGuard(user);
      if (blocked != null) return blocked;

      // Friendly default: if authenticated and on the root, go to dashboard
      if (user != null && state.matchedLocation == '/') {
        return '/${AppRoutes.dashboard}';
      }
      return null;
    },
    routes: [
      GoRoute(
        name: AppRoutes.landing,
        path: '/',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        name: AppRoutes.signIn,
        path: '/${AppRoutes.signIn}',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        name: AppRoutes.createAccount,
        path: '/${AppRoutes.createAccount}',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        name: AppRoutes.pricing,
        path: '/${AppRoutes.pricing}',
        builder: (context, state) => const PricingScreen(),
      ),
      GoRoute(
        name: AppRoutes.settings,
        path: '/${AppRoutes.settings}',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Dashboards
      GoRoute(
        name: AppRoutes.dashboard,
        path: '/${AppRoutes.dashboard}',
        builder: (context, state) => const ProjectDashboardScreen(),
      ),
      GoRoute(
        name: AppRoutes.programDashboard,
        path: '/${AppRoutes.programDashboard}',
        builder: (context, state) => const ProgramDashboardScreen(),
      ),
      GoRoute(
        name: AppRoutes.portfolioDashboard,
        path: '/${AppRoutes.portfolioDashboard}',
        builder: (context, state) => const PortfolioDashboardScreen(),
      ),
      GoRoute(
        name: AppRoutes.launchChecklist,
        path: '/${AppRoutes.launchChecklist}',
        builder: (context, state) => const LaunchChecklistScreen(),
      ),

      // Supplemental entry points
      GoRoute(name: AppRoutes.home, path: '/${AppRoutes.home}', builder: (c, s) => const HomeScreen()),
      GoRoute(name: AppRoutes.managementLevel, path: '/${AppRoutes.managementLevel}', builder: (c, s) => const ManagementLevelScreen()),
      GoRoute(name: AppRoutes.lessonsLearned, path: '/${AppRoutes.lessonsLearned}', builder: (c, s) => const LessonsLearnedScreen()),
      GoRoute(name: AppRoutes.stakeholderManagement, path: '/${AppRoutes.stakeholderManagement}', builder: (c, s) => const StakeholderManagementScreen()),
      GoRoute(
        name: AppRoutes.coreStakeholders,
        path: '/${AppRoutes.coreStakeholders}',
        builder: (c, s) => const CoreStakeholdersScreen(notes: '', solutions: []),
      ),

      // FEP cluster
      GoRoute(name: AppRoutes.fep, path: '/${AppRoutes.fep}', builder: (c, s) => const FrontEndPlanningScreen()),
      GoRoute(name: AppRoutes.fepWorkspace, path: '/${AppRoutes.fepWorkspace}', builder: (c, s) => const FrontEndPlanningWorkspaceScreen()),
      GoRoute(name: AppRoutes.fepRequirements, path: '/${AppRoutes.fepRequirements}', builder: (c, s) => const FrontEndPlanningRequirementsScreen()),
      GoRoute(name: AppRoutes.fepPersonnel, path: '/${AppRoutes.fepPersonnel}', builder: (c, s) => const FrontEndPlanningPersonnelScreen()),
      GoRoute(name: AppRoutes.fepProcurement, path: '/${AppRoutes.fepProcurement}', builder: (c, s) => const FrontEndPlanningProcurementScreen()),
      GoRoute(name: AppRoutes.fepContracts, path: '/${AppRoutes.fepContracts}', builder: (c, s) => const FrontEndPlanningContractsScreen()),
      GoRoute(name: AppRoutes.fepVendorQuotes, path: '/${AppRoutes.fepVendorQuotes}', builder: (c, s) => const FrontEndPlanningContractVendorQuotesScreen()),
      GoRoute(name: AppRoutes.fepInfrastructure, path: '/${AppRoutes.fepInfrastructure}', builder: (c, s) => const FrontEndPlanningInfrastructureScreen()),
      GoRoute(name: AppRoutes.fepTechnology, path: '/${AppRoutes.fepTechnology}', builder: (c, s) => const FrontEndPlanningTechnologyScreen()),
      GoRoute(name: AppRoutes.fepTechnologyPersonnel, path: '/${AppRoutes.fepTechnologyPersonnel}', builder: (c, s) => const FrontEndPlanningTechnologyPersonnelScreen()),
      GoRoute(name: AppRoutes.fepRisks, path: '/${AppRoutes.fepRisks}', builder: (c, s) => const FrontEndPlanningRisksScreen()),
      GoRoute(name: AppRoutes.fepAllowance, path: '/${AppRoutes.fepAllowance}', builder: (c, s) => const FrontEndPlanningAllowanceScreen()),
      GoRoute(name: AppRoutes.fepOpportunities, path: '/${AppRoutes.fepOpportunities}', builder: (c, s) => const FrontEndPlanningOpportunitiesScreen()),
      GoRoute(name: AppRoutes.fepSummary, path: '/${AppRoutes.fepSummary}', builder: (c, s) => const FrontEndPlanningSummaryScreen()),
      GoRoute(name: AppRoutes.fepSummaryEnd, path: '/${AppRoutes.fepSummaryEnd}', builder: (c, s) => const FrontEndPlanningSummaryEndScreen()),
      GoRoute(name: AppRoutes.fepSecurity, path: '/${AppRoutes.fepSecurity}', builder: (c, s) => const FrontEndPlanningSecurityScreen()),

      // Process cluster
      GoRoute(name: AppRoutes.projectPlan, path: '/${AppRoutes.projectPlan}', builder: (c, s) => const ProjectPlanScreen()),
      GoRoute(name: AppRoutes.projectFramework, path: '/${AppRoutes.projectFramework}', builder: (c, s) => const ProjectManagementFrameworkScreen()),
      GoRoute(name: AppRoutes.projectFrameworkNext, path: '/${AppRoutes.projectFrameworkNext}', builder: (c, s) => const ProjectFrameworkNextScreen()),
      GoRoute(name: AppRoutes.projectCharter, path: '/${AppRoutes.projectCharter}', builder: (c, s) => const ProjectCharterScreen()),
      GoRoute(
        name: AppRoutes.projectDecisionSummary,
        path: '/${AppRoutes.projectDecisionSummary}',
        builder: (c, s) => ProjectDecisionSummaryScreen(
          projectName: 'Untitled Project',
          selectedSolution: AiSolutionItem(title: 'TBD Solution', description: 'Draft placeholder'),
          allSolutions: const [],
          businessCase: '',
          notes: '',
        ),
      ),
      GoRoute(name: AppRoutes.progressTracking, path: '/${AppRoutes.progressTracking}', builder: (c, s) => const ProgressTrackingScreen()),
      GoRoute(name: AppRoutes.wbs, path: '/${AppRoutes.wbs}', builder: (c, s) => const WorkBreakdownStructureScreen()),
      GoRoute(name: AppRoutes.executionPlan, path: '/${AppRoutes.executionPlan}', builder: (c, s) => const ExecutionPlanScreen()),
      GoRoute(name: AppRoutes.executionPlanInterface, path: '/${AppRoutes.executionPlanInterface}', builder: (c, s) => const ExecutionPlanInterfaceManagementOverviewScreen()),
      GoRoute(name: AppRoutes.costEstimate, path: '/${AppRoutes.costEstimate}', builder: (c, s) => const CostEstimateScreen()),
      GoRoute(
        name: AppRoutes.costAnalysis,
        path: '/${AppRoutes.costAnalysis}',
        builder: (c, s) => const CostAnalysisScreen(notes: '', solutions: []),
      ),
      GoRoute(name: AppRoutes.potentialSolutions, path: '/${AppRoutes.potentialSolutions}', builder: (c, s) => const PotentialSolutionsScreen()),
      GoRoute(
        name: AppRoutes.preferredSolutionAnalysis,
        path: '/${AppRoutes.preferredSolutionAnalysis}',
        builder: (c, s) => const PreferredSolutionAnalysisScreen(notes: '', solutions: [], businessCase: ''),
      ),
      GoRoute(name: AppRoutes.riskAssessment, path: '/${AppRoutes.riskAssessment}', builder: (c, s) => const RiskAssessmentScreen()),
      GoRoute(
        name: AppRoutes.riskIdentification,
        path: '/${AppRoutes.riskIdentification}',
        builder: (c, s) => const RiskIdentificationScreen(notes: '', solutions: []),
      ),
      GoRoute(name: AppRoutes.issueManagement, path: '/${AppRoutes.issueManagement}', builder: (c, s) => const IssueManagementScreen()),
      GoRoute(name: AppRoutes.changeManagement, path: '/${AppRoutes.changeManagement}', builder: (c, s) => const ChangeManagementScreen()),
      GoRoute(name: AppRoutes.schedule, path: '/${AppRoutes.schedule}', builder: (c, s) => const ScheduleScreen()),
      GoRoute(name: AppRoutes.contractDetails, path: '/${AppRoutes.contractDetails}', builder: (c, s) => const ContractDetailsDashboardScreen()),
      GoRoute(name: AppRoutes.scheduleManagementBoard, path: '/${AppRoutes.scheduleManagementBoard}', builder: (c, s) => const ScheduleManagementBoardScreen()),

      // Team cluster
      GoRoute(name: AppRoutes.teamManagement, path: '/${AppRoutes.teamManagement}', builder: (c, s) => const TeamManagementScreen()),
      GoRoute(name: AppRoutes.teamMeetings, path: '/${AppRoutes.teamMeetings}', builder: (c, s) => const TeamMeetingsScreen()),
      GoRoute(name: AppRoutes.teamRoles, path: '/${AppRoutes.teamRoles}', builder: (c, s) => const TeamRolesResponsibilitiesScreen()),
      GoRoute(name: AppRoutes.teamTraining, path: '/${AppRoutes.teamTraining}', builder: (c, s) => const TeamTrainingAndBuildingScreen()),
      GoRoute(name: AppRoutes.trainingTasks, path: '/${AppRoutes.trainingTasks}', builder: (c, s) => const TrainingProjectTasksScreen()),
      GoRoute(name: AppRoutes.staffTeam, path: '/${AppRoutes.staffTeam}', builder: (c, s) => const StaffTeamScreen()),
      GoRoute(
        name: AppRoutes.infrastructureConsiderations,
        path: '/${AppRoutes.infrastructureConsiderations}',
        builder: (c, s) => const InfrastructureConsiderationsScreen(notes: '', solutions: []),
      ),
      GoRoute(
        name: AppRoutes.itConsiderations,
        path: '/${AppRoutes.itConsiderations}',
        builder: (c, s) => const ITConsiderationsScreen(notes: '', solutions: []),
      ),
      GoRoute(name: AppRoutes.securityManagement, path: '/${AppRoutes.securityManagement}', builder: (c, s) => const SecurityManagementScreen()),

      // Program basics
      GoRoute(name: AppRoutes.programBasics, path: '/${AppRoutes.programBasics}', builder: (c, s) => const ProgramBasicsScreen()),
      GoRoute(name: AppRoutes.initiationPhase, path: '/${AppRoutes.initiationPhase}', builder: (c, s) => const InitiationPhaseScreen()),
      GoRoute(name: AppRoutes.designPhase, path: '/${AppRoutes.designPhase}', builder: (c, s) => const DesignPhaseScreen()),
      GoRoute(name: AppRoutes.requirementsImplementation, path: '/${AppRoutes.requirementsImplementation}', builder: (c, s) => const RequirementsImplementationScreen()),
      GoRoute(name: AppRoutes.deliverablesRoadmap, path: '/${AppRoutes.deliverablesRoadmap}', builder: (c, s) => const DeliverablesRoadmapScreen()),
      GoRoute(name: AppRoutes.deliverProjectClosure, path: '/${AppRoutes.deliverProjectClosure}', builder: (c, s) => const DeliverProjectClosureScreen()),
      GoRoute(name: AppRoutes.transitionToProdTeam, path: '/${AppRoutes.transitionToProdTeam}', builder: (c, s) => const TransitionToProdTeamScreen()),
      GoRoute(name: AppRoutes.contractCloseOut, path: '/${AppRoutes.contractCloseOut}', builder: (c, s) => const ContractCloseOutScreen()),
      GoRoute(name: AppRoutes.vendorAccountCloseOut, path: '/${AppRoutes.vendorAccountCloseOut}', builder: (c, s) => const VendorAccountCloseOutScreen()),
      GoRoute(name: AppRoutes.uiUxDesign, path: '/${AppRoutes.uiUxDesign}', builder: (c, s) => const UiUxDesignScreen()),
      GoRoute(name: AppRoutes.developmentSetUp, path: '/${AppRoutes.developmentSetUp}', builder: (c, s) => const DevelopmentSetUpScreen()),
      GoRoute(name: AppRoutes.technicalAlignment, path: '/${AppRoutes.technicalAlignment}', builder: (c, s) => const TechnicalAlignmentScreen()),
      GoRoute(name: AppRoutes.backendDesign, path: '/${AppRoutes.backendDesign}', builder: (c, s) => const BackendDesignScreen()),
      GoRoute(name: AppRoutes.longLeadEquipmentOrdering, path: '/${AppRoutes.longLeadEquipmentOrdering}', builder: (c, s) => const LongLeadEquipmentOrderingScreen()),
      GoRoute(name: AppRoutes.projectCloseOut, path: '/${AppRoutes.projectCloseOut}', builder: (c, s) => const ProjectCloseOutScreen()),
      GoRoute(name: AppRoutes.demobilizeTeam, path: '/${AppRoutes.demobilizeTeam}', builder: (c, s) => const DemobilizeTeamScreen()),
      GoRoute(name: AppRoutes.technicalDevelopment, path: '/${AppRoutes.technicalDevelopment}', builder: (c, s) => const TechnicalDevelopmentScreen()),
      GoRoute(name: AppRoutes.toolsIntegration, path: '/${AppRoutes.toolsIntegration}', builder: (c, s) => const ToolsIntegrationScreen()),
      GoRoute(name: AppRoutes.summarizeAccountRisks, path: '/${AppRoutes.summarizeAccountRisks}', builder: (c, s) => const SummarizeAccountRisksScreen()),
      GoRoute(name: AppRoutes.agileDevelopmentIterations, path: '/${AppRoutes.agileDevelopmentIterations}', builder: (c, s) => const AgileDevelopmentIterationsScreen()),
      GoRoute(name: AppRoutes.engineeringDesign, path: '/${AppRoutes.engineeringDesign}', builder: (c, s) => const EngineeringDesignScreen()),
      GoRoute(name: AppRoutes.scopeCompletion, path: '/${AppRoutes.scopeCompletion}', builder: (c, s) => const ScopeCompletionScreen()),
      GoRoute(name: AppRoutes.technicalDebtManagement, path: '/${AppRoutes.technicalDebtManagement}', builder: (c, s) => const TechnicalDebtManagementScreen()),
      GoRoute(name: AppRoutes.riskTracking, path: '/${AppRoutes.riskTracking}', builder: (c, s) => const RiskTrackingScreen()),
      GoRoute(name: AppRoutes.identifyStaffOpsTeam, path: '/${AppRoutes.identifyStaffOpsTeam}', builder: (c, s) => const IdentifyStaffOpsTeamScreen()),
      GoRoute(name: AppRoutes.contractsTracking, path: '/${AppRoutes.contractsTracking}', builder: (c, s) => const ContractsTrackingScreen()),
      GoRoute(name: AppRoutes.vendorTracking, path: '/${AppRoutes.vendorTracking}', builder: (c, s) => const VendorTrackingScreen()),
      GoRoute(name: AppRoutes.detailedDesign, path: '/${AppRoutes.detailedDesign}', builder: (c, s) => const DetailedDesignScreen()),
      GoRoute(name: AppRoutes.scopeTrackingImplementation, path: '/${AppRoutes.scopeTrackingImplementation}', builder: (c, s) => const ScopeTrackingImplementationScreen()),
      GoRoute(name: AppRoutes.stakeholderAlignment, path: '/${AppRoutes.stakeholderAlignment}', builder: (c, s) => const StakeholderAlignmentScreen()),
      GoRoute(name: AppRoutes.updateOpsMaintenancePlans, path: '/${AppRoutes.updateOpsMaintenancePlans}', builder: (c, s) => const UpdateOpsMaintenancePlansScreen()),
      GoRoute(name: AppRoutes.privacyPolicy, path: '/${AppRoutes.privacyPolicy}', builder: (c, s) => const PrivacyPolicyScreen()),
      GoRoute(name: AppRoutes.termsConditions, path: '/${AppRoutes.termsConditions}', builder: (c, s) => const TermsConditionsScreen()),

      // SSHER suite
      GoRoute(name: AppRoutes.ssherStacked, path: '/${AppRoutes.ssherStacked}', builder: (c, s) => const SsherStackedScreen()),
      GoRoute(name: AppRoutes.ssher1, path: '/${AppRoutes.ssher1}', builder: (c, s) => const SsherScreen1()),
      GoRoute(name: AppRoutes.ssher2, path: '/${AppRoutes.ssher2}', builder: (c, s) => const SsherScreen2()),
      GoRoute(name: AppRoutes.ssher3, path: '/${AppRoutes.ssher3}', builder: (c, s) => const SsherScreen3()),
      GoRoute(name: AppRoutes.ssher4, path: '/${AppRoutes.ssher4}', builder: (c, s) => const SsherScreen4()),
      // SafetyFullViewScreen requires constructor data; reachable via the SSHER flow, not direct URL
    ],
    errorBuilder: (context, state) {
      return _RouteNotFound(path: state.uri.toString());
    },
  );

  // Admin router: used by lib/main_admin.dart
  static final GoRouter admin = GoRouter(
    debugLogDiagnostics: kDebugMode,
    initialLocation: '/',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final block = _adminHostGuard(user);
      if (block != null) return block;
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (c, s) => const AdminAuthWrapper()),
      GoRoute(name: AppRoutes.signIn, path: '/${AppRoutes.signIn}', builder: (c, s) => const SignInScreen()),
      GoRoute(name: AppRoutes.adminHome, path: '/${AppRoutes.adminHome}', builder: (c, s) => const AdminHomeScreen()),
      GoRoute(name: AppRoutes.adminProjects, path: '/${AppRoutes.adminProjects}', builder: (c, s) => const AdminProjectsScreen()),
      GoRoute(name: AppRoutes.adminUsers, path: '/${AppRoutes.adminUsers}', builder: (c, s) => const AdminUsersScreen()),
      GoRoute(name: AppRoutes.adminCoupons, path: '/${AppRoutes.adminCoupons}', builder: (c, s) => const AdminCouponsScreen()),
      GoRoute(name: AppRoutes.adminSubscriptionLookup, path: '/${AppRoutes.adminSubscriptionLookup}', builder: (c, s) => const AdminSubscriptionLookupScreen()),
    ],
    errorBuilder: (context, state) => _RouteNotFound(path: state.uri.toString()),
  );
}

class _RouteNotFound extends StatelessWidget {
  const _RouteNotFound({required this.path});
  final String path;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.travel_explore, color: t.colorScheme.primary, size: 32),
                    const SizedBox(width: 12),
                    Text('Page not found', style: t.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 8),
                Text('We couldn\'t find "$path". Check the URL or use navigation.', style: t.textTheme.bodyMedium),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.go('/${AppRoutes.dashboard}'),
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Go to dashboard'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
