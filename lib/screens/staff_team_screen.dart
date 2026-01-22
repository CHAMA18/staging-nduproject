import 'package:flutter/material.dart';
import 'package:ndu_project/screens/design_deliverables_screen.dart';
import 'package:ndu_project/screens/team_meetings_screen.dart';
import 'package:ndu_project/widgets/execution_phase_page.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';

class StaffTeamScreen extends StatelessWidget {
  const StaffTeamScreen({super.key});

  static void open(BuildContext context) {
    PhaseTransitionHelper.pushPhaseAware(
      context: context,
      builder: (_) => const StaffTeamScreen(),
      destinationCheckpoint: 'staff_team',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExecutionPhasePage(
      pageKey: 'staff_team',
      title: 'Staff Team Orchestration',
      subtitle: 'Execution Phase',
      sections: [
        ExecutionSectionSpec(
          key: 'staffingNeeds',
          title: 'Staffing needs',
          description: 'Capture roles, pods, or capabilities you need to staff.',
          includeStatus: true,
          titleLabel: 'Role / capability',
        ),
        ExecutionSectionSpec(
          key: 'onboardingActions',
          title: 'Onboarding actions',
          description: 'List onboarding steps and owners to get people productive.',
          includeStatus: true,
          titleLabel: 'Action / owner',
        ),
        ExecutionSectionSpec(
          key: 'coverageRisks',
          title: 'Coverage risks',
          description: 'Document gaps or risks in team coverage.',
          includeStatus: true,
          titleLabel: 'Risk',
        ),
      ],
      navigation: PhaseNavigationSpec(
        backLabel: 'Back: Design Deliverables',
        nextLabel: 'Next: Team Meetings',
        onBack: () => DesignDeliverablesScreen.open(context),
        onNext: () => TeamMeetingsScreen.open(context),
      ),
    );
  }
}
