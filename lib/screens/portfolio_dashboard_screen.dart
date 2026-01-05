import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/kaz_ai_chat_bubble.dart';
import '../routing/app_router.dart';
import '../services/navigation_context_service.dart';
import '../services/project_service.dart';
import '../services/program_service.dart';
import '../models/program_model.dart';

class PortfolioDashboardScreen extends StatelessWidget {
  const PortfolioDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    NavigationContextService.instance.setLastClientDashboard(AppRoutes.portfolioDashboard);
    return const Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      body: Stack(
        children: [
          SafeArea(
            child: _PortfolioRollUpContent(),
          ),
          KazAiChatBubble(),
        ],
      ),
    );
  }
}

class _PortfolioRollUpContent extends StatelessWidget {
  const _PortfolioRollUpContent();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final projectStream = user == null ? Stream.value(const <ProjectRecord>[]) : ProjectService.streamProjects(ownerId: user.uid);
    final programStream = user == null ? Stream.value(const <ProgramModel>[]) : ProgramService.streamPrograms(ownerId: user.uid);

    return StreamBuilder<List<ProjectRecord>>(
      stream: projectStream,
      builder: (context, snapshot) {
        final projects = snapshot.data ?? const <ProjectRecord>[];
        return StreamBuilder<List<ProgramModel>>(
          stream: programStream,
          builder: (context, programSnapshot) {
            final programs = programSnapshot.data ?? const <ProgramModel>[];
            final metrics = _PortfolioMetrics.fromData(projects: projects, programs: programs);

            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 1000;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderSection(metrics: metrics),
                      const SizedBox(height: 24),
                      if (isNarrow) ...[
                        _ProgramsProjectsCard(metrics: metrics),
                        const SizedBox(height: 24),
                        const _GovernanceReportingCard(),
                        const SizedBox(height: 24),
                        _IndependentProjectsCard(metrics: metrics),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  _ProgramsProjectsCard(metrics: metrics),
                                  const SizedBox(height: 16),
                                  _IndependentProjectsCard(metrics: metrics),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            const Expanded(flex: 4, child: _GovernanceReportingCard()),
                          ],
                        ),
                      const SizedBox(height: 24),
                      _CostScheduleRiskSection(metrics: metrics),
                      const SizedBox(height: 24),
                      _RollUpUpdateSection(metrics: metrics),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.metrics});

  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final programLabel = '${metrics.programCount} ${metrics.programCount == 1 ? 'program' : 'programs'}';
    final projectLabel = '${metrics.projectCount} ${metrics.projectCount == 1 ? 'project' : 'projects'} included';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFE4A0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Text('Roll-up preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade800)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Confirm portfolio roll-up', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF1A1D21))),
              const SizedBox(height: 8),
              Text(
                'Review which programs, projects, governance rules, and risks will be rolled up into this portfolio view before publishing it for executives and steering committees.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280), height: 1.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoChip(label: programLabel, icon: Icons.layers_outlined),
                  _InfoChip(label: projectLabel, icon: Icons.folder_outlined),
                  _InfoChip(label: 'Total portfolio value: ${metrics.formattedTotalValue}', icon: Icons.attach_money),
                  _InfoChip(label: 'Risk posture: ${metrics.riskPostureLabel}', icon: Icons.shield_outlined),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to portfolio dashboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            Text('Adjust selection of programs, projects, or independent work', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF9CA3AF))),
          ],
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ProgramsProjectsCard extends StatelessWidget {
  const _ProgramsProjectsCard({required this.metrics});

  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final programCount = metrics.programCount;
    final programScopeLabel = programCount == 0
        ? 'No programs yet'
        : '$programCount ${programCount == 1 ? 'program' : 'programs'} · ${metrics.inProgramProjectCount} ${metrics.inProgramProjectCount == 1 ? 'project' : 'projects'}';
    final rollups = metrics.programRollups;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Programs & projects in this roll-up', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Verify which programs and projects will contribute cost, schedule, and risk into the rolled-up portfolio.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                  child: Text(programScopeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2563EB))),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (rollups.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No programs created yet. Group projects into programs to see a roll-up here.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFFF9FAFB),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Program', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)))),
                  Expanded(flex: 2, child: Text('Projects in scope', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)))),
                  Expanded(flex: 1, child: Text('Value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)))),
                  Expanded(flex: 1, child: Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)))),
                ],
              ),
            ),
            for (final rollup in rollups)
              _ProgramRow(
                title: rollup.name,
                description: rollup.description,
                projectScopeLabel: rollup.projectScopeLabel,
                value: rollup.formattedValue,
                priority: rollup.priorityLabel,
                priorityColor: rollup.priorityColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProgramRow extends StatelessWidget {
  const _ProgramRow({
    required this.title,
    required this.description,
    required this.projectScopeLabel,
    required this.value,
    required this.priority,
    required this.priorityColor,
  });

  final String title;
  final String description;
  final String projectScopeLabel;
  final String value;
  final String priority;
  final Color priorityColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
              child: Text(projectScopeLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF92400E))),
            ),
          ),
          Expanded(flex: 1, child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)))),
          Expanded(flex: 1, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(priority, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: priorityColor)))),
        ],
      ),
    );
  }
}

