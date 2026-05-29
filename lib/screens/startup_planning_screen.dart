import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/pdf_export_helper.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

/// G7 Fix: Startup Planning overview screen now reads real data from the
/// `startup_planning` Firestore sub-collection instead of displaying
/// hardcoded placeholder metrics.
///
/// The screen aggregates readiness scores, checklist completion counts,
/// launch window dates, and hypercare duration from the four sub-pages
/// (Operations, Hypercare, DevOps, CloseOut) and displays live metrics.
class StartUpPlanningScreen extends StatefulWidget {
  const StartUpPlanningScreen({super.key});

  @override
  State<StartUpPlanningScreen> createState() => _StartUpPlanningScreenState();
}

class _StartUpPlanningScreenState extends State<StartUpPlanningScreen> {
  bool _isLoading = true;

  // Aggregated metrics from sub-pages
  int _readinessScore = 0;
  int _openReadinessTasks = 0;
  String _launchWindow = 'Not set';
  int _hypercareDays = 0;

  // Checklist data from sub-pages
  List<_ChecklistItem> _goLiveChecklist = [];
  List<_BulletItem> _trainingItems = [];
  List<_TimelineStep> _cutoverSteps = [];
  List<_ChecklistItem> _hypercareChecklist = [];
  List<_BulletItem> _opsHandoffItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Read all 4 sub-page documents in parallel
      final docs = await Future.wait([
        _loadDoc(projectId, 'operations_plan_manual'),
        _loadDoc(projectId, 'hypercare_plan'),
        _loadDoc(projectId, 'devops_readiness'),
        _loadDoc(projectId, 'closeout_plan'),
      ]);

      final opsData = docs[0];
      final hcData = docs[1];
      final devopsData = docs[2];
      final closeoutData = docs[3];

      // ── Compute readiness scores ──
      final opsReadiness = _computeReadiness(opsData, _opsChecks);
      final hcReadiness = _computeReadiness(hcData, _hcChecks);
      final devopsReadiness = _computeReadiness(devopsData, _devopsChecks);
      final closeoutReadiness = _computeReadiness(closeoutData, _closeoutChecks);

      final avgReadiness =
          [opsReadiness, hcReadiness, devopsReadiness, closeoutReadiness]
              .fold<int>(0, (s, v) => s + v) ~/
          4;

      // ── Count open tasks (incomplete checklist items) ──
      final openOps = _countIncompleteChecklist(opsData, [
        'runbooks',
        'monitoringItems',
        'recoveryItems',
      ]);
      final openHc = _countIncompleteChecklist(hcData, [
        'validationChecks',
        'watchItems',
        'exitCriteria',
      ]);
      final openDevops = _countIncompleteChecklist(devopsData, [
        'observabilityChecks',
        'secretsChecks',
        'releaseChecklist',
      ]);
      final openCloseout = _countIncompleteChecklist(closeoutData, [
        'acceptanceItems',
        'handoverArtifacts',
        'knowledgeTransfer',
        'residualActions',
        'followOnActions',
      ]);

      // ── Compute launch window from hypercare start date ──
      String launchWindow = 'Not set';
      int hypercareDays = 0;
      if (hcData != null) {
        final startDate = _parseDate(hcData['startDate']);
        final endDate = _parseDate(hcData['endDate']);
        if (startDate != null) {
          final months = [
            '',
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ];
          launchWindow =
              '${months[startDate.month]} ${startDate.day}';
        }
        if (startDate != null && endDate != null) {
          hypercareDays = endDate.difference(startDate).inDays;
        }
      }

      // ── Extract checklist items for display ──
      final goLiveItems = <_ChecklistItem>[];
      // Operations runbooks → go-live readiness
      _extractChecklistTitles(opsData, ['runbooks'], goLiveItems);
      // Add go-live approval as a checklist item
      if (opsData != null) {
        final approved = opsData['goLiveApproved'] as bool? ?? false;
        goLiveItems.add(_ChecklistItem(
            text: 'Operational sign-off (go-live approval)', done: approved));
      }
      // Add monitoring readiness
      _extractChecklistTitles(opsData, ['monitoringItems'], goLiveItems);

