import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ndu_project/screens/gap_analysis_scope_reconcillation_screen.dart';
import 'package:ndu_project/screens/technical_debt_management_screen.dart';
import 'package:ndu_project/utils/execution_phase_ai_seed.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/responsive.dart';

class PunchlistActionsScreen extends StatefulWidget {
  const PunchlistActionsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PunchlistActionsScreen()),
    );
  }

  @override
  State<PunchlistActionsScreen> createState() => _PunchlistActionsScreenState();
}

class _PunchlistActionsScreenState extends State<PunchlistActionsScreen> {
  static const double _panelMinHeight = 200;

  /*
  final List<_PunchlistInsight> _priorityItems = const [
    _PunchlistInsight(
      title: 'Rework integrations interface alerts',
      owner: 'N. Chan',
      dueIn: 'Due in 2 days',
      severity: _PunchlistSeverity.high,
      status: 'Field team ready',
    ),
    _PunchlistInsight(
      title: 'Validate HVAC balancing readings',
      owner: 'S. Patel',
      dueIn: 'Due Friday',
      severity: _PunchlistSeverity.medium,
      status: 'QA pending',
    ),
    _PunchlistInsight(
      title: 'Backfill cabinet missing fasteners',
      owner: 'L. Santos',
      dueIn: 'Overdue by 1 day',
      severity: _PunchlistSeverity.critical,
      status: 'Waiting on vendor',
    ),
  ];

  final List<_PunchlistInsight> _technicalInsights = const [
    _PunchlistInsight(
      title: 'P-107: Airside zoning dampers',
      owner: 'Systems',
      dueIn: 'QA sign-off 🟢',
      severity: _PunchlistSeverity.medium,
      status: 'Close out ready',
    ),
    _PunchlistInsight(
      title: 'Interface bus failover checks',
      owner: 'Integration',
      dueIn: 'Pending metrics',
      severity: _PunchlistSeverity.low,
      status: 'Monitoring',
    ),
  ];

  final List<_PunchlistInsight> _remediationItems = const [
    _PunchlistInsight(
      title: 'Resource planning aligned with sprint 42',
      owner: 'Operations',
      dueIn: 'In progress',
      severity: _PunchlistSeverity.medium,
      status: 'Capacity 80%',
    ),
    _PunchlistInsight(
      title: 'Vendor escalation touchpoint',
      owner: 'Supply chain',
      dueIn: 'Tomorrow',
      severity: _PunchlistSeverity.high,
      status: 'Meeting booked',
    ),
  ];

  final List<_PunchlistInsight> _fieldExecutionItems = const [
    _PunchlistInsight(
      title: 'Mobile inspections checklist sync',
      owner: 'Field Ops',
      dueIn: 'Sync nightly',
      severity: _PunchlistSeverity.low,
      status: 'Stable',
    ),
    _PunchlistInsight(
      title: 'Crew photo verification backlog',
      owner: 'QA',
      dueIn: 'Need 6 uploads',
      severity: _PunchlistSeverity.medium,
      status: 'Chasers sent',
    ),
  ];

  final List<_PunchlistInsight> _techDebtItems = const [
    _PunchlistInsight(
      title: 'Legacy tag cleanup for zone controllers',
      owner: 'Platform',
      dueIn: 'Sprint 43',
      severity: _PunchlistSeverity.high,
      status: 'Ready for grooming',
    ),
    _PunchlistInsight(
      title: 'Telemetry schema versioning',
      owner: 'Data services',
      dueIn: 'Needs impact review',
      severity: _PunchlistSeverity.medium,
      status: 'Blocked',
    ),
  ];

  final List<_PunchlistInsight> _closureItems = const [
    _PunchlistInsight(
      title: 'Stakeholder walkthrough sign-offs',
      owner: 'PMO',
      dueIn: '3 of 5 complete',
      severity: _PunchlistSeverity.low,
      status: 'Schedule review',
    ),
    _PunchlistInsight(
      title: 'Final acceptance documentation pack',
      owner: 'Quality',
      dueIn: 'Draft ready',
      severity: _PunchlistSeverity.medium,
      status: 'Legal review',
    ),
  ];
  */

  List<_PunchlistInsight> _priorityItems = [];
  List<_PunchlistInsight> _technicalInsights = [];
  List<_PunchlistInsight> _remediationItems = [];
  List<_PunchlistInsight> _fieldExecutionItems = [];
  List<_PunchlistInsight> _techDebtItems = [];
  List<_PunchlistInsight> _closureItems = [];
  List<_DistributionRow> _distributionRows = [];
  List<_ActionVelocityRow> _velocityRows = [];

  bool _isLoading = false;
  bool _autoGenerationTriggered = false;
  bool _isAutoGenerating = false;