class _IndependentProjectsCard extends StatelessWidget {
  const _IndependentProjectsCard({required this.metrics});

  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final independentProjects = metrics.independentProjects;
    final previewProjects = independentProjects.take(2).toList(growable: false);
    final chipLabel = metrics.independentProjectCount == 0
        ? 'No standalone projects'
        : metrics.independentProjectCount == 1
            ? '1 standalone project'
            : '${metrics.independentProjectCount} standalone projects';

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Independent projects in roll-up', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                child: Text(chipLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Decide which independent projects should be reflected in this portfolio\'s value and reporting.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
          const SizedBox(height: 16),
          if (previewProjects.isEmpty)
            Text(
              'All projects are grouped into programs right now.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
            )
          else ...[
            for (int i = 0; i < previewProjects.length; i++) ...[
              _IndependentProjectRow(
                title: previewProjects[i].name.isEmpty ? 'Untitled project' : previewProjects[i].name,
                subtitle: _projectSubtitle(previewProjects[i]),
                phase: _projectPhase(previewProjects[i]),
              ),
              if (i != previewProjects.length - 1) const SizedBox(height: 12),
            ],
            if (independentProjects.length > previewProjects.length) ...[
              const SizedBox(height: 12),
              Text(
                '+${independentProjects.length - previewProjects.length} more independent project${independentProjects.length - previewProjects.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF9CA3AF)),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(child: Text('Use the related/unrelated flag to control which independent work influences portfolio value and dashboards.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500))),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndependentProjectRow extends StatelessWidget {
  const _IndependentProjectRow({required this.title, required this.subtitle, required this.phase});
  final String title;
  final String subtitle;
  final String phase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFDDD6FE), borderRadius: BorderRadius.circular(4)), child: Text(phase, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF7C3AED)))),
        ],
      ),
    );
  }
}

class _GovernanceReportingCard extends StatelessWidget {
  const _GovernanceReportingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Governance & reporting', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), backgroundColor: const Color(0xFFF3F4F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                  child: const Text('Portfolio-wide settings', style: TextStyle(fontSize: 12, color: Color(0xFF374151))),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Confirm which approvals, risk registers, and reports will play in-sync across the portfolio.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
          ),
          const SizedBox(height: 16),
          const _GovernanceItem(title: 'Gate approvals', description: 'Use the same approval path for all included projects and stages.', trailing: 'Applies to entire portfolio', isEnabled: true),
          const _GovernanceItem(title: 'Shared risk register', description: 'Surface portfolio-level risks across all work in this roll-up.', trailing: 'Applies to entire portfolio', isEnabled: true),
          const _GovernanceItem(title: 'Common change control', description: 'Route change requests through a single portfolio change board.', trailing: 'Program-specific', isEnabled: false),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Reporting cadence', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF))),
          ),
          const _GovernanceItem(title: 'Executive portfolio summary', description: 'Costs, schedule, risk, and key decisions rolled up.', trailing: 'Weekly', isEnabled: true),
          const _GovernanceItem(title: 'Benefits realization tracker', description: 'Tracks realized vs. planned benefits across all programs.', trailing: 'Monthly', isEnabled: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GovernanceItem extends StatelessWidget {
  const _GovernanceItem({required this.title, required this.description, required this.trailing, required this.isEnabled});
  final String title, description, trailing;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isEnabled ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isEnabled ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
            child: Text(trailing, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }
}

class _CostScheduleRiskSection extends StatelessWidget {
  const _CostScheduleRiskSection({required this.metrics});

  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cost, schedule & risk snapshot', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Preview how this roll-up will appear to executives in the live portfolio view, with cost, schedule, and risk broken down by program.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280))),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 800;
              if (isNarrow) {
                return Column(
                  children: [
                    _PortfolioValueCard(metrics: metrics),
                    const SizedBox(height: 16),
                    _AggregateScheduleCard(metrics: metrics),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _PortfolioValueCard(metrics: metrics)),
                  const SizedBox(width: 24),
                  Expanded(child: _AggregateScheduleCard(metrics: metrics)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _RiskPostureSection(metrics: metrics),
          const SizedBox(height: 24),
          _ProjectCostComparison(metrics: metrics),
        ],
      ),
    );
  }
}

