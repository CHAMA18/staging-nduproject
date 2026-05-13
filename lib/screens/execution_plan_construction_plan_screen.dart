import 'package:ndu_project/screens/execution_plan_agile_delivery_plan_screen.dart';
import 'dart:async';
import 'package:ndu_project/screens/execution_plan_infrastructure_plan_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/execution_plan_shared.dart';
import 'package:ndu_project/widgets/ai_suggesting_textfield.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/execution_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';

class ExecutionPlanConstructionPlanScreen extends StatelessWidget {
  const ExecutionPlanConstructionPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ExecutionPlanConstructionPlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Execution Plan - Construction Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExecutionPlanHeader(
                      onBack: () => PlanningPhaseNavigation.goToPrevious(
                          context, 'execution_plan_construction_plan'),
                      onNext: () => PlanningPhaseNavigation.goToNext(
                          context, 'execution_plan_construction_plan'),
                    ),
                    const SizedBox(height: 32),
                    const SectionIntro(
                        title: 'Execution Plan - Construction Plan'),
                    const SizedBox(height: 24),
                    const ExecutionPlanForm(
                      title: 'Execution Plan - Construction Plan',
                      hintText:
                          'Summarize construction sequencing, logistics, and safety constraints.',
                      noteKey: 'execution_construction_plan',
                      showDiagram: false,
                    ),
                    const SizedBox(height: 32),
                    const _ConstructionPlanSection(),
                    const SizedBox(height: 56),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstructionPlanSection extends StatelessWidget {
  const _ConstructionPlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Construction Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 24),
        const PlanDecisionSection(
          question: 'Will construction work be done by this project?',
          planKeyPrefix: 'execution_construction_plan',
          formTitle: 'Construction Plan Inputs',
          formSubtitle:
              'Capture the sequencing, resources, and controls needed to deliver construction work safely.',
          fields: [
            PlanFieldConfig(
              keyName: 'scope',
              label: 'Scope & work packages',
              hint: 'Define in-scope components, exclusions, and deliverables.',
              minLines: 2,
              maxLines: 4,
              fullWidth: true,
            ),
            PlanFieldConfig(
              keyName: 'sequencing',
              label: 'Sequencing & milestones',
              hint: 'Outline phases, key handoffs, and milestone dates.',
              minLines: 2,
              maxLines: 4,
            ),
            PlanFieldConfig(
              keyName: 'resources',
              label: 'Resources & contractors',
              hint: 'List crews, vendors, and specialist roles.',
              minLines: 2,
              maxLines: 4,
            ),
            PlanFieldConfig(
              keyName: 'logistics',
              label: 'Site logistics & access',
              hint: 'Access, staging, equipment, and material flow.',
              minLines: 2,
              maxLines: 4,
            ),
            PlanFieldConfig(
              keyName: 'safety',
              label: 'Safety, compliance & QA/QC',
              hint: 'HSE controls, permits, inspections, and quality checks.',
              minLines: 2,
              maxLines: 4,
              fullWidth: true,
            ),
            PlanFieldConfig(
              keyName: 'risks',
              label: 'Risks & contingencies',
              hint: 'Key risks, dependencies, and mitigation actions.',
              minLines: 2,
              maxLines: 4,
              fullWidth: true,
            ),
          ],
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileConstructionPlanActions()
        else
          const _DesktopConstructionPlanActions(),
      ],
    );
  }
}

class _DesktopConstructionPlanActions extends StatelessWidget {
  const _DesktopConstructionPlanActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const AiTipCard(
                text:
                    'Outline the construction sequencing, resource allocation, and safety protocols.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInfrastructurePlanScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileConstructionPlanActions extends StatelessWidget {
  const _MobileConstructionPlanActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const InfoBadge(),
        const SizedBox(height: 20),
        const AiTipCard(
          text:
              'Outline the construction sequencing, resource allocation, and safety protocols.',
        ),
        const SizedBox(height: 20),
        YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInfrastructurePlanScreen.open(context),
        ),
      ],
    );
  }
}