  @override
  void initState() {
    super.initState();
    _priorityItems = _defaultPriorityItems();
    _technicalInsights = _defaultTechnicalInsights();
    _remediationItems = _defaultRemediationItems();
    _fieldExecutionItems = _defaultFieldExecutionItems();
    _techDebtItems = _defaultTechDebtItems();
    _closureItems = _defaultClosureItems();
    _distributionRows = _defaultDistributionRows();
    _velocityRows = _defaultVelocityRows();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 18 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Punchlist Actions'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        if (_isLoading) const SizedBox(height: 16),
                        _buildContextHeader(context),
                        const SizedBox(height: 18),
                        _buildPageHeader(context),
                        const SizedBox(height: 26),
                        _buildSummaryGrid(context),
                        const SizedBox(height: 26),
                        _buildMiddleInsights(context),
                        const SizedBox(height: 26),
                        _buildLowerGrid(context),
                        const SizedBox(height: 26),
                        LaunchPhaseNavigation(
                          backLabel:
                              'Back: Gap Analysis & Scope Reconciliation',
                          nextLabel: 'Next: Technical Debt Management',
                          onBack: () =>
                              GapAnalysisScopeReconcillationScreen.open(
                                  context),
                          onNext: () =>
                              TechnicalDebtManagementScreen.open(context),
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

  void _showActionSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _projectId() => ProjectDataHelper.getData(context).projectId;

  Future<void> _loadFromFirestore() async {
    if (_autoGenerationTriggered || _isAutoGenerating) return;
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final doc = await _docRef(projectId).get();
      final data = doc.data() ?? {};
      final priority = _PunchlistInsight.fromList(data['priorityItems']);
      final technical = _PunchlistInsight.fromList(data['technicalInsights']);
      final remediation = _PunchlistInsight.fromList(data['remediationItems']);
      final fieldItems = _PunchlistInsight.fromList(data['fieldExecutionItems']);
      final techDebt = _PunchlistInsight.fromList(data['techDebtItems']);
      final closure = _PunchlistInsight.fromList(data['closureItems']);
      final hasContent = priority.isNotEmpty ||
          technical.isNotEmpty ||
          remediation.isNotEmpty ||
          fieldItems.isNotEmpty ||
          techDebt.isNotEmpty ||
          closure.isNotEmpty;

      setState(() {
        _priorityItems =
            priority.isNotEmpty ? priority : _defaultPriorityItems();
        _technicalInsights =
            technical.isNotEmpty ? technical : _defaultTechnicalInsights();
        _remediationItems =
            remediation.isNotEmpty ? remediation : _defaultRemediationItems();
        _fieldExecutionItems =
            fieldItems.isNotEmpty ? fieldItems : _defaultFieldExecutionItems();
        _techDebtItems =
            techDebt.isNotEmpty ? techDebt : _defaultTechDebtItems();
        _closureItems =
            closure.isNotEmpty ? closure : _defaultClosureItems();
      });
      // Load distribution and velocity table data
      final distData = data['distributionRows'];
      final velData = data['velocityRows'];
      if (distData != null && distData is List && distData.isNotEmpty) {
        _distributionRows = distData.map((e) => _DistributionRow.fromMap(e as Map<String, dynamic>)).toList();
      }
      if (velData != null && velData is List && velData.isNotEmpty) {
        _velocityRows = velData.map((e) => _ActionVelocityRow.fromMap(e as Map<String, dynamic>)).toList();
      }
      if (!hasContent) {
        await _autoPopulateFromAi();
      }
    } catch (error) {
      debugPrint('Punchlist actions load error: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveToFirestore() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    try {
      await _docRef(projectId).set({
        'priorityItems': _priorityItems.map((e) => e.toMap()).toList(),
        'technicalInsights': _technicalInsights.map((e) => e.toMap()).toList(),
        'remediationItems': _remediationItems.map((e) => e.toMap()).toList(),
        'fieldExecutionItems':
            _fieldExecutionItems.map((e) => e.toMap()).toList(),
        'techDebtItems': _techDebtItems.map((e) => e.toMap()).toList(),
        'closureItems': _closureItems.map((e) => e.toMap()).toList(),
        'distributionRows': _distributionRows.map((e) => e.toMap()).toList(),
        'velocityRows': _velocityRows.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Punchlist actions save error: $error');
    }
  }

  DocumentReference<Map<String, dynamic>> _docRef(String projectId) {
    return FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('execution_phase_sections')
        .doc('punchlist_actions');
  }

  Future<void> _autoPopulateFromAi() async {
    if (_autoGenerationTriggered || _isAutoGenerating) return;
    _autoGenerationTriggered = true;
    setState(() => _isAutoGenerating = true);
    Map<String, List<LaunchEntry>> generated = {};
    try {
      generated = await ExecutionPhaseAiSeed.generateEntries(
        context: context,
        section: 'Punchlist Actions',
        sections: const {
          'priority': 'Priority punchlist items and owners',
          'technical': 'Technical insight punchlist items',
          'remediation': 'Remediation planning items',
          'field_execution': 'Field execution punch items',
          'tech_debt': 'Technical debt closure items',
          'closure': 'Final acceptance and closure items',
        },
        itemsPerSection: 3,
      );
    } catch (error) {
      debugPrint('Punchlist actions AI call failed: $error');
    }

    if (!mounted) return;
    final priority = _mapInsights(generated['priority']);
    final technical = _mapInsights(generated['technical']);
    final remediation = _mapInsights(generated['remediation']);
    final fieldItems = _mapInsights(generated['field_execution']);
    final techDebt = _mapInsights(generated['tech_debt']);
    final closure = _mapInsights(generated['closure']);

    setState(() {
      _priorityItems =
          priority.isNotEmpty ? priority : _defaultPriorityItems();
      _technicalInsights =
          technical.isNotEmpty ? technical : _defaultTechnicalInsights();
      _remediationItems =
          remediation.isNotEmpty ? remediation : _defaultRemediationItems();
      _fieldExecutionItems =
          fieldItems.isNotEmpty ? fieldItems : _defaultFieldExecutionItems();
      _techDebtItems = techDebt.isNotEmpty ? techDebt : _defaultTechDebtItems();
      _closureItems = closure.isNotEmpty ? closure : _defaultClosureItems();
      _isAutoGenerating = false;
    });
    await _saveToFirestore();
  }

  List<_PunchlistInsight> _mapInsights(List<LaunchEntry>? entries) {
    if (entries == null) return [];
    return entries
        .map((entry) {
          final details = entry.details;
          final owner = _extractField(details, 'Owner');
          final due = _extractField(details, 'Due');
          final status = _extractField(details, 'Status');
          return _PunchlistInsight(
            title: entry.title.trim(),
            owner: owner.isNotEmpty ? owner : 'Owner TBD',
            dueIn: due.isNotEmpty ? due : 'Next 7 days',
            severity: _severityFromText(
                '${entry.title} ${entry.details} ${entry.status ?? ''}'),
            status: status.isNotEmpty
                ? status
                : (entry.status?.trim().isNotEmpty == true
                    ? entry.status!.trim()
                    : 'In progress'),
          );
        })
        .where((item) => item.title.isNotEmpty)
        .toList();
  }

  String _extractField(String text, String key) {
    final match = RegExp('$key\\s*[:=-]\\s*([^|;\\n]+)',
            caseSensitive: false)
        .firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  _PunchlistSeverity _severityFromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('critical')) return _PunchlistSeverity.critical;
    if (lower.contains('high')) return _PunchlistSeverity.high;
    if (lower.contains('low')) return _PunchlistSeverity.low;
    return _PunchlistSeverity.medium;
  }

  Widget _buildContextHeader(BuildContext context) {
    final projectData = ProjectDataHelper.getData(context);
    final projectName = projectData.projectName.trim().isNotEmpty
        ? projectData.projectName.trim()
        : projectData.solutionTitle.trim();
    final items = [
      const _ContextChip(
          icon: Icons.cases_outlined, label: 'Program', value: 'Execution Hub'),
      _ContextChip(
          icon: Icons.local_airport_outlined,
          label: 'Project',
          value: projectName.isNotEmpty ? projectName : 'Active project'),
      const _ContextChip(
          icon: Icons.flag_circle_outlined, label: 'Phase', value: 'Execution'),
      const _ContextChip(
          icon: Icons.timeline_outlined,
          label: 'Sprint',
          value: 'Sprint 42 • 3 days remaining'),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: items.map(_buildContextChip).toList(),
    );
  }

  Widget _buildContextChip(_ContextChip chip) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.icon, size: 18, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chip.label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                chip.value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stack = constraints.maxWidth < 780;
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Punchlist Actions & Technical Debt Resolution',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 28,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Stay ahead of closure blockers, prioritize cross-team remediation, and track acceptance readiness in one workspace.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

        final actions = Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: stack ? WrapAlignment.start : WrapAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => _showActionSnack(
                  'Tracker export is queued while export templates are finalized.'),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export tracker'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _showActionSnack(
                  'Launch status shared. Keep item owners and due dates updated before the next sync.'),
              icon: const Icon(Icons.auto_graph_outlined, size: 18),
              label: const Text('Share launch status'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ],
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 18),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: header),
            const SizedBox(width: 24),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
    final cards = [
      _buildCompletionCard(),
      _buildDistributionCard(),
      _buildActionVelocityCard(),
      _buildResolutionCard(),
      _buildAcceptanceCard(),
    ];

