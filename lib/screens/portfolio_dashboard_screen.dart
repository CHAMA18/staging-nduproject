import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../widgets/dashboard_stat_card.dart';
import '../widgets/kaz_ai_chat_bubble.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_router.dart';
import '../services/navigation_context_service.dart';
import '../services/project_service.dart';
import '../services/program_service.dart';
import '../services/portfolio_service.dart';
import '../models/program_model.dart';
import '../models/portfolio_model.dart';
import 'basic_plan_dashboard_screen.dart';
import 'project_dashboard_screen.dart';
import 'program_dashboard_screen.dart';

class PortfolioDashboardScreen extends StatelessWidget {
  const PortfolioDashboardScreen({super.key, this.portfolioId});

  final String? portfolioId;

  @override
  Widget build(BuildContext context) {
    NavigationContextService.instance
        .setLastClientDashboard(AppRoutes.portfolioDashboard);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Stack(
        children: [
          SafeArea(
            child: _PortfolioRollUpContent(portfolioId: portfolioId),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }
}

class _PortfolioRollUpContent extends StatefulWidget {
  const _PortfolioRollUpContent({this.portfolioId});

  final String? portfolioId;

  @override
  State<_PortfolioRollUpContent> createState() =>
      _PortfolioRollUpContentState();
}

class _PortfolioRollUpContentState extends State<_PortfolioRollUpContent> {
  final Set<String> _selectedProjectIds = {};
  _ProjectSort _singleProjectsSort = _ProjectSort.newest;
  _ProjectSort _groupProjectsSort = _ProjectSort.newest;

  void _togglePortfolioSelection(ProjectRecord project) {
    final id = project.id;
    final isSelected = _selectedProjectIds.contains(id);
    if (isSelected) {
      setState(() {
        _selectedProjectIds.remove(id);
      });
      return;
    }
    if (_selectedProjectIds.length >= 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can add up to 7 projects to a portfolio.'),
        ),
      );
      return;
    }
    setState(() {
      _selectedProjectIds.add(id);
    });
    if (_selectedProjectIds.length == 7) {
      Future<void>.microtask(_promptPortfolioName);
    }
  }

  Future<void> _promptPortfolioName() async {
    final controller = TextEditingController();
    final selectedCount = _selectedProjectIds.length;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canCreate = controller.text.trim().isNotEmpty;
            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE0F2FE), Color(0xFFF0FDF4)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFF0EA5E9)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Name this portfolio',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You are grouping $selectedCount projects into a portfolio. Give it a name your executives will recognize.',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: controller,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.text_fields_rounded,
                            size: 18),
                        hintText: 'Portfolio name',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$selectedCount selected',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: canCreate
                              ? () => Navigator.of(dialogContext)
                                  .pop(controller.text.trim())
                              : null,
                          borderRadius: BorderRadius.circular(999),
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: canCreate
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF0EA5E9),
                                        Color(0xFF22C55E)
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFE5E7EB),
                                        Color(0xFFE5E7EB)
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Create',
                              style: TextStyle(
                                  color:
                                      canCreate ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    final name = result?.trim();
    if (name == null || name.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to create a portfolio.')),
      );
      return;
    }
    final projectIds = _selectedProjectIds.toList(growable: false);
    try {
      await PortfolioService.createPortfolio(
        name: name,
        projectIds: projectIds,
        ownerId: user.uid,
      );
      if (!mounted) return;
      setState(() {
        _selectedProjectIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Portfolio "$name" created successfully.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create portfolio.')),
      );
    }
  }

  void _openProjectDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProjectDashboardScreen()),
    );
  }

  List<ProjectRecord> _sortedProjects(
      List<ProjectRecord> projects, _ProjectSort sort) {
    final sorted = [...projects];
    sorted.sort((a, b) {
      final compare = a.createdAt.compareTo(b.createdAt);
      return sort == _ProjectSort.oldest ? compare : -compare;
    });
    return sorted;
  }

  void _openBasicProjectDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BasicPlanDashboardScreen()),
    );
  }

  void _openProgramDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgramDashboardScreen()),
    );
  }

  void _openPortfolioDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PortfolioDashboardScreen()),
    );
  }

  List<DashboardStatCard> _buildPortfolioStatsCards(
      BuildContext context, _PortfolioMetrics metrics) {
    final basicProjectCount =
        metrics.projects.where((project) => project.isBasicPlanProject).length;

    return [
      DashboardStatCard(
        label: 'Basic Projects',
        value: '$basicProjectCount',
        subLabel: 'Basic plan workspaces',
        icon: Icons.folder_special_rounded,
        color: Colors.teal.shade600,
        onTap: () => _openBasicProjectDashboard(context),
      ),
      DashboardStatCard(
        label: 'Single Projects',
        value: '${metrics.projectCount}',
        subLabel: 'Active workspaces',
        icon: Icons.folder_open_rounded,
        color: Colors.blue.shade600,
        onTap: () => _openProjectDashboard(context),
      ),
      DashboardStatCard(
        label: 'Programs',
        value: '${metrics.programCount}',
        subLabel: 'Grouped projects',
        icon: Icons.layers_outlined,
        color: Colors.purple.shade600,
        onTap: () => _openProgramDashboard(context),
      ),
      DashboardStatCard(
        label: 'Portfolios',
        value: '${metrics.portfolioCount}',
        subLabel: 'Executive views',
        icon: Icons.pie_chart_outline_rounded,
        color: const Color(0xFF16A34A),
        onTap: () => _openPortfolioDashboard(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final projectStream = user == null
        ? Stream.value(const <ProjectRecord>[])
        : ProjectService.streamProjects(ownerId: user.uid);
    final programStream = user == null
        ? Stream.value(const <ProgramModel>[])
        : ProgramService.streamPrograms(ownerId: user.uid);
    final portfolioStream = user == null
        ? Stream.value(const <PortfolioModel>[])
        : PortfolioService.streamPortfolios(ownerId: user.uid);

    return StreamBuilder<List<ProjectRecord>>(
      stream: projectStream,
      builder: (context, snapshot) {
        final projects = snapshot.data ?? const <ProjectRecord>[];
        return StreamBuilder<List<ProgramModel>>(
          stream: programStream,
          builder: (context, programSnapshot) {
            final programs = programSnapshot.data ?? const <ProgramModel>[];
            return StreamBuilder<List<PortfolioModel>>(
              stream: portfolioStream,
              builder: (context, portfolioSnapshot) {
                final portfolios =
                    portfolioSnapshot.data ?? const <PortfolioModel>[];
                final metrics = _PortfolioMetrics.fromData(
                  projects: projects,
                  programs: programs,
                  portfolios: portfolios,
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 1000;
                    final statsIsStacked = constraints.maxWidth < 920;
                    final statCards =
                        _buildPortfolioStatsCards(context, metrics);
                    final independentProjects = metrics.independentProjects;
                    final singleSource = independentProjects.isEmpty
                        ? metrics.projects
                        : independentProjects;
                    final sortedSingles =
                        _sortedProjects(singleSource, _singleProjectsSort)
                            .take(10)
                            .toList(growable: false);
                    final groupSource = independentProjects.isEmpty
                        ? metrics.projects
                        : independentProjects;
                    final sortedGroups =
                        _sortedProjects(groupSource, _groupProjectsSort)
                            .take(10)
                            .toList(growable: false);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderSection(metrics: metrics),
                          const SizedBox(height: 24),
                          DashboardStatLayout(
                            cards: statCards,
                            isStacked: statsIsStacked,
                            horizontalSpacing: 20,
                            verticalSpacing: 16,
                          ),
                          const SizedBox(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (isNarrow) ...[
                                _SingleProjectsCard(
                                  projects: sortedSingles,
                                  sort: _singleProjectsSort,
                                  onSortChanged: (sort) => setState(
                                      () => _singleProjectsSort = sort),
                                  onSeeAll: () =>
                                      _openProjectDashboard(context),
                                ),
                                const SizedBox(height: 24),
                                _GroupProjectsIntoPortfolioCard(
                                  projects: sortedGroups,
                                  sort: _groupProjectsSort,
                                  onSortChanged: (sort) => setState(
                                      () => _groupProjectsSort = sort),
                                  onSeeAll: () =>
                                      _openProjectDashboard(context),
                                  selectedProjectIds: _selectedProjectIds,
                                  onToggle: _togglePortfolioSelection,
                                ),
                              ] else ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _SingleProjectsCard(
                                        projects: sortedSingles,
                                        sort: _singleProjectsSort,
                                        onSortChanged: (sort) => setState(
                                            () => _singleProjectsSort = sort),
                                        onSeeAll: () =>
                                            _openProjectDashboard(context),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _GroupProjectsIntoPortfolioCard(
                                        projects: sortedGroups,
                                        sort: _groupProjectsSort,
                                        onSortChanged: (sort) => setState(
                                            () => _groupProjectsSort = sort),
                                        onSeeAll: () =>
                                            _openProjectDashboard(context),
                                        selectedProjectIds: _selectedProjectIds,
                                        onToggle: _togglePortfolioSelection,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 24),
                              _ProgramsProjectsCard(metrics: metrics),
                              const SizedBox(height: 24),
                              const _GovernanceReportingCard(),
                              const SizedBox(height: 24),
                              _IndependentProjectsCard(metrics: metrics),
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
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.metrics});

  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final programLabel =
        '${metrics.programCount} ${metrics.programCount == 1 ? 'program' : 'programs'}';
    final projectLabel =
        '${metrics.projectCount} ${metrics.projectCount == 1 ? 'project' : 'projects'} included';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(52),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 20),
                          blurRadius: 36,
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/Logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFE4A0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  size: 14, color: Colors.amber.shade700),
                              const SizedBox(width: 6),
                              Text('Roll-up preview',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade800)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Confirm portfolio roll-up',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1D21))),
                        const SizedBox(height: 8),
                        Text(
                          'Review which programs, projects, governance rules, and risks will be rolled up into this portfolio view before publishing it for executives and steering committees.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: const Color(0xFF6B7280), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoChip(label: programLabel, icon: Icons.layers_outlined),
                  _InfoChip(label: projectLabel, icon: Icons.folder_outlined),
                  _InfoChip(
                      label:
                          'Total portfolio value: ${metrics.formattedTotalValue}',
                      icon: Icons.attach_money),
                  _InfoChip(
                      label: 'Risk posture: ${metrics.riskPostureLabel}',
                      icon: Icons.shield_outlined),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            Text('Adjust selection of programs, projects, or independent work',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF9CA3AF))),
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
      decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500)),
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
                    Text('Programs & projects in this roll-up',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        'Verify which programs and projects will contribute cost, schedule, and risk into the rolled-up portfolio.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: const Color(0xFF6B7280))),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(programScopeLabel,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2563EB))),
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF6B7280)),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFFF9FAFB),
              child: const Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text('Program',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280)))),
                  Expanded(
                      flex: 2,
                      child: Text('Projects in scope',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280)))),
                  Expanded(
                      flex: 1,
                      child: Text('Value',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280)))),
                  Expanded(
                      flex: 1,
                      child: Text('Priority',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280)))),
                ],
              ),
            ),
            for (final rollup in rollups)
              _ProgramRow(
                programId: rollup.id,
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
    required this.programId,
    required this.title,
    required this.description,
    required this.projectScopeLabel,
    required this.value,
    required this.priority,
    required this.priorityColor,
  });

  final String programId;
  final String title;
  final String description;
  final String projectScopeLabel;
  final String value;
  final String priority;
  final Color priorityColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.go('/${AppRoutes.programDashboard}?programId=$programId');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(projectScopeLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF92400E))),
              ),
            ),
            Expanded(
                flex: 1,
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)))),
            Expanded(
                flex: 1,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(priority,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: priorityColor)))),
          ],
        ),
      ),
    );
  }
}

