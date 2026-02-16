import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/screens/execution_plan_interface_management_overview_screen.dart';
import 'package:ndu_project/widgets/ai_suggesting_textfield.dart';
import 'package:ndu_project/widgets/ai_diagram_panel.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/services/execution_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/screens/quality_management_screen.dart';
import 'package:ndu_project/screens/design_planning_screen.dart';

const Map<String, String> _executionCheckpointAlias = {
  'execution_plan_outline': 'execution_plan',
  'execution_lessons_learned': 'execution_plan_lessons_learned',
  'execution_best_practices': 'execution_plan_best_practices',
  'execution_construction_plan': 'execution_plan_construction_plan',
  'execution_infrastructure_plan': 'execution_plan_infrastructure_plan',
  'execution_agile_delivery_plan': 'execution_plan_agile_delivery_plan',
  'execution_interface_management': 'execution_plan_interface_management',
  'execution_communication_plan': 'execution_plan_communication_plan',
  'execution_interface_management_plan':
      'execution_plan_interface_management_plan',
  'execution_stakeholder_identification':
      'execution_plan_stakeholder_identification',
  'execution_plan_interface_overview':
      'execution_plan_interface_management_overview',
};

String _resolveExecutionCheckpoint(String key) {
  final trimmed = key.trim();
  if (trimmed.isEmpty) return 'execution_plan';
  return _executionCheckpointAlias[trimmed] ?? trimmed;
}

class ExecutionPlanScreen extends StatefulWidget {
  const ExecutionPlanScreen({super.key});

  @override
  State<ExecutionPlanScreen> createState() => _ExecutionPlanScreenState();
}

class _ExecutionPlanScreenState extends State<ExecutionPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final pid = provider?.projectData.projectId;
      if (pid != null && pid.isNotEmpty) {
        // Save this page as the last visited page for the project
        await ProjectNavigationService.instance
            .saveLastPage(pid, 'execution_plan');
      }
    });
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
                  activeItemLabel: 'Execution Plan Overview'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                      onBack: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const QualityManagementScreen()),
                      ),
                      onNext: () =>
                          ExecutionPlanConstructionPlanScreen.open(context),
                    ),
                    const SizedBox(height: 32),
                    const _SectionIntro(),
                    const SizedBox(height: 28),
                    _ExecutionPlanForm(
                      hintText:
                          'Describe the sequential, and overall, thought process for executing the project',
                      noteKey: 'execution_plan_outline',
                    ),
                    const SizedBox(height: 48),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.end,
                        children: [
                          const _InfoBadge(),
                          const _AiTipCard(),
                          _YellowActionButton(
                            label: 'Next',
                            onPressed: () =>
                                ExecutionPlanConstructionPlanScreen.open(
                                    context),
                          ),
                        ],
                      ),
                    ),
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

class _ExecutionPlanHeader extends StatelessWidget {
  const _ExecutionPlanHeader({required this.onBack, this.onNext});

  final VoidCallback onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
              const SizedBox(width: 12),
              _CircleIconButton(
                  icon: Icons.arrow_forward_ios_rounded, onTap: onNext),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Execution Plan',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const _CurrentUserProfileChip(),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _CurrentUserProfileChip extends StatelessWidget {
  const _CurrentUserProfileChip();

