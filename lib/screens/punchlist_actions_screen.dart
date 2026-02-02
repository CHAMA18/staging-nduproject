import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
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
  static const double _panelMinHeight = 360;

  final Set<String> _selectedScopeFilters = {'All open'};
  final Set<String> _selectedViewFilters = {'Show overdue'};

  static const List<String> _scopeOptions = [
    'All open',
    'Due this week',
    'Field fix',
    'In QA review',
    'Blocked',
  ];

  static const List<String> _viewOptions = [
    'Show overdue',
    'Only high risk',
    'Include archived',
    'Flagged for launch',
  ];

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
              child: const InitiationLikeSidebar(activeItemLabel: 'Punchlist Actions'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildContextHeader(context),
                        const SizedBox(height: 18),
                        _buildPageHeader(context),
                        const SizedBox(height: 20),
                        _buildFilterToolbar(context),
                        const SizedBox(height: 26),
                        _buildSummaryGrid(context),
                        const SizedBox(height: 26),
                        _buildMiddleInsights(context),
                        const SizedBox(height: 26),
                        _buildLowerGrid(context),
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

  Widget _buildContextHeader(BuildContext context) {
    final items = [
      const _ContextChip(icon: Icons.cases_outlined, label: 'Program', value: 'Execution Hub'),
      const _ContextChip(icon: Icons.local_airport_outlined, label: 'Project', value: 'Airport capacity uplift'),
      const _ContextChip(icon: Icons.flag_circle_outlined, label: 'Phase', value: 'Execution'),
      const _ContextChip(icon: Icons.timeline_outlined, label: 'Sprint', value: 'Sprint 42 • 3 days remaining'),
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
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export tracker'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.auto_graph_outlined, size: 18),
              label: const Text('Share launch status'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

  Widget _buildFilterToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEBF0F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool stack = constraints.maxWidth < 860;
              final chips = Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _scopeOptions
                    .map(
                      (option) => ChoiceChip(
                        label: Text(option),
                        selected: _selectedScopeFilters.contains(option),
                        onSelected: (_) => setState(() {
                          _selectedScopeFilters
                            ..clear()
                            ..add(option);
                        }),
                        showCheckmark: false,
                        backgroundColor: const Color(0xFFF3F4F6),
                        selectedColor: const Color(0xFFEFF6FF),
                        labelStyle: TextStyle(
                          fontWeight: _selectedScopeFilters.contains(option) ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedScopeFilters.contains(option) ? const Color(0xFF1D4ED8) : const Color(0xFF4B5563),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    )
                    .toList(),
              );

              final searchField = SizedBox(
                width: stack ? double.infinity : 260,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search punch items, owners, keywords…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              );

              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    chips,
                    const SizedBox(height: 18),
                    searchField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: chips),
                  const SizedBox(width: 24),
                  searchField,
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _viewOptions
                .map(
                  (option) => FilterChip(
                    label: Text(option),
                    selected: _selectedViewFilters.contains(option),
                    onSelected: (_) => setState(() {
                      if (_selectedViewFilters.contains(option)) {
                        _selectedViewFilters.remove(option);
                      } else {
                        _selectedViewFilters.add(option);
                      }
                    }),
                    showCheckmark: false,
                    backgroundColor: const Color(0xFFF4F4F5),
                    selectedColor: const Color(0xFFEDE9FE),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _selectedViewFilters.contains(option) ? const Color(0xFF5B21B6) : const Color(0xFF4B5563),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final int columns;
        if (maxWidth >= 1400) {
          columns = 3;
        } else if (maxWidth >= 980) {
          columns = 2;
        } else {
          columns = 1;
        }

        if (columns == 1) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) SizedBox(height: verticalSpacing),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (int i = 0; i < cards.length; i += columns) {
          final int end = (i + columns) > cards.length ? cards.length : i + columns;
          final rowCards = cards.sublist(i, end);
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int j = 0; j < rowCards.length; j++) ...[
                    Expanded(child: rowCards[j]),
                    if (j != rowCards.length - 1) SizedBox(width: horizontalSpacing),
                  ],
                ],
              ),
            ),
          );

          if (i + columns < cards.length) {
            rows.add(SizedBox(height: verticalSpacing));
          }
        }

        return Column(children: rows);
      },
    );
  }

  Widget _buildCompletionCard() {
    return _panel(
      title: 'Punchlist completion health',
      subtitle: '62% of punch actions closed this sprint window. 12 blockers remain triaged.',
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
                _LegendRow(label: 'Closed', color: Color(0xFF2563EB), value: '112'),
                SizedBox(height: 10),
                _LegendRow(label: 'In review', color: Color(0xFF60A5FA), value: '34'),
                SizedBox(height: 10),
                _LegendRow(label: 'Field fix pending', color: Color(0xFFFACC15), value: '21'),
                SizedBox(height: 10),
                _LegendRow(label: 'Escalated', color: Color(0xFFEF4444), value: '12'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard() {
    return _panel(
      title: 'Item distribution',
      subtitle: 'Tracked across systems, facilities, and QA ownership.',
      child: Column(
        children: const [
          _DistributionRow(title: 'Systems', count: '68', indicators: ['18 critical', '24 medium', '26 low']),
          SizedBox(height: 14),
          _DistributionRow(title: 'Facilities', count: '44', indicators: ['10 critical', '14 medium', '20 low']),
          SizedBox(height: 14),
          _DistributionRow(title: 'QA', count: '32', indicators: ['4 critical', '11 medium', '17 low']),
        ],
      ),
    );
  }

  Widget _buildActionVelocityCard() {
    return _panel(
      title: 'Action velocity',
      subtitle: 'Workstream momentum across last two sprints.',
      child: Column(
        children: const [
          _VelocityRow(label: 'Field execution', trend: 0.72, delta: '+8.2%'),
          SizedBox(height: 12),
          _VelocityRow(label: 'QA verification', trend: 0.58, delta: '+5.6%'),
          SizedBox(height: 12),
          _VelocityRow(label: 'Technical debt', trend: 0.41, delta: '-3.4%'),
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
          _MetricPill(label: 'Median resolution', value: '3.4 days', color: Color(0xFF2563EB)),
          SizedBox(height: 14),
          _MetricPill(label: 'Reopen rate', value: '6%', color: Color(0xFF10B981)),
          SizedBox(height: 14),
          _MetricPill(label: 'QA backlog aging', value: '4.6 days', color: Color(0xFFF59E0B)),
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
          _ChecklistRow(label: 'Operations playbooks updated', status: 'On track', color: Color(0xFF22C55E)),
          SizedBox(height: 12),
          _ChecklistRow(label: 'Stakeholder walkthroughs', status: '3 / 5 complete', color: Color(0xFFF97316)),
          SizedBox(height: 12),
          _ChecklistRow(label: 'Critical defects resolved', status: '2 pending', color: Color(0xFFEF4444)),
          SizedBox(height: 12),
          _ChecklistRow(label: 'Acceptance documentation', status: 'Draft sent', color: Color(0xFF6366F1)),
        ],
      ),
    );
  }

  Widget _panel({required String title, String? subtitle, required Widget child}) {
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
                onPressed: () {},
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
          ...items.map(_buildInsightTile).expand((widget) => [widget, const SizedBox(height: 14)]).take(items.length * 2 - 1),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {},
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
  const _ContextChip({required this.icon, required this.label, required this.value});

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
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
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

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({required this.title, required this.count, required this.indicators});

  final String title;
  final String count;
  final List<String> indicators;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: indicators
                    .map(
                      (text) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            count,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0C4A6E),
            ),
          ),
        ),
      ],
    );
  }
}

class _VelocityRow extends StatelessWidget {
  const _VelocityRow({required this.label, required this.trend, required this.delta});

  final String label;
  final double trend;
  final String delta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              delta,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: trend,
            minHeight: 10,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value, required this.color});

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
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
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
  const _ChecklistRow({required this.label, required this.status, required this.color});

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
