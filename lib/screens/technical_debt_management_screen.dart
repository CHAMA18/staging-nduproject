import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/models/project_data_model.dart';

class TechnicalDebtManagementScreen extends StatefulWidget {
  const TechnicalDebtManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TechnicalDebtManagementScreen()),
    );
  }

  @override
  State<TechnicalDebtManagementScreen> createState() => _TechnicalDebtManagementScreenState();
}

class _TechnicalDebtManagementScreenState extends State<TechnicalDebtManagementScreen> {
  final Set<String> _selectedFilters = {'All'};

  // Local copies updated from provider
  List<DebtItem> _debtItems = [];
  List<DebtInsight> _rootCauses = [];
  List<RemediationTrack> _tracks = [];
  List<OwnerItem> _owners = [];

  final _ai = OpenAiServiceSecure();

  @override
  Widget build(BuildContext context) {
  final data = ProjectDataHelper.getData(context).frontEndPlanning;
  // sync local view lists from persisted project data
  _debtItems = data.technicalDebtItems;
  _rootCauses = data.technicalDebtRootCauses;
  _tracks = data.technicalDebtTracks;
  _owners = data.technicalDebtOwners;
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Technical Debt Management',
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
                    _buildDebtRegister(),
                    const SizedBox(height: 20),
                    _buildRemediationPanel(),
                    const SizedBox(height: 20),
                    _buildRootCausePanel(),
                    const SizedBox(height: 20),
                    _buildOwnershipPanel(),
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
            'EXECUTION HEALTH',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Technical Debt Management',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Track residual debt, prioritize remediation, and align owners before project close-out.',
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
  _actionButton(Icons.add, 'Add debt item'),
        _actionButton(Icons.tune, 'Prioritize backlog'),
        _actionButton(Icons.description_outlined, 'Generate report'),
        _primaryButton('Launch remediation sprint'),
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
    const filters = ['All', 'Critical', 'High impact', 'Due this month', 'Blocked'];
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
      _StatCardData('Open debt items', '18', '6 critical', const Color(0xFFEF4444)),
      _StatCardData('In remediation', '7', '2 sprint owners', const Color(0xFF0EA5E9)),
      _StatCardData('Monthly burn-down', '14%', 'Goal 20%', const Color(0xFF10B981)),
      _StatCardData('Owner coverage', '92%', '2 gaps', const Color(0xFF6366F1)),
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

  Widget _buildDebtRegister() {
    return _PanelShell(
      title: 'Debt register',
      subtitle: 'Track high-impact debt items and remediation targets',
      trailing: Row(children: [
        _actionButton(Icons.filter_list, 'Filter'),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () async {
            // Call AI to seed debt items and persist via ProjectDataHelper
            final ctx = ProjectDataHelper.buildFepContext(ProjectDataHelper.getData(context));
            final text = await _ai.generateFepSectionText(section: 'Technical Debt', context: ctx, maxTokens: 600);
            // naive parse: split lines and create DebtItem titles
            final lines = text.split('\n').map((s) => s.replaceAll('*', '').trim()).where((s) => s.isNotEmpty).toList();
            final newItems = lines.map((l) => DebtItem(id: DateTime.now().microsecondsSinceEpoch.toString(), title: l)).toList();

            await ProjectDataHelper.updateAndSave(
              context: context,
              checkpoint: 'technical_debt_management',
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
                  technicalDebtItems: [...fep.technicalDebtItems, ...newItems],
                  technicalDebtRootCauses: fep.technicalDebtRootCauses,
                  technicalDebtTracks: fep.technicalDebtTracks,
                  technicalDebtOwners: fep.technicalDebtOwners,
                );
                return current.copyWith(frontEndPlanning: updated);
              },
            );
          },
          icon: const Icon(Icons.auto_fix_high, size: 16),
          label: const Text('Auto-populate (AI)'),
        ),
      ]),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Area', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Severity', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Target', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _debtItems.map((item) {
            return DataRow(cells: [
              DataCell(Text(item.id, style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9)))),
              DataCell(Text(item.title, style: const TextStyle(fontSize: 13))),
              DataCell(_chip(item.area)),
              DataCell(Text(item.owner, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
              DataCell(_severityChip(item.severity)),
              DataCell(_statusChip(item.status)),
              DataCell(Text(item.target, style: const TextStyle(fontSize: 12))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRemediationPanel() {
    return _PanelShell(
      title: 'Remediation runway',
      subtitle: 'Progress by priority lane',
      trailing: _chip('Weekly cadence'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _tracks.map((track) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(track.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                    Text('${(track.progress * 100).round()}%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: track.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(track.colorValue)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRootCausePanel() {
    return _PanelShell(
      title: 'Root cause signals',
      subtitle: 'Clustered themes driving technical debt',
      child: Column(
        children: _rootCauses.map((item) {
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
                Text(item.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOwnershipPanel() {
    return _PanelShell(
      title: 'Ownership coverage',
      subtitle: 'Confirm accountable owners and next review',
      trailing: _chip('Next review: Oct 14'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _owners.map((o) => _OwnerItem(o.name, o.count, o.note)).toList(),
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

  Widget _severityChip(String label) {
    Color color;
    switch (label) {
      case 'Critical':
        color = const Color(0xFFEF4444);
        break;
      case 'High':
        color = const Color(0xFFF97316);
        break;
      case 'Medium':
        color = const Color(0xFF6366F1);
        break;
      default:
        color = const Color(0xFF94A3B8);
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

  Widget _statusChip(String label) {
    final color = label == 'In progress'
        ? const Color(0xFF0EA5E9)
        : label == 'Backlog'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6366F1);
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

class _OwnerItem extends StatelessWidget {
  const _OwnerItem(this.name, this.count, this.note);

  final String name;
  final String count;
  final String note;

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
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
            child: Text(name.substring(0, 1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0EA5E9))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(note, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(count, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
// Legacy private data classes removed; using persisted models from project_data_model.dart

class _StatCardData {
  const _StatCardData(this.label, this.value, this.supporting, this.color);

  final String label;
  final String value;
  final String supporting;
  final Color color;
}