      // Training/enablement items
      final trainingItems = <_BulletItem>[];
      if (opsData != null) {
        final opsOwner = opsData['opsOwner'] as String? ?? '';
        if (opsOwner.isNotEmpty) {
          trainingItems.add(_BulletItem(
              text: 'Operations owner assigned: $opsOwner'));
        }
        final runbookCount = _countDone(opsData, 'runbookRegister');
        final totalRunbooks = _countTotal(opsData, 'runbookRegister');
        trainingItems.add(_BulletItem(
            text:
                'Runbooks reviewed: $runbookCount/$totalRunbooks'));
        if (opsData['supportHours'] != null) {
          trainingItems.add(_BulletItem(
              text:
                  'Support hours defined: ${opsData['supportHours']}'));
        }
      }
      if (trainingItems.isEmpty) {
        trainingItems.addAll([
          _BulletItem(text: 'Role-based training sessions scheduled for all teams.'),
          _BulletItem(text: 'Runbooks distributed and validated with support leads.'),
          _BulletItem(text: 'Internal FAQ and escalation guides published.'),
        ]);
      }

      // Cutover steps from hypercare data
      final cutoverSteps = <_TimelineStep>[];
      if (hcData != null) {
        final hcLead = hcData['hypercareLead'] as String? ?? '';
        cutoverSteps.add(_TimelineStep(
            time: 'T-48h',
            task: hcLead.isNotEmpty
                ? 'Freeze scope and final smoke tests (Lead: $hcLead)'
                : 'Freeze scope and final smoke tests'));
        cutoverSteps.add(const _TimelineStep(
            time: 'T-24h', task: 'Data migration + validation checks'));
        cutoverSteps.add(const _TimelineStep(
            time: 'T-4h',
            task: 'Enable monitoring + switch traffic routing'));
        cutoverSteps.add(const _TimelineStep(
            time: 'T+0', task: 'Launch announcement + live verification'));
        final warRoom = hcData['warRoomChannel'] as String? ?? '';
        cutoverSteps.add(_TimelineStep(
            time: 'T+4h',
            task: warRoom.isNotEmpty
                ? 'Hypercare war room begins ($warRoom)'
                : 'Hypercare war room begins'));
      }
      if (cutoverSteps.isEmpty) {
        cutoverSteps.addAll([
          const _TimelineStep(time: 'T-48h', task: 'Freeze scope and final smoke tests'),
          const _TimelineStep(time: 'T-24h', task: 'Data migration + validation checks'),
          const _TimelineStep(time: 'T-4h', task: 'Enable monitoring + switch traffic routing'),
          const _TimelineStep(time: 'T+0', task: 'Launch announcement + live verification'),
          const _TimelineStep(time: 'T+4h', task: 'Hypercare war room begins'),
        ]);
      }

      // Hypercare checklist
      final hcChecklist = <_ChecklistItem>[];
      _extractChecklistTitles(hcData, ['validationChecks', 'exitCriteria'], hcChecklist);
      if (hcChecklist.isEmpty) {
        hcChecklist.addAll([
          const _ChecklistItem(text: 'Daily incident review with owners', done: false),
          const _ChecklistItem(text: 'Real-time SLA tracking dashboard', done: false),
          const _ChecklistItem(text: 'Bug triage and prioritization within 2 hours', done: false),
        ]);
      }

