import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ndu_project/screens/deliver_project_closure_screen.dart';
import 'package:ndu_project/screens/scope_completion_screen.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/models/project_data_model.dart';

class GapAnalysisScopeReconcillationScreen extends StatefulWidget {
  const GapAnalysisScopeReconcillationScreen({
    super.key,
    this.activeItemLabel = 'Gap Analysis And Scope Reconcillation',
  });

  final String activeItemLabel;

  static void open(BuildContext context, {String activeItemLabel = 'Gap Analysis And Scope Reconcillation'}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GapAnalysisScopeReconcillationScreen(activeItemLabel: activeItemLabel)),
    );
  }

  @override
  State<GapAnalysisScopeReconcillationScreen> createState() => _GapAnalysisScopeReconcillationScreenState();
}

class _GapAnalysisScopeReconcillationScreenState extends State<GapAnalysisScopeReconcillationScreen> {
  final Set<String> _selectedFocusFilters = {'Gap register'};
  final Set<String> _selectedVisibilityFilters = {'Scope baseline', 'Mitigation backlog'};
  final List<_ImpactRow> _impactRows = [];
  final List<_WorkflowStep> _workflowSteps = [];
  final List<String> _lessonsLearned = [];
  bool _loadedEntries = false;
  bool _aiGenerated = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
                  child: InitiationLikeSidebar(activeItemLabel: widget.activeItemLabel),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PageHeader(),
                        const SizedBox(height: 20),
                        _InfoStrip(isMobile: isMobile),
                        const SizedBox(height: 24),
                        _FilterToolbar(
                          selectedFocusFilters: _selectedFocusFilters,
                          selectedVisibilityFilters: _selectedVisibilityFilters,
                          onFocusFilterChanged: (label) {
                            setState(() {
                              if (_selectedFocusFilters.contains(label)) {
                                _selectedFocusFilters.remove(label);
                              } else {
                                _selectedFocusFilters.add(label);
                              }
                            });
                          },
                          onVisibilityFilterChanged: (label) {
                            setState(() {
                              if (_selectedVisibilityFilters.contains(label)) {
                                _selectedVisibilityFilters.remove(label);
                              } else {
                                _selectedVisibilityFilters.add(label);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 28),
                        const _PrimarySections(),
                        const SizedBox(height: 24),
                        _SecondarySections(
                          impacts: _impactRows,
                          workflowSteps: _workflowSteps,
                          lessons: _lessonsLearned,
                          onWorkflowUpdated: (updated) {
                            setState(() {
                              _workflowSteps
                                ..clear()
                                ..addAll(updated);
                            });
                            _persistEntries();
                          },
                        ),
                        const SizedBox(height: 24),
                        LaunchPhaseNavigation(
                          backLabel: 'Back: Scope Completion',
                          nextLabel: 'Next: Deliver Project',
                          onBack: () => ScopeCompletionScreen.open(context),
                          onNext: () => DeliverProjectClosureScreen.open(context),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadEntries() async {
    if (_loadedEntries) return;
    final provider = ProjectDataHelper.getProvider(context);
    final projectId = provider.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('launch_phase')
          .doc('gap_analysis_scope_reconciliation')
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final impacts = (data['impactAssessment'] as List?)
                ?.whereType<Map>()
                .map((e) => _ImpactRow.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final workflow = (data['reconciliationWorkflow'] as List?)
                ?.whereType<Map>()
                .map((e) => _WorkflowStep.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [];
        final lessons = (data['lessonsLearned'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.trim().isNotEmpty)
                .toList() ??
            [];
        if (!mounted) return;
        setState(() {
          _impactRows
            ..clear()
            ..addAll(impacts);
          _workflowSteps
            ..clear()
            ..addAll(workflow);
          _lessonsLearned
            ..clear()
            ..addAll(lessons);
        });
      }
      _loadedEntries = true;
      if (_impactRows.isEmpty && _workflowSteps.isEmpty && _lessonsLearned.isEmpty) {
        await _populateFromAi();
      }
    } catch (error) {
      debugPrint('Failed to load gap analysis entries: $error');
    }
  }

  Future<void> _populateFromAi() async {
    if (_aiGenerated || _isGenerating) return;
    final projectData = ProjectDataHelper.getData(context);
    final contextText = ProjectDataHelper.buildFepContext(projectData, sectionLabel: 'Gap Analysis & Scope Reconciliation');
    if (contextText.trim().isEmpty) return;

    setState(() => _isGenerating = true);
    Map<String, List<Map<String, dynamic>>> generated = {};
    try {
      generated = await OpenAiServiceSecure().generateLaunchPhaseEntries(
        context: contextText,
        sections: const {
          'impact_assessment': 'Impact assessment results',
          'reconciliation_workflow': 'Reconciliation workflow & backlog',
          'lessons_learned': 'Lessons learned & prevention',
        },
        itemsPerSection: 3,
      );
    } catch (error) {
      debugPrint('Gap analysis AI call failed: $error');
    }

    if (!mounted) return;
    if (_impactRows.isNotEmpty || _workflowSteps.isNotEmpty || _lessonsLearned.isNotEmpty) {
      setState(() => _isGenerating = false);
      _aiGenerated = true;
      return;
    }

    setState(() {
      _impactRows
        ..clear()
        ..addAll(_mapImpactRows(generated['impact_assessment']));
      _workflowSteps
        ..clear()
        ..addAll(_mapWorkflowSteps(generated['reconciliation_workflow']));
      _lessonsLearned
        ..clear()
        ..addAll(_mapLessons(generated['lessons_learned']));
      _isGenerating = false;
    });
    _aiGenerated = true;
    await _persistEntries();
  }

  List<_ImpactRow> _mapImpactRows(List<Map<String, dynamic>>? raw) {
    if (raw == null) return [];
    return raw
        .map((item) => _ImpactRow.fromLaunchEntry(item))
        .where((row) => row.area.isNotEmpty)
        .toList();
  }

  List<_WorkflowStep> _mapWorkflowSteps(List<Map<String, dynamic>>? raw) {
    if (raw == null) return [];
    return raw
        .map((item) => _WorkflowStep.fromLaunchEntry(item))
        .where((step) => step.label.isNotEmpty)
        .toList();
  }

  List<String> _mapLessons(List<Map<String, dynamic>>? raw) {
    if (raw == null) return [];
    return raw
        .map((item) => (item['title'] ?? '').toString().trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  Future<void> _persistEntries() async {
    final provider = ProjectDataHelper.getProvider(context);
    final projectId = provider.projectData.projectId;
    if (projectId == null || projectId.isEmpty) return;

    final payload = {
      'impactAssessment': _impactRows.map((e) => e.toJson()).toList(),
      'reconciliationWorkflow': _workflowSteps.map((e) => e.toJson()).toList(),
      'lessonsLearned': _lessonsLearned,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('launch_phase')
        .doc('gap_analysis_scope_reconciliation')
        .set(payload, SetOptions(merge: true));
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Gap Analysis & Scope Reconciliation',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        SizedBox(height: 8),
        Text(
          'Assess active scope gaps, align remediation plans, and ensure stakeholders stay synchronized before handover.',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    const chips = [
      _InfoChipData(label: 'Project', value: 'AI path capacity uplift – Inception'),
      _InfoChipData(label: 'Track', value: 'Product launch alignment'),
      _InfoChipData(label: 'Delivery stage', value: 'Ready-to-build review'),
      _InfoChipData(label: 'Refresh cadence', value: 'Weekly · Next sync Thu, 10:00 AM'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.start,
      children: chips
          .map((chip) => _InfoChip(
                data: chip,
                isCompact: isMobile,
              ))
          .toList(),
    );
  }
}

class _FilterToolbar extends StatelessWidget {
  const _FilterToolbar({
    required this.selectedFocusFilters,
    required this.selectedVisibilityFilters,
    required this.onFocusFilterChanged,
    required this.onVisibilityFilterChanged,
  });

  final Set<String> selectedFocusFilters;
  final Set<String> selectedVisibilityFilters;
  final ValueChanged<String> onFocusFilterChanged;
  final ValueChanged<String> onVisibilityFilterChanged;

  @override
  Widget build(BuildContext context) {
    const focusOptions = [
      'Gap register',
      'Scope baseline',
      'Impacts',
      'Stakeholders',
      'Mitigation backlog',
    ];
    const visibilityOptions = [
      'Show riskiest gaps',
      'Show closed gaps',
      'Surface dependencies',
    ];

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Focus',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.video_call_outlined, size: 20),
                label: const Text('Schedule reconciliation meeting'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  backgroundColor: const Color(0xFF4154F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: focusOptions
                .map(
                  (option) => ChoiceChip(
                    label: Text(option),
                    selected: selectedFocusFilters.contains(option),
                    onSelected: (_) => onFocusFilterChanged(option),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    selectedColor: primary.withOpacity(0.12),
                    labelStyle: TextStyle(
                      color: selectedFocusFilters.contains(option) ? primary : const Color(0xFF374151),
                      fontWeight: selectedFocusFilters.contains(option) ? FontWeight.w600 : FontWeight.w500,
                    ),
                    backgroundColor: const Color(0xFFF3F4F6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: visibilityOptions
                .map(
                  (option) => FilterChip(
                    label: Text(option),
                    selected: selectedVisibilityFilters.contains(option),
                    onSelected: (_) => onVisibilityFilterChanged(option),
                    showCheckmark: false,
                    selectedColor: const Color(0xFFEEF2FF),
                    labelStyle: TextStyle(
                      color: selectedVisibilityFilters.contains(option) ? const Color(0xFF3730A3) : const Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid();

  static const _SummaryCardData _healthCard = _SummaryCardData(
    title: 'Overall reconciliation health',
    headline: '82% aligned',
    annotation: 'Remaining gaps: 3 critical · 4 moderate',
    accentColor: Color(0xFF2563EB),
    icon: Icons.insights_outlined,
    bullets: [
      'Material gaps tracked across design, ops, and adoption streams',
      'Integration hand-offs validated for 4 of 5 impacted squads',
    ],
    progress: 0.82,
  );

  static const _SummaryCardData _gapsCard = _SummaryCardData(
    title: 'Gaps',
    headline: '12 active',
    annotation: '5 closed this sprint · 2 newly logged',
    accentColor: Color(0xFF0891B2),
    icon: Icons.warning_amber_outlined,
    bullets: [
      'Critical: Prod-ready data sync · Release deployment',
      'Moderate: Support playbooks · API throttling policy',
    ],
  );

  static const _SummaryCardData _scopeCard = _SummaryCardData(
    title: 'Scope',
    headline: '3 packages in review',
    annotation: 'Procurement lead-time risk easing',
    accentColor: Color(0xFF7C3AED),
    icon: Icons.layers_outlined,
    bullets: [
      'MVP scope freeze by 18 Dec · Consumer onboarding locked',
      'Ops enablement kit staged for final sign-off',
    ],
  );

  static const _SummaryCardData _impactCard = _SummaryCardData(
    title: 'Impacts',
    headline: 'High impact areas',
    annotation: 'Primary: Deployment timeline · Secondary: Support load',
    accentColor: Color(0xFFEA580C),
    icon: Icons.auto_graph_outlined,
    bullets: [
      'Schedule: -4 days variance absorbed with overtime budget',
      'Cost: +3.2% attributed to additional QA automation',
    ],
  );

  static const _SummaryCardData _stakeholderCard = _SummaryCardData(
    title: 'Stakeholder alignment',
    headline: 'Managers synced',
    annotation: 'Last exec review: Mon, 2:00 PM',
    accentColor: Color(0xFF059669),
    icon: Icons.groups_outlined,
    bullets: [
      'Adoption: GTM + Customer success validated mitigation path',
      'Ops: Support + Reliability sign-off scheduled for Friday',
    ],
  );

  static const cards = [_healthCard, _gapsCard, _scopeCard, _impactCard, _stakeholderCard];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        double targetWidth;

        if (maxWidth >= 1100) {
          targetWidth = (maxWidth - 40) / 3;
        } else if (maxWidth >= 760) {
          targetWidth = (maxWidth - 20) / 2;
        } else {
          targetWidth = maxWidth;
        }

        final childWidth = maxWidth < 260 ? maxWidth : targetWidth.clamp(260.0, maxWidth);

        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: cards
              .map(
                (card) => _SummaryCard(
                  data: card,
                  width: childWidth,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, required this.width});

  final _SummaryCardData data;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: data.accentColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(data.icon, color: data.accentColor, size: 22),
            ),
            const Spacer(),
            if (data.progress != null)
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: data.progress,
                      strokeWidth: 5,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(data.accentColor),
                    ),
                    Center(
                      child: Text(
                        '${(data.progress! * 100).round()}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          data.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 10),
        Text(
          data.headline,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: data.accentColor),
        ),
        const SizedBox(height: 6),
        Text(
          data.annotation,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 14),
        ...data.bullets.map(
          (bullet) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 6, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bullet,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      constraints: BoxConstraints(minWidth: width),
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 14)),
        ],
      ),
      child: cardContent,
    );
  }
}

class _PrimarySections extends StatelessWidget {
  const _PrimarySections();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sectionWidth = constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GapRegisterCard(width: sectionWidth),
            const SizedBox(height: 20),
            _GapAnalysisRootCauseCard(width: sectionWidth),
            const SizedBox(height: 20),
            _ReconciliationPlanningCard(width: sectionWidth),
          ],
        );
      },
    );
  }
}

class _SecondarySections extends StatelessWidget {
  const _SecondarySections({
    required this.impacts,
    required this.workflowSteps,
    required this.lessons,
    required this.onWorkflowUpdated,
  });

  final List<_ImpactRow> impacts;
  final List<_WorkflowStep> workflowSteps;
  final List<String> lessons;
  final ValueChanged<List<_WorkflowStep>> onWorkflowUpdated;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sectionWidth = constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImpactAssessmentCard(width: sectionWidth, impacts: impacts),
            const SizedBox(height: 20),
            _ReconciliationWorkflowCard(
              width: sectionWidth,
              steps: workflowSteps,
              onWorkflowUpdated: onWorkflowUpdated,
            ),
            const SizedBox(height: 20),
            _LessonsLearnedCard(width: sectionWidth, lessons: lessons),
          ],
        );
      },
    );
  }
}

class _GapRegisterCard extends StatelessWidget {
  const _GapRegisterCard({required this.width});

  final double width;

  static const entries = [
    _GapEntry(
      id: 'GAP-017',
      title: 'Prod-ready data sync misaligned with AI pilot scope',
      stage: 'Critical',
      owner: 'Alex Rivera',
      nextStep: 'Finalize ops readiness checklist',
    ),
    _GapEntry(
      id: 'GAP-011',
      title: 'Support knowledge base misses new workflow',
      stage: 'Moderate',
      owner: 'Priya Nair',
      nextStep: 'Review enablement drafts (due Wed)',
    ),
    _GapEntry(
      id: 'GAP-004',
      title: 'API throttling policy conflicts with projected volume',
      stage: 'Moderate',
      owner: 'Morgan Lee',
      nextStep: 'Update rollout guardrails',
    ),
    _GapEntry(
      id: 'GAP-002',
      title: 'Deployment playbook lacks rollback automation',
      stage: 'Critical',
      owner: 'Jamie Chen',
      nextStep: 'Schedule dry-run with release manager',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      width: width,
      title: 'Gap register & catalog',
      subtitle: 'Tracking priority, owner, and mitigation status for each scope gap.',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Log new gap'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _Pill(label: 'Critical · 3', color: Color(0xFFDC2626)),
              _Pill(label: 'Moderate · 5', color: Color(0xFFF97316)),
              _Pill(label: 'Low · 4', color: Color(0xFF059669)),
              _Pill(label: 'Resolved · 18', color: Color(0xFF2563EB)),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: const [
                      _TableHeaderCell(flex: 3, label: 'Gap'),
                      _TableHeaderCell(flex: 1, label: 'Priority'),
                      _TableHeaderCell(flex: 1, label: 'Owner'),
                      _TableHeaderCell(flex: 3, label: 'Next step'),
                    ],
                  ),
                ),
                ...entries.map(
                  (entry) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.9)),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: _GapTitleCell(entry: entry)),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _PriorityBadge(label: entry.stage),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            entry.owner,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.nextStep,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GapAnalysisRootCauseCard extends StatelessWidget {
  const _GapAnalysisRootCauseCard({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      width: width,
      title: 'Gap analysis & root cause',
      subtitle: 'Identify the underlying sources of each scope discrepancy.',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.playlist_add_check_circle_outlined),
        label: const Text('Share updated findings'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _InsightBlock(
            label: 'Root cause themes',
            points: [
              'Handoffs between solution engineering and product readiness lack coverage on data retention scenarios.',
              'Operational load forecast underestimated AI inference traffic across two customer segments.',
              'Customer success enablement packs were built off outdated pilot assumptions.',
            ],
          ),
          SizedBox(height: 18),
          _InsightBlock(
            label: 'Mitigation confidence',
            points: [
              '80% confidence on deployment gap closure once automation scripts finish QA (ETA Tue).',
              'Stakeholder sign-off pending around support playbooks; expect approval during Thursday sync.',
              'Adoption risk tracked as medium – features flagged for staged rollout with guardrails.',
            ],
          ),
        ],
      ),
    );
  }
}

class _ReconciliationPlanningCard extends StatelessWidget {
  const _ReconciliationPlanningCard({required this.width});

