import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../widgets/dashboard_bottom_nav_bar.dart';
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
import 'program_dashboard_mobile_screen.dart';

import 'package:ndu_project/widgets/voice_text_field.dart';
class PortfolioDashboardScreen extends StatelessWidget {
  const PortfolioDashboardScreen({super.key, this.portfolioId});

  final String? portfolioId;

  @override
  Widget build(BuildContext context) {
    NavigationContextService.instance
        .setLastClientDashboard(AppRoutes.portfolioDashboard);

    // ── Desktop layout (width >= 700) ──
    if (MediaQuery.sizeOf(context).width >= 700) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        body: Stack(
          children: [
            SafeArea(
              child: _PortfolioDesktopContent(portfolioId: portfolioId),
            ),
            const KazAiChatBubble(),
          ],
        ),
      );
    }

    // ── Mobile layout (width < 700) ──
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: Stack(
        children: [
          SafeArea(
            child: _PortfolioRollUpContent(portfolioId: portfolioId),
          ),
          const KazAiChatBubble(),
          // Floating Help Button
          Positioned(
            bottom: 96,
            right: 16,
            child: Material(
              color: const Color(0xFFFFC400),
              borderRadius: BorderRadius.circular(24),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.15),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(24),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: DashboardBottomNavBar(
              currentIndex: 2,
              onNavigate: (index) {
                if (index == 0) {
                  Navigator.pop(context);
                } else if (index == 1) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const ProgramDashboardMobileScreen()),
                  );
                } else if (index == 3) {
                  context.go('/${AppRoutes.settings}?from=${AppRoutes.dashboard}');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioDesktopContent extends StatefulWidget {
  const _PortfolioDesktopContent({this.portfolioId});

  final String? portfolioId;

  @override
  State<_PortfolioDesktopContent> createState() =>
      _PortfolioDesktopContentState();
}

class _PortfolioDesktopContentState extends State<_PortfolioDesktopContent> {
  final Set<String> _selectedProjectIds = {};
  _ProjectSort _singleProjectsSort = _ProjectSort.newest;
  final _ProjectSort _groupProjectsSort = _ProjectSort.newest;
  bool _gateApprovals = true;
  bool _sharedRiskRegister = true;
  bool _executiveSummary = true;

  void _openProjectDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProjectDashboardScreen()),
    );
  }

  void _openBasicProjectDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BasicPlanDashboardScreen()),
    );
  }

  void _openProgramDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgramDashboardScreen()),
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

                final independentProjects = metrics.independentProjects;
                final singleSource = independentProjects.isEmpty
                    ? metrics.projects
                    : independentProjects;
                final sortedSingles =
                    _sortedProjects(singleSource, _singleProjectsSort)
                        .take(10)
                        .toList(growable: false);

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 1180;
                    final horizontalPadding =
                        constraints.maxWidth < 900 ? 20.0 : 40.0;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Desktop Header ──
                          _DesktopHeader(metrics: metrics),
                          const SizedBox(height: 24),
                          // ── Desktop Stats ──
                          _DesktopStatsRow(
                            metrics: metrics,
                            onBasicTap: _openBasicProjectDashboard,
                            onSingleTap: _openProjectDashboard,
                            onProgramTap: _openProgramDashboard,
                            onPortfolioTap: () {},
                            isStacked: constraints.maxWidth < 920,
                          ),
                          const SizedBox(height: 28),
                          // ── Content columns ──
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    children: [
                                      _SingleProjectsSection(
                                        projects: sortedSingles,
                                        sort: _singleProjectsSort,
                                        onSortChanged: (sort) => setState(
                                            () => _singleProjectsSort = sort),
                                        onSeeAll: _openProjectDashboard,
                                      ),
                                      const SizedBox(height: 24),
                                      _ProgramRollupSection(metrics: metrics),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _GovernanceSection(
                                        gateApprovals: _gateApprovals,
                                        sharedRiskRegister: _sharedRiskRegister,
                                        executiveSummary: _executiveSummary,
                                        onGateChanged: (v) =>
                                            setState(() => _gateApprovals = v),
                                        onSharedRiskChanged: (v) => setState(
                                            () => _sharedRiskRegister = v),
                                        onExecutiveChanged: (v) => setState(
                                            () => _executiveSummary = v),
                                      ),
                                      const SizedBox(height: 24),
                                      _IndependentProjectsSection(
                                          metrics: metrics),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _SingleProjectsSection(
                                  projects: sortedSingles,
                                  sort: _singleProjectsSort,
                                  onSortChanged: (sort) => setState(
                                      () => _singleProjectsSort = sort),
                                  onSeeAll: _openProjectDashboard,
                                ),
                                const SizedBox(height: 24),
                                _ProgramRollupSection(metrics: metrics),
                                const SizedBox(height: 24),
                                _GovernanceSection(
                                  gateApprovals: _gateApprovals,
                                  sharedRiskRegister: _sharedRiskRegister,
                                  executiveSummary: _executiveSummary,
                                  onGateChanged: (v) =>
                                      setState(() => _gateApprovals = v),
                                  onSharedRiskChanged: (v) =>
                                      setState(() => _sharedRiskRegister = v),
                                  onExecutiveChanged: (v) =>
                                      setState(() => _executiveSummary = v),
                                ),
                                const SizedBox(height: 24),
                                _IndependentProjectsSection(metrics: metrics),
                              ],
                            ),
                          const SizedBox(height: 96),
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