      // Ops handoff items
      final opsHandoffItems = <_BulletItem>[];
      if (closeoutData != null) {
        final deliveryOwner = closeoutData['deliveryOwner'] as String? ?? '';
        final supportOwner = closeoutData['supportOwner'] as String? ?? '';
        if (deliveryOwner.isNotEmpty) {
          opsHandoffItems.add(_BulletItem(text: 'Delivery owner: $deliveryOwner'));
        }
        if (supportOwner.isNotEmpty) {
          opsHandoffItems.add(_BulletItem(text: 'Support owner: $supportOwner'));
        }
        final handoffDone = _countDone(closeoutData, 'handoverArtifacts');
        final handoffTotal = _countTotal(closeoutData, 'handoverArtifacts');
        opsHandoffItems.add(_BulletItem(
            text: 'Handoff artifacts completed: $handoffDone/$handoffTotal'));
        final closeoutApproved =
            closeoutData['closeoutApproved'] as bool? ?? false;
        opsHandoffItems.add(_BulletItem(
            text: closeoutApproved
                ? 'Close-out approval granted'
                : 'Close-out approval pending'));
      }
      if (opsHandoffItems.isEmpty) {
        opsHandoffItems.addAll([
          const _BulletItem(text: 'Ops runbooks completed and reviewed'),
          const _BulletItem(text: 'Support contacts and SLAs shared with teams'),
          const _BulletItem(text: 'Monthly health checks scheduled'),
        ]);
      }

