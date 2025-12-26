import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class IdentifyStaffOpsTeamScreen extends StatefulWidget {
  const IdentifyStaffOpsTeamScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IdentifyStaffOpsTeamScreen()),
    );
  }

  @override
  State<IdentifyStaffOpsTeamScreen> createState() => _IdentifyStaffOpsTeamScreenState();
}

class _IdentifyStaffOpsTeamScreenState extends State<IdentifyStaffOpsTeamScreen> {
  final List<_OpsMember> _members = const [
    _OpsMember('Sarah Mitchell', 'Ops Lead', 'Operations strategy', 'Active', 86),
    _OpsMember('James Rodriguez', 'Support Manager', 'Tier-2 support', 'Active', 74),
    _OpsMember('Emily Chen', 'Training Lead', 'Enablement', 'Pending', 52),
    _OpsMember('Michael Thompson', 'Facilities', 'On-site readiness', 'Active', 68),
    _OpsMember('Lisa Park', 'Compliance', 'Regulatory liaison', 'Active', 62),
  ];

  final List<_CapabilityItem> _capabilities = const [
    _CapabilityItem('Incident response coverage', 0.78, Color(0xFF0EA5E9)),
    _CapabilityItem('Runbook completeness', 0.64, Color(0xFF6366F1)),
    _CapabilityItem('Training completion', 0.58, Color(0xFFF59E0B)),
    _CapabilityItem('Service desk readiness', 0.83, Color(0xFF10B981)),
  ];

  final List<_ChecklistItem> _checklist = const [
    _ChecklistItem('Ops onboarding packet distributed', true),
    _ChecklistItem('Escalation policy signed off', true),
    _ChecklistItem('Shadow support shifts scheduled', false),
    _ChecklistItem('Tooling access verified', true),
    _ChecklistItem('Go-live coverage confirmed', false),
  ];

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Identify and Staff Ops Team',
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isNarrow),
                const SizedBox(height: 18),
                _buildStatsRow(isNarrow),
                const SizedBox(height: 24),
                if (isNarrow)
                  Column(
                    children: [
                      _buildRosterPanel(),
                      const SizedBox(height: 20),
                      _buildCoveragePanel(),
                      const SizedBox(height: 20),
                      _buildChecklistPanel(),
                      const SizedBox(height: 20),
                      _buildHandoffPanel(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildRosterPanel()),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildCoveragePanel(),
                            const SizedBox(height: 20),
                            _buildChecklistPanel(),
                            const SizedBox(height: 20),
                            _buildHandoffPanel(),
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
            'OPS READINESS',
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
                    'Identify & Staff Ops Team',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Confirm operational roles, coverage, and training readiness before handover.',
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
        _actionButton(Icons.person_add_alt_1, 'Add role'),
        _actionButton(Icons.assignment_ind_outlined, 'Assign member'),
        _actionButton(Icons.description_outlined, 'Export roster'),
        _primaryButton('Publish handoff'),
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
      icon: const Icon(Icons.check_circle_outline, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildStatsRow(bool isNarrow) {
    final stats = [
      _StatCardData('Roles filled', '9/12', '3 open roles', const Color(0xFF0EA5E9)),
      _StatCardData('Coverage plan', '82%', 'Next shift Tue', const Color(0xFF10B981)),
      _StatCardData('Training completion', '58%', '2 modules overdue', const Color(0xFFF59E0B)),
      _StatCardData('Handoff readiness', '74%', 'Pending sign-off', const Color(0xFF6366F1)),
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

  Widget _buildRosterPanel() {
    return _PanelShell(
      title: 'Ops roster',
      subtitle: 'Role assignments, workload, and focus areas',
      trailing: _actionButton(Icons.filter_list, 'Filter'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Focus', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Capacity', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _members.map((member) {
            return DataRow(cells: [
              DataCell(Text(member.name, style: const TextStyle(fontSize: 13))),
              DataCell(Text(member.role, style: const TextStyle(fontSize: 13))),
              DataCell(Text(member.focus, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
              DataCell(_statusChip(member.status)),
              DataCell(_capacityChip(member.capacity)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCoveragePanel() {
    return _PanelShell(
      title: 'Capability coverage',
      subtitle: 'Readiness by operational capability',
      child: Column(
        children: _capabilities.map((capability) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(capability.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Text('${(capability.progress * 100).round()}%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: capability.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(capability.color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChecklistPanel() {
    return _PanelShell(
      title: 'Readiness checklist',
      subtitle: 'Pre-handover verification',
      child: Column(
        children: _checklist.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(item.done ? Icons.check_circle : Icons.radio_button_unchecked, size: 16, color: item.done ? const Color(0xFF10B981) : const Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(child: Text(item.label, style: const TextStyle(fontSize: 12))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHandoffPanel() {
    return _PanelShell(
      title: 'Handoff summary',
      subtitle: 'Critical items to complete before launch',
      child: Column(
        children: const [
          _HandoffItem('On-call rotation published', 'Pending confirmation'),
          _HandoffItem('Ops runbook review', 'Scheduled for Oct 16'),
          _HandoffItem('Stakeholder sign-off', 'Awaiting sponsor'),
        ],
      ),
    );
  }

  Widget _statusChip(String label) {
    final color = label == 'Active' ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _capacityChip(int value) {
    final color = value >= 80 ? const Color(0xFFEF4444) : value >= 60 ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text('$value%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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

class _HandoffItem extends StatelessWidget {
  const _HandoffItem(this.title, this.status);

  final String title;
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
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: const Color(0xFF0EA5E9), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
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

class _OpsMember {
  const _OpsMember(this.name, this.role, this.focus, this.status, this.capacity);

  final String name;
  final String role;
  final String focus;
  final String status;
  final int capacity;
}

class _CapabilityItem {
  const _CapabilityItem(this.label, this.progress, this.color);

  final String label;
  final double progress;
  final Color color;
}

class _ChecklistItem {
  const _ChecklistItem(this.label, this.done);

  final String label;
  final bool done;
}

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