// ═══════════════════════════════════════════════════════════
// DESKTOP HEADER
// ═══════════════════════════════════════════════════════════
class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.metrics});
  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5D7),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFE7A8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.account_tree_outlined,
                      size: 18, color: Color(0xFF8A5800)),
                  SizedBox(width: 8),
                  Text(
                    'Portfolio workspace overview',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A5800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              icon: const Icon(Icons.arrow_back, color: Color(0xFF343741)),
              label: const Text(
                'Back',
                style: TextStyle(
                    color: Color(0xFF343741), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Confirm portfolio roll-up',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0E1017),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Review which programs, projects, governance rules, and risks will be rolled up into this portfolio view.',
          style: textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF4D5060),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _HeaderChip(
              label: '${metrics.programCount} programs',
              dotColor: const Color(0xFFCBD5E1),
            ),
            _HeaderChip(
              label: '${metrics.projectCount} projects',
              dotColor: const Color(0xFFCBD5E1),
            ),
            _HeaderChip(
              label: metrics.formattedTotalValue,
              dotColor: const Color(0xFFCBD5E1),
            ),
            _HeaderChip(
              label: 'Risk: ${metrics.riskPostureLabel}',
              dotColor: metrics.riskPostureColor,
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DESKTOP STATS ROW
// ═══════════════════════════════════════════════════════════
class _DesktopStatsRow extends StatelessWidget {
  const _DesktopStatsRow({
    required this.metrics,
    required this.onBasicTap,
    required this.onSingleTap,
    required this.onProgramTap,
    required this.onPortfolioTap,
    required this.isStacked,
  });

  final _PortfolioMetrics metrics;
  final VoidCallback onBasicTap;
  final VoidCallback onSingleTap;
  final VoidCallback onProgramTap;
  final VoidCallback onPortfolioTap;
  final bool isStacked;

  @override
  Widget build(BuildContext context) {
    final basicProjectCount =
        metrics.projects.where((p) => p.isBasicPlanProject).length;

    final cards = [
      _StatCardData(
        value: '$basicProjectCount',
        label: 'Basic Projects',
        icon: Icons.description_outlined,
        iconBg: const Color(0xFFE6F7F1),
        iconColor: const Color(0xFF0D9488),
        onTap: onBasicTap,
      ),
      _StatCardData(
        value: '${metrics.projectCount}',
        label: 'Single Projects',
        icon: Icons.folder_outlined,
        iconBg: const Color(0xFFE8F0FE),
        iconColor: const Color(0xFF2563EB),
        onTap: onSingleTap,
      ),
      _StatCardData(
        value: '${metrics.programCount}',
        label: 'Programs',
        icon: Icons.layers_outlined,
        iconBg: const Color(0xFFEDE9FE),
        iconColor: const Color(0xFF7C3AED),
        onTap: onProgramTap,
      ),
      _StatCardData(
        value: '${metrics.portfolioCount}',
        label: 'Portfolios',
        icon: Icons.bar_chart_rounded,
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
        onTap: onPortfolioTap,
      ),
    ];

    if (isStacked) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: _DesktopStatCard(data: cards[i])),
                  const SizedBox(width: 12),
                  if (i + 1 < cards.length)
                    Expanded(child: _DesktopStatCard(data: cards[i + 1])),
                ],
              ),
            ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: _DesktopStatCard(data: cards[i])),
          if (i != cards.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}

class _DesktopStatCard extends StatelessWidget {
  const _DesktopStatCard({required this.data});
  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (data.onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
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
  final _ProjectSort _groupProjectsSort = _ProjectSort.newest;
  bool _gateApprovals = true;
  bool _sharedRiskRegister = true;
  bool _executiveSummary = true;

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
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFF0EA5E9), size: 22),
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
                    VoiceTextField(
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
                              color: canCreate
                                  ? const Color(0xFF0084FF)
                                  : const Color(0xFFE5E7EB),
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
    } catch (e) {
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

                return Column(
                  children: [
                    // ── Sticky TopAppBar ──
                    _TopAppBar(onBack: () => Navigator.pop(context)),
                    // ── Scrollable Body ──
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── PageHeader ──
                            _PageHeader(metrics: metrics),
                            const SizedBox(height: 16),
                            // ── Stats Grid (horizontal scroll) ──
                            _StatsGrid(
                              metrics: metrics,
                              onBasicTap: () =>
                                  _openBasicProjectDashboard(context),
                              onSingleTap: () =>
                                  _openProjectDashboard(context),
                              onProgramTap: () =>
                                  _openProgramDashboard(context),
                              onPortfolioTap: () =>
                                  _openPortfolioDashboard(context),
                            ),
                            const SizedBox(height: 24),
                            // ── Single Projects Section ──
                            _SingleProjectsSection(
                              projects: sortedSingles,
                              sort: _singleProjectsSort,
                              onSortChanged: (sort) => setState(
                                  () => _singleProjectsSort = sort),
                              onSeeAll: () =>
                                  _openProjectDashboard(context),
                            ),
                            const SizedBox(height: 24),
                            // ── Programs & Projects Roll-up ──
                            _ProgramRollupSection(metrics: metrics),
                            const SizedBox(height: 24),
                            // ── Governance & Reporting ──
                            _GovernanceSection(
                              gateApprovals: _gateApprovals,
                              sharedRiskRegister: _sharedRiskRegister,
                              executiveSummary: _executiveSummary,
                              onGateChanged: (v) =>
                                  setState(() => _gateApprovals = v),
                              onSharedRiskChanged: (v) =>
                                  setState(() => _sharedRiskRegister = v),
                              onExecutiveChanged: (v) =>
                                  setState(() => _executiveSummary = v),
                            ),
                            const SizedBox(height: 24),
                            // ── Independent Projects ──
                            _IndependentProjectsSection(metrics: metrics),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TOP APP BAR
// ═══════════════════════════════════════════════════════════
class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/Logo.png',
            height: 24,
            fit: BoxFit.contain,
          ),
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_back_ios_new, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 4),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PAGE HEADER
// ═══════════════════════════════════════════════════════════
class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.metrics});
  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: const Text(
              'ROLL-UP PREVIEW',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF57F17),
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Confirm portfolio roll-up',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Review which programs, projects, governance rules, and risks will be rolled up into this portfolio view.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Info chips row
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _HeaderChip(
                  label: '${metrics.programCount} programs',
                  dotColor: const Color(0xFFCBD5E1),
                ),
                _HeaderChip(
                  label: '${metrics.projectCount} projects',
                  dotColor: const Color(0xFFCBD5E1),
                ),
                _HeaderChip(
                  label: metrics.formattedTotalValue,
                  dotColor: const Color(0xFFCBD5E1),
                ),
                _HeaderChip(
                  label: 'Risk: ${metrics.riskPostureLabel}',
                  dotColor: metrics.riskPostureColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.dotColor});
  final String label;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// STATS GRID (horizontal scrollable cards)