      if (mounted) {
        setState(() {
          _readinessScore = avgReadiness;
          _openReadinessTasks =
              openOps + openHc + openDevops + openCloseout;
          _launchWindow = launchWindow;
          _hypercareDays = hypercareDays;
          _goLiveChecklist = goLiveItems;
          _trainingItems = trainingItems;
          _cutoverSteps = cutoverSteps;
          _hypercareChecklist = hcChecklist;
          _opsHandoffItems = opsHandoffItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('StartUpPlanningScreen._loadData error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _loadDoc(
      String projectId, String docId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('startup_planning')
          .doc(docId)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Error loading $docId: $e');
      return null;
    }
  }

  // ── Readiness computation helpers ──

  /// Compute a 0-100 readiness score by checking key fields in a sub-page doc.
  int _computeReadiness(
      Map<String, dynamic>? data, List<String> checkFields) {
    if (data == null) return 0;
    int passed = 0;
    for (final field in checkFields) {
      final value = data[field];
      if (value is String && value.trim().isNotEmpty) {
        passed++;
      } else if (value is bool && value) {
        passed++;
      } else if (value is List && value.isNotEmpty) {
        // Check if any checklist item is done
        final hasDone = value.any((item) {
          if (item is Map) return item['done'] == true;
          return false;
        });
        if (hasDone) passed++;
      }
    }
    return checkFields.isEmpty
        ? 0
        : ((passed / checkFields.length) * 100).round();
  }

  static const _opsChecks = [
    'opsOwner',
    'engineeringOwner',
    'sla',
    'runbooks',
    'monitoringItems',
    'goLiveApproved',
  ];

  static const _hcChecks = [
    'startDate',
    'endDate',
    'hypercareLead',
    'supportLead',
    'validationChecks',
    'exitCriteria',
    'handoverReady',
  ];

  static const _devopsChecks = [
    'releaseOwner',
    'platformOwner',
    'rollbackStrategy',
    'observabilityChecks',
    'secretsChecks',
    'devOpsApproved',
  ];

  static const _closeoutChecks = [
    'deliveryOwner',
    'supportOwner',
    'acceptanceItems',
    'handoverArtifacts',
    'knowledgeTransfer',
    'closeoutApproved',
  ];

  /// Count incomplete checklist items across specified list fields.
  int _countIncompleteChecklist(
      Map<String, dynamic>? data, List<String> listFields) {
    if (data == null) return 0;
    int count = 0;
    for (final field in listFields) {
      final value = data[field];
      if (value is List) {
        for (final item in value) {
          if (item is Map && item['done'] != true) count++;
        }
      }
    }
    return count;
  }

  /// Extract checklist titles from specified list fields into a display list.
  void _extractChecklistTitles(Map<String, dynamic>? data,
      List<String> listFields, List<_ChecklistItem> target) {
    if (data == null) return;
    for (final field in listFields) {
      final value = data[field];
      if (value is List) {
        for (final item in value) {
          if (item is Map) {
            target.add(_ChecklistItem(
              text: item['title'] as String? ?? 'Untitled',
              done: item['done'] as bool? ?? false,
            ));
          }
        }
      }
    }
  }

  int _countDone(Map<String, dynamic>? data, String field) {
    if (data == null) return 0;
    final value = data[field];
    if (value is! List) return 0;
    return value
        .where((item) => item is Map && item['status'] == 'Ready' || (item is Map && item['done'] == true))
        .length;
  }

  int _countTotal(Map<String, dynamic>? data, String field) {
    if (data == null) return 0;
    final value = data[field];
    if (value is! List) return 0;
    return value.length;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 20.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Start-Up Planning'),
            ),
            Expanded(
              child: Stack(
                children: [
                    MobileSidebarHamburger(
                      sidebar: const InitiationLikeSidebar(
                        activeItemLabel: 'Start-Up Planning',
                      ),
                    ),
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final gap = 24.0;
                        final twoCol = width >= 980;
                        final halfWidth =
                            twoCol ? (width - gap) / 2 : width;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlanningPhaseHeader(
                              title: 'Start-Up Planning',
                              breadcrumbPhase: 'Planning Phase',
                              breadcrumbTitle: 'Startup Planning',
                              onBack: () => PlanningPhaseNavigation.goToPrevious(
                                context,
                                'startup_planning',
                              ), onExportPdf: _exportPdf),
                            const SizedBox(height: 12),
                            const Text(
                              'Plan readiness, go-live criteria, and transition activities.',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            const PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: 'Start-Up Planning',
                              noteKey: 'planning_startup_planning_notes',
                              checkpoint: 'startup_planning',
                              description:
                                  'Summarize launch readiness, dependencies, and cutover approach.',
                            ),
                            const SizedBox(height: 24),
                            _isLoading
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : _ReadinessRow(
                                    readinessScore: _readinessScore,
                                    openTasks: _openReadinessTasks,
                                    launchWindow: _launchWindow,
                                    hypercareDays: _hypercareDays,
                                  ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                    width: halfWidth,
                                    child: _GoLiveChecklistCard(
                                        items: _goLiveChecklist)),
                                SizedBox(
                                    width: halfWidth,
                                    child: _TrainingEnablementCard(
                                        items: _trainingItems)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _CutoverPlanCard(steps: _cutoverSteps),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                    width: halfWidth,
                                    child: _HypercarePlanCard(
                                        items: _hypercareChecklist)),
                                SizedBox(
                                    width: halfWidth,
                                    child: _OpsHandoffCard(
                                        items: _opsHandoffItems)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            LaunchPhaseNavigation(
                              backLabel:
                                  PlanningPhaseNavigation.backLabel(
                                      'startup_planning'),
                              nextLabel:
                                  PlanningPhaseNavigation.nextLabel(
                                      'startup_planning'),
                              onBack: () =>
                                  PlanningPhaseNavigation.goToPrevious(
                                      context, 'startup_planning'),
                              onNext: () =>
                                  PlanningPhaseNavigation.goToNext(
                                      context, 'startup_planning'),
                            ),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
                  ),
                  const Positioned(
                      right: 24,
                      bottom: 24,
                      child: KazAiChatBubble(positioned: false)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  
  }

  Future<void> _exportPdf() async {
    final projectData = ProjectDataHelper.getData(context);
    await PdfExportHelper.exportScreenPdf(
      context: context,
      screenTitle: 'Startup Planning',
      sections: [
        PdfSection.keyValue('Project Info', [
          {'Project Name': projectData.projectName ?? 'N/A'},
          {'Solution Title': projectData.solutionTitle ?? 'N/A'},
        ]),
        PdfSection.text('Notes', projectData.planningNotes['planning_startup_planning_notes'] ?? 'No data recorded.'),
      ],
    );
  }
}

// ── Data model classes ──

class _ChecklistItem {
  const _ChecklistItem({required this.text, required this.done});
  final String text;
  final bool done;
}

class _BulletItem {
  const _BulletItem({required this.text});
  final String text;
}

class _TimelineStep {
  const _TimelineStep({required this.time, required this.task});
  final String time;
  final String task;
}



class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({
    required this.readinessScore,
    required this.openTasks,
    required this.launchWindow,
    required this.hypercareDays,
  });

  final int readinessScore;
  final int openTasks;
  final String launchWindow;
  final int hypercareDays;

  @override
  Widget build(BuildContext context) {
    final accent = readinessScore >= 80
        ? const Color(0xFF10B981)
        : readinessScore >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
            label: 'Readiness Score',
            value: '$readinessScore%',
            accent: accent),
        _MetricCard(
            label: 'Open Readiness Tasks',
            value: '$openTasks',
            accent: openTasks == 0
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B)),
        _MetricCard(
            label: 'Launch Window',
            value: launchWindow,
            accent: const Color(0xFF2563EB)),
        _MetricCard(
            label: 'Hypercare Days',
            value: hypercareDays > 0 ? '$hypercareDays' : 'Not set',
            accent: const Color(0xFF8B5CF6)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: accent),
          ),
        ],
      ),
    );
  }
}

