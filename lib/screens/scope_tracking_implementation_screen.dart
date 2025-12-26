import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class ScopeTrackingImplementationScreen extends StatefulWidget {
  const ScopeTrackingImplementationScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScopeTrackingImplementationScreen()),
    );
  }

  @override
  State<ScopeTrackingImplementationScreen> createState() => _ScopeTrackingImplementationScreenState();
}

class _ScopeTrackingImplementationScreenState extends State<ScopeTrackingImplementationScreen> {
  final Set<String> _selectedFilters = {'All scope'};

  final List<_ScopeItem> _scopeItems = const [
    _ScopeItem('SC-301', 'Core platform rollout', 'On track', '0%', 'Engineering', 'Oct 18'),
    _ScopeItem('SC-308', 'Reporting dashboards', 'Variance', '+6%', 'Analytics', 'Oct 22'),
    _ScopeItem('SC-315', 'Integration hub', 'At risk', '+3%', 'Platform', 'Oct 20'),
    _ScopeItem('SC-323', 'Training enablement', 'On track', '0%', 'Change team', 'Oct 28'),
    _ScopeItem('SC-332', 'Ops handover', 'Pending', '+2%', 'Operations', 'Nov 02'),
  ];

  final List<_VarianceSignal> _varianceSignals = const [
    _VarianceSignal('Scope variance', '2 items exceed baseline by 5%.'),
    _VarianceSignal('Change request backlog', '3 items awaiting approval.'),
    _VarianceSignal('Dependency gap', 'Vendor milestone shifted by 2 weeks.'),
  ];

  final List<_ChangeItem> _changeItems = const [
    _ChangeItem('CR-112', 'Add audit log export', 'Approved', 'Oct 10'),
    _ChangeItem('CR-118', 'Reduce legacy migration scope', 'Approved', 'Oct 14'),
    _ChangeItem('CR-123', 'Expand training scope', 'Pending', 'Oct 19'),
  ];

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Scope Tracking Implementation',
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isNarrow),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 20),
                _buildStatsRow(isNarrow),
                const SizedBox(height: 24),
                if (isNarrow)
                  Column(
                    children: [
                      _buildScopeRegister(),
                      const SizedBox(height: 20),
                      _buildVariancePanel(),
                      const SizedBox(height: 20),
                      _buildChangeLogPanel(),
                      const SizedBox(height: 20),
                      _buildBaselinePanel(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildScopeRegister()),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildVariancePanel(),
                            const SizedBox(height: 20),
                            _buildChangeLogPanel(),
                            const SizedBox(height: 20),
                            _buildBaselinePanel(),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'SCOPE CONTROL',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Scope Tracking Implementation',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Monitor scope delivery, variance, and change approvals during execution.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (!isNarrow) _buildHeaderActions(),
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 12),
          _buildHeaderActions(),
        ],
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _actionButton(Icons.add, 'Add scope item'),
        _actionButton(Icons.sync_alt, 'Sync baseline'),
        _actionButton(Icons.description_outlined, 'Export log'),
        _primaryButton('Run scope review'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _primaryButton(String label) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.play_arrow, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = ['All scope', 'On track', 'Variance', 'At risk', 'Pending'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: filters.map((filter) {
        final selected = _selectedFilters.contains(filter);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedFilters.remove(filter);
              } else {
                _selectedFilters.add(filter);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              filter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    final stats = [
      _StatCardData('Scope items', '32', '4 critical', const Color(0xFF0EA5E9)),
      _StatCardData('Variance', '2.4%', 'Within guardrails', const Color(0xFF10B981)),
      _StatCardData('Change requests', '3', '1 pending', const Color(0xFFF59E0B)),
      _StatCardData('Acceptance', '84%', 'Stakeholder aligned', const Color(0xFF6366F1)),
    ];

    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: stats.map((stat) => _buildStatCard(stat)).toList(),
      );
    }

    return Row(
      children: stats.map((stat) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildStatCard(stat),
        ),
      )).toList(),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: data.color)),
          const SizedBox(height: 6),
          Text(data.label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(data.supporting, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: data.color)),
        ],
      ),
    );
  }

  Widget _buildScopeRegister() {
    return _PanelShell(
      title: 'Scope register',
      subtitle: 'Baseline delivery and variance tracking',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Scope item', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Variance', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Next review', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _scopeItems.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.id, style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9)))),
              DataCell(Text(item.title, style: const TextStyle(fontSize: 13))),
              DataCell(_statusChip(item.status)),
              DataCell(Text(item.variance, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              DataCell(Text(item.owner, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
              DataCell(Text(item.reviewDate, style: const TextStyle(fontSize: 12))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVariancePanel() {
    return _PanelShell(
      title: 'Variance signals',
      subtitle: 'Scope drift and dependency impacts',
      child: Column(
        children: _varianceSignals.map((signal) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(signal.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(signal.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChangeLogPanel() {
    return _PanelShell(
      title: 'Change log',
      subtitle: 'Recent scope change requests',
      child: Column(
        children: _changeItems.map((change) {
          final color = change.status == 'Approved' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(change.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(change.date, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(change.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBaselinePanel() {
    return _PanelShell(
      title: 'Baseline alignment',
      subtitle: 'Scope checkpoints for sign-off',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _BaselineItem('Baseline scope sign-off', 'Complete', true),
          _BaselineItem('Scope variance review', 'In progress', false),
          _BaselineItem('Sponsor acceptance', 'Scheduled', false),
        ],
      ),
    );
  }

  Widget _statusChip(String label) {
    Color color;
    switch (label) {
      case 'On track':
        color = const Color(0xFF10B981);
        break;
      case 'Variance':
        color = const Color(0xFFF59E0B);
        break;
      case 'At risk':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFF6366F1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _BaselineItem extends StatelessWidget {
  const _BaselineItem(this.title, this.status, this.complete);

  final String title;
  final String status;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(complete ? Icons.check_circle : Icons.schedule, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(status, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeItem {
  const _ScopeItem(this.id, this.title, this.status, this.variance, this.owner, this.reviewDate);

  final String id;
  final String title;
  final String status;
  final String variance;
  final String owner;
  final String reviewDate;
}

class _VarianceSignal {
  const _VarianceSignal(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

class _ChangeItem {
  const _ChangeItem(this.id, this.title, this.status, this.date);

  final String id;
  final String title;
  final String status;
  final String date;
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