    return _buildPanelGrid(cards, horizontalSpacing: 20, verticalSpacing: 20);
  }

  Widget _buildMiddleInsights(BuildContext context) {
    final cards = [
      _buildInsightListCard(
        title: 'Punchlist insights & prioritisation',
        leadBadge: 'Focus',
        badgeColor: const Color(0xFF2563EB),
        items: _priorityItems,
        footerButtonLabel: 'Send next-step briefings',
      ),
      _buildInsightListCard(
        title: 'Item detail & technical insights',
        leadBadge: 'Systems scope',
        badgeColor: const Color(0xFF7C3AED),
        items: _technicalInsights,
        footerButtonLabel: 'Open detail workspace',
      ),
      _buildInsightListCard(
        title: 'Remediation planning & execution',
        leadBadge: 'Execution stream',
        badgeColor: const Color(0xFF0EA5E9),
        items: _remediationItems,
        footerButtonLabel: 'Review resourcing plan',
      ),
    ];

    return _wrapInsightCards(cards);
  }

  Widget _buildLowerGrid(BuildContext context) {
    final cards = [
      _buildInsightListCard(
        title: 'Field execution & mobile integration',
        leadBadge: 'Field data',
        badgeColor: const Color(0xFF22C55E),
        items: _fieldExecutionItems,
        footerButtonLabel: 'View field dashboards',
      ),
      _buildInsightListCard(
        title: 'Technical debt resolution backlog',
        leadBadge: 'Product debt',
        badgeColor: const Color(0xFFF97316),
        items: _techDebtItems,
        footerButtonLabel: 'Open backlog view',
      ),
      _buildInsightListCard(
        title: 'Closure verification & acceptance',
        leadBadge: 'Handover',
        badgeColor: const Color(0xFF8B5CF6),
        items: _closureItems,
        footerButtonLabel: 'Export acceptance log',
      ),
    ];

    return _wrapInsightCards(cards);
  }

  List<_PunchlistInsight> _defaultPriorityItems() => [
        _PunchlistInsight(
          title: 'Rework integrations interface alerts',
          owner: 'N. Chan',
          dueIn: 'Due in 2 days',
          severity: _PunchlistSeverity.high,
          status: 'Field team ready',
        ),
        _PunchlistInsight(
          title: 'Validate HVAC balancing readings',
          owner: 'S. Patel',
          dueIn: 'Due Friday',
          severity: _PunchlistSeverity.medium,
          status: 'QA pending',
        ),
        _PunchlistInsight(
          title: 'Backfill cabinet missing fasteners',
          owner: 'L. Santos',
          dueIn: 'Overdue by 1 day',
          severity: _PunchlistSeverity.critical,
          status: 'Waiting on vendor',
        ),
      ];

  List<_PunchlistInsight> _defaultTechnicalInsights() => [
        _PunchlistInsight(
          title: 'P-107: Airside zoning dampers',
          owner: 'Systems',
          dueIn: 'QA sign-off pending',
          severity: _PunchlistSeverity.medium,
          status: 'Close out ready',
        ),
        _PunchlistInsight(
          title: 'Interface bus failover checks',
          owner: 'Integration',
          dueIn: 'Pending metrics',
          severity: _PunchlistSeverity.low,
          status: 'Monitoring',
        ),
      ];

  List<_PunchlistInsight> _defaultRemediationItems() => [
        _PunchlistInsight(
          title: 'Resource planning aligned with sprint 42',
          owner: 'Operations',
          dueIn: 'In progress',
          severity: _PunchlistSeverity.medium,
          status: 'Capacity 80%',
        ),
        _PunchlistInsight(
          title: 'Vendor escalation touchpoint',
          owner: 'Supply chain',
          dueIn: 'Tomorrow',
          severity: _PunchlistSeverity.high,
          status: 'Meeting booked',
        ),
      ];

  List<_PunchlistInsight> _defaultFieldExecutionItems() => [
        _PunchlistInsight(
          title: 'Mobile inspections checklist sync',
          owner: 'Field Ops',
          dueIn: 'Sync nightly',
          severity: _PunchlistSeverity.low,
          status: 'Stable',
        ),
        _PunchlistInsight(
          title: 'Crew photo verification backlog',
          owner: 'QA',
          dueIn: 'Need 6 uploads',
          severity: _PunchlistSeverity.medium,
          status: 'Chasers sent',
        ),
      ];

  List<_PunchlistInsight> _defaultTechDebtItems() => [
        _PunchlistInsight(
          title: 'Legacy tag cleanup for zone controllers',
          owner: 'Platform',
          dueIn: 'Sprint 43',
          severity: _PunchlistSeverity.high,
          status: 'Ready for grooming',
        ),
        _PunchlistInsight(
          title: 'Telemetry schema versioning',
          owner: 'Data services',
          dueIn: 'Needs impact review',
          severity: _PunchlistSeverity.medium,
          status: 'Blocked',
        ),
      ];

  List<_PunchlistInsight> _defaultClosureItems() => [
        _PunchlistInsight(
          title: 'Stakeholder walkthrough sign-offs',
          owner: 'PMO',
          dueIn: '3 of 5 complete',
          severity: _PunchlistSeverity.low,
          status: 'Schedule review',
        ),
        _PunchlistInsight(
          title: 'Final acceptance documentation pack',
          owner: 'Quality',
          dueIn: 'Draft ready',
          severity: _PunchlistSeverity.medium,
          status: 'Legal review',
        ),
      ];

  List<_DistributionRow> _defaultDistributionRows() => [
    const _DistributionRow(category: 'Systems', openItems: 44, critical: 8, high: 10, medium: 16, low: 10, closed: 38, owner: 'Systems Team', status: 'Active', lastUpdated: '2 hrs ago'),
    const _DistributionRow(category: 'Facilities', openItems: 28, critical: 4, high: 6, medium: 10, low: 8, closed: 22, owner: 'Facilities Mgmt', status: 'Active', lastUpdated: '4 hrs ago'),
    const _DistributionRow(category: 'QA', openItems: 18, critical: 2, high: 2, medium: 8, low: 6, closed: 14, owner: 'QA Lead', status: 'Under Review', lastUpdated: '1 day ago'),
    const _DistributionRow(category: 'Integration', openItems: 30, critical: 3, high: 4, medium: 12, low: 11, closed: 25, owner: 'Integration Lead', status: 'Active', lastUpdated: '6 hrs ago'),
    const _DistributionRow(category: 'Field Ops', openItems: 22, critical: 5, high: 7, medium: 6, low: 4, closed: 18, owner: 'Field Ops Mgr', status: 'Monitoring', lastUpdated: '3 hrs ago'),
    const _DistributionRow(category: 'Safety', openItems: 12, critical: 6, high: 4, medium: 2, low: 0, closed: 9, owner: 'Safety Officer', status: 'Active', lastUpdated: '1 hr ago'),
    const _DistributionRow(category: 'Compliance', openItems: 8, critical: 1, high: 2, medium: 3, low: 2, closed: 7, owner: 'Compliance Lead', status: 'Under Review', lastUpdated: '5 hrs ago'),
  ];

  List<_ActionVelocityRow> _defaultVelocityRows() => [
    const _ActionVelocityRow(workstream: 'Field execution', openItems: 44, closedThisSprint: 32, velocity: 72, throughput: 16.0, delta: '+8.2%', avgCycleTime: 2.4, period: 'Sprint 41-42', owner: 'Field Ops', status: 'On Track'),
    const _ActionVelocityRow(workstream: 'QA verification', openItems: 18, closedThisSprint: 14, velocity: 58, throughput: 7.0, delta: '+5.6%', avgCycleTime: 3.1, period: 'Sprint 41-42', owner: 'QA Lead', status: 'Improving'),
    const _ActionVelocityRow(workstream: 'Technical debt', openItems: 30, closedThisSprint: 12, velocity: 41, throughput: 6.0, delta: '-3.4%', avgCycleTime: 5.8, period: 'Sprint 41-42', owner: 'Platform Team', status: 'At Risk'),
    const _ActionVelocityRow(workstream: 'Remediation', openItems: 22, closedThisSprint: 18, velocity: 65, throughput: 9.0, delta: '+2.1%', avgCycleTime: 3.6, period: 'Sprint 41-42', owner: 'Operations', status: 'On Track'),
    const _ActionVelocityRow(workstream: 'Closure items', openItems: 15, closedThisSprint: 12, velocity: 53, throughput: 6.0, delta: '+4.8%', avgCycleTime: 4.2, period: 'Sprint 41-42', owner: 'PMO', status: 'Stable'),
    const _ActionVelocityRow(workstream: 'Safety', openItems: 12, closedThisSprint: 9, velocity: 78, throughput: 4.5, delta: '+11.0%', avgCycleTime: 1.8, period: 'Sprint 41-42', owner: 'Safety Officer', status: 'On Track'),
  ];

  Widget _wrapInsightCards(List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i != cards.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildPanelGrid(
    List<Widget> cards, {
    double horizontalSpacing = 20,
    double verticalSpacing = 20,
  }) {
    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          cards[i],
          if (i != cards.length - 1) SizedBox(height: verticalSpacing),
        ],
      ],
    );
  }

  Widget _buildCompletionCard() {
    return _panel(
      title: 'Punchlist completion health',
      subtitle:
          '62% of punch actions closed this sprint window. 12 blockers remain triaged.',
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: const [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: 0.62,
                    strokeWidth: 12,
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation(Color(0xFF2563EB)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '62%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'complete',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _LegendRow(
                    label: 'Closed', color: Color(0xFF2563EB), value: '112'),
                SizedBox(height: 10),
                _LegendRow(
                    label: 'In review', color: Color(0xFF60A5FA), value: '34'),
                SizedBox(height: 10),
                _LegendRow(
                    label: 'Field fix pending',
                    color: Color(0xFFFACC15),
                    value: '21'),
                SizedBox(height: 10),
                _LegendRow(
                    label: 'Escalated', color: Color(0xFFEF4444), value: '12'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard() {
    final grandOpen = _distributionRows.fold<int>(0, (sum, r) => sum + r.openItems);
    final grandClosed = _distributionRows.fold<int>(0, (sum, r) => sum + r.closed);
    final grandTotal = grandOpen + grandClosed;
    final grandPct = grandTotal > 0 ? (grandClosed / grandTotal * 100) : 0.0;
    return _panel(
      title: 'Item distribution',
      subtitle: 'Punchlist item severity breakdown by workstream category with ownership tracking and closure metrics.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _summaryMetric(label: 'Total Items', value: '$grandTotal', color: const Color(0xFF1E293B)),
                const SizedBox(width: 28),
                _summaryMetric(label: 'Open', value: '$grandOpen', color: const Color(0xFFF59E0B)),
                const SizedBox(width: 28),
                _summaryMetric(label: 'Closed', value: '$grandClosed', color: const Color(0xFF22C55E)),
                const SizedBox(width: 28),
                _summaryMetric(label: 'Completion', value: '${grandPct.toStringAsFixed(1)}%', color: const Color(0xFF2563EB)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showDistributionDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Category'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Full-width table
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                    headingTextStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.4,
                    ),
                    dataTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    columnSpacing: 20,
                    horizontalMargin: 16,
                    columns: const [
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Open'), numeric: true),
                      DataColumn(label: Text('Critical'), numeric: true),
                      DataColumn(label: Text('High'), numeric: true),
                      DataColumn(label: Text('Medium'), numeric: true),
                      DataColumn(label: Text('Low'), numeric: true),
                      DataColumn(label: Text('Closed'), numeric: true),
                      DataColumn(label: Text('Total'), numeric: true),
                      DataColumn(label: Text('% Complete'), numeric: true),
                      DataColumn(label: Text('Owner')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Updated')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _distributionRows.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final row = entry.value;
                      final pct = row.percentComplete;
                      return DataRow(cells: [
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(row.category, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        )),
                        DataCell(_numberCell('${row.openItems}', const Color(0xFFF59E0B))),
                        DataCell(_numberCell('${row.critical}', row.critical > 0 ? const Color(0xFFDC2626) : const Color(0xFF94A3B8))),
                        DataCell(_numberCell('${row.high}', row.high > 0 ? const Color(0xFFEA580C) : const Color(0xFF94A3B8))),
                        DataCell(_numberCell('${row.medium}', const Color(0xFFF59E0B))),
                        DataCell(_numberCell('${row.low}', const Color(0xFF22C55E))),
                        DataCell(_numberCell('${row.closed}', const Color(0xFF22C55E))),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                          child: Text('${row.total}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8))),
                        )),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct / 100,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation(
                                    pct >= 70 ? const Color(0xFF22C55E) : pct >= 40 ? const Color(0xFF2563EB) : const Color(0xFFEF4444),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${pct.toStringAsFixed(0)}%', style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12,
                              color: pct >= 70 ? const Color(0xFF16A34A) : pct >= 40 ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
                            )),
                          ],
                        )),
                        DataCell(Text(row.owner, style: const TextStyle(fontSize: 12))),
                        DataCell(_buildStatusChip(row.status)),
                        DataCell(Text(row.lastUpdated.isNotEmpty ? row.lastUpdated : '-', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3B82F6)), onPressed: () => _showDistributionDialog(context, editIndex: idx), splashRadius: 18, tooltip: 'Edit'),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)), onPressed: () => _deleteDistributionRow(idx), splashRadius: 18, tooltip: 'Delete'),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric({required String label, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 0.4)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _numberCell(String value, Color color) {
    return Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontFeatures: const [FontFeature.tabularFigures()]));
  }

  Widget _buildActionVelocityCard() {
    final totalOpen = _velocityRows.fold<int>(0, (sum, r) => sum + r.openItems);
    final totalClosed = _velocityRows.fold<int>(0, (sum, r) => sum + r.closedThisSprint);
    final avgVelocity = _velocityRows.isNotEmpty
        ? _velocityRows.fold<int>(0, (sum, r) => sum + r.velocity) / _velocityRows.length
        : 0.0;
    final avgCycle = _velocityRows.isNotEmpty
        ? _velocityRows.fold<double>(0.0, (sum, r) => sum + r.avgCycleTime) / _velocityRows.length
        : 0.0;
    return _panel(
      title: 'Action velocity',
      subtitle: 'Workstream throughput momentum measured across sprint boundaries with trend indicators and cycle time analysis.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                _summaryMetric(label: 'Total Open', value: '$totalOpen', color: const Color(0xFFF59E0B)),
                const SizedBox(width: 28),
                _summaryMetric(label: 'Closed Sprint', value: '$totalClosed', color: const Color(0xFF22C55E)),
                const SizedBox(width: 28),
                _summaryMetric(label: 'Avg Velocity', value: '${avgVelocity.toStringAsFixed(0)}%', color: const Color(0xFF2563EB)),
                const SizedBox(width: 28),
                _summaryMetric(label: 'Avg Cycle Time', value: '${avgCycle.toStringAsFixed(1)}d', color: const Color(0xFF7C3AED)),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showVelocityDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Workstream'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Full-width table
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                    headingTextStyle: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.4,
                    ),
                    dataTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                    columnSpacing: 20,
                    horizontalMargin: 16,
                    columns: const [
                      DataColumn(label: Text('Workstream')),
                      DataColumn(label: Text('Open'), numeric: true),
                      DataColumn(label: Text('Closed'), numeric: true),
                      DataColumn(label: Text('Velocity %'), numeric: true),
                      DataColumn(label: Text('Throughput'), numeric: true),
                      DataColumn(label: Text('Trend')),
                      DataColumn(label: Text('Cycle Time'), numeric: true),
                      DataColumn(label: Text('Period')),
                      DataColumn(label: Text('Owner')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _velocityRows.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final row = entry.value;
                      final isPositive = row.delta.startsWith('+');
                      return DataRow(cells: [
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: isPositive ? const Color(0xFF22C55E) : const Color(0xFFEF4444), shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(row.workstream, style: const TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        )),
                        DataCell(_numberCell('${row.openItems}', const Color(0xFFF59E0B))),
                        DataCell(_numberCell('${row.closedThisSprint}', const Color(0xFF22C55E))),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 70,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: row.velocity / 100,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation(
                                    row.velocity >= 60 ? const Color(0xFF2563EB) : row.velocity >= 40 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${row.velocity}%', style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: row.velocity >= 60 ? const Color(0xFF2563EB) : row.velocity >= 40 ? const Color(0xFFD97706) : const Color(0xFFDC2626),
                            )),
                          ],
                        )),
                        DataCell(Text('${row.throughput.toStringAsFixed(1)}/sp', style: TextStyle(
                          fontWeight: FontWeight.w700, color: const Color(0xFF475569),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ))),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPositive ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 16, color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Text(row.delta, style: TextStyle(fontWeight: FontWeight.w700, color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                          ]),
                        )),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: row.avgCycleTime <= 3.0 ? const Color(0xFFF0FDF4) : row.avgCycleTime <= 5.0 ? const Color(0xFFFFFBEB) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${row.avgCycleTime.toStringAsFixed(1)}d', style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: row.avgCycleTime <= 3.0 ? const Color(0xFF16A34A) : row.avgCycleTime <= 5.0 ? const Color(0xFFD97706) : const Color(0xFFDC2626),
                          )),
                        )),
                        DataCell(Text(row.period, style: const TextStyle(fontSize: 12))),
                        DataCell(Text(row.owner, style: const TextStyle(fontSize: 12))),
                        DataCell(_buildStatusChip(row.status)),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF3B82F6)), onPressed: () => _showVelocityDialog(context, editIndex: idx), splashRadius: 18, tooltip: 'Edit'),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)), onPressed: () => _deleteVelocityRow(idx), splashRadius: 18, tooltip: 'Delete'),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard() {
    return _panel(
      title: 'Resolution velocity',
      subtitle: 'Avg. resolution and reopening cadence.',
      child: Column(
        children: const [
          _MetricPill(
              label: 'Median resolution',
              value: '3.4 days',
              color: Color(0xFF2563EB)),
          SizedBox(height: 14),
          _MetricPill(
              label: 'Reopen rate', value: '6%', color: Color(0xFF10B981)),
          SizedBox(height: 14),
          _MetricPill(
              label: 'QA backlog aging',
              value: '4.6 days',
              color: Color(0xFFF59E0B)),
          SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Escalations trending down 2.1% week over week.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptanceCard() {
    return _panel(
      title: 'Final acceptance readiness',
      subtitle: 'Cross-team sign-offs leading to launch gate.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ChecklistRow(
              label: 'Operations playbooks updated',
              status: 'On track',
              color: Color(0xFF22C55E)),
          SizedBox(height: 12),
          _ChecklistRow(
              label: 'Stakeholder walkthroughs',
              status: '3 / 5 complete',
              color: Color(0xFFF97316)),
          SizedBox(height: 12),
          _ChecklistRow(
              label: 'Critical defects resolved',
              status: '2 pending',
              color: Color(0xFFEF4444)),
          SizedBox(height: 12),
          _ChecklistRow(
              label: 'Acceptance documentation',
              status: 'Draft sent',
              color: Color(0xFF6366F1)),
        ],
      ),
    );
  }

  Widget _panel(
      {required String title, String? subtitle, required Widget child}) {
    return Container(
      constraints: const BoxConstraints(minHeight: _panelMinHeight),
      alignment: Alignment.topLeft,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showActionSnack(
                    'Additional panel actions will be available in the next refinement pass.'),
                icon: const Icon(Icons.more_horiz, color: Color(0xFF94A3B8)),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    switch (status.toLowerCase()) {
      case 'active':
      case 'on track':
        bg = const Color(0xFFF0FDF4); fg = const Color(0xFF16A34A); break;
      case 'improving':
      case 'stable':
        bg = const Color(0xFFEFF6FF); fg = const Color(0xFF2563EB); break;
      case 'at risk':
        bg = const Color(0xFFFEF2F2); fg = const Color(0xFFDC2626); break;
      case 'under review':
      case 'monitoring':
        bg = const Color(0xFFFFFBEB); fg = const Color(0xFFD97706); break;
      default:
        bg = const Color(0xFFF1F5F9); fg = const Color(0xFF475569);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  void _showDistributionDialog(BuildContext context, {int? editIndex}) {
    final isEdit = editIndex != null;
    final existing = isEdit ? _distributionRows[editIndex] : null;
    final categoryCtrl = TextEditingController(text: existing?.category ?? '');
    final openItemsCtrl = TextEditingController(text: existing != null ? '${existing.openItems}' : '0');
    final criticalCtrl = TextEditingController(text: existing != null ? '${existing.critical}' : '0');
    final highCtrl = TextEditingController(text: existing != null ? '${existing.high}' : '0');
    final mediumCtrl = TextEditingController(text: existing != null ? '${existing.medium}' : '0');
    final lowCtrl = TextEditingController(text: existing != null ? '${existing.low}' : '0');
    final closedCtrl = TextEditingController(text: existing != null ? '${existing.closed}' : '0');
    final ownerCtrl = TextEditingController(text: existing?.owner ?? '');
    final lastUpdatedCtrl = TextEditingController(text: existing?.lastUpdated ?? 'Just now');
    String status = existing?.status ?? 'Active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Category' : 'Add Category'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextField(controller: openItemsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Open Items', border: OutlineInputBorder()),)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: closedCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Closed', border: OutlineInputBorder()),)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextField(controller: criticalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Critical', border: OutlineInputBorder()),)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: highCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'High', border: OutlineInputBorder()),)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: mediumCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Medium', border: OutlineInputBorder()),)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: lowCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Low', border: OutlineInputBorder()),)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextField(controller: ownerCtrl, decoration: const InputDecoration(labelText: 'Owner', border: OutlineInputBorder()),)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: lastUpdatedCtrl, decoration: const InputDecoration(labelText: 'Last Updated', border: OutlineInputBorder()),)),
                  ]),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: ['Active', 'Under Review', 'Monitoring', 'At Risk'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setDialogState(() => status = v ?? 'Active'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final row = _DistributionRow(
                  category: categoryCtrl.text.trim(),
                  openItems: int.tryParse(openItemsCtrl.text) ?? 0,
                  critical: int.tryParse(criticalCtrl.text) ?? 0,
                  high: int.tryParse(highCtrl.text) ?? 0,
                  medium: int.tryParse(mediumCtrl.text) ?? 0,
                  low: int.tryParse(lowCtrl.text) ?? 0,
                  closed: int.tryParse(closedCtrl.text) ?? 0,
                  owner: ownerCtrl.text.trim(),
                  status: status,
                  lastUpdated: lastUpdatedCtrl.text.trim().isNotEmpty ? lastUpdatedCtrl.text.trim() : 'Just now',
                );
                setState(() {
                  if (isEdit) {
                    _distributionRows[editIndex] = row;
                  } else {
                    _distributionRows.add(row);
                  }
                });
                _saveToFirestore();
                Navigator.pop(ctx);
                _showActionSnack(isEdit ? 'Category updated successfully.' : 'Category added successfully.');
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVelocityDialog(BuildContext context, {int? editIndex}) {
    final isEdit = editIndex != null;
    final existing = isEdit ? _velocityRows[editIndex] : null;
    final workstreamCtrl = TextEditingController(text: existing?.workstream ?? '');
    final openItemsCtrl = TextEditingController(text: existing != null ? '${existing.openItems}' : '0');
    final closedThisSprintCtrl = TextEditingController(text: existing != null ? '${existing.closedThisSprint}' : '0');
    final velocityCtrl = TextEditingController(text: existing != null ? '${existing.velocity}' : '50');
    final throughputCtrl = TextEditingController(text: existing != null ? '${existing.throughput}' : '0.0');
    final deltaCtrl = TextEditingController(text: existing?.delta ?? '+0.0%');
    final avgCycleTimeCtrl = TextEditingController(text: existing != null ? '${existing.avgCycleTime}' : '0.0');
    final periodCtrl = TextEditingController(text: existing?.period ?? 'Sprint 41-42');
    final ownerCtrl = TextEditingController(text: existing?.owner ?? '');
    String status = existing?.status ?? 'On Track';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Workstream' : 'Add Workstream'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: workstreamCtrl, decoration: const InputDecoration(labelText: 'Workstream', border: OutlineInputBorder()),),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextField(controller: openItemsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Open Items', border: OutlineInputBorder()),)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: closedThisSprintCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Closed Sprint', border: OutlineInputBorder()),)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextField(controller: velocityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Velocity %', border: OutlineInputBorder()),)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: throughputCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Throughput (items/sp)', border: OutlineInputBorder()),)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextField(controller: deltaCtrl, decoration: const InputDecoration(labelText: 'Delta (e.g. +8.2%)', border: OutlineInputBorder()),)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: avgCycleTimeCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Avg Cycle Time (days)', border: OutlineInputBorder()),)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: TextField(controller: periodCtrl, decoration: const InputDecoration(labelText: 'Period', border: OutlineInputBorder()),)),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: ownerCtrl, decoration: const InputDecoration(labelText: 'Owner', border: OutlineInputBorder()),)),
                  ]),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: ['On Track', 'Improving', 'Stable', 'At Risk'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setDialogState(() => status = v ?? 'On Track'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final row = _ActionVelocityRow(
                  workstream: workstreamCtrl.text.trim(),
                  openItems: int.tryParse(openItemsCtrl.text) ?? 0,
                  closedThisSprint: int.tryParse(closedThisSprintCtrl.text) ?? 0,
                  velocity: int.tryParse(velocityCtrl.text) ?? 0,
                  throughput: double.tryParse(throughputCtrl.text) ?? 0.0,
                  delta: deltaCtrl.text.trim(),
                  avgCycleTime: double.tryParse(avgCycleTimeCtrl.text) ?? 0.0,
                  period: periodCtrl.text.trim(),
                  owner: ownerCtrl.text.trim(),
                  status: status,
                );
                setState(() {
                  if (isEdit) {
                    _velocityRows[editIndex] = row;
                  } else {
                    _velocityRows.add(row);
                  }
                });
                _saveToFirestore();
                Navigator.pop(ctx);
                _showActionSnack(isEdit ? 'Workstream updated successfully.' : 'Workstream added successfully.');
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteDistributionRow(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${_distributionRows[index].category}"? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              setState(() => _distributionRows.removeAt(index));
              _saveToFirestore();
              Navigator.pop(ctx);
              _showActionSnack('Category deleted.');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteVelocityRow(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Workstream'),
        content: Text('Are you sure you want to delete "${_velocityRows[index].workstream}"? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              setState(() => _velocityRows.removeAt(index));
              _saveToFirestore();
              Navigator.pop(ctx);
              _showActionSnack('Workstream deleted.');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightListCard({
    required String title,
    required String leadBadge,
    required Color badgeColor,
    required List<_PunchlistInsight> items,
    required String footerButtonLabel,
  }) {
    return _panel(
      title: title,
      subtitle: '$leadBadge focus stream overview',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                leadBadge,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ...items
              .map(_buildInsightTile)
              .expand((widget) => [widget, const SizedBox(height: 14)])
              .take(items.length * 2 - 1),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showActionSnack(
                  '$footerButtonLabel is queued. Continue updating this panel for now.'),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(footerButtonLabel),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                foregroundColor: const Color(0xFF2563EB),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInsightTile(_PunchlistInsight insight) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: insight.severity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  insight.severity.icon,
                  color: insight.severity.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _infoPill(Icons.account_circle_outlined, insight.owner),
                        _infoPill(Icons.schedule_outlined, insight.dueIn),
                        _infoPill(Icons.flag_outlined, insight.status),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextChip {
  const _ContextChip(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

class _PunchlistInsight {
  const _PunchlistInsight({
    required this.title,
    required this.owner,
    required this.dueIn,
    required this.severity,
    required this.status,
  });

  final String title;
  final String owner;
  final String dueIn;
  final _PunchlistSeverity severity;
  final String status;

  Map<String, dynamic> toMap() => {
        'title': title,
        'owner': owner,
        'dueIn': dueIn,
        'severity': severity.name,
        'status': status,
      };

  static _PunchlistInsight fromMap(Map<String, dynamic> map) {
    final severityKey = map['severity']?.toString() ?? 'medium';
    return _PunchlistInsight(
      title: map['title']?.toString() ?? '',
      owner: map['owner']?.toString() ?? '',
      dueIn: map['dueIn']?.toString() ?? '',
      severity: _severityFromKey(severityKey),
      status: map['status']?.toString() ?? '',
    );
  }

  static List<_PunchlistInsight> fromList(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => _PunchlistInsight.fromMap(
            Map<String, dynamic>.from(item)))
        .toList();
  }

  static _PunchlistSeverity _severityFromKey(String key) {
    switch (key.toLowerCase()) {
      case 'critical':
        return _PunchlistSeverity.critical;
      case 'high':
        return _PunchlistSeverity.high;
      case 'low':
        return _PunchlistSeverity.low;
      default:
        return _PunchlistSeverity.medium;
    }
  }
}

enum _PunchlistSeverity { low, medium, high, critical }

extension on _PunchlistSeverity {
  Color get color {
    switch (this) {
      case _PunchlistSeverity.low:
        return const Color(0xFF22C55E);
      case _PunchlistSeverity.medium:
        return const Color(0xFFFBBF24);
      case _PunchlistSeverity.high:
        return const Color(0xFF2563EB);
      case _PunchlistSeverity.critical:
        return const Color(0xFFEF4444);
    }
  }

  IconData get icon {
    switch (this) {
      case _PunchlistSeverity.low:
        return Icons.check_circle_outline;
      case _PunchlistSeverity.medium:
        return Icons.auto_fix_normal_outlined;
      case _PunchlistSeverity.high:
        return Icons.flag_outlined;
      case _PunchlistSeverity.critical:
        return Icons.warning_amber_outlined;
    }
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _DistributionRow {
  const _DistributionRow({
    required this.category,
    required this.openItems,
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
    required this.closed,
    required this.owner,
    required this.status,
    this.lastUpdated = '',
  });

  final String category;
  final int openItems;
  final int critical;
  final int high;
  final int medium;
  final int low;
  final int closed;
  final String owner;
  final String status;
  final String lastUpdated;

  int get total => openItems + closed;
  double get percentComplete => total > 0 ? (closed / total * 100) : 0.0;

  Map<String, dynamic> toMap() => {
    'category': category,
    'openItems': openItems,
    'critical': critical,
    'high': high,
    'medium': medium,
    'low': low,
    'closed': closed,
    'owner': owner,
    'status': status,
    'lastUpdated': lastUpdated,
  };

  static _DistributionRow fromMap(Map<String, dynamic> map) => _DistributionRow(
    category: map['category']?.toString() ?? '',
    openItems: (map['openItems'] is int) ? map['openItems'] as int : int.tryParse(map['openItems'].toString()) ?? 0,
    critical: (map['critical'] is int) ? map['critical'] as int : int.tryParse(map['critical'].toString()) ?? 0,
    high: (map['high'] is int) ? map['high'] as int : int.tryParse(map['high'].toString()) ?? 0,
    medium: (map['medium'] is int) ? map['medium'] as int : int.tryParse(map['medium'].toString()) ?? 0,
    low: (map['low'] is int) ? map['low'] as int : int.tryParse(map['low'].toString()) ?? 0,
    closed: (map['closed'] is int) ? map['closed'] as int : int.tryParse(map['closed'].toString()) ?? 0,
    owner: map['owner']?.toString() ?? '',
    status: map['status']?.toString() ?? 'Active',
    lastUpdated: map['lastUpdated']?.toString() ?? '',
  );
}

class _ActionVelocityRow {
  const _ActionVelocityRow({
    required this.workstream,
    required this.openItems,
    required this.closedThisSprint,
    required this.velocity,
    required this.throughput,
    required this.delta,
    required this.avgCycleTime,
    required this.period,
    required this.owner,
    required this.status,
  });

  final String workstream;
  final int openItems;
  final int closedThisSprint;
  final int velocity;
  final double throughput;
  final String delta;
  final double avgCycleTime;
  final String period;
  final String owner;
  final String status;

  Map<String, dynamic> toMap() => {
    'workstream': workstream,
    'openItems': openItems,
    'closedThisSprint': closedThisSprint,
    'velocity': velocity,
    'throughput': throughput,
    'delta': delta,
    'avgCycleTime': avgCycleTime,
    'period': period,
    'owner': owner,
    'status': status,
  };

  static _ActionVelocityRow fromMap(Map<String, dynamic> map) => _ActionVelocityRow(
    workstream: map['workstream']?.toString() ?? '',
    openItems: (map['openItems'] is int) ? map['openItems'] as int : int.tryParse(map['openItems'].toString()) ?? 0,
    closedThisSprint: (map['closedThisSprint'] is int) ? map['closedThisSprint'] as int : int.tryParse(map['closedThisSprint'].toString()) ?? 0,
    velocity: (map['velocity'] is int) ? map['velocity'] as int : int.tryParse(map['velocity'].toString()) ?? 0,
    throughput: (map['throughput'] is num) ? (map['throughput'] as num).toDouble() : double.tryParse(map['throughput'].toString()) ?? 0.0,
    delta: map['delta']?.toString() ?? '+0.0%',
    avgCycleTime: (map['avgCycleTime'] is num) ? (map['avgCycleTime'] as num).toDouble() : double.tryParse(map['avgCycleTime'].toString()) ?? 0.0,
    period: map['period']?.toString() ?? '',
    owner: map['owner']?.toString() ?? '',
    status: map['status']?.toString() ?? 'On Track',
  );
}

class _MetricPill extends StatelessWidget {
  const _MetricPill(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color.darken(),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
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

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow(
      {required this.label, required this.status, required this.color});

  final String label;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

extension _ColorShade on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
