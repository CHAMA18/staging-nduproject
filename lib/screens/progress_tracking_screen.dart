import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/models/deliverable_row.dart';
import 'package:ndu_project/models/recurring_deliverable_row.dart';
import 'package:ndu_project/models/status_report_row.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/contracts_tracking_screen.dart';
import 'package:ndu_project/screens/team_meetings_screen.dart';
import 'package:ndu_project/services/execution_phase_service.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';
import 'package:ndu_project/widgets/deliverables_tracking_widget.dart';
import 'package:ndu_project/widgets/progress_tracking_dashboard.dart';
import 'package:ndu_project/widgets/recurring_deliverables_widget.dart';
import 'package:ndu_project/widgets/status_reports_widget.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  static void open(BuildContext context) {
    PhaseTransitionHelper.pushPhaseAware(
      context: context,
      builder: (_) => const ProgressTrackingScreen(),
      destinationCheckpoint: 'progress_tracking',
    );
  }

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen>
    with SingleTickerProviderStateMixin {
  List<DeliverableRow> _deliverables = [];
  List<RecurringDeliverableRow> _recurringDeliverables = [];
  List<StatusReportRow> _statusReports = [];
  bool _loading = true;
  Timer? _autoSaveDebounce;
  late TabController _tabController;

  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  String? get _userId {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final deliverables =
          await ExecutionPhaseService.loadDeliverableRows(projectId: projectId);
      final recurring =
          await ExecutionPhaseService.loadRecurringDeliverableRows(
              projectId: projectId);
      final reports = await ExecutionPhaseService.loadStatusReportRows(
          projectId: projectId);

      if (mounted) {
        setState(() {
          _deliverables = deliverables;
          _recurringDeliverables = recurring;
          _statusReports = reports;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress tracking data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _persistChanges() {
    final projectId = _projectId;
    final userId = _userId;
    if (projectId == null || projectId.isEmpty) return;

    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 1500), () async {
      try {
        await Future.wait([
          ExecutionPhaseService.saveDeliverableRows(
            projectId: projectId,
            rows: _deliverables,
            userId: userId,
          ),
          ExecutionPhaseService.saveRecurringDeliverableRows(
            projectId: projectId,
            rows: _recurringDeliverables,
            userId: userId,
          ),
          ExecutionPhaseService.saveStatusReportRows(
            projectId: projectId,
            rows: _statusReports,
            userId: userId,
          ),
        ]);
      } catch (e) {
        debugPrint('Error saving progress tracking data: $e');
      }
    });
  }

  void _handleDeliverablesChanged(List<DeliverableRow> updated) {
    setState(() => _deliverables = updated);
    _persistChanges();
  }

  void _handleRecurringChanged(List<RecurringDeliverableRow> updated) {
    setState(() => _recurringDeliverables = updated);
    _persistChanges();
  }

  void _handleStatusReportsChanged(List<StatusReportRow> updated) {
    setState(() => _statusReports = updated);
    _persistChanges();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: 'Progress Tracking',
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: isMobile ? 16 : 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 24),
            // Content
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dashboard with Summary Cards
                      ProgressTrackingDashboard(
                        deliverables: _deliverables,
                        recurringDeliverables: _recurringDeliverables,
                        statusReports: _statusReports,
                        onDeliverablesChanged: _handleDeliverablesChanged,
                        onRecurringChanged: _handleRecurringChanged,
                        onStatusReportsChanged: _handleStatusReportsChanged,
                      ),
                      const SizedBox(height: 32),
                      // Tab Navigation
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF2563EB),
                        unselectedLabelColor: const Color(0xFF6B7280),
                        indicatorColor: const Color(0xFF2563EB),
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'Deliverable Status Updates'),
                          Tab(text: 'Recurring Deliverables'),
                          Tab(text: 'Status Reports & Asks'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Tab Content
                      SizedBox(
                        height: 600, // Fixed height for TabBarView
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Deliverables Tab
                            SingleChildScrollView(
                              child: DeliverablesTrackingWidget(
                                deliverables: _deliverables,
                                onDeliverablesChanged:
                                    _handleDeliverablesChanged,
                              ),
                            ),
                            // Recurring Tab
                            SingleChildScrollView(
                              child: RecurringDeliverablesWidget(
                                recurringDeliverables: _recurringDeliverables,
                                onRecurringChanged: _handleRecurringChanged,
                              ),
                            ),
                            // Status Reports Tab
                            SingleChildScrollView(
                              child: StatusReportsWidget(
                                statusReports: _statusReports,
                                onStatusReportsChanged:
                                    _handleStatusReportsChanged,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Navigation
                      LaunchPhaseNavigation(
        backLabel: 'Back: Team Meetings',
        nextLabel: 'Next: Contracts Tracking',
        onBack: () => TeamMeetingsScreen.open(context),
        onNext: () => ContractsTrackingScreen.open(context),
      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress Tracking Command Center',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Monitor project progress, track deliverables, manage recurring work, and communicate status updates to stakeholders.",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
