import 'package:ndu_project/screens/execution_plan_lessons_learned_screen.dart';
import 'dart:async';
import 'package:ndu_project/screens/execution_plan_construction_plan_screen.dart';
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

class ExecutionPlanBestPracticesScreen extends StatelessWidget {
  const ExecutionPlanBestPracticesScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ExecutionPlanBestPracticesScreen()),
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
                  activeItemLabel: 'Execution Plan - Best Practices'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExecutionPlanHeader(
                        onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const SectionIntro(
                        title: 'Execution Plan - Best Practices'),
                    const SizedBox(height: 24),
                    const ExecutionPlanForm(
                      title: 'Execution Plan - Best Practices',
                      hintText:
                          'Document the best practices to follow during execution.',
                      noteKey: 'execution_best_practices',
                    ),
                    const SizedBox(height: 32),
                    const _BestPracticesSection(),
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

class _BestPracticesSection extends StatelessWidget {
  const _BestPracticesSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Best Practices',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _BestPracticesTable(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: AddRowButton(
              onPressed: () => _BestPracticesTable.showAddDialog(context)),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileBestPracticesActions()
        else
          const _DesktopBestPracticesActions(),
      ],
    );
  }
}

class _BestPracticesTable extends StatelessWidget {
  const _BestPracticesTable();

  String? _getProjectId(BuildContext context) {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  static String? _getProjectIdStatic(BuildContext context) {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  static void showAddDialog(BuildContext context) {
    final projectId = _getProjectIdStatic(context);
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    LessonsLearnedTable.showChangeRequestDialog(
        context, null, projectId, 'BP');
  }

  static void showEditDialog(
      BuildContext context, ExecutionIssueModel request) {
    final projectId = _getProjectIdStatic(context);
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    LessonsLearnedTable.showChangeRequestDialog(
        context, request, projectId, 'BP');
  }

  static void showDeleteDialog(
      BuildContext context, ExecutionIssueModel request) {
    final projectId = _getProjectIdStatic(context);
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Best Practice'),
        content: Text(
            'Are you sure you want to delete "${request.issueTopic}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ExecutionService.deleteChangeRequest(
                    projectId: projectId, requestId: request.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Best practice deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting best practice: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectId = _getProjectId(context);
    if (projectId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No project selected. Please open a project first.',
              style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    return StreamBuilder<List<ExecutionIssueModel>>(
      stream: ExecutionService.streamChangeRequests(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Error loading best practices: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        // Filter for Best Practices (BP)
        final allRequests = snapshot.data ?? [];
        final bestPractices = allRequests
            .where((r) => (r.llOrBp ?? '').toLowerCase().contains('bp'))
            .toList();

        const headerStyle = TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        );
        const cellStyle = TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4B5563),
          height: 1.5,
        );

        Widget buildCell(String text,
            {bool isHeader = false,
            TextAlign align = TextAlign.left,
            TextStyle? style}) {
          return Container(
            color: isHeader ? const Color(0xFFF3F4F6) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Text(
              text,
              textAlign: align,
              style: style ?? (isHeader ? headerStyle : cellStyle),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(70),
                1: FixedColumnWidth(130),
                2: FixedColumnWidth(120),
                3: FixedColumnWidth(130),
                4: FixedColumnWidth(130),
                5: FixedColumnWidth(130),
                6: FixedColumnWidth(130),
                7: FixedColumnWidth(130),
                8: FixedColumnWidth(130),
                9: FixedColumnWidth(150),
                10: FixedColumnWidth(100),
              },
              border: const TableBorder(
                horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
                verticalInside: BorderSide(color: Color(0xFFE5E7EB)),
                top: BorderSide(color: Color(0xFFE5E7EB)),
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
                left: BorderSide(color: Color(0xFFE5E7EB)),
                right: BorderSide(color: Color(0xFFE5E7EB)),
              ),
              children: [
                TableRow(
                  children: [
                    buildCell('No', isHeader: true, align: TextAlign.center),
                    buildCell('Topic', isHeader: true),
                    buildCell('LL or BP?', isHeader: true),
                    buildCell('Discipline', isHeader: true),
                    buildCell('Impacted', isHeader: true),
                    buildCell('Raised by', isHeader: true),
                    buildCell('Schedule', isHeader: true),
                    buildCell('Cost Impact', isHeader: true),
                    buildCell('Approved?', isHeader: true),
                    buildCell('Comments', isHeader: true),
                    buildCell('Actions',
                        isHeader: true, align: TextAlign.center),
                  ],
                ),
                if (bestPractices.isEmpty)
                  TableRow(
                    children: [
                      buildCell('', align: TextAlign.center),
                      buildCell('No best practices added yet',
                          style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontStyle: FontStyle.italic)),
                      buildCell(''),
                      buildCell(''),
                      buildCell(''),
                      buildCell(''),
                      buildCell(''),
                      buildCell(''),
                      buildCell(''),
                      buildCell(''),
                      buildCell(''),
                    ],
                  )
                else
                  ...bestPractices.asMap().entries.map((entry) {
                    final index = entry.key;
                    final request = entry.value;
                    return TableRow(
                      children: [
                        buildCell('${index + 1}', align: TextAlign.center),
                        buildCell(request.issueTopic),
                        buildCell(request.llOrBp ?? 'N/A'),
                        buildCell(request.discipline),
                        buildCell(request.impacted ?? 'N/A'),
                        buildCell(request.raisedBy),
                        buildCell(request.scheduleImpact),
                        buildCell(request.costImpact),
                        buildCell(request.approved ? 'Yes' : 'No'),
                        buildCell(request.comments),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 18),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    size: 18, color: Color(0xFF64748B)),
                                onPressed: () =>
                                    showEditDialog(context, request),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 18, color: Color(0xFFEF4444)),
                                onPressed: () =>
                                    showDeleteDialog(context, request),
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DesktopBestPracticesActions extends StatelessWidget {
  const _DesktopBestPracticesActions();

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
                    'Document proven approaches and methodologies for the team to follow consistently.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanConstructionPlanScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileBestPracticesActions extends StatelessWidget {
  const _MobileBestPracticesActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const InfoBadge(),
        const SizedBox(height: 20),
        const AiTipCard(
          text:
              'Document proven approaches and methodologies for the team to follow consistently.',
        ),
        const SizedBox(height: 20),
        YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanConstructionPlanScreen.open(context),
        ),
      ],
    );
  }
}
