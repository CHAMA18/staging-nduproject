import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class ContractsTrackingScreen extends StatefulWidget {
  const ContractsTrackingScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContractsTrackingScreen()),
    );
  }

  @override
  State<ContractsTrackingScreen> createState() => _ContractsTrackingScreenState();
}

class _ContractsTrackingScreenState extends State<ContractsTrackingScreen> {
  final Set<String> _selectedFilters = {'All contracts'};

  final List<_ContractItem> _contracts = const [
    _ContractItem('CT-1024', 'Omega Systems', 'Integration', 'Active', 'Nov 12', '\$2.4M', 'L. Park'),
    _ContractItem('CT-1031', 'BrightWorks', 'Infrastructure', 'Renewal due', 'Oct 22', '\$1.1M', 'S. Mitchell'),
    _ContractItem('CT-1040', 'Vantage Labs', 'Security', 'At risk', 'Oct 18', '\$940K', 'J. Rodriguez'),
    _ContractItem('CT-1044', 'Eastline Partners', 'Operations', 'Active', 'Dec 05', '\$1.8M', 'M. Thompson'),
    _ContractItem('CT-1052', 'Nimbus Health', 'Compliance', 'Pending sign-off', 'Oct 28', '\$560K', 'E. Chen'),
  ];

  final List<_RenewalLane> _renewalLanes = const [
    _RenewalLane('30 days', 3, Color(0xFFF97316)),
    _RenewalLane('60 days', 5, Color(0xFF6366F1)),
    _RenewalLane('90 days', 8, Color(0xFF10B981)),
  ];

  final List<_SignalItem> _signals = const [
    _SignalItem('Renewal risk flagged', '2 vendors require escalation this week.'),
    _SignalItem('Service credits pending', '1 contract has SLA credits to reconcile.'),
    _SignalItem('Legal review backlog', '3 items awaiting legal sign-off.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Contracts Tracking',
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
                      _buildContractRegister(),
                      const SizedBox(height: 20),
                      _buildRenewalPanel(),
                      const SizedBox(height: 20),
                      _buildSignalsPanel(),
                      const SizedBox(height: 20),
                      _buildApprovalsPanel(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildContractRegister()),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildRenewalPanel(),
                            const SizedBox(height: 20),
                            _buildSignalsPanel(),
                            const SizedBox(height: 20),
                            _buildApprovalsPanel(),
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
            'CONTRACT CONTROL',
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
                    'Contracts Tracking',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Track renewals, approvals, and compliance milestones for critical vendor contracts.',
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
        _actionButton(Icons.add, 'Add contract'),
        _actionButton(Icons.upload_outlined, 'Upload addendum'),
        _actionButton(Icons.description_outlined, 'Export register'),
        _primaryButton('Start renewal review'),
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
    const filters = ['All contracts', 'Renewal due', 'At risk', 'Pending sign-off', 'Archived'];
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
      _StatCardData('Active contracts', '26', '8 strategic', const Color(0xFF0EA5E9)),
      _StatCardData('Renewal due', '4', 'Next 30 days', const Color(0xFFF97316)),
      _StatCardData('Total value', '\$8.4M', 'FY spend', const Color(0xFF10B981)),
      _StatCardData('Compliance score', '92%', '2 open findings', const Color(0xFF6366F1)),
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

  Widget _buildContractRegister() {
    return _PanelShell(
      title: 'Contract register',
      subtitle: 'Track scope, owners, and renewal milestones',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Vendor', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Renewal', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _contracts.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.id, style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9)))),
              DataCell(Text(item.vendor, style: const TextStyle(fontSize: 13))),
              DataCell(_chip(item.type)),
              DataCell(_statusChip(item.status)),
              DataCell(Text(item.renewal, style: const TextStyle(fontSize: 12))),
              DataCell(Text(item.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              DataCell(Text(item.owner, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRenewalPanel() {
    return _PanelShell(
      title: 'Renewal pipeline',
      subtitle: 'Contracts rolling into renewal windows',
      child: Column(
        children: _renewalLanes.map((lane) {
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
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: lane.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(lane.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Text('${lane.count} contracts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: lane.color)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSignalsPanel() {
    return _PanelShell(
      title: 'Risk signals',
      subtitle: 'Items that need attention this week',
      child: Column(
        children: _signals.map((signal) {
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

  Widget _buildApprovalsPanel() {
    return _PanelShell(
      title: 'Approval readiness',
      subtitle: 'Legal and finance checkpoints',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ApprovalItem('Legal review queue', '2 pending', true),
          _ApprovalItem('Finance sign-off', 'Complete', true),
          _ApprovalItem('Security assessment', 'Scheduled', false),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
    );
  }

  Widget _statusChip(String label) {
    Color color;
    switch (label) {
      case 'Renewal due':
        color = const Color(0xFFF97316);
        break;
      case 'At risk':
        color = const Color(0xFFEF4444);
        break;
      case 'Pending sign-off':
        color = const Color(0xFF6366F1);
        break;
      default:
        color = const Color(0xFF10B981);
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

class _ApprovalItem extends StatelessWidget {
  const _ApprovalItem(this.title, this.status, this.complete);

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
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          Text(status, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _ContractItem {
  const _ContractItem(this.id, this.vendor, this.type, this.status, this.renewal, this.value, this.owner);

  final String id;
  final String vendor;
  final String type;
  final String status;
  final String renewal;
  final String value;
  final String owner;
}

class _RenewalLane {
  const _RenewalLane(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

class _SignalItem {
  const _SignalItem(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