enum _ProjectSort { newest, oldest }

class _SingleProjectsCard extends StatelessWidget {
  const _SingleProjectsCard({
    required this.projects,
    required this.sort,
    required this.onSortChanged,
    required this.onSeeAll,
  });

  final List<ProjectRecord> projects;
  final _ProjectSort sort;
  final ValueChanged<_ProjectSort> onSortChanged;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Single Projects',
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'Review all standalone projects before they are linked into programs or portfolios.',
                      style: textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: const Color(0xFFFCE7F3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDB2777)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_work_outlined,
                        size: 16, color: Color(0xFF6B7280)),
                    SizedBox(width: 6),
                    Text('If more than 3 projects, group up to 7 into a portfolio',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              _SortDropdown(
                value: sort,
                onChanged: onSortChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText: 'Search projects...',
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  color: const Color(0xFFF9FAFB),
                  child: const Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Text('Project',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280))),
                          )),
                      Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Text('Stage',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280))),
                          )),
                      Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Text('Owner',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280))),
                          )),
                      Expanded(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('Investment',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280))),
                          )),
                    ],
                  ),
                ),
                if (projects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      'No standalone projects yet.',
                      style: textTheme.bodySmall
                          ?.copyWith(color: const Color(0xFF9CA3AF)),
                    ),
                  )
                else
                  for (int i = 0; i < projects.length; i++) ...[
                    _SingleProjectRow(project: projects[i]),
                    if (i != projects.length - 1)
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleProjectRow extends StatelessWidget {
  const _SingleProjectRow({required this.project});

  final ProjectRecord project;

  @override
  Widget build(BuildContext context) {
    final name = project.name.trim().isEmpty ? 'Untitled Project' : project.name;
    final owner =
        project.ownerName.trim().isEmpty ? 'Unassigned' : project.ownerName;
    final stage = _projectPhase(project);
    final investment = project.investmentMillions <= 0
        ? 'Not set'
        : _formatMillions(project.investmentMillions);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D4ED8)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                stage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D28D9)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12),
              child: Text(
                owner,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF111827)),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                investment,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF111827)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupProjectsIntoPortfolioCard extends StatelessWidget {
  const _GroupProjectsIntoPortfolioCard({
    required this.projects,
    required this.sort,
    required this.onSortChanged,
    required this.onSeeAll,
    required this.selectedProjectIds,
    required this.onToggle,
  });

  final List<ProjectRecord> projects;
  final _ProjectSort sort;
  final ValueChanged<_ProjectSort> onSortChanged;
  final VoidCallback onSeeAll;
  final Set<String> selectedProjectIds;
  final ValueChanged<ProjectRecord> onToggle;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 900;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Projects Into A Portfolio',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select up to seven projects that share an outcome to create a new portfolio.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: const Color(0xFFFCE7F3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDB2777)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.filter_list, size: 16, color: Color(0xFF6B7280)),
                    SizedBox(width: 6),
                    Text('Up to 7 projects',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              _SortDropdown(
                value: sort,
                onChanged: onSortChanged,
              ),
              SizedBox(
                width: isNarrow ? double.infinity : 320,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Search projects to group...',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (projects.isEmpty)
            Text(
              'No available projects to group right now.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF9CA3AF)),
            )
          else
            Column(
              children: [
                for (int i = 0; i < projects.length; i++) ...[
                  _GroupProjectRow(
                    title: projects[i].name.isEmpty
                        ? 'Untitled Project'
                        : projects[i].name,
                    subtitle: _projectPhase(projects[i]),
                    isSelected: selectedProjectIds
                        .contains(projects[i].id),
                    onToggle: () => onToggle(projects[i]),
                  ),
                  if (i != projects.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _GroupProjectRow extends StatelessWidget {
  const _GroupProjectRow({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onToggle,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isSelected
                ? const Color(0xFF93C5FD)
                : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF9CA3AF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onToggle,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999)),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Text(
              isSelected ? 'Included' : 'Tap to include',
              style: const TextStyle(fontSize: 11, color: Color(0xFF374151))),
          ),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.value, required this.onChanged});

  final _ProjectSort value;
  final ValueChanged<_ProjectSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_ProjectSort>(
          value: value,
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
          items: const [
            DropdownMenuItem(
              value: _ProjectSort.newest,
              child: Text('Newest'),
            ),
            DropdownMenuItem(
              value: _ProjectSort.oldest,
              child: Text('Oldest'),
            ),
          ],
        ),
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
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Independent projects in roll-up',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(chipLabel,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
              'Decide which independent projects should be reflected in this portfolio\'s value and reporting.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF6B7280))),
          const SizedBox(height: 16),
          if (previewProjects.isEmpty)
            Text(
              'All projects are grouped into programs right now.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF6B7280)),
            )
          else ...[
            for (int i = 0; i < previewProjects.length; i++) ...[
              _IndependentProjectRow(
                title: previewProjects[i].name.isEmpty
                    ? 'Untitled project'
                    : previewProjects[i].name,
                subtitle: _projectSubtitle(previewProjects[i]),
                phase: _projectPhase(previewProjects[i]),
              ),
              if (i != previewProjects.length - 1) const SizedBox(height: 12),
            ],
            if (independentProjects.length > previewProjects.length) ...[
              const SizedBox(height: 12),
              Text(
                '+${independentProjects.length - previewProjects.length} more independent project${independentProjects.length - previewProjects.length == 1 ? '' : 's'}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF9CA3AF)),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Use the related/unrelated flag to control which independent work influences portfolio value and dashboards.',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500))),
            ],
          ),
        ],
      ),
    );
  }
}