  final double width;

  static const plans = [
    _PlanEntry(title: 'Finalize design to ops handoff', due: 'Due Wed · Release train', owner: 'Ops integration squad', status: 'On track'),
    _PlanEntry(title: 'Validate deployment automation guardrails', due: 'Due Thu · QA automation', owner: 'Quality guild', status: 'At risk'),
    _PlanEntry(title: 'Roll out customer success knowledge base updates', due: 'Due Fri · Adoption pod', owner: 'GTM + CS enablement', status: 'In review'),
    _PlanEntry(title: 'Confirm post-launch monitoring coverage', due: 'Due Sat · Reliability team', owner: 'SRE task force', status: 'Not started'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      width: width,
      title: 'Reconciliation planning',
      subtitle: 'Sequenced closure plan with owners, timelines, and status.',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.task_alt_outlined),
        label: const Text('Export action plan'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: plans
            .map(
              (plan) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                          ),
                        ),
                        _StatusBadge(label: plan.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      plan.due,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF4C1D95)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.owner,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ImpactAssessmentCard extends StatelessWidget {
  const _ImpactAssessmentCard({required this.width, required this.impacts});

  final double width;
  final List<_ImpactRow> impacts;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      width: width,
      title: 'Impact assessment results',
      subtitle: 'Evaluate schedule, cost, quality, and adoption exposure for unresolved gaps.',
      trailing: TextButton.icon(
        onPressed: () {
          showDialog<void>(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.35),
            builder: (_) => _ScenarioMatrixDialog(
              impacts: impacts,
              gaps: _GapRegisterCard.entries,
              plans: _ReconciliationPlanningCard.plans,
            ),
          );
        },
        icon: const Icon(Icons.analytics_outlined),
        label: const Text('View scenario matrix'),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Impact area',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Rating',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Trend',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                if (impacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: _EmptyPanel(label: 'No impact assessment items yet.'),
                  )
                else
                  ...impacts.map(
                    (impact) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  impact.area,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  impact.detail,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _StatusBadge(label: impact.rating),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _TrendPill(label: impact.trend),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioMatrixDialog extends StatefulWidget {
  const _ScenarioMatrixDialog({
    required this.impacts,
    required this.gaps,
    required this.plans,
  });

  final List<_ImpactRow> impacts;
  final List<_GapEntry> gaps;
  final List<_PlanEntry> plans;

  @override
  State<_ScenarioMatrixDialog> createState() => _ScenarioMatrixDialogState();
}

class _ScenarioMatrixDialogState extends State<_ScenarioMatrixDialog> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _categoryFilters = {'All'};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scenarios = _buildScenarios();
    final filtered = _filterScenarios(scenarios);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(context, scenarios.length),
              const SizedBox(height: 16),
              _buildControls(),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildMatrix(filtered)),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildInsightsPanel(filtered)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalCount) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.grid_view_rounded, color: Color(0xFF4338CA)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scenario Matrix',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              Text(
                'Synthesized from your gap register, impact ratings, and plan milestones.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
  Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text('$totalCount scenarios', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Add scenario',
          onPressed: () {
            final fep = ProjectDataHelper.getData(context).frontEndPlanning;
            _openEditDialog(context, currentList: fep.scenarioMatrixItems);
          },
          icon: const Icon(Icons.add, color: Color(0xFF94A3B8)),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Future<void> _openEditDialog(BuildContext context, {ScenarioRecord? record, List<ScenarioRecord>? currentList}) async {
    final id = record?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final titleCtrl = TextEditingController(text: record?.title ?? '');
    final detailCtrl = TextEditingController(text: record?.detail ?? '');
    var category = record?.category ?? 'Custom';
    var owner = record?.owner ?? '';
    var severity = record?.severity ?? 2;
    var likelihood = record?.likelihood ?? 2;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(record == null ? 'Add scenario' : 'Edit scenario'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: 'Detail')),
              const SizedBox(height: 8),
              TextField(onChanged: (v) => owner = v, controller: TextEditingController(text: owner), decoration: const InputDecoration(labelText: 'Owner')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(initialValue: category, items: ['Custom', 'Impact', 'Gap', 'Plan'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => category = v ?? 'Custom', decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: DropdownButtonFormField<int>(initialValue: severity, items: [1, 2, 3].map((i) => DropdownMenuItem(value: i, child: Text('Severity $i'))).toList(), onChanged: (v) => severity = v ?? 2, decoration: const InputDecoration(labelText: 'Severity'))),
                const SizedBox(width: 8),
                Expanded(child: DropdownButtonFormField<int>(initialValue: likelihood, items: [1, 2, 3].map((i) => DropdownMenuItem(value: i, child: Text('Likelihood $i'))).toList(), onChanged: (v) => likelihood = v ?? 2, decoration: const InputDecoration(labelText: 'Likelihood'))),
              ])
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true) return;

