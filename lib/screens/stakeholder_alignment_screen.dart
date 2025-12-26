import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class StakeholderAlignmentScreen extends StatefulWidget {
  const StakeholderAlignmentScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StakeholderAlignmentScreen()),
    );
  }

  @override
  State<StakeholderAlignmentScreen> createState() => _StakeholderAlignmentScreenState();
}

class _StakeholderAlignmentScreenState extends State<StakeholderAlignmentScreen> {
  final Set<String> _selectedFilters = {'All stakeholders'};

  final List<_StakeholderItem> _stakeholders = const [
    _StakeholderItem('A. Gomez', 'Executive sponsor', 'High', 'Aligned', 'Sep 28', 'Oct 18'),
    _StakeholderItem('M. Patel', 'Operations', 'High', 'Watch', 'Oct 02', 'Oct 20'),
    _StakeholderItem('J. Nguyen', 'Finance', 'Medium', 'Aligned', 'Sep 30', 'Oct 25'),
    _StakeholderItem('S. Lee', 'Security', 'High', 'At risk', 'Oct 04', 'Oct 16'),
    _StakeholderItem('R. Cole', 'Product', 'Medium', 'Aligned', 'Oct 01', 'Oct 22'),
  ];

  final List<_PulseItem> _pulses = const [
    _PulseItem('Alignment score', '84%', 'Stable', Color(0xFF10B981)),
    _PulseItem('Open decisions', '6', '2 urgent', Color(0xFFF59E0B)),
    _PulseItem('Engagement cadence', 'Weekly', 'Next sync Fri', Color(0xFF0EA5E9)),
  ];

  final List<_SignalItem> _signals = const [
    _SignalItem('Decision backlog', '2 items need sponsor confirmation.'),
    _SignalItem('Scope sensitivity', 'Ops team needs clarity on runbook ownership.'),
    _SignalItem('Timeline pressure', 'Security review shift requested.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Stakeholder Alignment',
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
                _buildPulseRow(isNarrow),
                const SizedBox(height: 24),
                if (isNarrow)
                  Column(
                    children: [
                      _buildStakeholderRegister(),
                      const SizedBox(height: 20),
                      _buildSignalsPanel(),
                      const SizedBox(height: 20),
                      _buildDecisionPanel(),
                      const SizedBox(height: 20),
                      _buildCadencePanel(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildStakeholderRegister()),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildSignalsPanel(),
                            const SizedBox(height: 20),
                            _buildDecisionPanel(),
                            const SizedBox(height: 20),
                            _buildCadencePanel(),
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
            'STAKEHOLDER ALIGNMENT',
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
                    'Stakeholder Alignment',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Keep sponsors, operations, and governance aligned as execution closes.',
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
        _actionButton(Icons.add, 'Add stakeholder'),
        _actionButton(Icons.calendar_today_outlined, 'Schedule sync'),
        _actionButton(Icons.description_outlined, 'Export alignment'),
        _primaryButton('Send update pack'),
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
    const filters = ['All stakeholders', 'Aligned', 'Watch', 'At risk', 'Exec'];
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

  Widget _buildPulseRow(bool isNarrow) {
    if (isNarrow) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _pulses.map(_buildPulseCard).toList(),
      );
    }
    return Row(
      children: _pulses.map((pulse) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _buildPulseCard(pulse),
        ),
      )).toList(),
    );
  }

  Widget _buildPulseCard(_PulseItem item) {
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
          Text(item.value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: item.color)),
          const SizedBox(height: 6),
          Text(item.label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(item.supporting, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: item.color)),
        ],
      ),
    );
  }

  Widget _buildStakeholderRegister() {
    return _PanelShell(
      title: 'Stakeholder register',
      subtitle: 'Influence, sentiment, and next actions',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Influence', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Sentiment', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Last touch', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Next sync', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _stakeholders.map((stakeholder) {
            return DataRow(cells: [
              DataCell(Text(stakeholder.name, style: const TextStyle(fontSize: 13))),
              DataCell(Text(stakeholder.role, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
              DataCell(_chip(stakeholder.influence)),
              DataCell(_statusChip(stakeholder.sentiment)),
              DataCell(Text(stakeholder.lastTouch, style: const TextStyle(fontSize: 12))),
              DataCell(Text(stakeholder.nextSync, style: const TextStyle(fontSize: 12))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSignalsPanel() {
    return _PanelShell(
      title: 'Alignment signals',
      subtitle: 'Signals that require attention',
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

  Widget _buildDecisionPanel() {
    return _PanelShell(
      title: 'Decision board',
      subtitle: 'Open decisions and ownership',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _DecisionItem('Finalize support model', 'Owner: Ops', 'Due Oct 20'),
          _DecisionItem('Approve risk buffer', 'Owner: Sponsor', 'Due Oct 18'),
          _DecisionItem('Confirm launch readiness', 'Owner: Program', 'Due Oct 22'),
        ],
      ),
    );
  }

  Widget _buildCadencePanel() {
    return _PanelShell(
      title: 'Engagement cadence',
      subtitle: 'Upcoming touchpoints',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _CadenceItem('Sponsor sync', 'Friday 9:00 AM', 'Agenda shared'),
          _CadenceItem('Ops alignment', 'Tuesday 2:00 PM', 'Deck in review'),
          _CadenceItem('Steering committee', 'Oct 24', 'Risk memo pending'),
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
      case 'Aligned':
        color = const Color(0xFF10B981);
        break;
      case 'Watch':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = const Color(0xFFEF4444);
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

class _DecisionItem extends StatelessWidget {
  const _DecisionItem(this.title, this.owner, this.due);

  final String title;
  final String owner;
  final String due;

  @override
  Widget build(BuildContext context) {
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
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(owner, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(due, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _CadenceItem extends StatelessWidget {
  const _CadenceItem(this.title, this.time, this.status);

  final String title;
  final String time;
  final String status;

  @override
  Widget build(BuildContext context) {
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
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF0EA5E9), shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _StakeholderItem {
  const _StakeholderItem(this.name, this.role, this.influence, this.sentiment, this.lastTouch, this.nextSync);

  final String name;
  final String role;
  final String influence;
  final String sentiment;
  final String lastTouch;
  final String nextSync;
}

class _PulseItem {
  const _PulseItem(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}

class _SignalItem {
  const _SignalItem(this.title, this.subtitle);

  final String title;
  final String subtitle;
}