// ═══════════════════════════════════════════════════════════
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.metrics,
    required this.onBasicTap,
    required this.onSingleTap,
    required this.onProgramTap,
    required this.onPortfolioTap,
  });

  final _PortfolioMetrics metrics;
  final VoidCallback onBasicTap;
  final VoidCallback onSingleTap;
  final VoidCallback onProgramTap;
  final VoidCallback onPortfolioTap;

  @override
  Widget build(BuildContext context) {
    final basicProjectCount =
        metrics.projects.where((p) => p.isBasicPlanProject).length;

    final cards = [
      _StatCardData(
        value: '$basicProjectCount',
        label: 'Basic Projects',
        icon: Icons.description_outlined,
        iconBg: const Color(0xFFE6F7F1),
        iconColor: const Color(0xFF0D9488),
        onTap: onBasicTap,
      ),
      _StatCardData(
        value: '${metrics.projectCount}',
        label: 'Single Projects',
        icon: Icons.folder_outlined,
        iconBg: const Color(0xFFE8F0FE),
        iconColor: const Color(0xFF2563EB),
        onTap: onSingleTap,
      ),
      _StatCardData(
        value: '${metrics.programCount}',
        label: 'Programs',
        icon: Icons.layers_outlined,
        iconBg: const Color(0xFFEDE9FE),
        iconColor: const Color(0xFF7C3AED),
        onTap: onProgramTap,
      ),
      _StatCardData(
        value: '${metrics.portfolioCount}',
        label: 'Portfolios',
        icon: Icons.bar_chart_rounded,
        iconBg: const Color(0xFFDCFCE7),
        iconColor: const Color(0xFF16A34A),
        onTap: onPortfolioTap,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            _StatCard(data: cards[i]),
            if (i != cards.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: 156,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );

    if (data.onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(8),
        child: card,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SINGLE PROJECTS SECTION
// ═══════════════════════════════════════════════════════════
class _SingleProjectsSection extends StatelessWidget {
  const _SingleProjectsSection({
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Single Projects',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              InkWell(
                onTap: onSeeAll,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0084FF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (projects.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'No standalone projects yet.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...projects.map((project) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SingleProjectCard(project: project),
                )),
        ],
      ),
    );
  }
}

class _SingleProjectCard extends StatelessWidget {
  const _SingleProjectCard({required this.project});
  final ProjectRecord project;

  @override
  Widget build(BuildContext context) {
    final name = project.name.trim().isEmpty ? 'Untitled Project' : project.name;
    final owner = project.ownerName.trim().isEmpty ? 'Unassigned' : project.ownerName;
    final stage = _projectPhase(project);
    final initials = owner.isNotEmpty
        ? owner.split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stage,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0084FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    initials.length >= 2
                        ? initials
                        : initials.padRight(2, '?'),
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  project.ownerEmail.isNotEmpty ? project.ownerEmail : owner,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROGRAMS & PROJECTS ROLL-UP SECTION
// ═══════════════════════════════════════════════════════════
class _ProgramRollupSection extends StatelessWidget {
  const _ProgramRollupSection({required this.metrics});
  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final rollups = metrics.programRollups;
    final totalProjects = rollups.fold<int>(
        0, (sum, r) => sum + r.projectScopeCount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Programs & projects',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Verify programs and projects contributions',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Text(
                '${metrics.programCount} programs · $totalProjects projects',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0084FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                if (rollups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No programs created yet. Group projects into programs to see a roll-up here.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < rollups.length; i++) ...[
                    _ProgramRollupItem(rollup: rollups[i]),
                    if (i != rollups.length - 1)
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramRollupItem extends StatelessWidget {
  const _ProgramRollupItem({required this.rollup});
  final _ProgramRollupData rollup;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.go('/${AppRoutes.programDashboard}?programId=${rollup.id}');
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rollup.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rollup.description,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  rollup.formattedValue,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rollup.averageProgress.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFFFF8E1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFFC107)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rollup.projectScopeLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: rollup.priorityColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Rank ${rollup.rank} - ${rollup.rankLabel}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: rollup.priorityColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GOVERNANCE & REPORTING SECTION
// ═══════════════════════════════════════════════════════════
class _GovernanceSection extends StatelessWidget {
  const _GovernanceSection({
    required this.gateApprovals,
    required this.sharedRiskRegister,
    required this.executiveSummary,
    required this.onGateChanged,
    required this.onSharedRiskChanged,
    required this.onExecutiveChanged,
  });

  final bool gateApprovals;
  final bool sharedRiskRegister;
  final bool executiveSummary;
  final ValueChanged<bool> onGateChanged;
  final ValueChanged<bool> onSharedRiskChanged;
  final ValueChanged<bool> onExecutiveChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Governance & reporting',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Confirm which approvals, risk registers, and reports will sync',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _GovernanceCheckboxItem(
                  title: 'Gate approvals',
                  description:
                      'Use the same approval path for all included projects and stages.',
                  scope: 'ENTIRE PORTFOLIO',
                  value: gateApprovals,
                  onChanged: onGateChanged,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _GovernanceCheckboxItem(
                  title: 'Shared risk register',
                  description:
                      'Surface portfolio-level risks across all work in this roll-up.',
                  scope: 'ENTIRE PORTFOLIO',
                  value: sharedRiskRegister,
                  onChanged: onSharedRiskChanged,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _GovernanceCheckboxItem(
                  title: 'Executive portfolio summary',
                  description:
                      'Costs, schedule, risk, and key decisions rolled up.',
                  scope: 'WEEKLY',
                  value: executiveSummary,
                  onChanged: onExecutiveChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GovernanceCheckboxItem extends StatelessWidget {
  const _GovernanceCheckboxItem({
    required this.title,
    required this.description,
    required this.scope,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final String scope;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: const Color(0xFF0084FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    Text(
                      scope,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// INDEPENDENT PROJECTS SECTION
// ═══════════════════════════════════════════════════════════
class _IndependentProjectsSection extends StatelessWidget {
  const _IndependentProjectsSection({required this.metrics});
  final _PortfolioMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final independentProjects = metrics.independentProjects;
    final previewProjects = independentProjects.take(2).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Independent projects',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '${metrics.independentProjectCount} projects',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (previewProjects.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'All projects are grouped into programs right now.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            ...previewProjects.map((project) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _IndependentProjectCard(project: project),
                )),
        ],
      ),
    );
  }
}

class _IndependentProjectCard extends StatelessWidget {
  const _IndependentProjectCard({required this.project});
  final ProjectRecord project;

  @override
  Widget build(BuildContext context) {
    final name = project.name.trim().isEmpty ? 'Untitled project' : project.name;
    final subtitle = _projectSubtitle(project);
    final phase = _projectPhase(project);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              phase,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BOTTOM ACTION BAR (fixed at bottom)
// ═══════════════════════════════════════════════════════════
// This is rendered inside the parent Scaffold via a Stack,
// but since the parent already wraps in a Stack, we add it
// as an overlay in the _PortfolioRollUpContent build method.

// ═══════════════════════════════════════════════════════════
// DATA MODELS & HELPERS
// ═══════════════════════════════════════════════════════════

enum _ProjectSort { newest, oldest }
enum _RiskSeverity { high, medium, low }

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
  const _CostBarData({
    required this.label,
    required this.formattedValue,
    required this.height,
    required this.color,
  });
  final String label;
  final String formattedValue;
  final double height;
  final Color color;
}

class _ValueBreakdownData {
  const _ValueBreakdownData({
    required this.label,
    required this.value,
    required this.color,
  });
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
    required this.projectScopeCount,
    required this.totalValue,
    required this.formattedValue,
    required this.averageProgress,
    required this.progressLabel,
    required this.priorityLabel,
    required this.priorityColor,
    required this.rank,
    required this.rankLabel,
  });

  final String id;
  final String name;
  final String description;
  final String projectScopeLabel;
  final int projectScopeCount;
  final double totalValue;
  final String formattedValue;
  final double averageProgress;
  final String progressLabel;
  final String priorityLabel;
  final Color priorityColor;
  final int rank;
  final String rankLabel;

  _ProgramRollupData copyWith({
    String? priorityLabel,
    Color? priorityColor,
    int? rank,
    String? rankLabel,
  }) {
    return _ProgramRollupData(
      id: id,
      name: name,
      description: description,
      projectScopeLabel: projectScopeLabel,
      projectScopeCount: projectScopeCount,
      totalValue: totalValue,
      formattedValue: formattedValue,
      averageProgress: averageProgress,
      progressLabel: progressLabel,
      priorityLabel: priorityLabel ?? this.priorityLabel,
      priorityColor: priorityColor ?? this.priorityColor,
      rank: rank ?? this.rank,
      rankLabel: rankLabel ?? this.rankLabel,
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
          : '$inScopeCount of $totalCount projects in scope';
      final description = programProjects.isEmpty
          ? 'No projects assigned yet.'
          : 'Avg progress ${_formatPercent(averageProgress)} · $inScopeCount ${inScopeCount == 1 ? 'project' : 'projects'}';

      rollups.add(_ProgramRollupData(
        id: program.id,
        name: name,
        description: description,
        projectScopeLabel: scopeLabel,
        projectScopeCount: inScopeCount,
        totalValue: programValue,
        formattedValue: _formatMillions(programValue),
        averageProgress: averageProgress,
        progressLabel: programProjects.isEmpty
            ? '—'
            : '${_formatPercent(averageProgress)} avg',
        priorityLabel: 'Rank —',
        priorityColor: const Color(0xFF6B7280),
        rank: 0,
        rankLabel: '—',
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
          rank: rank,
          rankLabel: _priorityDescriptor(rank),
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
