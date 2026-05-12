import 'package:flutter_test/flutter_test.dart';
import 'package:ndu_project/models/project_activity.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/project_intelligence_service.dart';

void main() {
  test('builds unified activities from front-end planning inputs', () {
    final data = ProjectDataModel(
      withinScopeItems: [
        PlanningDashboardItem(description: 'Set up bakery retail area'),
      ],
      frontEndPlanning: FrontEndPlanningData(
        opportunityItems: [
          OpportunityItem(
            id: 'opp_1',
            opportunity: 'Automate approval workflow',
            discipline: 'Operations',
            stakeholder: 'Program Manager',
            potentialCostSavings: '50000',
            potentialScheduleSavings: '4 weeks',
            appliesTo: const ['Estimate', 'Training'],
            assignedTo: 'Operations Lead',
          ),
        ],
        allowanceItems: [
          AllowanceItem(
            id: 'allow_1',
            number: 1,
            name: 'Training reserve',
            type: 'Training',
            amount: 15000,
            appliesTo: const ['Schedule'],
            notes: 'Enable onboarding readiness',
          ),
        ],
        requirementItems: [
          RequirementItem(
            description: 'Integrate vendor order API',
            requirementType: 'Technical',
          ),
        ],
        riskRegisterItems: [
          RiskRegisterItem(
            riskName: 'Supplier delay',
            impactLevel: 'High',
            likelihood: 'Medium',
            mitigationStrategy: 'Early procurement package',
          ),
        ],
      ),
    );

    final enriched = ProjectIntelligenceService.rebuildActivityLog(data);
    final ids = enriched.projectActivities.map((e) => e.id).toSet();

    expect(ids.contains('activity_opp_opp_1'), isTrue);
    expect(ids.contains('activity_allow_allow_1'), isTrue);
    expect(ids.contains('activity_req_0'), isTrue);
    expect(ids.contains('activity_risk_0'), isTrue);
    expect(ids.contains('activity_scope_in_0'), isTrue);

    final opportunity = enriched.projectActivities
        .firstWhere((item) => item.id == 'activity_opp_opp_1');
    expect(opportunity.applicableSections.contains('cost_analysis'), isTrue);
    expect(opportunity.applicableSections.contains('team_training'), isTrue);
    expect(opportunity.status, ProjectActivityStatus.pending);
    expect(opportunity.approvalStatus, ProjectApprovalStatus.draft);
  });

  test('preserves lifecycle fields when rebuilding existing activity IDs', () {
    final existing = ProjectActivity(
      id: 'activity_opp_opp_1',
      title: 'Automate approval workflow',
      description: 'Existing activity',
      sourceSection: 'fep_opportunities',
      phase: 'Front End Planning',
      discipline: 'Operations',
      role: 'Program Manager',
      assignedTo: 'Specific Owner',
      applicableSections: const ['project_charter'],
      dueDate: '2026-05-31',
      status: ProjectActivityStatus.implemented,
      approvalStatus: ProjectApprovalStatus.locked,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    final data = ProjectDataModel(
      projectActivities: [existing],
      frontEndPlanning: FrontEndPlanningData(
        opportunityItems: [
          OpportunityItem(
            id: 'opp_1',
            opportunity: 'Automate approval workflow',
            discipline: 'Operations',
            stakeholder: 'Program Manager',
            appliesTo: const ['Estimate'],
            assignedTo: '',
          ),
        ],
      ),
    );

    final enriched = ProjectIntelligenceService.rebuildActivityLog(data);
    final activity = enriched.projectActivities
        .firstWhere((item) => item.id == 'activity_opp_opp_1');

    expect(activity.status, ProjectActivityStatus.implemented);
    expect(activity.approvalStatus, ProjectApprovalStatus.locked);
    expect(activity.dueDate, '2026-05-31');
    expect(activity.assignedTo, 'Specific Owner');
    expect(activity.createdAt, DateTime.utc(2026, 1, 1));
  });
}
