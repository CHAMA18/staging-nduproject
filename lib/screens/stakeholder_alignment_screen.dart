import 'package:flutter/material.dart';
import 'package:ndu_project/screens/scope_tracking_implementation_screen.dart';
import 'package:ndu_project/screens/update_ops_maintenance_plans_screen.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/project_insights_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = ProjectDataInherited.maybeOf(context);
    final projectId = provider?.projectData.projectId;
    final isNarrow = MediaQuery.sizeOf(context).width < 980;
    final padding = AppBreakpoints.pagePadding(context);

    if (projectId == null) {
      return ResponsiveScaffold(
        activeItemLabel: 'Stakeholder Alignment',
        backgroundColor: const Color(0xFFF5F7FB),
        body: Center(
          child: Text(
            'Select a project to view stakeholder alignment metrics.',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
        ),
      );
    }

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
                _buildPulseRow(isNarrow, projectId),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStakeholderRegister(projectId),
                    const SizedBox(height: 20),
                    _buildSignalsPanel(projectId),
                    const SizedBox(height: 20),
                    _buildDecisionPanel(),
                    const SizedBox(height: 20),
                    _buildCadencePanel(),
                  ],
                ),
                const SizedBox(height: 24),
                LaunchPhaseNavigation(
                  backLabel: 'Back: Scope Tracking Implementation',
                  nextLabel: 'Next: Update Ops & Maintenance Plans',
                  onBack: () => ScopeTrackingImplementationScreen.open(context),
                  onNext: () => UpdateOpsMaintenancePlansScreen.open(context),
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

  Widget _buildPulseRow(bool isNarrow, String projectId) {
    return StreamBuilder<StakeholderAlignmentOverview>(
      stream: ProjectInsightsService.streamStakeholderOverview(projectId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final pulses = snapshot.data!.pulses;
        if (pulses.isEmpty) {
          return const Text('No alignment metrics captured yet.', style: TextStyle(color: Color(0xFF6B7280)));
        }
        if (isNarrow) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: pulses.map(_buildPulseCard).toList(),
          );
        }
        return Row(
          children: pulses
              .map(
                (pulse) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildPulseCard(pulse),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildPulseCard(StakeholderPulse item) {
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

  Widget _buildStakeholderRegister(String projectId) {
    return StreamBuilder<List<StakeholderMember>>(
      stream: ProjectInsightsService.streamStakeholders(projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final stakeholders = snapshot.data ?? [];
        if (stakeholders.isEmpty) {
          return _emptyPanelMessage('No stakeholders captured yet.');
        }
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
              rows: stakeholders.map((stakeholder) {
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
      },
    );
  }

  Widget _buildSignalsPanel(String projectId) {
    return StreamBuilder<StakeholderAlignmentOverview>(
      stream: ProjectInsightsService.streamStakeholderOverview(projectId),
      builder: (context, snapshot) {
        final signals = snapshot.data?.signals ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (signals.isEmpty) {
          return _emptyPanelMessage('No alignment signals recorded yet.');
        }
        return _PanelShell(
          title: 'Alignment signals',
          subtitle: 'Signals that require attention',
          child: Column(
            children: signals.map((signal) {
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
                    Text(signal.detail, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
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

  Widget _emptyPanelMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF6B7280))),
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
