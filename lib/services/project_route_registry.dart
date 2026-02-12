import 'package:flutter/material.dart';
import 'package:ndu_project/services/sidebar_navigation_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

// Screen Imports
import 'package:ndu_project/screens/project_framework_screen.dart';
import 'package:ndu_project/screens/project_framework_next_screen.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'package:ndu_project/screens/planning_requirements_screen.dart';
import 'package:ndu_project/screens/organization_plan_subsections_screen.dart';
import 'package:ndu_project/screens/team_training_building_screen.dart';
import 'package:ndu_project/screens/stakeholder_management_screen.dart';
import 'package:ndu_project/screens/ssher_stacked_screen.dart';
import 'package:ndu_project/screens/quality_management_screen.dart';
import 'package:ndu_project/screens/execution_plan_screen.dart';
import 'package:ndu_project/screens/design_planning_screen.dart';
import 'package:ndu_project/screens/front_end_planning_technology_screen.dart';
import 'package:ndu_project/screens/interface_management_screen.dart';
import 'package:ndu_project/screens/risk_assessment_screen.dart';
import 'package:ndu_project/screens/front_end_planning_contracts_screen.dart';
import 'package:ndu_project/screens/schedule_screen.dart';
import 'package:ndu_project/screens/cost_estimate_screen.dart';
import 'package:ndu_project/screens/scope_tracking_plan_screen.dart';
import 'package:ndu_project/screens/change_management_screen.dart';
import 'package:ndu_project/screens/issue_management_screen.dart';
import 'package:ndu_project/screens/lessons_learned_screen.dart';
import 'package:ndu_project/screens/startup_planning_screen.dart';
import 'package:ndu_project/screens/deliverables_roadmap_screen.dart';
import 'package:ndu_project/screens/agile_project_baseline_screen.dart';
import 'package:ndu_project/screens/project_plan_screen.dart';
import 'package:ndu_project/screens/project_baseline_screen.dart';

/// Central registry for mapping Planning Phase checkpoints to their corresponding screen widgets.
/// This allows dynamic navigation that automatically follows the sidebar order.
class ProjectRouteRegistry {
  ProjectRouteRegistry._();

  /// Maps Planning Phase checkpoints to their corresponding screen widgets
  static final Map<String, Widget Function()> _screens = {
    'project_framework': () => const ProjectFrameworkScreen(),
    'project_goals_milestones': () => const ProjectFrameworkNextScreen(),
    'work_breakdown_structure': () => const WorkBreakdownStructureScreen(),
    'requirements': () => const PlanningRequirementsScreen(),
    'organization_roles_responsibilities': () =>
        const OrganizationRolesResponsibilitiesScreen(),
    'organization_staffing_plan': () => const OrganizationStaffingPlanScreen(),
    'team_training': () => const TeamTrainingAndBuildingScreen(),
    'stakeholder_management': () => const StakeholderManagementScreen(),
    'ssher': () => const SsherStackedScreen(),
    'quality_management': () => const QualityManagementScreen(),
    'execution_plan': () => const ExecutionPlanScreen(),
    'design': () => const DesignPlanningScreen(),
    'technology': () => const FrontEndPlanningTechnologyScreen(),
    'interface_management': () => const InterfaceManagementScreen(),
    'risk_assessment': () => const RiskAssessmentScreen(),
    'contracts': () => const FrontEndPlanningContractsScreen(),
    'schedule': () => const ScheduleScreen(),
    'cost_estimate': () => const CostEstimateScreen(),
    'scope_tracking_plan': () => const ScopeTrackingPlanScreen(),
    'change_management': () => const ChangeManagementScreen(),
    'issue_management': () => const IssueManagementScreen(),
    'lessons_learned': () => const LessonsLearnedScreen(),
    'startup_planning': () => const StartUpPlanningScreen(),
    'deliverable_roadmap': () => const DeliverablesRoadmapScreen(),
    'agile_project_baseline': () => const AgileProjectBaselineScreen(),
    'project_plan': () => const ProjectPlanScreen(),
    'project_baseline': () => const ProjectBaselineScreen(),
  };

  /// Get a screen widget by checkpoint (with BuildContext for future extensibility)
  static Widget? getScreen(BuildContext? context, String checkpoint) {
    return _screens[checkpoint]?.call();
  }

  /// Get the next accessible screen based on current checkpoint and plan type
  static Widget? getNextScreen(BuildContext context, String currentCheckpoint) {
    final isBasicPlan = ProjectDataHelper.getData(context).isBasicPlanProject;
    final nextItem = SidebarNavigationService.instance
        .getNextAccessibleItem(currentCheckpoint, isBasicPlan);
    return nextItem != null ? getScreen(context, nextItem.checkpoint) : null;
  }

  /// Get all Planning Phase checkpoints in order
  static List<String> getAllPlanningCheckpoints() {
    return _screens.keys.toList();
  }
}
