import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/ai_suggesting_textfield.dart';
import 'package:ndu_project/widgets/ai_diagram_panel.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/screens/staff_team_screen.dart';

class ExecutionPlanInterfaceManagementOverviewScreen extends StatelessWidget {
  const ExecutionPlanInterfaceManagementOverviewScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) =>
              const ExecutionPlanInterfaceManagementOverviewScreen()),
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
                      'Execution Plan - Interface Management Overview'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PlanningPhaseHeader(title: 'Execution Plan'),
                    const SizedBox(height: 32),
                    const _ExecutionPlanDetailsSection(),
                    const SizedBox(height: 32),
                    const _InterfaceManagementSection(),
                    const SizedBox(height: 48),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _DoneButton(
                        onPressed: () {
                          // Navigate to main execution flow (Staff Team screen)
                          StaffTeamScreen.open(context);
                          // Alternative: Navigate to progress tracking
                          // context.go('/${AppRoutes.progressTracking}');
                          // Alternative: Navigate to dashboard
                          // context.go('/${AppRoutes.dashboard}');
                        },
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

class _ExecutionPlanDetailsSection extends StatelessWidget {
  const _ExecutionPlanDetailsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Execution Plan Details',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Outline the strategy and actions for the implementation phase.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          _OverviewAiEditor(),
        ],
      ),
    );
  }
}

class _InterfaceManagementSection extends StatelessWidget {
  const _InterfaceManagementSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interface management',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          const SizedBox(height: 24),
          const Text(
            'Interface Architecture Overview',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          const SizedBox(height: 24),
          const _ExternalSystemsRow(
            title: 'External Systems',
            systems: [
              _SystemCard(
                  title: 'Payment Gateway',
                  subtitle: 'Third party',
                  color: Color(0xFFFFE4CC)),
              _SystemCard(
                  title: 'Identity Provider',
                  subtitle: 'SSO Service',
                  color: Color(0xFFFFE4CC)),
              _SystemCard(
                  title: 'CRM System',
                  subtitle: 'Legacy',
                  color: Color(0xFFFFE4CC)),
            ],
          ),
          const SizedBox(height: 24),
          const _ExternalSystemsRow(
            title: 'External Systems',
            systems: [
              _SystemCard(
                  title: 'Api Gateway',
                  subtitle: 'Routing, Security, Monitoring',
                  color: Color(0xFFD4E4FF),
                  fullWidth: true),
            ],
          ),
          const SizedBox(height: 24),
          const _ExternalSystemsRow(
            title: 'External Systems',
            systems: [
              _SystemCard(
                  title: 'Web Application',
                  subtitle: 'Frontend',
                  color: Color(0xFFD4FFD4)),
              _SystemCard(
                  title: 'Business Logic',
                  subtitle: 'Core Services',
                  color: Color(0xFFD4FFD4)),
              _SystemCard(
                  title: 'Data Storage',
                  subtitle: 'Database',
                  color: Color(0xFFD4FFD4)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewAiEditor extends StatefulWidget {
  @override
  State<_OverviewAiEditor> createState() => _OverviewAiEditorState();
}

class _OverviewAiEditorState extends State<_OverviewAiEditor> {
  String _current = '';
  Timer? _saveDebounce;
  DateTime? _lastSavedAt;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _current = value;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () async {
      final trimmed = value.trim();
      final success = await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'execution_plan_interface_management_overview',
        dataUpdater: (data) => data.copyWith(
          planningNotes: {
            ...data.planningNotes,
            'execution_plan_interface_overview': trimmed,
          },
        ),
        showSnackbar: false,
      );
      if (mounted && success) {
        setState(() => _lastSavedAt = DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_current.isEmpty) {
      final saved = ProjectDataHelper.getData(context)
              .planningNotes['execution_plan_interface_overview'] ??
          '';
      if (saved.trim().isNotEmpty) {
        _current = saved;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AiSuggestingTextField(
          fieldLabel: 'Execution Plan Details',
          hintText: 'Input your notes here...',
          sectionLabel: 'Execution Plan - Interface Management Overview',
          showLabel: false,
          initialText: ProjectDataHelper.getData(context)
              .planningNotes['execution_plan_interface_overview'],
          autoGenerate: true,
          autoGenerateSection: 'Interface Management Overview',
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
        const SizedBox(height: 8),
        AiDiagramPanel(
          sectionLabel: 'Interface Management Overview',
          currentTextProvider: () => _current,
          title: 'Generate Interface Management Diagram',
        ),
      ],
    );
  }
}

class _ExternalSystemsRow extends StatelessWidget {
  const _ExternalSystemsRow({required this.title, required this.systems});

  final String title;
  final List<_SystemCard> systems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        if (systems.length == 1 && systems.first.fullWidth)
          systems.first
        else
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: systems,
          ),
      ],
    );
  }
}

class _SystemCard extends StatelessWidget {
  const _SystemCard({
    required this.title,
    required this.subtitle,
    required this.color,
    this.fullWidth = false,
  });

  final String title;
  final String subtitle;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      constraints: fullWidth ? null : const BoxConstraints(minWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Done',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}
