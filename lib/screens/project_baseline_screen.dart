import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/utils/project_data_helper.dart';

class ProjectBaselineScreen extends StatefulWidget {
  const ProjectBaselineScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectBaselineScreen()),
    );
  }

  @override
  State<ProjectBaselineScreen> createState() => _ProjectBaselineScreenState();
}

class _ProjectBaselineScreenState extends State<ProjectBaselineScreen> {
  static const List<String> _projectOptions = [];
  static const List<_BaselineHistoryEntry> _history = [];
  static const List<_ScheduleVarianceRow> _scheduleVariance = [];
  static const List<_CostVarianceRow> _costVariance = [];

  String? _selectedProject;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final name = ProjectDataHelper.getData(context).projectName.trim();
      if (name.isNotEmpty && mounted) {
        setState(() => _selectedProject = name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 18 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: AppBreakpoints.sidebarWidth(context),
                  child: const InitiationLikeSidebar(activeItemLabel: 'Project Baseline'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 24),
                        const PlanningAiNotesCard(
                          title: 'Notes',
                          sectionLabel: 'Project Baseline',
                          noteKey: 'planning_project_baseline_notes',
                          checkpoint: 'project_baseline',
                          description: 'Summarize baseline assumptions, schedule/cost variances, and approvals.',
                        ),
                        const SizedBox(height: 24),
                        _buildBaselineCards(context),
                        const SizedBox(height: 24),
                        _buildBaselineHistory(),
                        const SizedBox(height: 24),
                        _buildVarianceAnalysis(),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const KazAiChatBubble(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primary = const Color(0xFF2563EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 16,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Baseline',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Monitor schedule, cost, and scope baselines to keep delivery commitments visible and actionable.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.update, size: 18),
                  label: const Text('Update Baseline'),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share_outlined, size: 18),
                  label: const Text('Export'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withValues(alpha: 0.45)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildProjectDropdown(),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                _StatusChip(label: 'Status: —', color: Color(0xFF1F2937), inverted: true),
                _StatusChip(label: 'Start: —', color: Color(0xFF1F2937), inverted: true),
                _StatusChip(label: 'End: —', color: Color(0xFF1F2937), inverted: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectDropdown() {
    final options = _selectedProject != null ? [_selectedProject!] : _projectOptions;
    if (options.isEmpty) {
      return _EmptyStateChip(
        label: 'Select project',
        icon: Icons.folder_open_outlined,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProject ?? options.first,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          items: options
              .map(
                (project) => DropdownMenuItem<String>(
                  value: project,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(project),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedProject = value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBaselineCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var availableWidth = constraints.maxWidth;
        if (!availableWidth.isFinite) {
          availableWidth = MediaQuery.of(context).size.width;
        }

        int columns;
        if (availableWidth >= 1080) {
          columns = 3;
        } else if (availableWidth >= 720) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 16.0;
        final double cardWidth = columns == 1
            ? availableWidth
            : (availableWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: 18,
          children: [
            SizedBox(width: cardWidth, child: _buildScheduleBaselineCard()),
            SizedBox(width: cardWidth, child: _buildCostBaselineCard()),
            SizedBox(width: cardWidth, child: _buildScopeBaselineCard()),
          ],
        );
      },
    );
  }

  Widget _buildScheduleBaselineCard() {
    if (_scheduleDetails.isEmpty) {
      return const _EmptyStateCard(
        title: 'No schedule baseline yet',
        message: 'Add baseline milestones to see schedule health.',
        icon: Icons.schedule_outlined,
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x331D4ED8), blurRadius: 24, offset: Offset(0, 20)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Schedule Baseline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._scheduleDetails.map(
            (detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    detail.label,
                    style: const TextStyle(
                      color: Color(0xCCEFF6FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    detail.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: 0.68,
              minHeight: 14,
              color: const Color(0xFF60A5FA),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start',
                style: TextStyle(color: Color(0xCCEFF6FF), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'Current Progress (68%)',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                'End',
                style: TextStyle(color: Color(0xCCEFF6FF), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostBaselineCard() {
    if (_costDetails.isEmpty) {
      return const _EmptyStateCard(
        title: 'No cost baseline yet',
        message: 'Add baseline cost items to track budget health.',
        icon: Icons.account_balance_wallet_outlined,
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _whiteCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF1F2937), size: 22),
              SizedBox(width: 10),
              Text(
                'Cost Baseline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._costDetails.map(
            (detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    detail.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Budget Variance',
                  style: TextStyle(color: Color(0xFF6B21A8), fontWeight: FontWeight.w700),
                ),
                Text(
                  '—',
                  style: TextStyle(color: Color(0xFF6B21A8), fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeBaselineCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _whiteCardDecoration(),
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
                    const Row(
                      children: [
                        Icon(Icons.dashboard_customize_outlined, color: Color(0xFF1F2937), size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Scope Baseline',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildScopeStatRow('Last Baseline Date', '—'),
                    _buildScopeStatRow('Original EPICs', '—'),
                    _buildScopeStatRow('Current EPICs', '—'),
                    _buildScopeStatRow('Original Features', '—'),
                    _buildScopeStatRow('Current Features', '—'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(label: 'Status: —', color: Color(0xFF1F2937), inverted: true),
                  SizedBox(height: 12),
                  Text(
                    'Start: —',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    'End: —',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.trending_up, color: Color(0xFF1D4ED8), size: 18),
                SizedBox(width: 10),
                Text(
                  'Scope Change:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Not set',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineHistory() {
    if (_history.isEmpty) {
      return const _EmptyStateCard(
        title: 'No baseline history yet',
        message: 'Capture baseline approvals to build version history.',
        icon: Icons.history_outlined,
      );
    }
    return Container(
      decoration: _whiteCardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Baseline History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 18),
          _buildHistoryHeaderRow(),
          const SizedBox(height: 12),
          ..._history.map((entry) => _buildHistoryRow(entry)),
        ],
      ),
    );
  }

  Widget _buildHistoryHeaderRow() {
    return Row(
      children: const [
        Expanded(
          flex: 2,
          child: Text(
            'Baseline Version',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          child: Text(
            'Date',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Approved By',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Description',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            'Actions',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryRow(_BaselineHistoryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              entry.version,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            ),
          ),
          Expanded(
            child: Text(
              entry.date,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.approvedBy,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.description,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4B5563)),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              tooltip: 'View baseline',
              onPressed: () {},
              icon: const Icon(Icons.remove_red_eye_outlined, size: 20, color: Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceAnalysis() {
    if (_scheduleVariance.isEmpty && _costVariance.isEmpty) {
      return const _EmptyStateCard(
        title: 'No variance data yet',
        message: 'Add schedule and cost baselines to track variance trends.',
        icon: Icons.equalizer_outlined,
      );
    }
    return Container(
      decoration: _whiteCardDecoration(),
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool singleColumn = constraints.maxWidth < 820;
          final schedule = _buildScheduleVarianceColumn();
          final cost = _buildCostVarianceColumn();

          if (singleColumn) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                schedule,
                const SizedBox(height: 24),
                cost,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: schedule),
              const SizedBox(width: 24),
              Expanded(child: cost),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScheduleVarianceColumn() {
    if (_scheduleVariance.isEmpty) {
      return const _EmptyStateCard(
        title: 'No schedule variance',
        message: 'Schedule variance will appear once baselines are captured.',
        icon: Icons.timeline_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schedule Variance Breakdown',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 18),
        ..._scheduleVariance.map(
          (variance) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      variance.label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                    ),
                    Text(
                      variance.varianceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: variance.tone.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: variance.progress,
                    minHeight: 12,
                    color: variance.tone.barColor,
                    backgroundColor: const Color(0xFFE5E7EB),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostVarianceColumn() {
    if (_costVariance.isEmpty) {
      return const _EmptyStateCard(
        title: 'No cost variance',
        message: 'Cost variance will appear once baselines are captured.',
        icon: Icons.payments_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cost Variance Breakdown',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 18),
        ..._costVariance.map(
          (row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.category,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${row.actual} (planned: ${row.planned})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(height: 1, color: const Color(0xFFE5E7EB)),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Variance',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
            ),
            Text(
              '+\$32,500 (5%)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
            ),
          ],
        ),
      ],
    );
  }

  BoxDecoration _whiteCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

class _BaselineHistoryEntry {
  const _BaselineHistoryEntry({
    required this.version,
    required this.date,
    required this.approvedBy,
    required this.description,
  });

  final String version;
  final String date;
  final String approvedBy;
  final String description;
}

class _ScheduleVarianceRow {
  const _ScheduleVarianceRow({
    required this.label,
    required this.varianceLabel,
    required this.progress,
    required this.tone,
  });

  final String label;
  final String varianceLabel;
  final double progress;
  final _VarianceTone tone;
}

class _CostVarianceRow {
  const _CostVarianceRow({
    required this.category,
    required this.actual,
    required this.planned,
  });

  final String category;
  final String actual;
  final String planned;
}

Widget _buildScopeStatRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color, this.inverted = false});

  final String label;
  final Color color;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final Color background = inverted ? const Color(0xFFF3F4F6) : color.withValues(alpha: 0.12);
    final Color foreground = inverted ? color : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.message, required this.icon});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateChip extends StatelessWidget {
  const _EmptyStateChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _VarianceTone {
  const _VarianceTone._(this.color, this.barColor);

  final Color color;
  final Color barColor;

  static const _VarianceTone onTrack = _VarianceTone._(Color(0xFF047857), Color(0xFF10B981));
  static const _VarianceTone warning = _VarianceTone._(Color(0xFFB45309), Color(0xFFFBBF24));
  static const _VarianceTone behind = _VarianceTone._(Color(0xFFB91C1C), Color(0xFFF87171));
}

class _ScheduleDetail {
  const _ScheduleDetail({required this.label, required this.value});

  final String label;
  final String value;
}

class _CostDetail {
  const _CostDetail({required this.label, required this.value});

  final String label;
  final String value;
}

const List<_ScheduleDetail> _scheduleDetails = [];

const List<_CostDetail> _costDetails = [];
