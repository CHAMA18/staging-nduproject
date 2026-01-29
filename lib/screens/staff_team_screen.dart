import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/models/staffing_row.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/design_deliverables_screen.dart';
import 'package:ndu_project/screens/team_meetings_screen.dart';
import 'package:ndu_project/services/execution_phase_service.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/staff_team_resource_grid.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart' as launch;

class StaffTeamScreen extends StatefulWidget {
  const StaffTeamScreen({super.key});

  static void open(BuildContext context) {
    PhaseTransitionHelper.pushPhaseAware(
      context: context,
      builder: (_) => const StaffTeamScreen(),
      destinationCheckpoint: 'staff_team',
    );
  }

  @override
  State<StaffTeamScreen> createState() => _StaffTeamScreenState();
}

class _StaffTeamScreenState extends State<StaffTeamScreen> {
  List<StaffingRow> _staffingRows = [];
  List<launch.LaunchEntry> _onboardingActions = [];
  List<launch.LaunchEntry> _coverageRisks = [];
  bool _loading = true;
  Timer? _autoSaveDebounce;

  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final rows =
          await ExecutionPhaseService.loadStaffingRows(projectId: projectId);

      // Also load other sections using the standard method
      final data = await ExecutionPhaseService.loadPageData(
        projectId: projectId,
        pageKey: 'staff_team',
      );

      if (mounted) {
        setState(() {
          _staffingRows = rows;
          _onboardingActions = data?['onboardingActions']
                  ?.map((e) => launch.LaunchEntry(
                        title: e.title,
                        details: e.details,
                        status: e.status,
                      ))
                  .toList() ??
              [];
          _coverageRisks = data?['coverageRisks']
                  ?.map((e) => launch.LaunchEntry(
                        title: e.title,
                        details: e.details,
                        status: e.status,
                      ))
                  .toList() ??
              [];
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading staff team data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onStaffingRowsChanged(List<StaffingRow> rows) {
    setState(() => _staffingRows = rows);
    _autoSave();
  }

  void _autoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 1500), () {
      _persistChanges();
    });
  }

  Future<void> _persistChanges() async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) return;

    try {
      await ExecutionPhaseService.saveStaffingRows(
        projectId: projectId,
        rows: _staffingRows,
        userId: FirebaseAuth.instance.currentUser?.uid,
      );

      // Also save other sections
      await ExecutionPhaseService.savePageData(
        projectId: projectId,
        pageKey: 'staff_team',
        sections: {
          'onboardingActions': _onboardingActions,
          'coverageRisks': _coverageRisks,
        },
        userId: FirebaseAuth.instance.currentUser?.uid,
      );
    } catch (e) {
      debugPrint('Error persisting staff team data: $e');
    }
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: 'Staff Team',
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding, vertical: isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else ...[
              // Staffing Needs - Resource Grid
              StaffTeamResourceGrid(
                rows: _staffingRows,
                onRowsChanged: _onStaffingRowsChanged,
              ),
              const SizedBox(height: 24),
              // Onboarding Actions
              launch.LaunchEditableSection(
                title: 'Onboarding actions',
                description:
                    'List onboarding steps and owners to get people productive.',
                entries: _onboardingActions,
                onAdd: () => _addOnboardingAction(),
                onRemove: (i) {
                  setState(() => _onboardingActions.removeAt(i));
                  _autoSave();
                },
                onEdit: (i, entry) => _editOnboardingAction(i, entry),
              ),
              const SizedBox(height: 16),
              // Coverage Risks
              launch.LaunchEditableSection(
                title: 'Coverage risks',
                description: 'Document gaps or risks in team coverage.',
                entries: _coverageRisks,
                onAdd: () => _addCoverageRisk(),
                onRemove: (i) {
                  setState(() => _coverageRisks.removeAt(i));
                  _autoSave();
                },
                onEdit: (i, entry) => _editCoverageRisk(i, entry),
              ),
            ],
            const SizedBox(height: 24),
            LaunchPhaseNavigation(
              backLabel: 'Back: Design Deliverables',
              nextLabel: 'Next: Team Meetings',
              onBack: () => DesignDeliverablesScreen.open(context),
              onNext: () => TeamMeetingsScreen.open(context),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Staff Team Orchestration',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        const SizedBox(height: 6),
        Text(
          _loading ? 'Execution Phase · Loading...' : 'Execution Phase',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          "Strategize your project's human capital requirements. Identify core roles, determine resource allocation, and align staffing costs with your project's execution timeline.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4B5563),
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Future<void> _addOnboardingAction() async {
    final entry = await launch.showLaunchEntryDialog(
      context,
      titleLabel: 'Action / owner',
      detailsLabel: 'Details',
      includeStatus: true,
    );
    if (entry != null && mounted) {
      setState(() => _onboardingActions.add(entry));
      _autoSave();
    }
  }

  Future<void> _editOnboardingAction(
      int index, launch.LaunchEntry currentEntry) async {
    final entry = await launch.showLaunchEntryDialog(
      context,
      titleLabel: 'Action / owner',
      detailsLabel: 'Details',
      includeStatus: true,
      initialEntry: currentEntry,
    );
    if (entry != null && mounted) {
      setState(() => _onboardingActions[index] = entry);
      _autoSave();
    }
  }

  Future<void> _addCoverageRisk() async {
    final entry = await launch.showLaunchEntryDialog(
      context,
      titleLabel: 'Risk',
      detailsLabel: 'Details',
      includeStatus: true,
    );
    if (entry != null && mounted) {
      setState(() => _coverageRisks.add(entry));
      _autoSave();
    }
  }

  Future<void> _editCoverageRisk(
      int index, launch.LaunchEntry currentEntry) async {
    final entry = await launch.showLaunchEntryDialog(
      context,
      titleLabel: 'Risk',
      detailsLabel: 'Details',
      includeStatus: true,
      initialEntry: currentEntry,
    );
    if (entry != null && mounted) {
      setState(() => _coverageRisks[index] = entry);
      _autoSave();
    }
  }
}