class _GoLiveChecklistCard extends StatelessWidget {
  const _GoLiveChecklistCard({required this.items});
  final List<_ChecklistItem> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Go-Live Readiness Checklist',
      subtitle: 'Critical items required before launch.',
      child: items.isEmpty
          ? const Text('No checklist items found. Configure Operations page.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))
          : Column(
              children: items
                  .map((item) => _ChecklistRow(text: item.text, done: item.done))
                  .toList(),
            ),
    );
  }
}

class _TrainingEnablementCard extends StatelessWidget {
  const _TrainingEnablementCard({required this.items});
  final List<_BulletItem> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Training & Enablement',
      subtitle: 'Ensure teams are ready for launch day.',
      child: Column(
        children: items
            .map((item) => _BulletRow(text: item.text))
            .toList(),
      ),
    );
  }
}

class _CutoverPlanCard extends StatelessWidget {
  const _CutoverPlanCard({required this.steps});
  final List<_TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Cutover & Launch Timeline',
      subtitle: 'Sequenced steps for the go-live window.',
      child: Column(
        children: steps
            .map((step) => _TimelineRow(time: step.time, task: step.task))
            .toList(),
      ),
    );
  }
}

class _HypercarePlanCard extends StatelessWidget {
  const _HypercarePlanCard({required this.items});
  final List<_ChecklistItem> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Hypercare Plan',
      subtitle: 'Post-launch monitoring and support.',
      child: items.isEmpty
          ? const Text('No hypercare items found. Configure Hypercare page.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))
          : Column(
              children: items
                  .map((item) => _ChecklistRow(text: item.text, done: item.done))
                  .toList(),
            ),
    );
  }
}

class _OpsHandoffCard extends StatelessWidget {
  const _OpsHandoffCard({required this.items});
  final List<_BulletItem> items;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Operations Handoff',
      subtitle: 'Ownership transition after launch.',
      child: Column(
        children: items
            .map((item) => _BulletRow(text: item.text))
            .toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text, required this.done});

  final String text;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.check_circle_outline,
            size: 16,
            color: done ? const Color(0xFF10B981) : const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                    fontSize: 12,
                    color: done ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
                    decoration: done ? null : TextDecoration.none,
                  ))),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF374151), height: 1.4))),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.time, required this.task});

  final String time;
  final String task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          SizedBox(
              width: 60,
              child: Text(time,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600))),
          Expanded(
              child: Text(task,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
        ],
      ),
    );
  }
}