class _PortfolioValueCard extends StatelessWidget {
  const _PortfolioValueCard({required this.metrics});

  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final breakdowns = metrics.valueBreakdowns;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total portfolio value', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text(metrics.formattedTotalValue, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('${metrics.projectCount} projects in scope', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          if (breakdowns.isEmpty)
            const Text('No value breakdowns yet.', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))
          else
            Row(
              children: [
                for (int i = 0; i < breakdowns.length; i++) ...[
                  _ValueBreakdown(label: breakdowns[i].label, value: breakdowns[i].value, color: breakdowns[i].color),
                  if (i != breakdowns.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ValueBreakdown extends StatelessWidget {
  const _ValueBreakdown({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      ],
    );
  }
}

class _AggregateScheduleCard extends StatelessWidget {
  const _AggregateScheduleCard({required this.metrics});

  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final rollups = metrics.programRollups;
    final averageLabel = _formatPercent(metrics.averageProgress);
    final earliestLabel = _formatShortDate(metrics.earliestStartAt);
    final latestLabel = _formatShortDate(metrics.lastUpdatedAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aggregate progress', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text(averageLabel, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('${metrics.projectCount} projects in scope', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          const Text('Progress by program', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          if (rollups.isEmpty)
            const Text('No programs yet.', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)))
          else ...[
            for (int i = 0; i < rollups.length; i++) ...[
              _ScheduleBar(label: rollups[i].name, detail: rollups[i].progressLabel, progress: rollups[i].averageProgress, color: rollups[i].priorityColor),
              if (i != rollups.length - 1) const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 12),
          Text('Earliest start: $earliestLabel · Latest update: $latestLabel', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _ScheduleBar extends StatelessWidget {
  const _ScheduleBar({required this.label, required this.detail, required this.progress, required this.color});
  final String label;
  final String detail;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF374151)), overflow: TextOverflow.ellipsis)),
            Text(detail, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
          ),
        ),
      ],
    );
  }
}

class _RiskPostureSection extends StatelessWidget {
  const _RiskPostureSection({required this.metrics});

  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final tags = metrics.riskTags.isEmpty
        ? [
            _RiskTagData(label: 'No risk tags yet', severity: _RiskSeverity.low),
          ]
        : metrics.riskTags;

    final buckets = metrics.riskBuckets.isEmpty
        ? [
            _RiskBucketData(label: 'Coverage', high: 0, medium: 0),
          ]
        : metrics.riskBuckets;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Risk posture', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const SizedBox(height: 8),
              Text(
                metrics.riskPostureLabel,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: metrics.riskPostureColor),
              ),
              const SizedBox(height: 4),
              Text(
                '${metrics.highRiskCount} high risks · ${metrics.mediumRiskCount} medium · ${metrics.lowRiskCount} low',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) => _RiskTag(label: tag.label, severity: tag.severity)).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                metrics.projects.isEmpty ? 'No projects in scope yet' : 'Based on ${metrics.projects.length} projects',
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < buckets.length; i++) ...[
              Text(buckets[i].label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Row(
                children: [
                  _RiskLevel(level: '${buckets[i].high} high', color: buckets[i].high > 0 ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  _RiskLevel(level: '${buckets[i].medium} medium', color: buckets[i].medium > 0 ? const Color(0xFFF59E0B) : const Color(0xFF9CA3AF)),
                ],
              ),
              if (i != buckets.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ],
    );
  }
}