    final newRecord = ScenarioRecord(id: id, title: titleCtrl.text.trim(), detail: detailCtrl.text.trim(), category: category, owner: owner, severity: severity, likelihood: likelihood);
    // update provider
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'gap_analysis_scope_reconcillation',
      dataUpdater: (current) {
        final fep = current.frontEndPlanning;
        final updated = FrontEndPlanningData(
          requirements: fep.requirements,
          requirementsNotes: fep.requirementsNotes,
          risks: fep.risks,
          opportunities: fep.opportunities,
          contractVendorQuotes: fep.contractVendorQuotes,
          procurement: fep.procurement,
          security: fep.security,
          allowance: fep.allowance,
          summary: fep.summary,
          technology: fep.technology,
          personnel: fep.personnel,
          infrastructure: fep.infrastructure,
          contracts: fep.contracts,
          requirementItems: fep.requirementItems,
          technicalDebtItems: fep.technicalDebtItems,
          technicalDebtRootCauses: fep.technicalDebtRootCauses,
          technicalDebtTracks: fep.technicalDebtTracks,
          technicalDebtOwners: fep.technicalDebtOwners,
          scenarioMatrixItems: [...fep.scenarioMatrixItems.where((s) => s.id != id), newRecord],
        );
        return current.copyWith(frontEndPlanning: updated);
      },
    );
  }

  Widget _buildControls() {
    const categories = ['All', 'Impact', 'Gap', 'Plan'];
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search scenarios, owners, or tags',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4338CA), width: 1.6)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          children: categories.map((category) {
            final selected = _categoryFilters.contains(category);
            return ChoiceChip(
              label: Text(category),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  _categoryFilters
                    ..clear()
                    ..add(value ? category : 'All');
                  if (category != 'All' && value) {
                    _categoryFilters.remove('All');
                  }
                  if (_categoryFilters.isEmpty) {
                    _categoryFilters.add('All');
                  }
                });
              },
              selectedColor: const Color(0xFF111827),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: const BorderSide(color: Color(0xFFE2E8F0))),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMatrix(List<_ScenarioPoint> scenarios) {
    final grouped = _groupByCell(scenarios);
    const likelihoodLabels = ['Low likelihood', 'Medium likelihood', 'High likelihood'];
    const impactLabels = ['Low impact', 'Medium impact', 'High impact'];

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 110),
            for (int i = 0; i < 3; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _AxisHeader(label: likelihoodLabels[i]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            children: [
              for (int row = 2; row >= 0; row--)
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(width: 110, child: _AxisHeader(label: impactLabels[row], isVertical: true)),
                      for (int col = 0; col < 3; col++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: _MatrixCell(
                              scenarios: grouped[_cellKey(row, col)] ?? const [],
                              tone: _cellTone(row, col),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsPanel(List<_ScenarioPoint> scenarios) {
  final persisted = ProjectDataHelper.getData(context).frontEndPlanning.scenarioMatrixItems.map((r) {
      return _ScenarioPoint(title: r.title, detail: r.detail, category: r.category, owner: r.owner, severity: r.severity, likelihood: r.likelihood);
    }).toList();

    final merged = [...scenarios, ...persisted];
    final sorted = [...merged]..sort((a, b) => b.score.compareTo(a.score));
    final topThree = sorted.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Priority scenarios', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Highest impact and likelihood combinations based on your inputs.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          if (topThree.isEmpty)
            const Text('No scenarios match the current filters.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))
          else
            ...topThree.map((scenario) {
              // locate persisted record id if any
              final match = ProjectDataHelper.getData(context).frontEndPlanning.scenarioMatrixItems.firstWhere((r) => r.title == scenario.title && r.detail == scenario.detail, orElse: () => ScenarioRecord(id: '', title: '', detail: '', category: '', owner: '', severity: 2, likelihood: 2));
              final isPersisted = match.id.isNotEmpty;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(scenario.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                        _ScorePill(score: scenario.score),
                        const SizedBox(width: 8),
                        if (isPersisted)
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () {
                              final rec = ProjectDataHelper.getData(context).frontEndPlanning.scenarioMatrixItems.firstWhere((r) => r.id == match.id);
                              _openEditDialog(context, record: rec);
                            },
                            icon: const Icon(Icons.edit, size: 18),
                          ),
                        if (isPersisted)
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Delete scenario?'), content: const Text('This will remove the scenario from the project.'), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete'))]));
                              if (confirmed == true) {
                                await ProjectDataHelper.updateAndSave(context: context, checkpoint: 'gap_analysis_scope_reconcillation', dataUpdater: (current) {
                                  final fep = current.frontEndPlanning;
                                  final updated = FrontEndPlanningData(
                                    requirements: fep.requirements,
                                    requirementsNotes: fep.requirementsNotes,
                                    risks: fep.risks,
                                    opportunities: fep.opportunities,
                                    contractVendorQuotes: fep.contractVendorQuotes,
                                    procurement: fep.procurement,
                                    security: fep.security,
                                    allowance: fep.allowance,
                                    summary: fep.summary,
                                    technology: fep.technology,
                                    personnel: fep.personnel,
                                    infrastructure: fep.infrastructure,
                                    contracts: fep.contracts,
                                    requirementItems: fep.requirementItems,
                                    technicalDebtItems: fep.technicalDebtItems,
                                    technicalDebtRootCauses: fep.technicalDebtRootCauses,
                                    technicalDebtTracks: fep.technicalDebtTracks,
                                    technicalDebtOwners: fep.technicalDebtOwners,
                                    scenarioMatrixItems: fep.scenarioMatrixItems.where((s) => s.id != match.id).toList(),
                                  );
                                  return current.copyWith(frontEndPlanning: updated);
                                });
                                setState(() {});
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(scenario.detail, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Tag(label: scenario.category),
                        const SizedBox(width: 6),
                        _Tag(label: scenario.owner),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.ios_share_outlined, size: 16),
            label: const Text('Export matrix'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  List<_ScenarioPoint> _buildScenarios() {
    final scenarios = <_ScenarioPoint>[];
    for (final impact in widget.impacts) {
      final severity = _severityFromRating(impact.rating);
      final likelihood = _likelihoodFromTrend(impact.trend);
      scenarios.add(
        _ScenarioPoint(
          title: '${impact.area} exposure',
          detail: impact.detail,
          category: 'Impact',
          owner: impact.area,
          severity: severity,
          likelihood: likelihood,
        ),
      );
    }
    for (final gap in widget.gaps) {
      final severity = _severityFromStage(gap.stage);
      final likelihood = severity;
      scenarios.add(
        _ScenarioPoint(
          title: gap.title,
          detail: gap.nextStep,
          category: 'Gap',
          owner: gap.owner,
          severity: severity,
          likelihood: likelihood,
        ),
      );
    }
    for (final plan in widget.plans) {
      final severity = _severityFromPlanStatus(plan.status);
      final likelihood = _likelihoodFromPlanStatus(plan.status);
      scenarios.add(
        _ScenarioPoint(
          title: plan.title,
          detail: '${plan.due} · ${plan.owner}',
          category: 'Plan',
          owner: plan.owner,
          severity: severity,
          likelihood: likelihood,
        ),
      );
    }
    return scenarios;
  }

  List<_ScenarioPoint> _filterScenarios(List<_ScenarioPoint> scenarios) {
    final query = _searchController.text.trim().toLowerCase();
    return scenarios.where((scenario) {
      final matchesCategory = _categoryFilters.contains('All') || _categoryFilters.contains(scenario.category);
      final matchesQuery = query.isEmpty ||
          scenario.title.toLowerCase().contains(query) ||
          scenario.detail.toLowerCase().contains(query) ||
          scenario.owner.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  Map<String, List<_ScenarioPoint>> _groupByCell(List<_ScenarioPoint> scenarios) {
    final map = <String, List<_ScenarioPoint>>{};
    for (final scenario in scenarios) {
      final key = _cellKey(scenario.severity - 1, scenario.likelihood - 1);
      map.putIfAbsent(key, () => []).add(scenario);
    }
    return map;
  }

  int _severityFromRating(String rating) {
    switch (rating.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 2;
    }
  }

  int _severityFromStage(String stage) {
    switch (stage.toLowerCase()) {
      case 'critical':
        return 3;
      case 'moderate':
        return 2;
      case 'low':
        return 1;
      default:
        return 2;
    }
  }

  int _severityFromPlanStatus(String status) {
    switch (status.toLowerCase()) {
      case 'at risk':
        return 3;
      case 'in review':
        return 2;
      case 'not started':
        return 3;
      default:
        return 1;
    }
  }

  int _likelihoodFromTrend(String trend) {
    switch (trend.toLowerCase()) {
      case 'needs attention':
        return 3;
      case 'stable':
        return 2;
      case 'improving':
        return 1;
      default:
        return 2;
    }
  }

  int _likelihoodFromPlanStatus(String status) {
    switch (status.toLowerCase()) {
      case 'at risk':
        return 3;
      case 'in review':
        return 2;
      case 'not started':
        return 3;
      default:
        return 1;
    }
  }

  String _cellKey(int severityIndex, int likelihoodIndex) => '$severityIndex-$likelihoodIndex';

  Color _cellTone(int severityIndex, int likelihoodIndex) {
    final score = (severityIndex + 1) * (likelihoodIndex + 1);
    if (score >= 7) return const Color(0xFFFEE2E2);
    if (score >= 4) return const Color(0xFFFEF3C7);
    return const Color(0xFFECFDF3);
  }
}

class _ScenarioPoint {
  const _ScenarioPoint({
    required this.title,
    required this.detail,
    required this.category,
    required this.owner,
    required this.severity,
    required this.likelihood,
  });

  final String title;
  final String detail;
  final String category;
  final String owner;
  final int severity;
  final int likelihood;

  int get score => severity * likelihood;
}

class _MatrixCell extends StatelessWidget {
  const _MatrixCell({required this.scenarios, required this.tone});

  final List<_ScenarioPoint> scenarios;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${scenarios.length} scenario${scenarios.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              const Spacer(),
              if (scenarios.isNotEmpty) _ScorePill(score: scenarios.map((s) => s.score).reduce((a, b) => a > b ? a : b)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: scenarios.isEmpty
                ? const Center(child: Text('—', style: TextStyle(color: Color(0xFF94A3B8))))
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: scenarios.length.clamp(0, 3),
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final scenario = scenarios[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                scenario.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _Tag(label: scenario.category),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AxisHeader extends StatelessWidget {
  const _AxisHeader({required this.label, this.isVertical = false});

  final String label;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        textAlign: isVertical ? TextAlign.right : TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (score >= 7) {
      color = const Color(0xFFDC2626);
    } else if (score >= 4) {
      color = const Color(0xFFF59E0B);
    } else {
      color = const Color(0xFF10B981);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('Score $score', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
    );
  }
}

class _ReconciliationWorkflowCard extends StatefulWidget {
  const _ReconciliationWorkflowCard({
    required this.width,
    required this.steps,
    required this.onWorkflowUpdated,
  });

  final double width;
  final List<_WorkflowStep> steps;
  final ValueChanged<List<_WorkflowStep>> onWorkflowUpdated;

  @override
  State<_ReconciliationWorkflowCard> createState() => _ReconciliationWorkflowCardState();
}

class _ReconciliationWorkflowCardState extends State<_ReconciliationWorkflowCard> {
  static const _columns = [
    _WorkflowBoardColumnConfig(
      keyName: 'planned',
      label: 'Planned',
      accent: Color(0xFF94A3B8),
    ),
    _WorkflowBoardColumnConfig(
      keyName: 'active',
      label: 'Active',
      accent: Color(0xFF2563EB),
    ),
    _WorkflowBoardColumnConfig(
      keyName: 'in_progress',
      label: 'In Progress',
      accent: Color(0xFFF59E0B),
    ),
    _WorkflowBoardColumnConfig(
      keyName: 'ongoing',
      label: 'Ongoing',
      accent: Color(0xFF10B981),
    ),
    _WorkflowBoardColumnConfig(
      keyName: 'complete',
      label: 'Complete',
      accent: Color(0xFF16A34A),
    ),
  ];

  late Map<String, List<_WorkflowStep>> _grouped;

  @override
  void initState() {
    super.initState();
    _grouped = _buildGrouped(widget.steps);
  }

  @override
  void didUpdateWidget(covariant _ReconciliationWorkflowCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.steps != widget.steps) {
      _grouped = _buildGrouped(widget.steps);
    }
  }

  String _statusKey(String status) {
    final value = status.toLowerCase();
    if (value.contains('ongoing')) return 'ongoing';
    if (value.contains('active')) return 'active';
    if (value.contains('progress')) return 'in_progress';
    if (value.contains('complete') || value.contains('done')) return 'complete';
    if (value.contains('review')) return 'review';
    return 'planned';
  }

  Map<String, List<_WorkflowStep>> _buildGrouped(List<_WorkflowStep> steps) {
    final grouped = <String, List<_WorkflowStep>>{};
    for (final step in steps) {
      final key = _statusKey(step.status);
      grouped.putIfAbsent(key, () => []).add(step);
    }
    return grouped;
  }

  Future<void> _openAddWorkflowItem() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String status = _columns.first.label;

    final result = await showDialog<_WorkflowStep>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add workflow item'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  items: _columns
                      .map((col) => DropdownMenuItem<String>(
                            value: col.label,
                            child: Text(col.label),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      status = value;
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(
                  _WorkflowStep(
                    label: title,
                    status: status,
                    description: descController.text.trim().isEmpty
                        ? 'Define workflow details.'
                        : descController.text.trim(),
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    setState(() {
      _grouped = _buildGrouped([..._grouped.values.expand((e) => e), result]);
    });
    final updatedList = <_WorkflowStep>[];
    for (final column in _columns) {
      updatedList.addAll(_grouped[column.keyName] ?? const []);
    }
    widget.onWorkflowUpdated(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);

    return _SectionShell(
      width: widget.width,
      title: 'Reconciliation workflow & backlog',
      subtitle: 'Track the lifecycle of gap discovery through launch readiness.',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.view_kanban_outlined),
        label: const Text('Open workflow board'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.steps.isEmpty
            ? const [
                _EmptyPanel(label: 'No workflow items yet.'),
              ]
            : [
                const Text(
                  'Open workflow board',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _columns.map((column) {
                    final items = _grouped[column.keyName] ?? const <_WorkflowStep>[];
                    return SizedBox(
                      width: isMobile ? double.infinity : 260,
                      child: _WorkflowBoardColumn(
                        label: column.label,
                        accent: column.accent,
                        items: items,
                        onAccept: (step) {
                          setState(() {
                            for (final list in _grouped.values) {
                              list.removeWhere((item) =>
                                  item.label == step.label &&
                                  item.description == step.description);
                            }
                            final updated = _WorkflowStep(
                              label: step.label,
                              status: column.label,
                              description: step.description,
                            );
                            _grouped.putIfAbsent(column.keyName, () => []).add(updated);
                          });
                          final updatedList = <_WorkflowStep>[];
                          for (final column in _columns) {
                            updatedList.addAll(_grouped[column.keyName] ?? const []);
                          }
                          widget.onWorkflowUpdated(updatedList);
                        },
                        onDelete: (step) {
                          setState(() {
                            for (final list in _grouped.values) {
                              list.removeWhere((item) =>
                                  item.label == step.label &&
                                  item.description == step.description);
                            }
                          });
                          final updatedList = <_WorkflowStep>[];
                          for (final column in _columns) {
                            updatedList.addAll(_grouped[column.keyName] ?? const []);
                          }
                          widget.onWorkflowUpdated(updatedList);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _openAddWorkflowItem,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add workflow item'),
                  ),
                ),
              ],
      ),
    );
  }
}

class _WorkflowBoardColumnConfig {
  const _WorkflowBoardColumnConfig({
    required this.keyName,
    required this.label,
    required this.accent,
  });

  final String keyName;
  final String label;
  final Color accent;
}

class _WorkflowBoardColumn extends StatelessWidget {
  const _WorkflowBoardColumn({
    required this.label,
    required this.accent,
    required this.items,
    required this.onAccept,
    required this.onDelete,
  });

  final String label;
  final Color accent;
  final List<_WorkflowStep> items;
  final ValueChanged<_WorkflowStep> onAccept;
  final ValueChanged<_WorkflowStep> onDelete;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_WorkflowStep>(
      onWillAccept: (data) => data != null,
      onAccept: onAccept,
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isActive ? accent.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isActive ? accent : const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${items.length}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty && !isActive)
                const Text(
                  'No items yet',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              if (items.isEmpty && isActive)
                const Text(
                  'Drop here',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              if (items.isNotEmpty)
                ...items.map(
                  (item) => _DraggableWorkflowCard(
                    step: item,
                    accent: accent,
                    onDelete: onDelete,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableWorkflowCard extends StatelessWidget {
  const _DraggableWorkflowCard({
    required this.step,
    required this.accent,
    required this.onDelete,
  });

  final _WorkflowStep step;
  final Color accent;
  final ValueChanged<_WorkflowStep> onDelete;

  @override
  Widget build(BuildContext context) {
    final card = _WorkflowBoardCard(
      label: step.label,
      description: step.description,
      accent: accent,
      onDelete: () => onDelete(step),
    );
    return LongPressDraggable<_WorkflowStep>(
      data: step,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: card,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: card,
    );
  }
}

class _WorkflowBoardCard extends StatelessWidget {
  const _WorkflowBoardCard({
    required this.label,
    required this.description,
    required this.accent,
    required this.onDelete,
  });

  final String label;
  final String description;
  final Color accent;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 18,
                tooltip: 'Delete card',
              ),
              Container(
                width: 6,
                height: 18,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _LessonsLearnedCard extends StatelessWidget {
  const _LessonsLearnedCard({required this.width, required this.lessons});

  final double width;
  final List<String> lessons;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      width: width,
      title: 'Lessons learned & prevention',
      subtitle: 'Document leading indicators and preventative practices for future launches.',
      trailing: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.history_edu_outlined),
        label: const Text('Log follow-up insight'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lessons.isEmpty
            ? const [
                _EmptyPanel(label: 'No lessons captured yet.'),
              ]
            : lessons
                .map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.check_circle, size: 18, color: Color(0xFF22C55E)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            line,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final double width;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: trailing!,
              ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    );

    return Container(
      width: width,
      constraints: BoxConstraints(minWidth: width),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 12)),
        ],
      ),
      child: content,
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.data, required this.isCompact});

  final _InfoChipData data;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: TextStyle(fontSize: isCompact ? 13 : 14, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
          ),
        ],
      ),
    );
  }
}

class _GapTitleCell extends StatelessWidget {
  const _GapTitleCell({required this.entry});

  final _GapEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.id,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 4),
        Text(
          entry.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
        ),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.label});

  final String label;

  Color _badgeColor() {
    switch (label.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFECACA);
      case 'moderate':
        return const Color(0xFFFDE68A);
      case 'low':
        return const Color(0xFFCFFAFE);
      default:
        return const Color(0xFFE0E7FF);
    }
  }

  Color _textColor() {
    switch (label.toLowerCase()) {
      case 'critical':
        return const Color(0xFFB91C1C);
      case 'moderate':
        return const Color(0xFFB45309);
      case 'low':
        return const Color(0xFF0F766E);
      default:
        return const Color(0xFF3730A3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _badgeColor(), borderRadius: BorderRadius.circular(30)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textColor()),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  Color _statusColor() {
    switch (label.toLowerCase()) {
      case 'on track':
        return const Color(0xFF16A34A);
      case 'at risk':
        return const Color(0xFFF97316);
      case 'in review':
        return const Color(0xFF2563EB);
      case 'not started':
        return const Color(0xFF4B5563);
      case 'complete':
        return const Color(0xFF0F766E);
      case 'upcoming':
        return const Color(0xFF6366F1);
      case 'planned':
        return const Color(0xFF5B21B6);
      default:
        return const Color(0xFF111827);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(30)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.label});

  final String label;

  Color _trendColor() {
    switch (label.toLowerCase()) {
      case 'improving':
        return const Color(0xFF16A34A);
      case 'stable':
        return const Color(0xFF2563EB);
      case 'needs attention':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF4B5563);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _trendColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label.toLowerCase() == 'needs attention' ? Icons.warning_amber_outlined : Icons.trending_up,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _InsightBlock extends StatelessWidget {
  const _InsightBlock({required this.label, required this.points});

  final String label;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 12),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell({required this.label, this.flex = 1});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.3),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _InfoChipData {
  const _InfoChipData({required this.label, required this.value});

  final String label;
  final String value;
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.headline,
    required this.annotation,
    required this.accentColor,
    required this.icon,
    required this.bullets,
    this.progress,
  });

  final String title;
  final String headline;
  final String annotation;
  final Color accentColor;
  final IconData icon;
  final List<String> bullets;
  final double? progress;
}

class _GapEntry {
  const _GapEntry({
    required this.id,
    required this.title,
    required this.stage,
    required this.owner,
    required this.nextStep,
  });

  final String id;
  final String title;
  final String stage;
  final String owner;
  final String nextStep;
}

class _PlanEntry {
  const _PlanEntry({required this.title, required this.due, required this.owner, required this.status});

  final String title;
  final String due;
  final String owner;
  final String status;
}

class _ImpactRow {
  const _ImpactRow({required this.area, required this.rating, required this.trend, required this.detail});

  final String area;
  final String rating;
  final String trend;
  final String detail;

  Map<String, dynamic> toJson() => {
        'area': area,
        'rating': rating,
        'trend': trend,
        'detail': detail,
      };

  factory _ImpactRow.fromJson(Map<String, dynamic> json) {
    return _ImpactRow(
      area: json['area']?.toString() ?? '',
      rating: json['rating']?.toString() ?? 'Medium',
      trend: json['trend']?.toString() ?? 'Stable',
      detail: json['detail']?.toString() ?? '',
    );
  }

  factory _ImpactRow.fromLaunchEntry(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString().trim();
    final detail = (json['details'] ?? '').toString().trim();
    final status = (json['status'] ?? '').toString().trim();
    var rating = 'Medium';
    var trend = 'Stable';
    if (status.isNotEmpty) {
      final parts = status
          .split(RegExp(r'[|/,-]'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        rating = parts[0];
        trend = parts[1];
      } else if (parts.length == 1) {
        rating = parts[0];
      }
    }
    return _ImpactRow(
      area: title,
      rating: rating,
      trend: trend,
      detail: detail.isEmpty ? 'Update impact details.' : detail,
    );
  }
}

class _WorkflowStep {
  const _WorkflowStep({required this.label, required this.status, required this.description});

  final String label;
  final String status;
  final String description;

  Map<String, dynamic> toJson() => {
        'label': label,
        'status': status,
        'description': description,
      };

  factory _WorkflowStep.fromJson(Map<String, dynamic> json) {
    return _WorkflowStep(
      label: json['label']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Planned',
      description: json['description']?.toString() ?? '',
    );
  }

  factory _WorkflowStep.fromLaunchEntry(Map<String, dynamic> json) {
    final label = (json['title'] ?? '').toString().trim();
    final description = (json['details'] ?? '').toString().trim();
    final status = (json['status'] ?? '').toString().trim();
    return _WorkflowStep(
      label: label,
      status: status.isEmpty ? 'Planned' : status,
      description: description.isEmpty ? 'Define workflow details.' : description,
    );
  }
}