  String _initials(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r"\s+"));
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final photoUrl = user?.photoURL;
    final email = user?.email ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        _initials(displayName),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563)),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                  ),
                  Text(
                    role,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({this.title = 'Executive Plan Outline'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Outline the strategy and actions for the implementation phase.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _ExecutionPlanForm extends StatefulWidget {
  const _ExecutionPlanForm({
    this.title = 'Executive Plan Outline',
    required this.hintText,
    this.noteKey,
    this.showDiagram = true,
  });

  final String title;
  final String hintText;
  final String? noteKey;
  final bool showDiagram;

  @override
  State<_ExecutionPlanForm> createState() => _ExecutionPlanFormState();
}

class _ExecutionPlanFormState extends State<_ExecutionPlanForm> {
  String _currentText = '';
  Timer? _saveDebounce;
  DateTime? _lastSavedAt;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _currentText = value;
    final noteKey = widget.noteKey;
    if (noteKey == null || noteKey.trim().isEmpty) return;
    final checkpoint = _resolveExecutionCheckpoint(noteKey);
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () async {
      final trimmed = value.trim();
      final success = await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: checkpoint,
        dataUpdater: (data) {
          final currentExecutionData =
              data.executionPhaseData ?? ExecutionPhaseData();
          final updatedExecutionData = (noteKey == 'execution_plan_outline')
              ? currentExecutionData.copyWith(executionPlanOutline: trimmed)
              : (noteKey == 'execution_plan_strategy')
                  ? currentExecutionData.copyWith(
                      executionPlanStrategy: trimmed)
                  : currentExecutionData;

          return data.copyWith(
            executionPhaseData: updatedExecutionData,
            planningNotes: {
              ...data.planningNotes,
              noteKey:
                  trimmed, // Keep in planningNotes for backward compatibility
            },
          );
        },
        showSnackbar: false,
      );
      if (mounted && success) {
        setState(() => _lastSavedAt = DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final noteKey = widget.noteKey;
    if (noteKey != null && _currentText.isEmpty) {
      final projectData = ProjectDataHelper.getData(context);
      String saved = '';

      // Try to load from executionPhaseData first
      if (noteKey == 'execution_plan_outline') {
        saved = projectData.executionPhaseData?.executionPlanOutline ?? '';
      } else if (noteKey == 'execution_plan_strategy') {
        saved = projectData.executionPhaseData?.executionPlanStrategy ?? '';
      }

      // Fallback to planningNotes for backward compatibility
      if (saved.isEmpty) {
        saved = projectData.planningNotes[noteKey] ?? '';
      }

      if (saved.trim().isNotEmpty) {
        _currentText = saved;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AiSuggestingTextField(
          fieldLabel: widget.title,
          hintText: widget.hintText,
          sectionLabel: 'Execution Plan',
          showLabel: true,
          initialText: noteKey == null
              ? null
              : () {
                  final projectData = ProjectDataHelper.getData(context);
                  // Try executionPhaseData first
                  if (noteKey == 'execution_plan_outline') {
                    return projectData
                            .executionPhaseData?.executionPlanOutline ??
                        projectData.planningNotes[noteKey];
                  } else if (noteKey == 'execution_plan_strategy') {
                    return projectData
                            .executionPhaseData?.executionPlanStrategy ??
                        projectData.planningNotes[noteKey];
                  }
                  // Fallback to planningNotes
                  return projectData.planningNotes[noteKey];
                }(),
          autoGenerate: true,
          autoGenerateSection: widget.title,
          onChanged: _handleChanged,
        ),
        if (_lastSavedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Saved ${TimeOfDay.fromDateTime(_lastSavedAt!).format(context)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        if (widget.showDiagram)
          AiDiagramPanel(
            sectionLabel: widget.title,
            currentTextProvider: () => _currentText,
            title: 'Generate ${widget.title} Diagram',
          ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFDAE9FF),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB)),
    );
  }
}

class _AiTipCard extends StatelessWidget {
  const _AiTipCard({this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE1EEFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AiBadge(),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              text ??
                  'Focus on major risks associated with each potential solution.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.auto_awesome, size: 16, color: Color(0xFFF59E0B)),
          SizedBox(width: 6),
          Text(
            'AI',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}

class _YellowActionButton extends StatelessWidget {
  const _YellowActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class ExecutionPlanSolutionsScreen extends StatelessWidget {
  const ExecutionPlanSolutionsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionPlanSolutionsScreen()),
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
                  activeItemLabel: 'Executive Plan Strategy'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                        onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 24),
                    const _TeamSummaryCard(),
                    const SizedBox(height: 28),
                    const _SectionIntro(title: 'Executive Plan Strategy'),
                    const SizedBox(height: 28),
                    _ExecutionPlanForm(
                      title: 'Executive Plan Strategy',
                      hintText: 'Input your notes here...',
                      noteKey: 'execution_plan_strategy',
                    ),
                    const SizedBox(height: 28),
                    const _ExecutionPlanTable(),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _AddSolutionButton(
                          onPressed: () =>
                              _ExecutionPlanTable.showAddDialog(context)),
                    ),
                    const SizedBox(height: 44),
                    Wrap(
                      spacing: 20,
                      runSpacing: 16,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const _InfoBadge(),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.end,
                          children: [
                            const _AiTipCard(),
                            _YellowActionButton(
                              label: 'Next',
                              onPressed: () =>
                                  ExecutionPlanDetailsScreen.open(context),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _TeamSummaryCard extends StatelessWidget {
  const _TeamSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFF4B5563)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'StackOne',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '12 Members',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExecutionPlanTable extends StatelessWidget {
  const _ExecutionPlanTable();

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
    _showToolDialog(context, null, projectId);
  }

  static void showEditDialog(BuildContext context, ExecutionToolModel tool) {
    final projectId = _getProjectIdStatic(context);
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showToolDialog(context, tool, projectId);
  }

  static void showDeleteDialog(BuildContext context, ExecutionToolModel tool) {
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
        title: const Text('Delete Tool'),
        content: Text(
            'Are you sure you want to delete "${tool.tool}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ExecutionService.deleteTool(
                    projectId: projectId, toolId: tool.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tool deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting tool: $e')),
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

  static void _showToolDialog(
      BuildContext context, ExecutionToolModel? tool, String projectId) {
    final isEdit = tool != null;
    final toolController = TextEditingController(text: tool?.tool ?? '');
    final descriptionController =
        TextEditingController(text: tool?.description ?? '');
    final sourceController = TextEditingController(text: tool?.source ?? '');
    final costController = TextEditingController(text: tool?.cost ?? '');
    final commentsController =
        TextEditingController(text: tool?.comments ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Tool' : 'Add New Tool'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: toolController,
                  decoration: const InputDecoration(labelText: 'Tool *')),
              const SizedBox(height: 12),
              TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 2),
              const SizedBox(height: 12),
              TextField(
                  controller: sourceController,
                  decoration: const InputDecoration(labelText: 'Source *')),
              const SizedBox(height: 12),
              TextField(
                  controller: costController,
                  decoration: const InputDecoration(
                      labelText: 'Cost', hintText: 'Optional')),
              const SizedBox(height: 12),
              TextField(
                  controller: commentsController,
                  decoration: const InputDecoration(labelText: 'Comments *'),
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (toolController.text.isEmpty ||
                  descriptionController.text.isEmpty ||
                  sourceController.text.isEmpty ||
                  commentsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill in all required fields')),
                );
                return;
              }

              try {
                if (isEdit) {
                  await ExecutionService.updateTool(
                    projectId: projectId,
                    toolId: tool.id,
                    tool: toolController.text,
                    description: descriptionController.text,
                    source: sourceController.text,
                    cost: costController.text.isEmpty
                        ? null
                        : costController.text,
                    comments: commentsController.text,
                  );
                } else {
                  await ExecutionService.createTool(
                    projectId: projectId,
                    tool: toolController.text,
                    description: descriptionController.text,
                    source: sourceController.text,
                    cost: costController.text.isEmpty
                        ? null
                        : costController.text,
                    comments: commentsController.text,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(isEdit
                            ? 'Tool updated successfully'
                            : 'Tool added successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
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

    return StreamBuilder<List<ExecutionToolModel>>(
      stream: ExecutionService.streamTools(projectId),
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
              child: Text('Error loading tools: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        final tools = snapshot.data ?? [];

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
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(70),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(2),
              5: FixedColumnWidth(100),
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
                  buildCell('Execution Tool', isHeader: true),
                  buildCell('Description', isHeader: true),
                  buildCell('Source', isHeader: true),
                  buildCell('Comments', isHeader: true),
                  buildCell('Actions', isHeader: true, align: TextAlign.center),
                ],
              ),
              if (tools.isEmpty)
                TableRow(
                  children: [
                    buildCell('', align: TextAlign.center),
                    buildCell('No tools added yet',
                        style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontStyle: FontStyle.italic)),
                    buildCell(''),
                    buildCell(''),
                    buildCell(''),
                    buildCell(''),
                  ],
                )
              else
                ...tools.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tool = entry.value;
                  return TableRow(
                    children: [
                      buildCell('${index + 1}', align: TextAlign.center),
                      buildCell(tool.tool),
                      buildCell(tool.description),
                      buildCell(tool.source),
                      buildCell(tool.comments),
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
                              onPressed: () => showEditDialog(context, tool),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Color(0xFFEF4444)),
                              onPressed: () => showDeleteDialog(context, tool),
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
        );
      },
    );
  }
}

class _AddSolutionButton extends StatelessWidget {
  const _AddSolutionButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, color: Color(0xFF111827)),
      label: const Text(
        'Add Solution',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class ExecutionPlanDetailsScreen extends StatelessWidget {
  const ExecutionPlanDetailsScreen({
    super.key,
    this.activeItemLabel = 'Execution Plan Details',
    this.showPlanDetails = true,
    this.showEarlyWorks = false,
  });

  final String activeItemLabel;
  final bool showPlanDetails;
  final bool showEarlyWorks;

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ExecutionPlanDetailsScreen(
          activeItemLabel: 'Execution Plan Details',
          showPlanDetails: true,
          showEarlyWorks: false,
        ),
      ),
    );
  }

  static void openEarlyWorks(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ExecutionPlanDetailsScreen(
          activeItemLabel: 'Execution Early Works',
          showPlanDetails: false,
          showEarlyWorks: true,
        ),
      ),
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
              child: InitiationLikeSidebar(activeItemLabel: activeItemLabel),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                        onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    if (showPlanDetails) ...[
                      const _SectionIntro(title: 'Execution Plan Details'),
                      const SizedBox(height: 28),
                      _ExecutionPlanForm(
                        title: 'Execution Plan Details',
                        hintText: 'Input your notes here...',
                        noteKey: 'execution_plan_details',
                      ),
                      const SizedBox(height: 40),
                    ],
                    if (showPlanDetails && !showEarlyWorks) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          alignment: WrapAlignment.end,
                          children: [
                            const _InfoBadge(),
                            const _AiTipCard(),
                            _YellowActionButton(
                              label: 'Next',
                              onPressed: () =>
                                  ExecutionPlanDetailsScreen.openEarlyWorks(
                                      context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 56),
                    ],
                    if (showEarlyWorks) ...[
                      const _SectionIntro(title: 'Execution Early Works'),
                      const SizedBox(height: 24),
                      const _ExecutionPlanForm(
                        title: 'Execution Early Works',
                        hintText:
                            'Outline early works scope, sequencing, and handoffs.',
                        noteKey: 'execution_early_works',
                      ),
                      const SizedBox(height: 32),
                      const _EarlyWorksSection(),
                      const SizedBox(height: 56),
                    ],
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

class _EarlyWorksSection extends StatelessWidget {
  const _EarlyWorksSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Early Works',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _EarlyWorksTable(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: _AddSolutionButton(
              onPressed: () => _EarlyWorksTable.showAddDialog(context)),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileEarlyWorksActions()
        else
          const _DesktopEarlyWorksActions(),
      ],
    );
  }
}

class _EarlyWorksTable extends StatelessWidget {
  const _EarlyWorksTable();

  String? _getProjectId(BuildContext context) {
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
    _showToolDialog(context, null, projectId);
  }

  // ignore: unused_element
  static void showEditDialog(BuildContext context, ExecutionToolModel tool) {
    final projectId = _getProjectIdStatic(context);
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showToolDialog(context, tool, projectId);
  }

  // ignore: unused_element
  static void showDeleteDialog(BuildContext context, ExecutionToolModel tool) {
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
        title: const Text('Delete Tool'),
        content: Text(
            'Are you sure you want to delete "${tool.tool}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ExecutionService.deleteTool(
                    projectId: projectId, toolId: tool.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tool deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting tool: $e')),
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

  static String? _getProjectIdStatic(BuildContext context) {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  static void _showToolDialog(
      BuildContext context, ExecutionToolModel? tool, String projectId) {
    final isEdit = tool != null;
    final toolController = TextEditingController(text: tool?.tool ?? '');
    final descriptionController =
        TextEditingController(text: tool?.description ?? '');
    final sourceController = TextEditingController(text: tool?.source ?? '');
    final costController = TextEditingController(text: tool?.cost ?? '');
    final commentsController =
        TextEditingController(text: tool?.comments ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Tool' : 'Add New Tool'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: toolController,
                  decoration: const InputDecoration(labelText: 'Tool *')),
              const SizedBox(height: 12),
              TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 2),
              const SizedBox(height: 12),
              TextField(
                  controller: sourceController,
                  decoration: const InputDecoration(labelText: 'Source *')),
              const SizedBox(height: 12),
              TextField(
                  controller: costController,
                  decoration: const InputDecoration(
                      labelText: 'Cost', hintText: 'Optional')),
              const SizedBox(height: 12),
              TextField(
                  controller: commentsController,
                  decoration: const InputDecoration(labelText: 'Comments *'),
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (toolController.text.isEmpty ||
                  descriptionController.text.isEmpty ||
                  sourceController.text.isEmpty ||
                  commentsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill in all required fields')),
                );
                return;
              }

              try {
                if (isEdit) {
                  await ExecutionService.updateTool(
                    projectId: projectId,
                    toolId: tool.id,
                    tool: toolController.text,
                    description: descriptionController.text,
                    source: sourceController.text,
                    cost: costController.text.isEmpty
                        ? null
                        : costController.text,
                    comments: commentsController.text,
                  );
                } else {
                  await ExecutionService.createTool(
                    projectId: projectId,
                    tool: toolController.text,
                    description: descriptionController.text,
                    source: sourceController.text,
                    cost: costController.text.isEmpty
                        ? null
                        : costController.text,
                    comments: commentsController.text,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(isEdit
                            ? 'Tool updated successfully'
                            : 'Tool added successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
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

    return StreamBuilder<List<ExecutionToolModel>>(
      stream: ExecutionService.streamTools(projectId),
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
              child: Text('Error loading tools: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        final tools = snapshot.data ?? [];

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
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(70),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(2),
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
                  buildCell('Execution Tool', isHeader: true),
                  buildCell('Description', isHeader: true),
                  buildCell('Cost', isHeader: true),
                  buildCell('Comments', isHeader: true),
                  buildCell('Actions', isHeader: true),
                ],
              ),
              if (tools.isEmpty)
                TableRow(
                  children: [
                    buildCell('', align: TextAlign.center),
                    buildCell('No tools added yet',
                        style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontStyle: FontStyle.italic)),
                    buildCell(''),
                    buildCell(''),
                    buildCell(''),
                    buildCell(''),
                  ],
                )
              else
                ...tools.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tool = entry.value;
                  return TableRow(
                    children: [
                      buildCell('${index + 1}', align: TextAlign.center),
                      buildCell(tool.tool),
                      buildCell(tool.description),
                      buildCell(tool.cost ?? '—'),
                      buildCell(tool.comments),
                      buildCell('',
                          align: TextAlign.center,
                          style: const TextStyle(fontSize: 0)),
                    ],
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopEarlyWorksActions extends StatelessWidget {
  const _DesktopEarlyWorksActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionEnablingWorkPlanScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileEarlyWorksActions extends StatelessWidget {
  const _MobileEarlyWorksActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionEnablingWorkPlanScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionEnablingWorkPlanScreen extends StatelessWidget {
  const ExecutionEnablingWorkPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ExecutionEnablingWorkPlanScreen()),
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
                  activeItemLabel: 'Execution Enabling Work Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                        onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Enabling Work Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Enabling Work Plan',
                      hintText:
                          'Capture enabling works, dependencies, and resourcing needs.',
                      noteKey: 'execution_enabling_work_plan',
                    ),
                    const SizedBox(height: 32),
                    const _EnablingWorksPlanSection(),
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

class _EnablingWorksPlanSection extends StatelessWidget {
  const _EnablingWorksPlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enabling Works Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _EnablingWorksPlanTable(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: _AddRowButton(
              onPressed: () => _EnablingWorksPlanTable.showAddDialog(context)),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileEnablingWorksActions()
        else
          const _DesktopEnablingWorksActions(),
      ],
    );
  }
}

class _EnablingWorksPlanTable extends StatelessWidget {
  const _EnablingWorksPlanTable();

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
    _showEnablingWorkDialog(context, null, projectId);
  }

  static void showEditDialog(
      BuildContext context, ExecutionEnablingWorkModel work) {
    final projectId = _getProjectIdStatic(context);
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showEnablingWorkDialog(context, work, projectId);
  }

  static void showDeleteDialog(
      BuildContext context, ExecutionEnablingWorkModel work) {
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
        title: const Text('Delete Enabling Work'),
        content: Text(
            'Are you sure you want to delete "${work.aspect}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ExecutionService.deleteEnablingWork(
                    projectId: projectId, workId: work.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Enabling work deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting enabling work: $e')),
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

  static void _showEnablingWorkDialog(BuildContext context,
      ExecutionEnablingWorkModel? work, String projectId) {
    final isEdit = work != null;
    final aspectController = TextEditingController(text: work?.aspect ?? '');
    final descriptionController =
        TextEditingController(text: work?.description ?? '');
    final durationController =
        TextEditingController(text: work?.duration ?? '');
    final costController = TextEditingController(text: work?.cost ?? '');
    final commentsController =
        TextEditingController(text: work?.comments ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Enabling Work' : 'Add New Enabling Work'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: aspectController,
                  decoration: const InputDecoration(labelText: 'Aspect *')),
              const SizedBox(height: 12),
              TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 2),
              const SizedBox(height: 12),
              TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration *')),
              const SizedBox(height: 12),
              TextField(
                  controller: costController,
                  decoration: const InputDecoration(labelText: 'Cost *')),
              const SizedBox(height: 12),
              TextField(
                  controller: commentsController,
                  decoration: const InputDecoration(labelText: 'Comments *'),
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (aspectController.text.isEmpty ||
                  descriptionController.text.isEmpty ||
                  durationController.text.isEmpty ||
                  costController.text.isEmpty ||
                  commentsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill in all required fields')),
                );
                return;
              }

              try {
                if (isEdit) {
                  await ExecutionService.updateEnablingWork(
                    projectId: projectId,
                    workId: work.id,
                    aspect: aspectController.text,
                    description: descriptionController.text,
                    duration: durationController.text,
                    cost: costController.text,
                    comments: commentsController.text,
                  );
                } else {
                  await ExecutionService.createEnablingWork(
                    projectId: projectId,
                    aspect: aspectController.text,
                    description: descriptionController.text,
                    duration: durationController.text,
                    cost: costController.text,
                    comments: commentsController.text,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(isEdit
                            ? 'Enabling work updated successfully'
                            : 'Enabling work added successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Add'),
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

    return StreamBuilder<List<ExecutionEnablingWorkModel>>(
      stream: ExecutionService.streamEnablingWorks(projectId),
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
              child: Text('Error loading enabling works: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        final works = snapshot.data ?? [];

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
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(70),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2.5),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(2),
              5: FlexColumnWidth(2),
              6: FixedColumnWidth(100),
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
                  buildCell('Enabling work Aspect', isHeader: true),
                  buildCell('Description', isHeader: true),
                  buildCell('Duration', isHeader: true),
                  buildCell('Cost', isHeader: true),
                  buildCell('Comments', isHeader: true),
                  buildCell('Actions', isHeader: true, align: TextAlign.center),
                ],
              ),
              if (works.isEmpty)
                TableRow(
                  children: [
                    buildCell('', align: TextAlign.center),
                    buildCell('No enabling works added yet',
                        style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontStyle: FontStyle.italic)),
                    buildCell(''),
                    buildCell(''),
                    buildCell(''),
                    buildCell(''),
                    buildCell(''),
                  ],
                )
              else
                ...works.asMap().entries.map((entry) {
                  final index = entry.key;
                  final work = entry.value;
                  return TableRow(
                    children: [
                      buildCell('${index + 1}', align: TextAlign.center),
                      buildCell(work.aspect),
                      buildCell(work.description),
                      buildCell(work.duration),
                      buildCell(work.cost),
                      buildCell(work.comments),
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
                              onPressed: () => showEditDialog(context, work),
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Color(0xFFEF4444)),
                              onPressed: () => showDeleteDialog(context, work),
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
        );
      },
    );
  }
}

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_rounded, color: Color(0xFF111827)),
      label: const Text(
        'Add Row',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _DesktopEnablingWorksActions extends StatelessWidget {
  const _DesktopEnablingWorksActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionIssueManagementScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileEnablingWorksActions extends StatelessWidget {
  const _MobileEnablingWorksActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionIssueManagementScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionIssueManagementScreen extends StatelessWidget {
  const ExecutionIssueManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExecutionIssueManagementScreen()),
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
                  activeItemLabel: 'Execution Issue Management'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                        onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(title: 'Execution Issue Management'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Issue Management',
                      hintText:
                          'Summarize issue tracking, escalation paths, and mitigation cadence.',
                      noteKey: 'execution_issue_management',
                    ),
                    const SizedBox(height: 32),
                    const _IssuesManagementSection(),
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

class _IssuesManagementSection extends StatelessWidget {
  const _IssuesManagementSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Issues Management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _IssuesManagementTable(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: _AddRowButton(
              onPressed: () => _IssuesManagementTable.showAddDialog(context)),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileIssueManagementActions()
        else
          const _DesktopIssueManagementActions(),
      ],
    );
  }
}

class _IssuesManagementTable extends StatelessWidget {
  const _IssuesManagementTable();

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
    _showIssueDialog(context, null, projectId);
  }

  static void showEditDialog(BuildContext context, ExecutionIssueModel issue) {
    final projectId = _getProjectIdStatic(context);
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No project selected. Please open a project first.')),
      );
      return;
    }
    _showIssueDialog(context, issue, projectId);
  }

  static void showDeleteDialog(
      BuildContext context, ExecutionIssueModel issue) {
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
        title: const Text('Delete Issue'),
        content: Text(
            'Are you sure you want to delete "${issue.issueTopic}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ExecutionService.deleteIssue(
                    projectId: projectId, issueId: issue.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Issue deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting issue: $e')),
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

  static void _showIssueDialog(
      BuildContext context, ExecutionIssueModel? issue, String projectId) {
    final isEdit = issue != null;
    final topicController =
        TextEditingController(text: issue?.issueTopic ?? '');
    final descriptionController =
        TextEditingController(text: issue?.description ?? '');
    final disciplineController =
        TextEditingController(text: issue?.discipline ?? '');
    final raisedByController =
        TextEditingController(text: issue?.raisedBy ?? '');
    final scheduleImpactController =
        TextEditingController(text: issue?.scheduleImpact ?? '');
    final costImpactController =
        TextEditingController(text: issue?.costImpact ?? '');
    final commentsController =
        TextEditingController(text: issue?.comments ?? '');
    bool approved = issue?.approved ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Issue' : 'Add New Issue'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: topicController,
                    decoration:
                        const InputDecoration(labelText: 'Issue Topic *')),
                const SizedBox(height: 12),
                TextField(
                    controller: descriptionController,
                    decoration:
                        const InputDecoration(labelText: 'Description *'),
                    maxLines: 2),
                const SizedBox(height: 12),
                TextField(
                    controller: disciplineController,
                    decoration:
                        const InputDecoration(labelText: 'Discipline *')),
                const SizedBox(height: 12),
                TextField(
                    controller: raisedByController,
                    decoration:
                        const InputDecoration(labelText: 'Raised By *')),
                const SizedBox(height: 12),
                TextField(
                    controller: scheduleImpactController,
                    decoration:
                        const InputDecoration(labelText: 'Schedule Impact *')),
                const SizedBox(height: 12),
                TextField(
                    controller: costImpactController,
                    decoration:
                        const InputDecoration(labelText: 'Cost Impact *')),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Approved'),
                  value: approved,
                  onChanged: (value) =>
                      setState(() => approved = value ?? false),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: commentsController,
                    decoration: const InputDecoration(labelText: 'Comments *'),
                    maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (topicController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    disciplineController.text.isEmpty ||
                    raisedByController.text.isEmpty ||
                    scheduleImpactController.text.isEmpty ||
                    costImpactController.text.isEmpty ||
                    commentsController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                try {
                  if (isEdit) {
                    await ExecutionService.updateIssue(
                      projectId: projectId,
                      issueId: issue.id,
                      issueTopic: topicController.text,
                      description: descriptionController.text,
                      discipline: disciplineController.text,
                      raisedBy: raisedByController.text,
                      scheduleImpact: scheduleImpactController.text,
                      costImpact: costImpactController.text,
                      approved: approved,
                      comments: commentsController.text,
                    );
                  } else {
                    await ExecutionService.createIssue(
                      projectId: projectId,
                      issueTopic: topicController.text,
                      description: descriptionController.text,
                      discipline: disciplineController.text,
                      raisedBy: raisedByController.text,
                      scheduleImpact: scheduleImpactController.text,
                      costImpact: costImpactController.text,
                      approved: approved,
                      comments: commentsController.text,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(isEdit
                              ? 'Issue updated successfully'
                              : 'Issue added successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
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
      stream: ExecutionService.streamIssues(projectId),
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
              child: Text('Error loading issues: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        final issues = snapshot.data ?? [];

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
                1: FixedColumnWidth(140),
                2: FixedColumnWidth(160),
                3: FixedColumnWidth(130),
                4: FixedColumnWidth(130),
                5: FixedColumnWidth(130),
                6: FixedColumnWidth(130),
                7: FixedColumnWidth(130),
                8: FixedColumnWidth(150),
                9: FixedColumnWidth(100),
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
                    buildCell('Issue Topic', isHeader: true),
                    buildCell('Description', isHeader: true),
                    buildCell('Discipline', isHeader: true),
                    buildCell('Raised by', isHeader: true),
                    buildCell('Schedule In', isHeader: true),
                    buildCell('Cost Impact', isHeader: true),
                    buildCell('Approved?', isHeader: true),
                    buildCell('Comments', isHeader: true),
                    buildCell('Actions',
                        isHeader: true, align: TextAlign.center),
                  ],
                ),
                if (issues.isEmpty)
                  TableRow(
                    children: [
                      buildCell('', align: TextAlign.center),
                      buildCell('No issues added yet',
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
                    ],
                  )
                else
                  ...issues.asMap().entries.map((entry) {
                    final index = entry.key;
                    final issue = entry.value;
                    return TableRow(
                      children: [
                        buildCell('${index + 1}', align: TextAlign.center),
                        buildCell(issue.issueTopic),
                        buildCell(issue.description),
                        buildCell(issue.discipline),
                        buildCell(issue.raisedBy),
                        buildCell(issue.scheduleImpact),
                        buildCell(issue.costImpact),
                        buildCell(issue.approved ? 'Yes' : 'No'),
                        buildCell(issue.comments),
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
                                onPressed: () => showEditDialog(context, issue),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 18, color: Color(0xFFEF4444)),
                                onPressed: () =>
                                    showDeleteDialog(context, issue),
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

class _DesktopIssueManagementActions extends StatelessWidget {
  const _DesktopIssueManagementActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text:
                    'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanLessonsLearnedScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileIssueManagementActions extends StatelessWidget {
  const _MobileIssueManagementActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanLessonsLearnedScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanLessonsLearnedScreen extends StatelessWidget {
  const ExecutionPlanLessonsLearnedScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ExecutionPlanLessonsLearnedScreen()),
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
                  activeItemLabel: 'Execution Plan - Lesson Learned'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                        onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(
                        title: 'Execution Plan - Lesson Learned'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Lesson Learned',
                      hintText:
                          'Capture lessons learned and how they influence execution.',
                      noteKey: 'execution_lessons_learned',
                    ),
                    const SizedBox(height: 32),
                    const _LessonsLearnedSection(),
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

class _LessonsLearnedSection extends StatelessWidget {
  const _LessonsLearnedSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lessons Learned',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        const _LessonsLearnedTable(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: _AddRowButton(
              onPressed: () => _LessonsLearnedTable.showAddDialog(context)),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileLessonsLearnedActions()
        else
          const _DesktopLessonsLearnedActions(),
      ],
    );
  }
}

class _LessonsLearnedTable extends StatelessWidget {
  const _LessonsLearnedTable();

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
    _showChangeRequestDialog(context, null, projectId, 'LL');
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
    _showChangeRequestDialog(context, request, projectId, 'LL');
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
        title: const Text('Delete Lesson Learned'),
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
                        content: Text('Lesson learned deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error deleting lesson learned: $e')),
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

  static void _showChangeRequestDialog(BuildContext context,
      ExecutionIssueModel? request, String projectId, String llOrBp) {
    final isEdit = request != null;
    final topicController =
        TextEditingController(text: request?.issueTopic ?? '');
    final descriptionController =
        TextEditingController(text: request?.description ?? '');
    final disciplineController =
        TextEditingController(text: request?.discipline ?? '');
    final raisedByController =
        TextEditingController(text: request?.raisedBy ?? '');
    final scheduleImpactController =
        TextEditingController(text: request?.scheduleImpact ?? '');
    final costImpactController =
        TextEditingController(text: request?.costImpact ?? '');
    final commentsController =
        TextEditingController(text: request?.comments ?? '');
    final impactedController =
        TextEditingController(text: request?.impacted ?? '');
    bool approved = request?.approved ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit
              ? 'Edit ${llOrBp == 'LL' ? 'Lesson Learned' : 'Best Practice'}'
              : 'Add New ${llOrBp == 'LL' ? 'Lesson Learned' : 'Best Practice'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: topicController,
                    decoration: const InputDecoration(labelText: 'Topic *')),
                const SizedBox(height: 12),
                TextField(
                    controller: descriptionController,
                    decoration:
                        const InputDecoration(labelText: 'Description *'),
                    maxLines: 2),
                const SizedBox(height: 12),
                TextField(
                    controller: disciplineController,
                    decoration:
                        const InputDecoration(labelText: 'Discipline *')),
                const SizedBox(height: 12),
                TextField(
                    controller: impactedController,
                    decoration: const InputDecoration(labelText: 'Impacted')),
                const SizedBox(height: 12),
                TextField(
                    controller: raisedByController,
                    decoration:
                        const InputDecoration(labelText: 'Raised By *')),
                const SizedBox(height: 12),
                TextField(
                    controller: scheduleImpactController,
                    decoration:
                        const InputDecoration(labelText: 'Schedule Impact *')),
                const SizedBox(height: 12),
                TextField(
                    controller: costImpactController,
                    decoration:
                        const InputDecoration(labelText: 'Cost Impact *')),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Approved'),
                  value: approved,
                  onChanged: (value) =>
                      setState(() => approved = value ?? false),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: commentsController,
                    decoration: const InputDecoration(labelText: 'Comments *'),
                    maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (topicController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    disciplineController.text.isEmpty ||
                    raisedByController.text.isEmpty ||
                    scheduleImpactController.text.isEmpty ||
                    costImpactController.text.isEmpty ||
                    commentsController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                try {
                  if (isEdit) {
                    await ExecutionService.updateChangeRequest(
                      projectId: projectId,
                      requestId: request.id,
                      issueTopic: topicController.text,
                      description: descriptionController.text,
                      discipline: disciplineController.text,
                      raisedBy: raisedByController.text,
                      scheduleImpact: scheduleImpactController.text,
                      costImpact: costImpactController.text,
                      approved: approved,
                      comments: commentsController.text,
                      llOrBp: llOrBp,
                      impacted: impactedController.text.isEmpty
                          ? null
                          : impactedController.text,
                    );
                  } else {
                    await ExecutionService.createChangeRequest(
                      projectId: projectId,
                      issueTopic: topicController.text,
                      description: descriptionController.text,
                      discipline: disciplineController.text,
                      raisedBy: raisedByController.text,
                      scheduleImpact: scheduleImpactController.text,
                      costImpact: costImpactController.text,
                      approved: approved,
                      comments: commentsController.text,
                      llOrBp: llOrBp,
                      impacted: impactedController.text.isEmpty
                          ? null
                          : impactedController.text,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(isEdit
                              ? '${llOrBp == 'LL' ? 'Lesson learned' : 'Best practice'} updated successfully'
                              : '${llOrBp == 'LL' ? 'Lesson learned' : 'Best practice'} added successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
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
              child: Text('Error loading lessons learned: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        // Filter for Lessons Learned (LL)
        final allRequests = snapshot.data ?? [];
        final lessonsLearned = allRequests
            .where((r) =>
                (r.llOrBp ?? '').toLowerCase().contains('ll') ||
                (r.llOrBp ?? '').isEmpty)
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
                if (lessonsLearned.isEmpty)
                  TableRow(
                    children: [
                      buildCell('', align: TextAlign.center),
                      buildCell('No lessons learned added yet',
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
                      buildCell(''),
                    ],
                  )
                else
                  ...lessonsLearned.asMap().entries.map((entry) {
                    final index = entry.key;
                    final request = entry.value;
                    return TableRow(
                      children: [
                        buildCell('${index + 1}', align: TextAlign.center),
                        buildCell(request.issueTopic),
                        buildCell(request.llOrBp ?? '—'),
                        buildCell(request.discipline),
                        buildCell(request.impacted ?? '—'),
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

class _DesktopLessonsLearnedActions extends StatelessWidget {
  const _DesktopLessonsLearnedActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text:
                    'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanBestPracticesScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileLessonsLearnedActions extends StatelessWidget {
  const _MobileLessonsLearnedActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanBestPracticesScreen.open(context),
        ),
      ],
    );
  }
}

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
                    _ExecutionPlanHeader(
                        onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(
                        title: 'Execution Plan - Best Practices'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
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
          child: _AddRowButton(
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
    _LessonsLearnedTable._showChangeRequestDialog(
        context, null, projectId, 'BP');
  }

  // ignore: unused_element
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
    _LessonsLearnedTable._showChangeRequestDialog(
        context, request, projectId, 'BP');
  }

  // ignore: unused_element
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
                        buildCell(request.llOrBp ?? '—'),
                        buildCell(request.discipline),
                        buildCell(request.impacted ?? '—'),
                        buildCell(request.raisedBy),
                        buildCell(request.scheduleImpact),
                        buildCell(request.costImpact),
                        buildCell(request.approved ? 'Yes' : 'No'),
                        buildCell(request.comments),
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
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text:
                    'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
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
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanConstructionPlanScreen.open(context),
        ),
      ],
    );
  }
}

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
                    _ExecutionPlanHeader(
                      onBack: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ExecutionPlanScreen()),
                      ),
                      onNext: () =>
                          ExecutionPlanInfrastructurePlanScreen.open(context),
                    ),
                    const SizedBox(height: 32),
                    const _SectionIntro(
                        title: 'Execution Plan - Construction Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
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
        const _PlanDecisionSection(
          question: 'Will construction work be done by this project?',
          planKeyPrefix: 'execution_construction_plan',
          formTitle: 'Construction Plan Inputs',
          formSubtitle:
              'Capture the sequencing, resources, and controls needed to deliver construction work safely.',
          fields: [
            _PlanFieldConfig(
              keyName: 'scope',
              label: 'Scope & work packages',
              hint: 'Define in-scope components, exclusions, and deliverables.',
              minLines: 2,
              maxLines: 4,
              fullWidth: true,
            ),
            _PlanFieldConfig(
              keyName: 'sequencing',
              label: 'Sequencing & milestones',
              hint: 'Outline phases, key handoffs, and milestone dates.',
              minLines: 2,
              maxLines: 4,
            ),
            _PlanFieldConfig(
              keyName: 'resources',
              label: 'Resources & contractors',
              hint: 'List crews, vendors, and specialist roles.',
              minLines: 2,
              maxLines: 4,
            ),
            _PlanFieldConfig(
              keyName: 'logistics',
              label: 'Site logistics & access',
              hint: 'Access, staging, equipment, and material flow.',
              minLines: 2,
              maxLines: 4,
            ),
            _PlanFieldConfig(
              keyName: 'safety',
              label: 'Safety, compliance & QA/QC',
              hint: 'HSE controls, permits, inspections, and quality checks.',
              minLines: 2,
              maxLines: 4,
              fullWidth: true,
            ),
            _PlanFieldConfig(
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
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text:
                    'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
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
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInfrastructurePlanScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanInfrastructurePlanScreen extends StatelessWidget {
  const ExecutionPlanInfrastructurePlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ExecutionPlanInfrastructurePlanScreen()),
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
                  activeItemLabel: 'Execution Plan - Infrastructure Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                      onBack: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ExecutionPlanConstructionPlanScreen()),
                      ),
                      onNext: () =>
                          ExecutionPlanAgileDeliveryPlanScreen.open(context),
                    ),
                    const SizedBox(height: 32),
                    const _SectionIntro(
                        title: 'Execution Plan - Infrastructure Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Infrastructure Plan',
                      hintText:
                          'Outline infrastructure dependencies, scope, and delivery approach.',
                      noteKey: 'execution_infrastructure_plan',
                      showDiagram: false,
                    ),
                    const SizedBox(height: 32),
                    const _InfrastructurePlanSection(),
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

class _InfrastructurePlanSection extends StatelessWidget {
  const _InfrastructurePlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Infrastructure Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 24),
        const _PlanDecisionSection(
          question: 'Will infrastructure work be done by this project?',
          planKeyPrefix: 'execution_infrastructure_plan',
          formTitle: 'Infrastructure Plan Inputs',
          formSubtitle:
              'Define the environments, capacity, and operational readiness needed for delivery.',
          fields: [
            _PlanFieldConfig(
              keyName: 'scope',
              label: 'Infrastructure scope & components',
              hint: 'List core platforms, environments, and services in scope.',
              minLines: 2,
              maxLines: 4,
              fullWidth: true,
            ),
            _PlanFieldConfig(
              keyName: 'environment',
              label: 'Environment strategy',
              hint: 'Dev/test/stage/prod topology and parity goals.',
              minLines: 2,
              maxLines: 4,
            ),
            _PlanFieldConfig(
              keyName: 'capacity',
              label: 'Capacity & performance targets',
              hint: 'Sizing assumptions, scalability targets, and SLAs.',
              minLines: 2,
              maxLines: 4,
            ),
            _PlanFieldConfig(
              keyName: 'security',
              label: 'Security, compliance & DR',
              hint:
                  'Security controls, data protection, backup/restore, RTO/RPO.',
              minLines: 2,
              maxLines: 4,
              fullWidth: true,
            ),
            _PlanFieldConfig(
              keyName: 'dependencies',
              label: 'Dependencies & vendors',
              hint: 'Third-party services, contracts, and lead times.',
              minLines: 2,
              maxLines: 4,
            ),
            _PlanFieldConfig(
              keyName: 'cutover',
              label: 'Migration & cutover plan',
              hint: 'Data migration steps, cutover windows, rollback.',
              minLines: 2,
              maxLines: 4,
            ),
            _PlanFieldConfig(
              keyName: 'monitoring',
              label: 'Operations & monitoring',
              hint: 'Monitoring, alerting, and on-call ownership.',
              minLines: 2,
              maxLines: 4,
              fullWidth: true,
            ),
          ],
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileInfrastructurePlanActions()
        else
          const _DesktopInfrastructurePlanActions(),
      ],
    );
  }
}

class _DesktopInfrastructurePlanActions extends StatelessWidget {
  const _DesktopInfrastructurePlanActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text:
                    'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanAgileDeliveryPlanScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileInfrastructurePlanActions extends StatelessWidget {
  const _MobileInfrastructurePlanActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanAgileDeliveryPlanScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanAgileDeliveryPlanScreen extends StatelessWidget {
  const ExecutionPlanAgileDeliveryPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ExecutionPlanAgileDeliveryPlanScreen()),
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
                  activeItemLabel: 'Execution Plan - Agile Delivery Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                      onBack: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ExecutionPlanInfrastructurePlanScreen()),
                      ),
                      onNext: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DesignPlanningScreen()),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const _SectionIntro(
                        title: 'Execution Plan - Agile Delivery Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Agile Delivery Plan',
                      hintText:
                          'Outline sprint cadence, release waves, and backlog governance.',
                      noteKey: 'execution_agile_delivery_plan',
                      showDiagram: false,
                    ),
                    const SizedBox(height: 32),
                    const _AgileDeliveryPlanSection(),
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

class _AgileDeliveryPlanSection extends StatelessWidget {
  const _AgileDeliveryPlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agile Delivery Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 24),
        const _PlanDecisionSection(
          question: 'Will agile delivery be used for this project?',
          planKeyPrefix: 'execution_agile_delivery_plan',
          formTitle: 'Agile Delivery Plan Inputs',
          formSubtitle:
              'Define cadence, governance, and delivery guardrails for agile execution.',
          fields: [
            _PlanFieldConfig(
              keyName: 'model',
              label: 'Delivery model',
              hint: 'Scrum, Kanban, or hybrid approach and rationale.',
              minLines: 2,
              maxLines: 4,
              fullWidth: true,
            ),
            _PlanFieldConfig(
              keyName: 'cadence',
              label: 'Sprint cadence & calendar',
              hint: 'Sprint length, ceremonies, and planning calendar.',
              minLines: 2,
              maxLines: 4,
            ),
            _PlanFieldConfig(
              keyName: 'release',
              label: 'Release strategy',
              hint: 'Release waves, branching, and approval gates.',
              minLines: 2,
              maxLines: 4,
            ),
            _PlanFieldConfig(
              keyName: 'backlog',
              label: 'Backlog governance',
              hint:
                  'Definition of Ready/Done, prioritization, and grooming cadence.',
              minLines: 2,
              maxLines: 4,
              fullWidth: true,
            ),
            _PlanFieldConfig(
              keyName: 'team',
              label: 'Team structure & roles',
              hint:
                  'Squad ownership, product roles, and cross-functional coverage.',
              minLines: 2,
              maxLines: 4,
            ),
            _PlanFieldConfig(
              keyName: 'metrics',
              label: 'Metrics & reporting',
              hint:
                  'Velocity, throughput, predictability, and quality measures.',
              minLines: 2,
              maxLines: 4,
            ),
            _PlanFieldConfig(
              keyName: 'risks',
              label: 'Impediment & risk handling',
              hint:
                  'Escalation process, dependency tracking, and blockers removal.',
              minLines: 2,
              maxLines: 4,
              fullWidth: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment:
              isMobile ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            const _InfoBadge(),
            const SizedBox(width: 16),
            _YellowActionButton(
              label: 'Next',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DesignPlanningScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanDecisionSection extends StatefulWidget {
  const _PlanDecisionSection({
    required this.question,
    required this.planKeyPrefix,
    required this.formTitle,
    required this.formSubtitle,
    required this.fields,
  });

  final String question;
  final String planKeyPrefix;
  final String formTitle;
  final String formSubtitle;
  final List<_PlanFieldConfig> fields;

  @override
  State<_PlanDecisionSection> createState() => _PlanDecisionSectionState();
}

class _PlanDecisionSectionState extends State<_PlanDecisionSection> {
  final Map<String, TextEditingController> _controllers = {};
  Timer? _saveDebounce;
  bool? _decision;
  bool _didInit = false;
  bool _isLoading = true;
  bool _hasFirestoreDoc = false;
  DateTime? _lastSavedAt;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      _controllers[field.keyName] = TextEditingController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    final notes = ProjectDataHelper.getData(context).planningNotes;
    final savedDecision = notes['${widget.planKeyPrefix}_decision'] ?? '';
    if (savedDecision == 'yes') {
      _decision = true;
    } else if (savedDecision == 'no') {
      _decision = false;
    }
    for (final field in widget.fields) {
      final key = '${widget.planKeyPrefix}_${field.keyName}';
      _controllers[field.keyName]?.text = notes[key] ?? '';
    }
    _didInit = true;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleDecision(bool value) {
    setState(() => _decision = value);
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), _saveNow);
  }

  Future<void> _loadFromFirestore() async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await _docRef(projectId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final decision = (data['decision'] as String?) ?? '';
        final fields = data['fields'];
        if (decision == 'yes') {
          _decision = true;
        } else if (decision == 'no') {
          _decision = false;
        }
        if (fields is Map) {
          for (final field in widget.fields) {
            final value = fields[field.keyName];
            if (value is String) {
              _controllers[field.keyName]?.text = value;
            }
          }
        }
        _lastSavedAt = _readTimestamp(data['updatedAt']);
        _hasFirestoreDoc = true;
      }
    } catch (error) {
      debugPrint('Failed to load execution plan section: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveNow() async {
    final updates = <String, String>{
      '${widget.planKeyPrefix}_decision':
          _decision == null ? '' : (_decision! ? 'yes' : 'no'),
    };
    for (final field in widget.fields) {
      updates['${widget.planKeyPrefix}_${field.keyName}'] =
          _controllers[field.keyName]?.text.trim() ?? '';
    }
    final success = await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: _resolveExecutionCheckpoint(widget.planKeyPrefix),
      dataUpdater: (data) => data.copyWith(
        planningNotes: {
          ...data.planningNotes,
          ...updates,
        },
      ),
      showSnackbar: false,
    );
    final firestoreSaved = await _saveToFirestore(updates);
    if (mounted && success && firestoreSaved) {
      setState(() => _lastSavedAt = DateTime.now());
    }
  }

  Future<bool> _saveToFirestore(Map<String, String> updates) async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) return false;
    final payload = <String, dynamic>{
      'decision': updates['${widget.planKeyPrefix}_decision'] ?? '',
      'fields': {
        for (final field in widget.fields)
          field.keyName:
              updates['${widget.planKeyPrefix}_${field.keyName}'] ?? '',
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!_hasFirestoreDoc) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    try {
      await _docRef(projectId).set(payload, SetOptions(merge: true));
      _hasFirestoreDoc = true;
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save plan data: $error')),
        );
      }
      return false;
    }
  }

  DocumentReference<Map<String, dynamic>> _docRef(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('execution_plan_sections')
        .doc(widget.planKeyPrefix);
  }

  DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
            _PlanDecisionCard(
              question: widget.question,
              decision: _decision,
              onChanged: _handleDecision,
            ),
            if (_decision == true) ...[
              const SizedBox(height: 20),
              _PlanInputCard(
                title: widget.formTitle,
                subtitle: widget.formSubtitle,
                fields: widget.fields,
                controllers: _controllers,
                onChanged: _scheduleSave,
                lastSavedAt: _lastSavedAt,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanDecisionCard extends StatelessWidget {
  const _PlanDecisionCard({
    required this.question,
    required this.decision,
    required this.onChanged,
  });

  final String question;
  final bool? decision;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFFBDBDBD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PlanDecisionButton(
                label: 'Yes',
                color: const Color(0xFF22C55E),
                isSelected: decision == true,
                onPressed: () => onChanged(true),
              ),
              const SizedBox(width: 18),
              _PlanDecisionButton(
                label: 'No',
                color: const Color(0xFFEF4444),
                isSelected: decision == false,
                onPressed: () => onChanged(false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanDecisionButton extends StatelessWidget {
  const _PlanDecisionButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.white,
        foregroundColor: isSelected ? Colors.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: color, width: 1.4),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PlanInputCard extends StatelessWidget {
  const _PlanInputCard({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.controllers,
    required this.onChanged,
    required this.lastSavedAt,
  });

  final String title;
  final String subtitle;
  final List<_PlanFieldConfig> fields;
  final Map<String, TextEditingController> controllers;
  final VoidCallback onChanged;
  final DateTime? lastSavedAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final gap = 16.0;
          final bool twoCol = width >= 760;
          final double halfWidth = twoCol ? (width - gap) / 2 : width;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827))),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: fields.map((field) {
                  final fieldWidth = field.fullWidth ? width : halfWidth;
                  return SizedBox(
                    width: fieldWidth,
                    child: _PlanTextField(
                      label: field.label,
                      hint: field.hint,
                      minLines: field.minLines,
                      maxLines: field.maxLines,
                      controller: controllers[field.keyName]!,
                      onChanged: (_) => onChanged(),
                    ),
                  );
                }).toList(),
              ),
              if (lastSavedAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Saved ${TimeOfDay.fromDateTime(lastSavedAt!).format(context)}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PlanTextField extends StatelessWidget {
  const _PlanTextField({
    required this.label,
    required this.hint,
    required this.minLines,
    required this.maxLines,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final int minLines;
  final int maxLines;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
      ),
    );
  }
}

class _PlanFieldConfig {
  const _PlanFieldConfig({
    required this.keyName,
    required this.label,
    required this.hint,
    required this.minLines,
    required this.maxLines,
    this.fullWidth = false,
  });

  final String keyName;
  final String label;
  final String hint;
  final int minLines;
  final int maxLines;
  final bool fullWidth;
}

class ExecutionPlanStakeholderIdentificationScreen extends StatelessWidget {
  const ExecutionPlanStakeholderIdentificationScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ExecutionPlanStakeholderIdentificationScreen()),
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
                  activeItemLabel:
                      'Execution Plan - Stakeholder Identification'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                        onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(
                        title: 'Execution Plan - Stakeholder Identification'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Stakeholder Identification',
                      hintText:
                          'Capture stakeholder groups, engagement strategies, and key concerns.',
                      noteKey: 'execution_stakeholder_identification',
                    ),
                    const SizedBox(height: 32),
                    const _StakeholderIdentificationSection(),
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

class _StakeholderIdentificationSection extends StatefulWidget {
  const _StakeholderIdentificationSection();

  @override
  State<_StakeholderIdentificationSection> createState() =>
      _StakeholderIdentificationSectionState();
}

class _StakeholderIdentificationSectionState
    extends State<_StakeholderIdentificationSection> {
  final List<Map<String, String>> _rows = [];

  void _addRow() {
    setState(() {
      _rows.add({
        'stakeholderGroup': '',
        'category': '',
        'influence': '',
        'keyConcerns': '',
        'engagementStrategy': '',
        'comments': '',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stakeholder Identification',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 28),
        _StakeholderIdentificationTable(rows: _rows),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: _AddRowButton(onPressed: _addRow),
        ),
        const SizedBox(height: 44),
        if (isMobile)
          _MobileStakeholderIdentificationActions()
        else
          const _DesktopStakeholderIdentificationActions(),
      ],
    );
  }
}

class _StakeholderIdentificationTable extends StatelessWidget {
  const _StakeholderIdentificationTable({required this.rows});

  final List<Map<String, String>> rows;

  @override
  Widget build(BuildContext context) {
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
        {bool isHeader = false, TextAlign align = TextAlign.left}) {
      return Container(
        color: isHeader ? const Color(0xFFF3F4F6) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(
          text,
          textAlign: align,
          style: isHeader ? headerStyle : cellStyle,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(70),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
          4: FlexColumnWidth(2),
          5: FlexColumnWidth(2),
          6: FlexColumnWidth(2),
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
              buildCell('Stakeholder Group', isHeader: true),
              buildCell('Category', isHeader: true),
              buildCell('Influence', isHeader: true),
              buildCell('Key Concerns', isHeader: true),
              buildCell('Engagement Strategy', isHeader: true),
              buildCell('Comments', isHeader: true),
            ],
          ),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return TableRow(
              children: [
                buildCell('${index + 1}', align: TextAlign.center),
                buildCell(row['stakeholderGroup'] ?? ''),
                buildCell(row['category'] ?? ''),
                buildCell(row['influence'] ?? ''),
                buildCell(row['keyConcerns'] ?? ''),
                buildCell(row['engagementStrategy'] ?? ''),
                buildCell(row['comments'] ?? ''),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DesktopStakeholderIdentificationActions extends StatelessWidget {
  const _DesktopStakeholderIdentificationActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text:
                    'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInterfaceManagementScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileStakeholderIdentificationActions extends StatelessWidget {
  const _MobileStakeholderIdentificationActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanInterfaceManagementScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanInterfaceManagementScreen extends StatelessWidget {
  const ExecutionPlanInterfaceManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ExecutionPlanInterfaceManagementScreen()),
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
                  activeItemLabel: 'Execution Plan - Interface Management'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                        onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(
                        title: 'Execution Plan - Interface Management'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Interface Management',
                      hintText:
                          'Summarize interface dependencies, coordination protocols, and governance.',
                      noteKey: 'execution_interface_management',
                    ),
                    const SizedBox(height: 32),
                    const _InterfaceManagementSection(),
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

class _InterfaceManagementSection extends StatelessWidget {
  const _InterfaceManagementSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interface management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 200),
        if (isMobile)
          _MobileInterfaceManagementActions()
        else
          const _DesktopInterfaceManagementActions(),
      ],
    );
  }
}

class _DesktopInterfaceManagementActions extends StatelessWidget {
  const _DesktopInterfaceManagementActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text:
                    'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanCommunicationPlanScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileInterfaceManagementActions extends StatelessWidget {
  const _MobileInterfaceManagementActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () => ExecutionPlanCommunicationPlanScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanCommunicationPlanScreen extends StatelessWidget {
  const ExecutionPlanCommunicationPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ExecutionPlanCommunicationPlanScreen()),
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
                  activeItemLabel: 'Execution Plan - Communication Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                        onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(
                        title: 'Execution Plan - Communication Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Communication Plan',
                      hintText:
                          'Outline communication cadence, channels, and stakeholder updates.',
                      noteKey: 'execution_communication_plan',
                    ),
                    const SizedBox(height: 32),
                    const _CommunicationPlanSection(),
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

class _CommunicationPlanSection extends StatelessWidget {
  const _CommunicationPlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Communication Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 200),
        if (isMobile)
          _MobileCommunicationPlanActions()
        else
          const _DesktopCommunicationPlanActions(),
      ],
    );
  }
}

class _DesktopCommunicationPlanActions extends StatelessWidget {
  const _DesktopCommunicationPlanActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text:
                    'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () =>
              ExecutionPlanInterfaceManagementPlanScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileCommunicationPlanActions extends StatelessWidget {
  const _MobileCommunicationPlanActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () =>
              ExecutionPlanInterfaceManagementPlanScreen.open(context),
        ),
      ],
    );
  }
}

class ExecutionPlanInterfaceManagementPlanScreen extends StatelessWidget {
  const ExecutionPlanInterfaceManagementPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const ExecutionPlanInterfaceManagementPlanScreen()),
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
                  activeItemLabel:
                      'Execution Plan - Interface Management Plan'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ExecutionPlanHeader(
                        onBack: () => Navigator.maybePop(context)),
                    const SizedBox(height: 32),
                    const _SectionIntro(
                        title: 'Execution Plan - Interface Management Plan'),
                    const SizedBox(height: 24),
                    const _ExecutionPlanForm(
                      title: 'Execution Plan - Interface Management Plan',
                      hintText:
                          'Summarize interface management plan objectives and control points.',
                      noteKey: 'execution_interface_management_plan',
                    ),
                    const SizedBox(height: 32),
                    const _InterfaceManagementPlanForm(),
                    const SizedBox(height: 48),
                    const _InterfaceManagementPlanSection(),
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

class _InterfaceManagementPlanForm extends StatelessWidget {
  const _InterfaceManagementPlanForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interface Management Plan Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Text(
            'Stakeholder identification process systematically identifies all parties who may be affected by or can influence the project, analyzing their interests, influence levels, and developing appropriate engagement strategies.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _InterfaceManagementPlanSection extends StatelessWidget {
  const _InterfaceManagementPlanSection();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interface Management Plan',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 200),
        if (isMobile)
          _MobileInterfaceManagementPlanActions()
        else
          const _DesktopInterfaceManagementPlanActions(),
      ],
    );
  }
}

class _DesktopInterfaceManagementPlanActions extends StatelessWidget {
  const _DesktopInterfaceManagementPlanActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(width: 32),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AiTipCard(
                text:
                    'Focus on major risks associated with each potential solution.',
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _YellowActionButton(
          label: 'Next',
          onPressed: () =>
              ExecutionPlanInterfaceManagementOverviewScreen.open(context),
        ),
      ],
    );
  }
}

class _MobileInterfaceManagementPlanActions extends StatelessWidget {
  const _MobileInterfaceManagementPlanActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _InfoBadge(),
        const SizedBox(height: 20),
        const _AiTipCard(
          text: 'Focus on major risks associated with each potential solution.',
        ),
        const SizedBox(height: 20),
        _YellowActionButton(
          label: 'Next',
          onPressed: () =>
              ExecutionPlanInterfaceManagementOverviewScreen.open(context),
        ),
      ],
    );
  }
}