class _RiskTag extends StatelessWidget {
  const _RiskTag({required this.label, required this.severity});
  final String label;
  final _RiskSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

class _RiskLevel extends StatelessWidget {
  const _RiskLevel({required this.level, required this.color});
  final String level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(level, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

class _ProjectCostComparison extends StatelessWidget {
  const _ProjectCostComparison({required this.metrics});

  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final items = metrics.costBars;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Project cost comparison', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Text('No projects available yet.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _CostBar(
                    label: items[i].label,
                    value: items[i].formattedValue,
                    height: items[i].height,
                    color: items[i].color,
                  ),
                  if (i != items.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

enum _RiskSeverity { high, medium, low }

Color _riskColor(_RiskSeverity severity) {
  switch (severity) {
    case _RiskSeverity.high:
      return const Color(0xFFEF4444);
    case _RiskSeverity.medium:
      return const Color(0xFFF59E0B);
    case _RiskSeverity.low:
      return const Color(0xFF10B981);
  }
}

class _RiskTagData {
  const _RiskTagData({required this.label, required this.severity});
  final String label;
  final _RiskSeverity severity;
}

class _RiskBucketData {
  const _RiskBucketData({required this.label, required this.high, required this.medium});
  final String label;
  final int high;
  final int medium;
}

class _CostBarData {
  const _CostBarData({required this.label, required this.formattedValue, required this.height, required this.color});
  final String label;
  final String formattedValue;
  final double height;
  final Color color;
}

class _ValueBreakdownData {
  const _ValueBreakdownData({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
}

class _ProgramRollupData {
  const _ProgramRollupData({
    required this.id,
    required this.name,
    required this.description,
    required this.projectScopeLabel,
    required this.totalValue,
    required this.formattedValue,
    required this.averageProgress,
    required this.progressLabel,
    required this.priorityLabel,
    required this.priorityColor,
  });

  final String id;
  final String name;
  final String description;
  final String projectScopeLabel;
  final double totalValue;
  final String formattedValue;
  final double averageProgress;
  final String progressLabel;
  final String priorityLabel;
  final Color priorityColor;

  _ProgramRollupData copyWith({
    String? priorityLabel,
    Color? priorityColor,
  }) {
    return _ProgramRollupData(
      id: id,
      name: name,
      description: description,
      projectScopeLabel: projectScopeLabel,
      totalValue: totalValue,
      formattedValue: formattedValue,
      averageProgress: averageProgress,
      progressLabel: progressLabel,
      priorityLabel: priorityLabel ?? this.priorityLabel,
      priorityColor: priorityColor ?? this.priorityColor,
    );
  }
}

class _PortfolioMetrics {
  _PortfolioMetrics({
    required this.projects,
    required this.projectCount,
    required this.programCount,
    required this.inProgramProjectCount,
    required this.independentProjectCount,
    required this.totalValue,
    required this.formattedTotalValue,
    required this.highRiskCount,
    required this.mediumRiskCount,
    required this.lowRiskCount,
    required this.riskPostureLabel,
    required this.riskPostureColor,
    required this.riskTags,
    required this.riskBuckets,
    required this.costBars,
    required this.programRollups,
    required this.independentProjects,
    required this.valueBreakdowns,
    required this.averageProgress,
    required this.earliestStartAt,
    required this.lastUpdatedAt,
  });

  final List<ProjectRecord> projects;
  final int projectCount;
  final int programCount;
  final int inProgramProjectCount;
  final int independentProjectCount;
  final double totalValue;
  final String formattedTotalValue;
  final int highRiskCount;
  final int mediumRiskCount;
  final int lowRiskCount;
  final String riskPostureLabel;
  final Color riskPostureColor;
  final List<_RiskTagData> riskTags;
  final List<_RiskBucketData> riskBuckets;
  final List<_CostBarData> costBars;
  final List<_ProgramRollupData> programRollups;
  final List<ProjectRecord> independentProjects;
  final List<_ValueBreakdownData> valueBreakdowns;
  final double averageProgress;
  final DateTime? earliestStartAt;
  final DateTime? lastUpdatedAt;

  static _PortfolioMetrics fromData({
    required List<ProjectRecord> projects,
    required List<ProgramModel> programs,
  }) {
    final totalValue = projects.fold<double>(0, (sum, project) => sum + project.investmentMillions);
    final formattedTotalValue = _formatMillions(totalValue);

    final projectById = {for (final project in projects) project.id: project};
    final allProgramProjectIds = <String>{};
    final rollups = <_ProgramRollupData>[];

    for (final program in programs) {
      final name = program.name.trim().isEmpty ? 'Untitled program' : program.name.trim();
      final projectIds = program.projectIds;
      allProgramProjectIds.addAll(projectIds);
      final programProjects = projectIds.map((id) => projectById[id]).whereType<ProjectRecord>().toList();
      final inScopeCount = programProjects.length;
      final totalCount = projectIds.length;
      final programValue = programProjects.fold<double>(0, (sum, project) => sum + project.investmentMillions);
      final double averageProgress = programProjects.isEmpty
          ? 0.0
          : programProjects.fold<double>(0.0, (sum, project) => sum + project.progress) / programProjects.length;
      final scopeLabel = totalCount == 0 ? 'No projects yet' : '$inScopeCount of $totalCount projects';
      final description = programProjects.isEmpty
          ? 'No projects assigned yet.'
          : 'Avg progress ${_formatPercent(averageProgress)} · $inScopeCount ${inScopeCount == 1 ? 'project' : 'projects'}';

      rollups.add(_ProgramRollupData(
        id: program.id,
        name: name,
        description: description,
        projectScopeLabel: scopeLabel,
        totalValue: programValue,
        formattedValue: _formatMillions(programValue),
        averageProgress: averageProgress,
        progressLabel: programProjects.isEmpty ? '—' : '${_formatPercent(averageProgress)} avg',
        priorityLabel: 'Rank —',
        priorityColor: const Color(0xFF6B7280),
      ));
    }

    if (rollups.isNotEmpty) {
      final sortedByValue = [...rollups]..sort((a, b) => b.totalValue.compareTo(a.totalValue));
      for (int i = 0; i < sortedByValue.length; i++) {
        final rank = i + 1;
        final index = rollups.indexWhere((rollup) => rollup.id == sortedByValue[i].id);
        if (index == -1) continue;
        rollups[index] = rollups[index].copyWith(
          priorityLabel: 'Rank $rank · ${_priorityDescriptor(rank)}',
          priorityColor: _priorityColor(rank),
        );
      }
      rollups.sort((a, b) => b.totalValue.compareTo(a.totalValue));
    }

    final independentProjects = projects.where((project) => !allProgramProjectIds.contains(project.id)).toList(growable: false);
    final inProgramProjectCount = projects.where((project) => allProgramProjectIds.contains(project.id)).length;
    final independentProjectCount = independentProjects.length;

    final double averageProgress = projects.isEmpty
        ? 0.0
        : projects.fold<double>(0.0, (sum, project) => sum + project.progress) / projects.length;

    DateTime? earliestStartAt;
    DateTime? lastUpdatedAt;
    for (final project in projects) {
      if (project.createdAt.millisecondsSinceEpoch > 0) {
        if (earliestStartAt == null || project.createdAt.isBefore(earliestStartAt)) {
          earliestStartAt = project.createdAt;
        }
      }
      if (project.updatedAt.millisecondsSinceEpoch > 0) {
        if (lastUpdatedAt == null || project.updatedAt.isAfter(lastUpdatedAt)) {
          lastUpdatedAt = project.updatedAt;
        }
      }
    }

    int high = 0;
    int medium = 0;
    int low = 0;

    for (final project in projects) {
      switch (_riskSeverityForProject(project)) {
        case _RiskSeverity.high:
          high++;
          break;
        case _RiskSeverity.medium:
          medium++;
          break;
        case _RiskSeverity.low:
          low++;
          break;
      }
    }

    final riskPosture = projects.isEmpty
        ? const _RiskPosture(label: 'No data', color: Color(0xFF9CA3AF))
        : _overallRiskPosture(high: high, medium: medium, low: low);

    final tagStats = <String, List<_RiskSeverity>>{};
    for (final project in projects) {
      final severity = _riskSeverityForProject(project);
      final tags = project.tags.isNotEmpty ? project.tags : [project.status];
      for (final rawTag in tags) {
        final tag = rawTag.trim();
        if (tag.isEmpty) continue;
        tagStats.putIfAbsent(tag, () => []).add(severity);
      }
    }

    final sortedTags = tagStats.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final riskTags = sortedTags.take(6).map((entry) {
      final severity = _dominantSeverity(entry.value);
      return _RiskTagData(label: entry.key, severity: severity);
    }).toList(growable: false);

    final riskBuckets = sortedTags.take(3).map((entry) {
      final highs = entry.value.where((s) => s == _RiskSeverity.high).length;
      final mediums = entry.value.where((s) => s == _RiskSeverity.medium).length;
      return _RiskBucketData(label: entry.key, high: highs, medium: mediums);
    }).toList(growable: false);

    final costBars = _buildCostBars(projects);
    final valueBreakdowns = _buildValueBreakdowns(projects);

    return _PortfolioMetrics(
      projects: projects,
      projectCount: projects.length,
      programCount: programs.length,
      inProgramProjectCount: inProgramProjectCount,
      independentProjectCount: independentProjectCount,
      totalValue: totalValue,
      formattedTotalValue: formattedTotalValue,
      highRiskCount: high,
      mediumRiskCount: medium,
      lowRiskCount: low,
      riskPostureLabel: riskPosture.label,
      riskPostureColor: riskPosture.color,
      riskTags: riskTags,
      riskBuckets: riskBuckets,
      costBars: costBars,
      programRollups: rollups,
      independentProjects: independentProjects,
      valueBreakdowns: valueBreakdowns,
      averageProgress: averageProgress,
      earliestStartAt: earliestStartAt,
      lastUpdatedAt: lastUpdatedAt,
    );
  }
}

class _RiskPosture {
  const _RiskPosture({required this.label, required this.color});
  final String label;
  final Color color;
}

_RiskPosture _overallRiskPosture({required int high, required int medium, required int low}) {
  if (high >= medium && high >= low) {
    return const _RiskPosture(label: 'High', color: Color(0xFFEF4444));
  }
  if (medium >= low) {
    return const _RiskPosture(label: 'Medium', color: Color(0xFFF59E0B));
  }
  return const _RiskPosture(label: 'Low', color: Color(0xFF10B981));
}

_RiskSeverity _riskSeverityForProject(ProjectRecord project) {
  if (project.progress < 0.34) return _RiskSeverity.high;
  if (project.progress < 0.67) return _RiskSeverity.medium;
  return _RiskSeverity.low;
}

_RiskSeverity _dominantSeverity(List<_RiskSeverity> severities) {
  final high = severities.where((s) => s == _RiskSeverity.high).length;
  final medium = severities.where((s) => s == _RiskSeverity.medium).length;
  final low = severities.where((s) => s == _RiskSeverity.low).length;
  if (high >= medium && high >= low) return _RiskSeverity.high;
  if (medium >= low) return _RiskSeverity.medium;
  return _RiskSeverity.low;
}

List<_CostBarData> _buildCostBars(List<ProjectRecord> projects) {
  if (projects.isEmpty) return const [];

  final sorted = [...projects]..sort((a, b) => b.investmentMillions.compareTo(a.investmentMillions));
  final top = sorted.take(8).toList(growable: false);
  final maxValue = top.fold<double>(0, (max, project) => project.investmentMillions > max ? project.investmentMillions : max);

  return top.map((project) {
    final value = project.investmentMillions;
    final height = _scaleHeight(value, maxValue);
    final label = _shortenLabel(project.name.isEmpty ? 'Untitled project' : project.name);
    final color = _statusColor(project.status);
    return _CostBarData(
      label: label,
      formattedValue: _formatMillions(value),
      height: height,
      color: color,
    );
  }).toList(growable: false);
}

double _scaleHeight(double value, double maxValue) {
  const minHeight = 40.0;
  const range = 90.0;
  if (maxValue <= 0) return minHeight;
  return minHeight + (value / maxValue) * range;
}

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('execution') || normalized.contains('progress')) {
    return const Color(0xFF10B981);
  }
  if (normalized.contains('planning')) {
    return const Color(0xFF3B82F6);
  }
  return const Color(0xFFF59E0B);
}

String _formatMillions(double value) {
  final rounded = value.toStringAsFixed(1);
  return '\$${rounded}M';
}

String _shortenLabel(String label) {
  final trimmed = label.trim();
  if (trimmed.length <= 12) {
    return trimmed;
  }
  final words = trimmed.split(RegExp(r'\s+'));
  if (words.length >= 2) {
    return '${words[0]}\n${words[1]}';
  }
  return '${trimmed.substring(0, 10)}…';
}

String _formatPercent(double value) {
  final percent = (value * 100).round().clamp(0, 100);
  return '$percent%';
}

String _priorityDescriptor(int rank) {
  switch (rank) {
    case 1:
      return 'Primary';
    case 2:
      return 'Growth';
    case 3:
      return 'Enablement';
    default:
      return 'Supporting';
  }
}

Color _priorityColor(int rank) {
  switch (rank) {
    case 1:
      return const Color(0xFF10B981);
    case 2:
      return const Color(0xFF3B82F6);
    case 3:
      return const Color(0xFF8B5CF6);
    default:
      return const Color(0xFF64748B);
  }
}

List<_ValueBreakdownData> _buildValueBreakdowns(List<ProjectRecord> projects) {
  if (projects.isEmpty) return const [];
  final totals = <String, double>{};
  for (final project in projects) {
    final status = project.status.trim().isEmpty ? 'Unspecified' : project.status.trim();
    totals[status] = (totals[status] ?? 0) + project.investmentMillions;
  }
  final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return sorted.take(3).map((entry) {
    return _ValueBreakdownData(
      label: entry.key,
      value: _formatMillions(entry.value),
      color: _statusColor(entry.key),
    );
  }).toList(growable: false);
}

String _formatShortDate(DateTime? date) {
  if (date == null) return '—';
  return DateFormat('MMM d').format(date);
}

String _scopeSummary(_PortfolioMetrics metrics) {
  if (metrics.projectCount == 0) {
    return 'No projects in scope yet';
  }
  if (metrics.programCount == 0 && metrics.independentProjectCount > 0) {
    return '${metrics.independentProjectCount} standalone project${metrics.independentProjectCount == 1 ? '' : 's'}';
  }
  final programLabel = '${metrics.programCount} ${metrics.programCount == 1 ? 'program' : 'programs'}';
  final programProjectLabel = '${metrics.inProgramProjectCount} program project${metrics.inProgramProjectCount == 1 ? '' : 's'}';
  if (metrics.independentProjectCount == 0) {
    return '$programLabel · $programProjectLabel';
  }
  final independentLabel = '${metrics.independentProjectCount} standalone project${metrics.independentProjectCount == 1 ? '' : 's'}';
  return '$programLabel · $programProjectLabel + $independentLabel';
}

String _projectSubtitle(ProjectRecord project) {
  final solutionTitle = project.solutionTitle.trim();
  if (solutionTitle.isNotEmpty) return solutionTitle;
  final status = project.status.trim();
  if (status.isNotEmpty) return status;
  final notes = project.notes.trim();
  if (notes.isNotEmpty) return notes;
  return 'Independent project';
}

String _projectPhase(ProjectRecord project) {
  final milestone = project.milestone.trim();
  if (milestone.isNotEmpty) return milestone;
  final status = project.status.trim();
  if (status.isNotEmpty) return status;
  return 'Unspecified';
}

class _CostBar extends StatelessWidget {
  const _CostBar({required this.label, required this.value, required this.height, required this.color});
  final String label, value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        Container(width: 50, height: height, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 8),
        SizedBox(width: 50, child: Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)), textAlign: TextAlign.center)),
      ],
    );
  }
}

class _RollUpUpdateSection extends StatelessWidget {
  const _RollUpUpdateSection({required this.metrics});

  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final lastUpdatedLabel = metrics.lastUpdatedAt == null
        ? 'No updates yet'
        : DateFormat('MMM d, h:mm a').format(metrics.lastUpdatedAt!);
    final scopeLabel = _scopeSummary(metrics);

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This roll-up will update', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 8),
                const Text('Executive dashboards & governance reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    const Text('Latest refresh', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(lastUpdatedLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    const Text('Included scope', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(scopeLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                const SizedBox(height: 12),
                Text('Once published, this roll-up becomes the live portfolio view used in steering committees, executive dashboards, and downstream project scorecards.', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFE5E7EB)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Cancel roll-up'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Publish roll-up'),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle_outline, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