class _IndependentProjectRow extends StatelessWidget {
  const _IndependentProjectRow(
      {required this.title, required this.subtitle, required this.phase});
  final String title;
  final String subtitle;
  final String phase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFDDD6FE),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(phase,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7C3AED)))),
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
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Governance & reporting',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      backgroundColor: const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6))),
                  child: const Text('Portfolio-wide settings',
                      style: TextStyle(fontSize: 12, color: Color(0xFF374151))),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
                'Confirm which approvals, risk registers, and reports will play in-sync across the portfolio.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: const Color(0xFF6B7280))),
          ),
          const SizedBox(height: 16),
          const _GovernanceItem(
              title: 'Gate approvals',
              description:
                  'Use the same approval path for all included projects and stages.',
              trailing: 'Applies to entire portfolio',
              isEnabled: true),
          const _GovernanceItem(
              title: 'Shared risk register',
              description:
                  'Surface portfolio-level risks across all work in this roll-up.',
              trailing: 'Applies to entire portfolio',
              isEnabled: true),
          const _GovernanceItem(
              title: 'Common change control',
              description:
                  'Route change requests through a single portfolio change board.',
              trailing: 'Program-specific',
              isEnabled: false),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('Reporting cadence',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF))),
          ),
          const _GovernanceItem(
              title: 'Executive portfolio summary',
              description:
                  'Costs, schedule, risk, and key decisions rolled up.',
              trailing: 'Weekly',
              isEnabled: true),
          const _GovernanceItem(
              title: 'Benefits realization tracker',
              description:
                  'Tracks realized vs. planned benefits across all programs.',
              trailing: 'Monthly',
              isEnabled: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GovernanceItem extends StatelessWidget {
  const _GovernanceItem(
      {required this.title,
      required this.description,
      required this.trailing,
      required this.isEnabled});
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
              color:
                  isEnabled ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: isEnabled
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4)),
            child: Text(trailing,
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
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
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cost, schedule & risk snapshot',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              'Preview how this roll-up will appear to executives in the live portfolio view, with cost, schedule, and risk broken down by program.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: const Color(0xFF6B7280))),
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
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total portfolio value',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text(metrics.formattedTotalValue,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('${metrics.projectCount} projects in scope',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          if (breakdowns.isEmpty)
            const Text('No value breakdowns yet.',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)))
          else
            Row(
              children: [
                for (int i = 0; i < breakdowns.length; i++) ...[
                  _ValueBreakdown(
                      label: breakdowns[i].label,
                      value: breakdowns[i].value,
                      color: breakdowns[i].color),
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
  const _ValueBreakdown(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        Text(value,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827))),
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
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aggregate progress',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 8),
          Text(averageLabel,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 4),
          Text('${metrics.projectCount} projects in scope',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          const Text('Progress by program',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 12),
          if (rollups.isEmpty)
            const Text('No programs yet.',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)))
          else ...[
            for (int i = 0; i < rollups.length; i++) ...[
              _ScheduleBar(
                  label: rollups[i].name,
                  detail: rollups[i].progressLabel,
                  progress: rollups[i].averageProgress,
                  color: rollups[i].priorityColor),
              if (i != rollups.length - 1) const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 12),
          Text('Earliest start: $earliestLabel · Latest update: $latestLabel',
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

class _ScheduleBar extends StatelessWidget {
  const _ScheduleBar(
      {required this.label,
      required this.detail,
      required this.progress,
      required this.color});
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
            Flexible(
                child: Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF374151)),
                    overflow: TextOverflow.ellipsis)),
            Text(detail,
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(3))),
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
            _RiskTagData(
                label: 'No risk tags yet', severity: _RiskSeverity.low),
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
              const Text('Risk posture',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827))),
              const SizedBox(height: 8),
              Text(
                metrics.riskPostureLabel,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: metrics.riskPostureColor),
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
                children: tags
                    .map((tag) =>
                        _RiskTag(label: tag.label, severity: tag.severity))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                metrics.projects.isEmpty
                    ? 'No projects in scope yet'
                    : 'Based on ${metrics.projects.length} projects',
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
              Text(buckets[i].label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Row(
                children: [
                  _RiskLevel(
                      level: '${buckets[i].high} high',
                      color: buckets[i].high > 0
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  _RiskLevel(
                      level: '${buckets[i].medium} medium',
                      color: buckets[i].medium > 0
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF9CA3AF)),
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
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: color)),
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
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(level,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w500, color: color)),
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
        const Text('Project cost comparison',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827))),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Text('No projects available yet.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final double spacing = 12.0;
              final int count = math.max(1, items.length);
              final double totalSpacing = (count - 1) * spacing;
              final double usableWidth =
                  math.max(0, constraints.maxWidth - totalSpacing);
              final double candidateWidth = usableWidth / count;
              final double barWidth = math.max(110, candidateWidth).toDouble();
              return Row(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    SizedBox(
                      width: barWidth,
                      child: _CostBar(
                        label: items[i].label,
                        value: items[i].formattedValue,
                        height: items[i].height,
                        color: items[i].color,
                      ),
                    ),
                    if (i != items.length - 1) SizedBox(width: spacing),
                  ],
                ],
              );
            },
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
  const _RiskBucketData(
      {required this.label, required this.high, required this.medium});
  final String label;
  final int high;
  final int medium;
}

