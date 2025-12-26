import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class DetailedDesignScreen extends StatefulWidget {
  const DetailedDesignScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DetailedDesignScreen()),
    );
  }

  @override
  State<DetailedDesignScreen> createState() => _DetailedDesignScreenState();
}

class _DetailedDesignScreenState extends State<DetailedDesignScreen> {
  final Set<String> _selectedFilters = {'All packages'};

  final List<_DesignPackage> _packages = const [
    _DesignPackage('DD-210', 'Service blueprint', 'Core platform', 'Ready', 'Lead architect', 'Oct 18'),
    _DesignPackage('DD-216', 'Interface spec', 'Integrations', 'In review', 'Integration lead', 'Oct 22'),
    _DesignPackage('DD-223', 'Data contract map', 'Analytics', 'Draft', 'Data lead', 'Oct 25'),
    _DesignPackage('DD-231', 'Security design', 'Security', 'Ready', 'Security team', 'Oct 28'),
    _DesignPackage('DD-238', 'Ops runbook draft', 'Operations', 'Pending', 'Ops lead', 'Nov 02'),
  ];

  final List<_ReviewPulse> _reviewPulses = const [
    _ReviewPulse('Architecture review', 0.78, Color(0xFF10B981)),
    _ReviewPulse('Interface alignment', 0.62, Color(0xFF6366F1)),
    _ReviewPulse('Data readiness', 0.54, Color(0xFFF59E0B)),
    _ReviewPulse('Security sign-off', 0.83, Color(0xFF0EA5E9)),
  ];

  final List<_DecisionItem> _decisions = const [
    _DecisionItem('Queue strategy', 'Approve async processing for batch jobs.', 'Owner: Platform'),
    _DecisionItem('Data retention rules', 'Align on 18-month retention.', 'Owner: Compliance'),
    _DecisionItem('Failover protocol', 'Select hot-warm strategy for services.', 'Owner: Infra'),
  ];

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Detailed Design',
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
                      _buildPackageRegister(),
                      const SizedBox(height: 20),
                      _buildReviewPanel(),
                      const SizedBox(height: 20),
                      _buildDecisionPanel(),
                      const SizedBox(height: 20),
                      _buildArtifactsPanel(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildPackageRegister()),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildReviewPanel(),
                            const SizedBox(height: 20),
                            _buildDecisionPanel(),
                            const SizedBox(height: 20),
                            _buildArtifactsPanel(),
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
            'EXECUTION DESIGN',
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
                    'Detailed Design',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Track design packages, interface sign-off, and decisions before build execution.',
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
        _actionButton(Icons.add, 'Add package'),
        _actionButton(Icons.upload_outlined, 'Upload artifact'),
        _actionButton(Icons.description_outlined, 'Export bundle'),
        _primaryButton('Start design review'),
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
    const filters = ['All packages', 'Ready', 'In review', 'Draft', 'Pending'];
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
      _StatCardData('Design packages', '18', '6 ready', const Color(0xFF0EA5E9)),
      _StatCardData('Reviews pending', '4', '2 this week', const Color(0xFFF59E0B)),
      _StatCardData('Decisions open', '5', '3 high impact', const Color(0xFFEF4444)),
      _StatCardData('Interface readiness', '72%', 'On track', const Color(0xFF6366F1)),
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

  Widget _buildPackageRegister() {
    return _PanelShell(
      title: 'Design package register',
      subtitle: 'Traceable artifacts and approvals',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Package', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Area', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Review date', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _packages.map((pkg) {
            return DataRow(cells: [
              DataCell(Text(pkg.id, style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9)))),
              DataCell(Text(pkg.name, style: const TextStyle(fontSize: 13))),
              DataCell(_chip(pkg.area)),
              DataCell(_statusChip(pkg.status)),
              DataCell(Text(pkg.owner, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
              DataCell(Text(pkg.reviewDate, style: const TextStyle(fontSize: 12))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReviewPanel() {
    return _PanelShell(
      title: 'Design review pulse',
      subtitle: 'Readiness by workstream',
      child: Column(
        children: _reviewPulses.map((pulse) {
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

  Widget _buildDecisionPanel() {
    return _PanelShell(
      title: 'Decision log',
      subtitle: 'Open decisions needing closure',
      child: Column(
        children: _decisions.map((item) {
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
                Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(item.summary, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                Text(item.owner, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildArtifactsPanel() {
    return _PanelShell(
      title: 'Artifact readiness',
      subtitle: 'Design assets staged for handoff',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ArtifactItem('API schema v4', 'Ready for build', true),
          _ArtifactItem('Sequence diagrams', 'Review pending', false),
          _ArtifactItem('Observability plan', 'Ready for build', true),
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
      case 'Ready':
        color = const Color(0xFF10B981);
        break;
      case 'In review':
        color = const Color(0xFF0EA5E9);
        break;
      case 'Draft':
        color = const Color(0xFFF59E0B);
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

class _ArtifactItem extends StatelessWidget {
  const _ArtifactItem(this.title, this.status, this.ready);

  final String title;
  final String status;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final color = ready ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
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
          Icon(ready ? Icons.check_circle : Icons.schedule, size: 16, color: color),
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

class _DesignPackage {
  const _DesignPackage(this.id, this.name, this.area, this.status, this.owner, this.reviewDate);

  final String id;
  final String name;
  final String area;
  final String status;
  final String owner;
  final String reviewDate;
}

class _ReviewPulse {
  const _ReviewPulse(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _DecisionItem {
  const _DecisionItem(this.title, this.summary, this.owner);

  final String title;
  final String summary;
  final String owner;
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
