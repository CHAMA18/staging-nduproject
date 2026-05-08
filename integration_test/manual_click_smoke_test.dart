import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ndu_project/firebase_options.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/providers/app_content_provider.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/front_end_planning_allowance.dart';
import 'package:ndu_project/screens/front_end_planning_opportunities_screen.dart';
import 'package:ndu_project/screens/project_charter_screen.dart';
import 'package:ndu_project/screens/team_training_building_screen.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:provider/provider.dart';

ProjectDataProvider _providerWith(ProjectDataModel data) {
  final provider = ProjectDataProvider();
  provider.updateProjectData(data);
  return provider;
}

ProjectDataModel _seedData({
  List<String> opportunityApplyTo = const [],
  List<String> allowanceApplyTo = const [],
}) {
  return ProjectDataModel(
    projectName: 'Smoke Pass Project',
    solutionTitle: 'Operational Automation',
    solutionDescription: 'Automate key front-end planning workflows.',
    businessCase: 'Seeded for smoke testing.',
    projectGoals: [
      ProjectGoal(name: 'Reduce cycle time', description: 'Improve delivery')
    ],
    charterAssumptions: 'Stable staffing levels',
    charterConstraints: 'Budget cap applies',
    frontEndPlanning: FrontEndPlanningData(
      opportunityItems: [
        OpportunityItem(
          id: 'opp-smoke-1',
          opportunity: 'Automate manual approval workflow',
          discipline: 'Operations',
          stakeholder: 'Operations Manager',
          potentialCostSavings: '50000',
          potentialScheduleSavings: '4 weeks',
          appliesTo: opportunityApplyTo,
          assignedTo: 'Program Manager',
        ),
      ],
      allowanceItems: [
        AllowanceItem(
          id: 'allow-smoke-1',
          number: 1,
          name: 'Training and readiness reserve',
          type: 'Training',
          amount: 15000,
          appliesTo: allowanceApplyTo,
          assignedTo: 'HR Lead',
          notes: 'Enable rollout and onboarding',
        ),
      ],
    ),
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required ProjectDataProvider provider,
  required Widget screen,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 1024));
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectDataProvider>.value(value: provider),
        ChangeNotifierProvider<AppContentProvider>(
            create: (_) => AppContentProvider()),
      ],
      child: Builder(
        builder: (context) {
          final projectProvider =
              Provider.of<ProjectDataProvider>(context, listen: false);
          return ProjectDataInherited(
            provider: projectProvider,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: screen,
            ),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> _toggleOpportunityApplyTo(
  WidgetTester tester,
  String menuLabel,
) async {
  await tester.tap(find.byTooltip('Actions').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(menuLabel).last);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  });

  testWidgets(
      'Screen 1 - Opportunities: toggling Apply To updates propagated data',
      (tester) async {
    final provider = _providerWith(_seedData());
    await _pumpScreen(
      tester,
      provider: provider,
      screen: const FrontEndPlanningOpportunitiesScreen(),
    );

    expect(find.text('Project Opportunities'), findsOneWidget);

    await _toggleOpportunityApplyTo(tester, 'Apply to Estimate');
    await _toggleOpportunityApplyTo(tester, 'Apply to Schedule');
    await _toggleOpportunityApplyTo(tester, 'Apply to Training');

    final updated = provider.projectData;
    final tags = updated.frontEndPlanning.opportunityItems.first.appliesTo;
    expect(tags.contains('Estimate'), isTrue);
    expect(tags.contains('Schedule'), isTrue);
    expect(tags.contains('Training'), isTrue);
    expect(
      updated.keyMilestones
          .any((m) => m.comments.contains('[AUTO_APPLY_SCHEDULE]')),
      isTrue,
    );
    expect(
      updated.trainingActivities
          .any((a) => a.id.startsWith('auto_apply_training_opp_')),
      isTrue,
    );
    expect(
      (updated.costAnalysisData?.benefitLineItems ?? const <BenefitLineItem>[])
          .any((b) => b.id.startsWith('auto_apply_benefit_opp_')),
      isTrue,
    );
  });

  testWidgets('Screen 2 - Allowance: toggling chips updates propagated data',
      (tester) async {
    final provider = _providerWith(_seedData());
    await _pumpScreen(
      tester,
      provider: provider,
      screen: const FrontEndPlanningAllowanceScreen(),
    );

    expect(find.text('Allowance & Contingency Items'), findsOneWidget);

    await tester.tap(find.text('Estimate').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Training').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Schedule').first);
    await tester.pumpAndSettle();

    final updated = provider.projectData;
    final tags = updated.frontEndPlanning.allowanceItems.first.appliesTo;
    expect(tags.contains('Estimate'), isTrue);
    expect(tags.contains('Schedule'), isTrue);
    expect(tags.contains('Training'), isTrue);
    expect(
      updated.costEstimateItems
          .any((e) => e.id.startsWith('auto_apply_cost_allow_')),
      isTrue,
    );
    expect(
      updated.trainingActivities
          .any((a) => a.id.startsWith('auto_apply_training_allow_')),
      isTrue,
    );
    expect(
      updated.keyMilestones
          .any((m) => m.comments.contains('[AUTO_APPLY_SCHEDULE]')),
      isTrue,
    );
  });

  testWidgets('Screen 3 - Project Charter: propagated entries are visible',
      (tester) async {
    final seeded = _seedData(
      opportunityApplyTo: const ['Estimate', 'Schedule', 'Training'],
      allowanceApplyTo: const ['Estimate', 'Schedule', 'Training'],
    );
    final applied = ProjectDataHelper.applyTaggedFrontEndPlanningData(seeded);
    final provider = _providerWith(applied);

    await _pumpScreen(
      tester,
      provider: provider,
      screen: const ProjectCharterScreen(),
    );

    expect(find.text('Project Charter'), findsWidgets);
    expect(find.text('TENTATIVE SCHEDULE'), findsOneWidget);
    expect(find.textContaining('Opportunity:'), findsWidgets);
    expect(find.textContaining('Allowance:'), findsWidgets);
    expect(find.text('TOTAL ESTIMATED COST'), findsOneWidget);
    expect(find.text('EXPECTED BENEFIT'), findsOneWidget);
  });

  testWidgets(
      'Screen 4 - Team Training: propagated opportunity and allowance activities are visible',
      (tester) async {
    final seeded = _seedData(
      opportunityApplyTo: const ['Training'],
      allowanceApplyTo: const ['Training'],
    );
    final applied = ProjectDataHelper.applyTaggedFrontEndPlanningData(seeded);
    final provider = _providerWith(applied);

    await _pumpScreen(
      tester,
      provider: provider,
      screen: const TeamTrainingAndBuildingScreen(),
    );

    expect(find.text('Team Training and Team Building'), findsOneWidget);
    expect(find.textContaining('Opportunity Follow-up:'), findsWidgets);
    expect(find.textContaining('Allowance Readiness:'), findsWidgets);
  });
}
