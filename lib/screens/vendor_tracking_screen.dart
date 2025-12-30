import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class VendorTrackingScreen extends StatefulWidget {
  const VendorTrackingScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VendorTrackingScreen()),
    );
  }

  @override
  State<VendorTrackingScreen> createState() => _VendorTrackingScreenState();
}

class _VendorTrackingScreenState extends State<VendorTrackingScreen> {
  final Set<String> _selectedFilters = {'All vendors'};

  final List<_VendorItem> _vendors = const [
    _VendorItem('Omega Systems', 'Integration', '92%', 'A', 'Active', 'Oct 28'),
    _VendorItem('BrightWorks', 'Infrastructure', '84%', 'B', 'Watch', 'Oct 16'),
    _VendorItem('Vantage Labs', 'Security', '76%', 'C', 'At risk', 'Oct 12'),
    _VendorItem('Eastline Partners', 'Operations', '88%', 'B', 'Active', 'Nov 05'),
    _VendorItem('Nimbus Health', 'Compliance', '90%', 'A', 'Onboard', 'Nov 18'),
  ];

  final List<_PerformancePulse> _pulses = const [
    _PerformancePulse('On-time delivery', 0.86, Color(0xFF10B981)),
    _PerformancePulse('Incident response', 0.72, Color(0xFF0EA5E9)),
    _PerformancePulse('Quality score', 0.79, Color(0xFF6366F1)),
    _PerformancePulse('Cost adherence', 0.65, Color(0xFFF59E0B)),
  ];

  final List<_SignalItem> _signals = const [
    _SignalItem('SLA breach alerts', '2 vendors breached response SLA this week.'),
    _SignalItem('Contract coverage gap', '1 supplier lacks updated NDA.'),
    _SignalItem('Quality drift', 'Defect rate spiked on two deliveries.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Vendor Tracking',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildVendorRegister(),
                    const SizedBox(height: 20),
                    _buildPerformancePanel(),
                    const SizedBox(height: 20),
                    _buildSignalsPanel(),
                    const SizedBox(height: 20),
                    _buildActionPanel(),
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
            'VENDOR OVERSIGHT',
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
                    'Vendor Tracking',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Monitor vendor performance, compliance, and delivery health across execution.',
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
        _actionButton(Icons.add, 'Add vendor'),
        _actionButton(Icons.assessment_outlined, 'Quarterly review'),
        _actionButton(Icons.description_outlined, 'Export scorecard'),
        _primaryButton('Start vendor audit'),
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
    const filters = ['All vendors', 'At risk', 'Watchlist', 'Strategic', 'New'];
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
      _StatCardData('Active vendors', '14', '3 strategic', const Color(0xFF0EA5E9)),
      _StatCardData('On-time delivery', '86%', '2 late this month', const Color(0xFF10B981)),
      _StatCardData('Risk rating', 'B+', 'Trending stable', const Color(0xFFF59E0B)),
      _StatCardData('Spend variance', '4.2%', 'Within guardrails', const Color(0xFF6366F1)),
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

  Widget _buildVendorRegister() {
    return _PanelShell(
      title: 'Vendor scorecard',
      subtitle: 'Performance, rating, and compliance checkpoints',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Vendor', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('SLA', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Rating', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Next review', style: TextStyle(fontWeight: FontWeight.w600))),
                ],
                rows: _vendors.map((vendor) {
                  return DataRow(cells: [
                    DataCell(Text(vendor.name, style: const TextStyle(fontSize: 13))),
                    DataCell(_chip(vendor.category)),
                    DataCell(Text(vendor.sla, style: const TextStyle(fontSize: 12))),
                    DataCell(_ratingChip(vendor.rating)),
                    DataCell(_statusChip(vendor.status)),
                    DataCell(Text(vendor.nextReview, style: const TextStyle(fontSize: 12))),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformancePanel() {
    return _PanelShell(
      title: 'Performance pulse',
      subtitle: 'Key service health indicators',
      child: Column(
        children: _pulses.map((pulse) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(pulse.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Text('${(pulse.value * 100).round()}%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pulse.value,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(pulse.color),
                  ),
                ),
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
      subtitle: 'Active alerts and vendor watch items',
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

  Widget _buildActionPanel() {
    return _PanelShell(
      title: 'Action plan',
      subtitle: 'Upcoming touchpoints and remediation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ActionItem('Quarterly business review', 'Oct 21', 'Agenda locked'),
          _ActionItem('Security compliance audit', 'Oct 25', 'Docs requested'),
          _ActionItem('Performance tuning workshop', 'Nov 02', 'Pending invite'),
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

  Widget _ratingChip(String label) {
    final color = label == 'A' ? const Color(0xFF10B981) : label == 'B' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _statusChip(String label) {
    Color color;
    switch (label) {
      case 'At risk':
        color = const Color(0xFFEF4444);
        break;
      case 'Watch':
        color = const Color(0xFFF59E0B);
        break;
      case 'Onboard':
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

class _ActionItem extends StatelessWidget {
  const _ActionItem(this.title, this.date, this.status);

  final String title;
  final String date;
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
                Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _VendorItem {
  const _VendorItem(this.name, this.category, this.sla, this.rating, this.status, this.nextReview);

  final String name;
  final String category;
  final String sla;
  final String rating;
  final String status;
  final String nextReview;
}

class _PerformancePulse {
  const _PerformancePulse(this.label, this.value, this.color);

  final String label;
  final double value;
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