class _CostBarData {
  const _CostBarData(
      {required this.label,
      required this.formattedValue,
      required this.height,
      required this.color});
  final String label;
  final String formattedValue;
  final double height;
  final Color color;
}

class _ValueBreakdownData {
  const _ValueBreakdownData(
      {required this.label, required this.value, required this.color});
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
    required this.portfolioCount,
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
  final int portfolioCount;
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
    required List<PortfolioModel> portfolios,
  }) {
    final totalValue = projects.fold<double>(
        0, (sum, project) => sum + project.investmentMillions);
    final formattedTotalValue = _formatMillions(totalValue);

    final projectById = {for (final project in projects) project.id: project};
    final allProgramProjectIds = <String>{};
    final rollups = <_ProgramRollupData>[];

    for (final program in programs) {
      final name = program.name.trim().isEmpty
          ? 'Untitled program'
          : program.name.trim();
      final projectIds = program.projectIds;
      allProgramProjectIds.addAll(projectIds);
      final programProjects = projectIds
          .map((id) => projectById[id])
          .whereType<ProjectRecord>()
          .toList();
      final inScopeCount = programProjects.length;
      final totalCount = projectIds.length;
      final programValue = programProjects.fold<double>(
          0, (sum, project) => sum + project.investmentMillions);
      final double averageProgress = programProjects.isEmpty
          ? 0.0
          : programProjects.fold<double>(
                  0.0, (sum, project) => sum + project.progress) /
              programProjects.length;
      final scopeLabel = totalCount == 0
          ? 'No projects yet'
          : '$inScopeCount of $totalCount projects';
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
        progressLabel: programProjects.isEmpty
            ? '—'
            : '${_formatPercent(averageProgress)} avg',
        priorityLabel: 'Rank —',
        priorityColor: const Color(0xFF6B7280),
      ));
    }

    if (rollups.isNotEmpty) {
      final sortedByValue = [...rollups]
        ..sort((a, b) => b.totalValue.compareTo(a.totalValue));
      for (int i = 0; i < sortedByValue.length; i++) {
        final rank = i + 1;
        final index =
            rollups.indexWhere((rollup) => rollup.id == sortedByValue[i].id);
        if (index == -1) continue;
        rollups[index] = rollups[index].copyWith(
          priorityLabel: 'Rank $rank · ${_priorityDescriptor(rank)}',
          priorityColor: _priorityColor(rank),
        );
      }
      rollups.sort((a, b) => b.totalValue.compareTo(a.totalValue));
    }

    final independentProjects = projects
        .where((project) => !allProgramProjectIds.contains(project.id))
        .toList(growable: false);
    final inProgramProjectCount = projects
        .where((project) => allProgramProjectIds.contains(project.id))
        .length;
    final independentProjectCount = independentProjects.length;

    final double averageProgress = projects.isEmpty
        ? 0.0
        : projects.fold<double>(0.0, (sum, project) => sum + project.progress) /
            projects.length;

    DateTime? earliestStartAt;
    DateTime? lastUpdatedAt;
    for (final project in projects) {
      if (project.createdAt.millisecondsSinceEpoch > 0) {
        if (earliestStartAt == null ||
            project.createdAt.isBefore(earliestStartAt)) {
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
      final mediums =
          entry.value.where((s) => s == _RiskSeverity.medium).length;
      return _RiskBucketData(label: entry.key, high: highs, medium: mediums);
    }).toList(growable: false);

    final costBars = _buildCostBars(projects);
    final valueBreakdowns = _buildValueBreakdowns(projects);

    return _PortfolioMetrics(
      projects: projects,
      projectCount: projects.length,
      programCount: programs.length,
      portfolioCount: portfolios.length,
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

_RiskPosture _overallRiskPosture(
    {required int high, required int medium, required int low}) {
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

  final sorted = [...projects]
    ..sort((a, b) => b.investmentMillions.compareTo(a.investmentMillions));
  final top = sorted.take(8).toList(growable: false);
  final maxValue = top.fold<double>(
      0,
      (max, project) =>
          project.investmentMillions > max ? project.investmentMillions : max);

  return top.map((project) {
    final value = project.investmentMillions;
    final height = _scaleHeight(value, maxValue);
    final label =
        _shortenLabel(project.name.isEmpty ? 'Untitled project' : project.name);
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
    final status =
        project.status.trim().isEmpty ? 'Unspecified' : project.status.trim();
    totals[status] = (totals[status] ?? 0) + project.investmentMillions;
  }
  final sorted = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
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
  final programLabel =
      '${metrics.programCount} ${metrics.programCount == 1 ? 'program' : 'programs'}';
  final programProjectLabel =
      '${metrics.inProgramProjectCount} program project${metrics.inProgramProjectCount == 1 ? '' : 's'}';
  if (metrics.independentProjectCount == 0) {
    return '$programLabel · $programProjectLabel';
  }
  final independentLabel =
      '${metrics.independentProjectCount} standalone project${metrics.independentProjectCount == 1 ? '' : 's'}';
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
  const _CostBar(
      {required this.label,
      required this.value,
      required this.height,
      required this.color});
  final String label, value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 4),
        Container(
            width: 50,
            height: height,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 8),
        SizedBox(
            width: 50,
            child: Text(label,
                style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center)),
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
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB))),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This roll-up will update',
                    style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 8),
                const Text('Executive dashboards & governance reports',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    const Text('Latest refresh',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(lastUpdatedLabel,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    const Text('Included scope',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(scopeLabel,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827))),
                const SizedBox(height: 12),
                Text(
                    'Once published, this roll-up becomes the live portfolio view used in steering committees, executive dashboards, and downstream project scorecards.',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: const Text('Cancel roll-up'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0),
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
