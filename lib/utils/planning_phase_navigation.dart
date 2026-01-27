import 'package:flutter/material.dart';
import 'package:ndu_project/screens/project_framework_screen.dart';
import 'package:ndu_project/screens/project_framework_next_screen.dart';
import 'package:ndu_project/screens/work_breakdown_structure_screen.dart';
import 'package:ndu_project/screens/planning_requirements_screen.dart';
import 'package:ndu_project/screens/front_end_planning_personnel_screen.dart';
import 'package:ndu_project/screens/organization_plan_subsections_screen.dart';
import 'package:ndu_project/screens/team_training_building_screen.dart';
import 'package:ndu_project/screens/stakeholder_management_screen.dart';
import 'package:ndu_project/screens/ssher_stacked_screen.dart';
import 'package:ndu_project/screens/quality_management_screen.dart';
import 'package:ndu_project/screens/execution_plan_screen.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/screens/front_end_planning_technology_screen.dart';
import 'package:ndu_project/screens/interface_management_screen.dart';
import 'package:ndu_project/screens/risk_assessment_screen.dart';
import 'package:ndu_project/screens/front_end_planning_contracts_screen.dart';
import 'package:ndu_project/screens/front_end_planning_procurement_screen.dart';
import 'package:ndu_project/screens/schedule_screen.dart';
import 'package:ndu_project/screens/cost_estimate_screen.dart';
import 'package:ndu_project/screens/scope_tracking_plan_screen.dart';
import 'package:ndu_project/screens/change_management_screen.dart';
import 'package:ndu_project/screens/issue_management_screen.dart';
import 'package:ndu_project/screens/lessons_learned_screen.dart';
import 'package:ndu_project/screens/startup_planning_screen.dart';
import 'package:ndu_project/screens/deliverables_roadmap_screen.dart';
import 'package:ndu_project/screens/deliverable_roadmap_subsections_screen.dart';
import 'package:ndu_project/screens/project_plan_screen.dart';
import 'package:ndu_project/screens/project_baseline_screen.dart';

class PlanningPhaseNavigation {
  
  static final List<PlanningPage> pages = [
    PlanningPage(
      id: 'project_details',
      title: 'Project Details',
      builder: (_) => const ProjectFrameworkScreen(),
    ),
    PlanningPage(
      id: 'wbs',
      title: 'Work Breakdown Structure',
      builder: (_) => const WorkBreakdownStructureScreen(),
    ),
    PlanningPage(
      id: 'project_goals_milestones',
      title: 'Project Goals & Milestones',
      builder: (_) => const ProjectFrameworkNextScreen(),
    ),
    PlanningPage(
      id: 'requirements',
      title: 'Requirements',
      builder: (_) => const PlanningRequirementsScreen(),
    ),
    // Organization Plan Group
    PlanningPage(
      id: 'organization_roles_responsibilities',
      title: 'Roles and Responsibilities',
      builder: (_) => const OrganizationRolesResponsibilitiesScreen(),
    ),
    PlanningPage(
      id: 'organization_staffing_plan',
      title: 'Staffing Plan',
      builder: (_) => const OrganizationStaffingPlanScreen(),
    ),
    PlanningPage(
      id: 'team_training',
      title: 'Training & Team Building',
      builder: (_) => const TeamTrainingAndBuildingScreen(),
    ),
    PlanningPage(
      id: 'stakeholder_management',
      title: 'Stakeholder Management',
      builder: (_) => const StakeholderManagementScreen(),
    ),
    // End Organization Plan Group
    
    PlanningPage(
      id: 'ssher',
      title: 'SSHER',
      builder: (_) => const SsherStackedScreen(),
    ),
    PlanningPage(
      id: 'quality_management',
      title: 'Quality',
      builder: (_) => const QualityManagementScreen(),
    ),
    PlanningPage(
      id: 'execution_plan',
      title: 'Execution Plan',
      builder: (_) => const ExecutionPlanScreen(),
    ),
    PlanningPage(
      id: 'design_planning',
      title: 'Design Planning',
      builder: (_) => const DesignPhaseScreen(activeItemLabel: 'Design'),
    ),
    PlanningPage(
      id: 'technology',
      title: 'Technology',
      builder: (_) => const FrontEndPlanningTechnologyScreen(),
    ),
    PlanningPage(
      id: 'interface_management',
      title: 'Interface Management',
      builder: (_) => const InterfaceManagementScreen(),
    ),
    PlanningPage(
      id: 'risk_management',
      title: 'Risk Management',
      builder: (_) => const RiskAssessmentScreen(),
    ),
    PlanningPage(
      id: 'contract_management',
      title: 'Contract Management',
      builder: (_) => const FrontEndPlanningContractsScreen(),
    ),
    PlanningPage(
      id: 'procurement',
      title: 'Procurement',
      builder: (_) => const FrontEndPlanningProcurementScreen(),
    ),
    PlanningPage(
      id: 'schedule',
      title: 'Schedule',
      builder: (_) => const ScheduleScreen(),
    ),
    PlanningPage(
      id: 'cost_estimate',
      title: 'Cost Estimate',
      builder: (_) => const CostEstimateScreen(),
    ),
    PlanningPage(
      id: 'project_services',
      title: 'Project Services',
      builder: (_) => const ScopeTrackingPlanScreen(), // Represents Project Services -> Scope Tracking as per sidebar
    ),
    PlanningPage(
      id: 'change_management',
      title: 'Change Management',
      builder: (_) => ChangeManagementScreen(),
    ),
    PlanningPage(
      id: 'issue_management',
      title: 'Issues Management',
      builder: (_) => const IssueManagementScreen(),
    ),
    PlanningPage(
      id: 'lessons_learned',
      title: 'Lessons Learned',
      builder: (_) => const LessonsLearnedScreen(),
    ),
    PlanningPage(
      id: 'startup_planning',
      title: 'Start-up Planning',
      builder: (_) => const StartUpPlanningScreen(),
    ),
    PlanningPage(
      id: 'deliverables_roadmap',
      title: 'Deliverables Roadmap',
      builder: (_) => const DeliverablesRoadmapScreen(),
    ),
    PlanningPage(
      id: 'agile_project_wireframe',
      title: 'Agile Project Wireframe',
      builder: (_) => const DeliverableRoadmapAgileMapOutScreen(),
    ),
    PlanningPage(
      id: 'project_plan',
      title: 'Project Plan',
      builder: (_) => const ProjectPlanScreen(),
    ),
    PlanningPage(
      id: 'project_baseline',
      title: 'Project Baseline',
      builder: (_) => const ProjectBaselineScreen(),
    ),
  ];

  static int getPageIndex(String id) {
    return pages.indexWhere((p) => p.id == id);
  }

  static void navigateToNext(BuildContext context, String currentId) {
    int index = getPageIndex(currentId);
    if (index != -1 && index < pages.length - 1) {
      final nextPage = pages[index + 1];
      Navigator.of(context).push(
        MaterialPageRoute(builder: nextPage.builder),
      );
    } else {
       // If last page, maybe go to home or show completion?
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('End of Planning Phase navigation path.')),
       );
    }
  }

  static void navigateToPrevious(BuildContext context, String currentId) {
    // Usually handled by Navigator.pop, but if we need explicit back flow:
    int index = getPageIndex(currentId);
    if (index > 0) {
       Navigator.of(context).pop(); 
    }
  }
}

class PlanningPage {
  final String id;
  final String title;
  final WidgetBuilder builder;

  PlanningPage({required this.id, required this.title, required this.builder});
}
