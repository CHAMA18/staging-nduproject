
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/screens/management_level_screen.dart';
import 'package:ndu_project/screens/program_basics_screen.dart';
import 'package:ndu_project/screens/pricing_screen.dart';
import 'package:ndu_project/screens/team_roles_responsibilities_screen.dart';
import 'package:ndu_project/screens/project_decision_summary_screen.dart';
import 'package:ndu_project/screens/preferred_solution_analysis_screen.dart';
import 'package:ndu_project/screens/initiation_phase_screen.dart';
import 'package:ndu_project/screens/cost_analysis_screen.dart';
import 'package:ndu_project/screens/risk_identification_screen.dart';
import 'package:ndu_project/screens/it_considerations_screen.dart';
import 'package:ndu_project/screens/infrastructure_considerations_screen.dart';
import 'package:ndu_project/screens/core_stakeholders_screen.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/auth_nav.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/project_service.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';

const Color _pageBackground = Color(0xFFFFFFFF);
const Color _surfaceBase = Color(0xFF111118);
const Color _surfaceElevated = Color(0xFF171722);
const Color _surfaceOutline = Color(0xFF252535);
const Color _surfaceOutlineLight = Color(0xFF2E2E42);
const Color _textPrimary = Color(0xFFEFF3F8);
const Color _textSecondary = Color(0xFFA3A7BE);
const Color _textTertiary = Color(0xFF6B6F89);
const Color _accentIndigo = Color(0xFF6366F1);
const Color _accentBlue = Color(0xFF2563EB);
const Color _accentTeal = Color(0xFF2DD4BF);
const Color _accentGold = Color(0xFFFFC812);
const Color _accentMagenta = Color(0xFFE11D48);
const Color _accentSoftPurple = Color(0xFF7C3AED);
const Color _accentSoftBlue = Color(0xFF60A5FA);

const BorderRadius _radiusXl = BorderRadius.all(Radius.circular(36));
const BorderRadius _radiusLg = BorderRadius.all(Radius.circular(28));
const BorderRadius _radiusMd = BorderRadius.all(Radius.circular(22));

/// Sleek homepage showcasing projects, programs, and portfolios.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<String> _dismissedProgramTitles = <String>{};
  final Set<String> _dismissedPortfolioTitles = <String>{};

  List<_PrimaryStat> _buildQuickStats(ColorScheme scheme, {
    required int projectCount,
    required String portfolioValueLabel,
  }) {
    final helperPalette = [
      _accentIndigo,
      _accentBlue,
      _accentTeal,
    ];
    final accentPalette = [
      _accentIndigo,
      _accentBlue,
      _accentTeal,
    ];

    return [
      _PrimaryStat(
        label: 'Active Projects',
        value: projectCount.toString().padLeft(2, '0'),
        helper: projectCount == 0 ? 'Start your first project' : '$projectCount in flight',
        helperColor: helperPalette[0],
        accent: accentPalette[0],
        icon: Icons.workspaces_outline,
      ),
      _PrimaryStat(
        label: 'Programs',
        value: '05',
        helper: '3 running on track',
        helperColor: helperPalette[1],
        accent: accentPalette[1],
        icon: Icons.alt_route,
      ),
      _PrimaryStat(
        label: 'Portfolios',
        value: '03',
        helper: '>\$${portfolioValueLabel}M managed value',
        helperColor: helperPalette[2],
        accent: accentPalette[2],
        icon: Icons.layers_outlined,
      ),
    ];
  }

  List<_ShowcaseData> _mapProjectRecordsToShowcase(List<ProjectRecord> records, ColorScheme scheme) {
    if (records.isEmpty) return const [];

    final palette = [
      _accentGold,
    ];

    return List.generate(records.length, (index) {
      final record = records[index];
      final tags = record.tags.isNotEmpty ? record.tags.take(3).toList() : <String>[record.status.isNotEmpty ? record.status : 'Initiation'];
      final description = record.solutionDescription.isNotEmpty
          ? record.solutionDescription
          : (record.solutionTitle.isNotEmpty ? 'Selected solution: ${record.solutionTitle}' : 'Document the project context to keep teams aligned.');

      return _ShowcaseData(
        title: record.name.isNotEmpty
            ? record.name
            : (record.solutionTitle.isNotEmpty ? record.solutionTitle : 'Untitled Project'),
        description: description,
        owner: record.ownerName.isNotEmpty ? record.ownerName : 'Project Team',
        status: record.status.isNotEmpty ? record.status : 'Initiation',
        progress: record.progress.clamp(0.0, 1.0).toDouble(),
        investment: record.investmentMillions,
        milestone: record.milestone.isNotEmpty ? record.milestone : 'Kickoff ready',
        tags: tags,
        accent: palette[index % palette.length],
        projectId: record.id,
      );
    });
  }

  List<_ShowcaseData> _buildPrograms(ColorScheme scheme) {
    return [
      _ShowcaseData(
        title: 'NextGen Workforce',
        description: 'Upskill program aligning engineering talent with AI-first delivery models.',
        owner: 'People Ops',
        status: 'Momentum',
        progress: 0.64,
        investment: 9,
        milestone: 'FY2025',
        tags: ['Talent', 'AI Academy'],
         accent: _accentGold,
      ),
      _ShowcaseData(
        title: 'Sustainability Mandate',
        description: 'Carbon-aware delivery frameworks embedded into every release train.',
        owner: 'Strategy Office',
        status: 'Emerging',
        progress: 0.41,
        investment: 6,
        milestone: 'FY2026',
        tags: ['ESG', 'Compliance'],
         accent: _accentGold,
      ),
    ];
  }

  List<_ShowcaseData> _visiblePrograms(ColorScheme scheme) {
    final programs = _buildPrograms(scheme);
    if (_dismissedProgramTitles.isEmpty) return programs;
    return programs.where((item) => !_dismissedProgramTitles.contains(item.title)).toList();
  }

  List<_ShowcaseData> _buildPortfolios(ColorScheme scheme) {
    return [
      _ShowcaseData(
        title: 'Customer Impact',
        description: 'Experience-led portfolio blending personalization, loyalty, and care operations.',
        owner: 'CX Council',
        status: 'Performing',
        progress: 0.83,
        investment: 42,
        milestone: 'Rolling 18M',
        tags: ['NPS', 'Automation'],
         accent: _accentGold,
      ),
      _ShowcaseData(
        title: 'Enterprise Platforms',
        description: 'Mission-critical assets modernized with cloud-native resilience and observability.',
        owner: 'CTO Office',
        status: 'Stabilizing',
        progress: 0.58,
        investment: 38,
        milestone: 'Rolling 24M',
        tags: ['Platform', 'Observability'],
         accent: _accentGold,
      ),
    ];
  }

  List<_ShowcaseData> _visiblePortfolios(ColorScheme scheme) {
    final portfolios = _buildPortfolios(scheme);
    if (_dismissedPortfolioTitles.isEmpty) return portfolios;
    return portfolios.where((item) => !_dismissedPortfolioTitles.contains(item.title)).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    setState(() {});
  }

  Future<void> _confirmAndDeleteProject(BuildContext context, _ShowcaseData data) async {
    final projectId = data.projectId;
    if (projectId == null) return;

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final scheme = Theme.of(dialogContext).colorScheme;
            return AlertDialog(
              title: const Text('Delete project?'),
              content: Text('This will permanently remove "${data.title}" from your projects.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) return;

    try {
      await ProjectService.deleteProject(projectId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project "${data.title}" deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete project: $error')),
      );
    }
  }

  Future<void> _openProjectById(BuildContext context, String? projectId, {required _ShowcaseData fallback}) async {
    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing project id.')));
      return;
    }

    final record = await ProjectService.getProjectById(projectId);
    if (!mounted) return;
    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project not found.')));
      return;
    }

    // CRITICAL: Load project data into the provider so all screens can access it
    final provider = ProjectDataInherited.of(context);
    await provider.loadFromFirebase(projectId);

    // Route mapping: default to decision summary checkpoint
    final route = (record.checkpointRoute.isNotEmpty) ? record.checkpointRoute : 'project_decision_summary';

    switch (route) {
      case 'business_case':
      case 'initiation_phase':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const InitiationPhaseScreen(scrollToBusinessCase: true),
          ),
        );
        break;
      case 'core_stakeholders':
        final selected = AiSolutionItem(title: record.solutionTitle, description: record.solutionDescription);
        final all = <AiSolutionItem>[selected];
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CoreStakeholdersScreen(
              notes: record.notes,
              solutions: all,
            ),
          ),
        );
        break;
      case 'infrastructure_considerations':
        final selected = AiSolutionItem(title: record.solutionTitle, description: record.solutionDescription);
        final all = <AiSolutionItem>[selected];
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InfrastructureConsiderationsScreen(
              notes: record.notes,
              solutions: all,
            ),
          ),
        );
        break;
      case 'it_considerations':
        final selected = AiSolutionItem(title: record.solutionTitle, description: record.solutionDescription);
        final all = <AiSolutionItem>[selected];
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ITConsiderationsScreen(
              notes: record.notes,
              solutions: all,
            ),
          ),
        );
        break;
      case 'risk_identification':
        final selected = AiSolutionItem(title: record.solutionTitle, description: record.solutionDescription);
        final all = <AiSolutionItem>[selected];
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RiskIdentificationScreen(
              notes: record.notes,
              solutions: all,
              businessCase: record.businessCase,
            ),
          ),
        );
        break;
      case 'cost_analysis':
        final selected = AiSolutionItem(title: record.solutionTitle, description: record.solutionDescription);
        final all = <AiSolutionItem>[selected];
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CostAnalysisScreen(
              notes: record.notes,
              solutions: all,
            ),
          ),
        );
        break;
      case 'preferred_solution_analysis':
        final selected = AiSolutionItem(title: record.solutionTitle, description: record.solutionDescription);
        final all = <AiSolutionItem>[selected];
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PreferredSolutionAnalysisScreen(
              notes: record.notes,
              solutions: all,
              businessCase: record.businessCase,
            ),
          ),
        );
        break;
      case 'project_decision_summary':
        final selected = AiSolutionItem(title: record.solutionTitle, description: record.solutionDescription);
        final all = <AiSolutionItem>[selected];
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectDecisionSummaryScreen(
              projectName: record.name.isNotEmpty ? record.name : fallback.title,
              selectedSolution: selected,
              allSolutions: all,
              businessCase: record.businessCase,
              notes: record.notes,
            ),
          ),
        );
        break;
      default:
        // Fallback until more checkpoints are introduced.
        final selected = AiSolutionItem(title: record.solutionTitle, description: record.solutionDescription);
        final all = <AiSolutionItem>[selected];
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectDecisionSummaryScreen(
              projectName: record.name.isNotEmpty ? record.name : fallback.title,
              selectedSolution: selected,
              allSolutions: all,
              businessCase: record.businessCase,
              notes: record.notes,
            ),
          ),
        );
        break;
    }
  }

  Future<void> _confirmAndDeleteProgram(BuildContext context, _ShowcaseData data) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final scheme = Theme.of(dialogContext).colorScheme;
            return AlertDialog(
              title: const Text('Remove program?'),
              content: Text('"${data.title}" will be removed from your dashboard view.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete || !mounted) return;

    setState(() {
      _dismissedProgramTitles.add(data.title);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Program "${data.title}" removed.')),
    );
  }

  Future<void> _confirmAndDeletePortfolio(BuildContext context, _ShowcaseData data) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final scheme = Theme.of(dialogContext).colorScheme;
            return AlertDialog(
              title: const Text('Remove portfolio?'),
              content: Text('"${data.title}" will be removed from your dashboard view.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Remove'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete || !mounted) return;

    setState(() {
      _dismissedPortfolioTitles.add(data.title);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Portfolio "${data.title}" removed.')),
    );
  }

  List<_ShowcaseData> _filter(List<_ShowcaseData> source) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return source;
    return source.where((item) => item.matches(query)).toList();
  }

  String _portfolioValueLabel(List<_ShowcaseData> portfolios) {
    final total = portfolios.fold<double>(0, (sum, item) => sum + item.investment);
    return total % 1 == 0 ? total.toStringAsFixed(0) : total.toStringAsFixed(1);
  }

  Future<void> _openWorkspacePortal({
    required BuildContext context,
    required _WorkspaceCategory initialCategory,
    required List<_ShowcaseData> projects,
    required List<_ShowcaseData> programs,
    required List<_ShowcaseData> portfolios,
  }) async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WorkspacePortalPage(
          initialCategory: initialCategory,
          projects: projects,
          programs: programs,
          portfolios: portfolios,
        ),
      ),
    );
  }

  String _extractInitials(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'S';
    final parts = trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'S';
    final initials = parts.take(2).map((part) => part[0]).join();
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use app's light color scheme and a white page backdrop.
    final lightScheme = theme.colorScheme.copyWith(brightness: Brightness.light);
    final dashboardTheme = theme.copyWith(
      colorScheme: lightScheme,
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      cardColor: Colors.white,
    );
    final scheme = dashboardTheme.colorScheme;
    final programs = _visiblePrograms(scheme);
    final portfolios = _visiblePortfolios(scheme);
    final portfolioValueLabel = _portfolioValueLabel(portfolios);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      final quickStats = _buildQuickStats(
        scheme,
        projectCount: 0,
        portfolioValueLabel: portfolioValueLabel,
      );
       return Scaffold(
        key: _scaffoldKey,
         backgroundColor: Colors.white,
        drawer: _buildDrawer(context, theme),
         body: Theme(
           data: dashboardTheme,
           child: SafeArea(
             child: _buildBody(
               context,
               dashboardTheme,
            quickStats,
            const [],
            programs,
            portfolios,
          ),
           ),
        ),
      );
    }

    return StreamBuilder<List<ProjectRecord>>(
      stream: ProjectService.streamProjects(ownerId: user.uid),
      builder: (context, snapshot) {
        final records = snapshot.data ?? const <ProjectRecord>[];
        final projects = _mapProjectRecordsToShowcase(records, scheme);
        final quickStats = _buildQuickStats(
          scheme,
          projectCount: records.length,
          portfolioValueLabel: portfolioValueLabel,
        );
        final isLoading = snapshot.connectionState == ConnectionState.waiting && records.isEmpty;
        final hasError = snapshot.hasError;
        if (hasError) {
          // ignore: avoid_print
          print('Project stream error: ${snapshot.error}');
        }

        return Scaffold(
           key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: _buildDrawer(context, theme),
          body: Theme(
            data: dashboardTheme,
            child: SafeArea(
              child: _buildBody(
                context,
                dashboardTheme,
                quickStats,
                projects,
                programs,
                portfolios,
                projectsLoading: isLoading,
                projectsEmptyTitle: hasError ? 'Unable to load projects' : null,
                projectsEmptyMessage: hasError ? 'Check your connection or Firebase rules, then try again.' : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    List<_PrimaryStat> quickStats,
    List<_ShowcaseData> projects,
    List<_ShowcaseData> programs,
    List<_ShowcaseData> portfolios, {
    bool projectsLoading = false,
    String? projectsEmptyTitle,
    String? projectsEmptyMessage,
  }) {
    final scheme = theme.colorScheme;
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = AppBreakpoints.pagePadding(context);
    final topPadding = isMobile ? 24.0 : 36.0;
    final filteredProjects = _filter(projects);
    final filteredPrograms = _filter(programs);
    final filteredPortfolios = _filter(portfolios);
    final filteredPortfolioValueLabel = _portfolioValueLabel(filteredPortfolios);

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            top: -180,
            right: -120,
            child: _AmbientGlow(
              size: isMobile ? 220 : 320,
              colors: [_accentIndigo.withOpacity(0.18), Colors.transparent],
            ),
          ),
          Positioned(
            bottom: -160,
            left: -80,
            child: _AmbientGlow(
              size: isMobile ? 200 : 280,
              colors: [_accentTeal.withOpacity(0.14), Colors.transparent],
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, topPadding, horizontalPadding, 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(
                  context,
                  isMobile,
                  theme,
                  portfolioValueLabel: filteredPortfolioValueLabel,
                  projectCount: filteredProjects.length,
                  programCount: filteredPrograms.length,
                  portfolioCount: filteredPortfolios.length,
                ),
                const SizedBox(height: 28),
                _buildHero(isMobile, theme),
                const SizedBox(height: 36),
                _buildStats(theme, quickStats),
                const SizedBox(height: 40),
                  _buildSection(
                  context,
                  title: 'Projects',
                  subtitle: 'Shaping the next wave of delivery impact.',
                  items: filteredProjects,
                  theme: theme,
                  isLoading: projectsLoading,
                  emptyTitle: projectsEmptyTitle ?? 'No projects yet',
                  emptyMessage: projectsEmptyMessage ?? 'Run through a solution analysis to capture your first project.',
                  onDelete: (data) => _confirmAndDeleteProject(context, data),
                  onOpenWorkspace: () {
                    _openWorkspacePortal(
                      context: context,
                      initialCategory: _WorkspaceCategory.projects,
                      projects: projects,
                      programs: programs,
                      portfolios: portfolios,
                    );
                  },
                    onItemTap: (data) => _openProjectById(context, data.projectId, fallback: data),
                ),
                const SizedBox(height: 36),
                _buildSection(
                  context,
                  title: 'Programs',
                  subtitle: 'Multi-track initiatives orchestrated across domains.',
                  items: filteredPrograms,
                  theme: theme,
                  onDelete: (data) => _confirmAndDeleteProgram(context, data),
                  onOpenWorkspace: () {
                    _openWorkspacePortal(
                      context: context,
                      initialCategory: _WorkspaceCategory.programs,
                      projects: projects,
                      programs: programs,
                      portfolios: portfolios,
                    );
                  },
                  onItemTap: (_) => ProgramBasicsScreen.open(context),
                ),
                const SizedBox(height: 36),
                _buildSection(
                  context,
                  title: 'Portfolios',
                  subtitle: 'Strategic investment clusters balancing value and risk.',
                  items: filteredPortfolios,
                  theme: theme,
                  onDelete: (data) => _confirmAndDeletePortfolio(context, data),
                  onOpenWorkspace: () {
                    _openWorkspacePortal(
                      context: context,
                      initialCategory: _WorkspaceCategory.portfolios,
                      projects: projects,
                      programs: programs,
                      portfolios: portfolios,
                    );
                  },
                ),
              ],
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    bool isMobile,
    ThemeData theme, {
    required String portfolioValueLabel,
    required int projectCount,
    required int programCount,
    required int portfolioCount,
  }) {
    final scheme = theme.colorScheme;
    final name = FirebaseAuthService.displayNameOrEmail(fallback: 'Leader');
    final initials = _extractInitials(name);
    final portfolioNoun = portfolioCount == 1 ? 'portfolio' : 'portfolios';

    Widget identity({required bool dense}) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 16 : 20, vertical: dense ? 12 : 14),
        decoration: _elevatedCard(
          radius: 26,
          borderOpacity: 0.1,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF3F4FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadows: [
            BoxShadow(
              color: const Color(0xFF0E1320).withOpacity(0.12),
              blurRadius: 42,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: dense ? 38 : 44,
              height: dense ? 38 : 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Today\'s overview',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: dense ? 34 : 38, color: Colors.black.withOpacity(0.08)),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Notifications',
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications center coming soon.')),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.notifications_none_rounded, color: scheme.onSurface.withOpacity(0.7), size: dense ? 20 : 22),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: 'Sign out',
              child: InkWell(
                onTap: () => AuthNav.signOutAndExit(context),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.logout_outlined, color: scheme.onSurface.withOpacity(0.7), size: dense ? 20 : 22),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final overviewTexts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/images/data.png',
          height: 48,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildDrawerButton(theme),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Dashboard',
                style: theme.textTheme.headlineMedium?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Real-time pulse across every project, program, and portfolio.',
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.7)),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          overviewTexts,
          const SizedBox(height: 16),
          identity(dense: true),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: overviewTexts),
              identity(dense: false),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _FocusChip(
              icon: Icons.auto_awesome_outlined,
              label: 'Showcase Projects',
              value: '$projectCount spotlight',
              theme: theme,
            ),
            _FocusChip(
              icon: Icons.all_inbox_outlined,
              label: 'Programs Cohorts',
              value: '$programCount active',
              theme: theme,
            ),
            _FocusChip(
              icon: Icons.stacked_line_chart_outlined,
              label: 'Portfolio Value',
              value: '$portfolioCount $portfolioNoun · \$${portfolioValueLabel}M managed',
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawerButton(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Tooltip(
      message: 'Open menu',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: scheme.primary.withOpacity(0.08),
              border: Border.all(color: scheme.primary.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(Icons.menu_rounded, color: scheme.primary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext rootContext, ThemeData theme) {
    final scheme = theme.colorScheme;
    final entries = [
      _DrawerEntry(
        label: 'Billing',
        icon: Icons.credit_card_outlined,
        onTap: (context) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PricingScreen()),
          );
        },
      ),
      _DrawerEntry(
        label: 'Team',
        icon: Icons.groups_outlined,
        onTap: (context) {
          TeamRolesResponsibilitiesScreen.open(context);
        },
      ),
      _DrawerEntry(label: 'Terms And Conditions', icon: Icons.description_outlined),
      _DrawerEntry(label: 'Privacy Policy', icon: Icons.privacy_tip_outlined),
    ];

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: scheme.primary.withOpacity(0.08),
                  border: Border.all(color: scheme.primary.withOpacity(0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dashboard_customize_rounded, color: scheme.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Control Center',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: scheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Navigate across operations, resources, and policy anchors.',
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.7), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.of(rootContext).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (entry.onTap != null) {
                              entry.onTap!(rootContext);
                            } else {
                              ScaffoldMessenger.of(rootContext).showSnackBar(
                                SnackBar(content: Text('${entry.label} section coming soon.')),
                              );
                            }
                          });
                        },
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: scheme.surfaceContainerHighest.withOpacity(0.25),
                            border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(entry.icon, color: scheme.primary),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  entry.label,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withOpacity(0.4)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool isMobile, ThemeData theme) {
    final scheme = theme.colorScheme;
    final name = FirebaseAuthService.displayNameOrEmail(fallback: 'Leader');
    const heroTextColor = _textPrimary;
    const borderAccent = _accentIndigo;
    final insights = [
      const _HeroInsight(title: 'Delivery confidence', value: '92%', helper: 'Sentiment +6.4%'),
      const _HeroInsight(title: 'Execution health', value: '13 squads', helper: '5 squads ready for scale'),
      const _HeroInsight(title: 'Focus horizon', value: 'Next 45 days', helper: '14 milestones queued'),
    ];

    final heroHighlights = const [
      _HeroHighlightData(
        icon: Icons.auto_awesome_outlined,
        label: 'AI governance board',
        helper: 'Live risk heatmaps in one view',
      ),
      _HeroHighlightData(
        icon: Icons.ssid_chart_outlined,
        label: 'Investment telemetry',
        helper: 'Predictive spend versus velocity',
      ),
      _HeroHighlightData(
        icon: Icons.groups_2_outlined,
        label: 'Squad readiness',
        helper: 'Talent coverage & certifications',
      ),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E1029), Color(0xFF14163A), Color(0xFF1C1F3E)],
        ),
        borderRadius: _radiusXl,
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: borderAccent.withOpacity(0.35),
            blurRadius: 60,
            offset: const Offset(0, 46),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -120,
            right: -60,
            child: _HeroAccentOrb(
              size: 260,
              colors: [borderAccent.withOpacity(0.22), Colors.transparent],
            ),
          ),
          Positioned(
            bottom: -160,
            left: -40,
            child: _HeroAccentOrb(
              size: 220,
              colors: [_accentBlue.withOpacity(0.28), Colors.transparent],
            ),
          ),
          Positioned(
            bottom: -120,
            right: -40,
            child: _HeroAccentOrb(
              size: 210,
              colors: [_accentTeal.withOpacity(0.22), Colors.transparent],
            ),
          ),
          Positioned(
            top: 60,
            right: isMobile ? -30 : 32,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: borderAccent.withOpacity(0.2),
                    blurRadius: 38,
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.auto_graph_rounded, color: heroTextColor, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'AI delivery nerve center',
                    style: TextStyle(fontWeight: FontWeight.w600, color: heroTextColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 26 : 40, vertical: isMobile ? 30 : 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $name',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: heroTextColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Command every layer of execution with contextual AI that keeps decisions, investment, and delivery in sync.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                        color: heroTextColor.withOpacity(0.72),
                        height: 1.6,
                      ),
                ),
                const SizedBox(height: 26),
                Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _HeroSearchField(
                      controller: _searchController,
                      hint: 'Search initiatives, owners, milestones or tags',
                    ),
                    _HeroCommandButton(
                      label: 'Launch initiative',
                      icon: Icons.bolt_outlined,
                      background: _accentSoftBlue.withOpacity(0.32),
                      foreground: _textPrimary,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Create initiative coming soon.')),
                        );
                      },
                    ),
                    _HeroOutlineButton(
                      label: 'View portfolio timeline',
                      icon: Icons.timeline_outlined,
                      borderColor: borderAccent,
                      foreground: _textPrimary,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Portfolio timeline opening soon.')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      for (final highlight in heroHighlights) ...[
                        _HeroHighlightPill(data: highlight),
                        const SizedBox(width: 14),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isTight = constraints.maxWidth < 600;
                    if (isTight) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroPulseCard(
                            title: 'Next milestone triggers',
                            description: 'Deployment gates for infrastructure modernization and AI compliance due in five days.',
                          ),
                          const SizedBox(height: 18),
                          _InsightStrip(insights: insights),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _HeroPulseCard(
                            title: 'Next milestone triggers',
                            description: 'Deployment gates for infrastructure modernization and AI compliance due in five days.',
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(child: _InsightStrip(insights: insights)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ThemeData theme, List<_PrimaryStat> quickStats) {
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [scheme.primary.withOpacity(0.85), scheme.secondary.withOpacity(0.85)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.speed_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enterprise Scoreboard',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Track momentum across transformation layers and surface the next best acceleration move.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.68), height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        LayoutBuilder(
          builder: (context, constraints) {
            int columns = 1;
            if (constraints.maxWidth >= 1120) {
              columns = 3;
            } else if (constraints.maxWidth >= 760) {
              columns = 2;
            }
            const double spacing = 24;
            final double itemWidth = columns == 1
                ? double.infinity
                : (constraints.maxWidth - (columns - 1) * spacing) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final stat in quickStats)
                  SizedBox(
                    width: columns == 1 ? double.infinity : itemWidth,
                    child: _QuickStatCard(stat: stat, theme: theme),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<_ShowcaseData> items,
    required ThemeData theme,
    bool isLoading = false,
    String? emptyTitle,
    String? emptyMessage,
    Future<void> Function(_ShowcaseData data)? onDelete,
    VoidCallback? onOpenWorkspace,
    void Function(_ShowcaseData data)? onItemTap,
  }) {
    final scheme = theme.colorScheme;
    final entriesLabel = '${items.length} ${items.length == 1 ? 'entry' : 'entries'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.7), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: _elevatedCard(
                radius: 20,
                borderOpacity: 0.12,
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                entriesLabel,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () {
                if (onOpenWorkspace != null) {
                  onOpenWorkspace();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Full $title workspace coming soon.')),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: scheme.primary,
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open workspace'),
            ),
            if (title == 'Projects') ...[
              const SizedBox(width: 8),
              Text(
                '/',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                   Navigator.of(context).push(
                     MaterialPageRoute(builder: (_) => const ManagementLevelScreen()),
                   );
                },
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                ),
                child: const Text('Create Project'),
              ),
            ],
            if (title == 'Programs') ...[
              const SizedBox(width: 8),
              Text(
                '/',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                   Navigator.of(context).push(
                     MaterialPageRoute(builder: (_) => const ManagementLevelScreen()),
                   );
                },
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                ),
                child: const Text('Create Program'),
              ),
            ],
            if (title == 'Portfolios') ...[
              const SizedBox(width: 8),
              Text(
                '/',
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ManagementLevelScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                ),
                child: const Text('Create Portfolio'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            int columns = 1;
            if (constraints.maxWidth >= 1240) {
              columns = 3;
            } else if (constraints.maxWidth >= 860) {
              columns = 2;
            }
            const double spacing = 26;
            final double itemWidth = columns == 1
                ? double.infinity
                : (constraints.maxWidth - (columns - 1) * spacing) / columns;

            if (isLoading) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(34),
                decoration: _elevatedCard(radius: 26, borderOpacity: 0.12),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(34),
                decoration: _elevatedCard(radius: 26, borderOpacity: 0.12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.inbox_outlined, color: Colors.black54),
                    const SizedBox(height: 12),
                    Text(
                      emptyTitle ?? 'No matches right now',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      emptyMessage ?? 'Try another search or create a new record to bring this section to life.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              );
            }

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final item in items)
                  SizedBox(
                    width: columns == 1 ? double.infinity : itemWidth,
                    child: _ShowcaseCard(
                      data: item,
                      theme: theme,
                      borderColor: title == 'Projects'
                          ? theme.colorScheme.primary.withOpacity(0.24)
                          : null,
                      onDelete: onDelete != null
                          ? () => onDelete(item)
                          : null,
                      onTap: onItemTap != null
                          ? () => onItemTap(item)
                          : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

BoxDecoration _elevatedCard({
  double radius = 28,
  Gradient? gradient,
  double borderOpacity = 0.12,
  Color color = Colors.white,
  List<BoxShadow>? shadows,
}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    color: gradient == null ? color : null,
    gradient: gradient,
    border: Border.all(color: Colors.black.withOpacity(borderOpacity), width: 1),
    boxShadow: shadows ??
        [
          BoxShadow(
            color: const Color(0xFF0E1320).withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
  );
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({required this.stat, required this.theme});

  final _PrimaryStat stat;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final numericValue = double.tryParse(stat.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final widthFactor = (numericValue / 30).clamp(0.25, 1.0);
    final accentGradient = LinearGradient(
      colors: [stat.accent, stat.accent.withOpacity(0.65)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      decoration: _elevatedCard(radius: 30, borderOpacity: 0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: accentGradient,
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(stat.icon, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.black.withOpacity(0.72),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: stat.accent.withOpacity(0.12),
                      ),
                      child: Text(
                        stat.helper,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: stat.accent.darken(0.25),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  stat.value,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.88),
                    letterSpacing: -1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: accentGradient,
                ),
                child: Icon(Icons.north_east_rounded, size: 16, color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: stat.accent.withOpacity(0.08),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: widthFactor,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: accentGradient,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard({
    required this.data,
    required this.theme,
    this.onDelete,
    this.onTap,
    this.borderColor,
  });

  final _ShowcaseData data;
  final ThemeData theme;
  final Future<void> Function()? onDelete;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final accent = data.accent;
    final scheme = theme.colorScheme;
    final canDelete = onDelete != null;
    final deleteTooltip = data.projectId != null ? 'Delete project' : 'Remove item';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          if (onTap != null) {
            onTap!();
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${data.title} details coming soon.')),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(26),
          decoration: _elevatedCard(
            radius: 28,
            borderOpacity: 0.12,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.55)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.28),
                          blurRadius: 26,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.work_outline_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.alternate_email, size: 16, color: accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                data.owner,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent.withOpacity(0.24), accent.withOpacity(0.12)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          data.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (canDelete) ...[
                        const SizedBox(height: 10),
                        Tooltip(
                          message: deleteTooltip,
                          preferBelow: false,
                          child: IconButton(
                            onPressed: () async {
                              if (onDelete == null) return;
                              await onDelete!();
                            },
                            icon: const Icon(Icons.delete_outline, size: 20),
                            style: IconButton.styleFrom(
                              foregroundColor: accent.darken(0.2),
                              backgroundColor: accent.withOpacity(0.12),
                              padding: const EdgeInsets.all(10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                data.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              _ProgressBar(progress: data.progress, accent: accent, theme: theme),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Investment',
                      value: '${data.investment.toStringAsFixed(0)}M',
                      icon: Icons.attach_money,
                      accent: accent,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: 'Milestone',
                      value: data.milestone,
                      icon: Icons.event_outlined,
                      accent: accent,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  for (final tag in data.tags)
                    Chip(
                      label: Text(tag, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.black.withOpacity(0.12)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: accent.withOpacity(0.18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          Icon(Icons.security_outlined, size: 16, color: accent.darken(0.15)),
                        const SizedBox(width: 6),
                        Text(
                          'Compliance ready',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Deep dive for ${data.title} coming soon.')),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: accent),
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('Open insights'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _WorkspaceCategory { projects, programs, portfolios }

class _WorkspacePortalPage extends StatefulWidget {
  const _WorkspacePortalPage({
    required this.initialCategory,
    required this.projects,
    required this.programs,
    required this.portfolios,
  });

  final _WorkspaceCategory initialCategory;
  final List<_ShowcaseData> projects;
  final List<_ShowcaseData> programs;
  final List<_ShowcaseData> portfolios;

  @override
  State<_WorkspacePortalPage> createState() => _WorkspacePortalPageState();
}

class _WorkspacePortalPageState extends State<_WorkspacePortalPage> {
  late _WorkspaceCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  List<_ShowcaseData> _itemsFor(_WorkspaceCategory category) {
    switch (category) {
      case _WorkspaceCategory.projects:
        return widget.projects;
      case _WorkspaceCategory.programs:
        return widget.programs;
      case _WorkspaceCategory.portfolios:
        return widget.portfolios;
    }
  }

  String _titleFor(_WorkspaceCategory category) {
    switch (category) {
      case _WorkspaceCategory.projects:
        return 'Projects workspace';
      case _WorkspaceCategory.programs:
        return 'Programs workspace';
      case _WorkspaceCategory.portfolios:
        return 'Portfolios workspace';
    }
  }

  String _subtitleFor(_WorkspaceCategory category) {
    switch (category) {
      case _WorkspaceCategory.projects:
        return 'A dedicated view of the projects you have in motion.';
      case _WorkspaceCategory.programs:
        return 'Explore the programs you are steering right now.';
      case _WorkspaceCategory.portfolios:
        return 'Zoom in on the portfolios you are curating.';
    }
  }

  Color _accentFor(_WorkspaceCategory category, ColorScheme scheme) {
    switch (category) {
      case _WorkspaceCategory.projects:
        return scheme.primary;
      case _WorkspaceCategory.programs:
        return scheme.secondary;
      case _WorkspaceCategory.portfolios:
        return scheme.tertiary;
    }
  }

  String _entriesLabel(List<_ShowcaseData> items) {
    final count = items.length;
    final noun = count == 1 ? 'entry' : 'entries';
    return '$count $noun';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _itemsFor(_selectedCategory);
    final accent = _accentFor(_selectedCategory, scheme);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleFor(_selectedCategory),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _subtitleFor(_selectedCategory),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withOpacity(0.7),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: _surfaceBase,
                        border: Border.all(color: _surfaceOutline),
                      ),
                      child: Text(
                        _entriesLabel(items),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _CategorySelector(
                  selected: _selectedCategory,
                  onSelect: (category) {
                    if (_selectedCategory == category) return;
                    setState(() => _selectedCategory = category);
                  },
                  projectsCount: widget.projects.length,
                  programsCount: widget.programs.length,
                  portfoliosCount: widget.portfolios.length,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (items.isEmpty) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        child: _WorkspacePortalEmptyState(theme: theme, accent: accent),
                      );
                    }

                    final maxWidth = constraints.maxWidth;
                    int columns = 1;
                    if (maxWidth >= 1280) {
                      columns = 3;
                    } else if (maxWidth >= 880) {
                      columns = 2;
                    }

                    const spacing = 20.0;

                    if (columns == 1) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        itemBuilder: (context, index) {
                          final data = items[index];
                          return _PortalShowcaseCard(
                            data: data,
                            theme: theme,
                            borderColor: accent.withOpacity(0.24),
                            flat: true,
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: spacing),
                        itemCount: items.length,
                      );
                    }

                    final availableWidth = maxWidth - 32; // account for horizontal padding
                    final itemWidth = (availableWidth - (columns - 1) * spacing) / columns;

                    return Scrollbar(
                      radius: const Radius.circular(12),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        child: Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                            children: [
                              for (final data in items)
                                SizedBox(
                                  width: itemWidth,
                                  child: _PortalShowcaseCard(
                                    data: data,
                                    theme: theme,
                                    borderColor: accent.withOpacity(0.24),
                                    flat: true,
                                  ),
                                ),
                            ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.onSelect,
    required this.projectsCount,
    required this.programsCount,
    required this.portfoliosCount,
  });

  final _WorkspaceCategory selected;
  final ValueChanged<_WorkspaceCategory> onSelect;
  final int projectsCount;
  final int programsCount;
  final int portfoliosCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color accentFor(_WorkspaceCategory category) {
      switch (category) {
        case _WorkspaceCategory.projects:
          return scheme.primary;
        case _WorkspaceCategory.programs:
          return scheme.secondary;
        case _WorkspaceCategory.portfolios:
          return scheme.tertiary;
      }
    }

    IconData iconFor(_WorkspaceCategory category) {
      switch (category) {
        case _WorkspaceCategory.projects:
          return Icons.auto_awesome_outlined;
        case _WorkspaceCategory.programs:
          return Icons.route_outlined;
        case _WorkspaceCategory.portfolios:
          return Icons.layers_outlined;
      }
    }

    String labelFor(_WorkspaceCategory category) {
      switch (category) {
        case _WorkspaceCategory.projects:
          return 'Projects';
        case _WorkspaceCategory.programs:
          return 'Programs';
        case _WorkspaceCategory.portfolios:
          return 'Portfolios';
      }
    }

    int countFor(_WorkspaceCategory category) {
      switch (category) {
        case _WorkspaceCategory.projects:
          return projectsCount;
        case _WorkspaceCategory.programs:
          return programsCount;
        case _WorkspaceCategory.portfolios:
          return portfoliosCount;
      }
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final category in _WorkspaceCategory.values)
          _WorkspaceCategoryChip(
            category: category,
            selected: selected == category,
            accent: accentFor(category),
            icon: iconFor(category),
            label: labelFor(category),
            count: countFor(category),
            onSelect: onSelect,
          ),
      ],
    );
  }
}

class _WorkspaceCategoryChip extends StatelessWidget {
  const _WorkspaceCategoryChip({
    required this.category,
    required this.selected,
    required this.accent,
    required this.icon,
    required this.label,
    required this.count,
    required this.onSelect,
  });

  final _WorkspaceCategory category;
  final bool selected;
  final Color accent;
  final IconData icon;
  final String label;
  final int count;
  final ValueChanged<_WorkspaceCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = Colors.black87;
    final iconColor = accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => onSelect(category),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white,
            border: Border.all(
                color: Colors.black.withOpacity(selected ? 0.2 : 0.12),
                width: selected ? 1.6 : 1,
            ),
            boxShadow: const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 10),
              Text(
                '$label · ${count.toString().padLeft(2, '0')}',
                 style: theme.textTheme.labelLarge?.copyWith(
                   fontWeight: FontWeight.w600,
                   color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspacePortalEmptyState extends StatelessWidget {
  const _WorkspacePortalEmptyState({required this.theme, required this.accent});

  final ThemeData theme;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withOpacity(0.12), width: 1),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_outlined, size: 36, color: accent.darken(0.2)),
            const SizedBox(height: 16),
            Text(
              'Nothing here yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once you create and open records in this space, they will appear in this workspace portal.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalShowcaseCard extends StatelessWidget {
  const _PortalShowcaseCard({required this.data, required this.theme, this.borderColor, this.flat = true});

  final _ShowcaseData data;
  final ThemeData theme;
  final Color? borderColor;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final accent = data.accent;
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: _elevatedCard(
        radius: 30,
        borderOpacity: 0.12,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadows: const <BoxShadow>[],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, accent.withOpacity(0.55)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Owned by ${data.owner}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.26), accent.withOpacity(0.14)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  data.status,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            data.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          _ProgressBar(progress: data.progress, accent: accent, theme: theme),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Investment',
                  value: '${data.investment.toStringAsFixed(0)}M',
                  icon: Icons.monetization_on_outlined,
                  accent: accent,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Milestone',
                  value: data.milestone,
                  icon: Icons.flag_outlined,
                  accent: accent,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final tag in data.tags)
                Chip(
                  label: Text(
                    tag,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.black.withOpacity(0.12)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${data.title} insights coming soon.')),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open detail'),
              style: TextButton.styleFrom(foregroundColor: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.theme,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: _elevatedCard(
        radius: 20,
        borderOpacity: 0.12,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF3F6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent, accent.withOpacity(0.55)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroInsight {
  const _HeroInsight({required this.title, required this.value, required this.helper});

  final String title;
  final String value;
  final String helper;
}

class _HeroHighlightData {
  const _HeroHighlightData({required this.icon, required this.label, required this.helper});

  final IconData icon;
  final String label;
  final String helper;
}

class _HeroHighlightPill extends StatelessWidget {
  const _HeroHighlightPill({required this.data});

  final _HeroHighlightData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_accentSoftBlue, _accentSoftPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(data.icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                data.helper,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPulseCard extends StatelessWidget {
  const _HeroPulseCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const cardTextColor = Colors.black87;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF4F6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_accentMagenta, _accentSoftPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.flag_circle_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Critical cadence',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: cardTextColor.withOpacity(0.88),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(Icons.schedule, size: 18, color: cardTextColor.withOpacity(0.45)),
              const SizedBox(width: 4),
              Text(
                '5 days',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cardTextColor.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: cardTextColor,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cardTextColor.withOpacity(0.72),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              const _HeroPulseTag(label: 'AI compliance', icon: Icons.verified_user_outlined),
              const _HeroPulseTag(label: 'Infra release', icon: Icons.cloud_done_outlined),
              const _HeroPulseTag(label: 'Change advisory', icon: Icons.account_tree_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPulseTag extends StatelessWidget {
  const _HeroPulseTag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pillColor = Colors.white;
    final foreground = Colors.black87;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: pillColor.withOpacity(0.92),
        border: Border.all(color: Colors.black.withOpacity(0.12), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAccentOrb extends StatelessWidget {
  const _HeroAccentOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _HeroSearchField extends StatelessWidget {
  const _HeroSearchField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    const borderAccent = _accentIndigo;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 720;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: isCompact ? double.infinity : 320,
        maxWidth: isCompact ? double.infinity : 420,
      ),
      child: SizedBox(
        width: isCompact ? double.infinity : 380,
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withOpacity(0.96),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.black.withOpacity(0.12), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.16), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: borderAccent, width: 1.6),
            ),
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _HeroCommandButton extends StatelessWidget {
  const _HeroCommandButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 17),
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}

class _HeroOutlineButton extends StatelessWidget {
  const _HeroOutlineButton({
    required this.label,
    required this.icon,
    required this.borderColor,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color borderColor;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: borderColor, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          textStyle: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({required this.insights});

  final List<_HeroInsight> insights;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const stripTextColor = Color(0xFF141414);
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Executive snapshots',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: stripTextColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 20),
          for (int i = 0; i < insights.length; i++)
            _InsightRow(
              insight: insights[i],
              isLast: i == insights.length - 1,
            ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight, required this.isLast});

  final _HeroInsight insight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    // Use a dark, high-contrast text color on white containers for readability
    const rowTextColor = Color(0xFF141414);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.radio_button_checked, color: Colors.black, size: 14),
            const SizedBox(width: 8),
            Text(
              insight.title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          insight.value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 4),
        Text(
          insight.helper,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black, fontSize: 12),
        ),
        if (!isLast) ...[
          const SizedBox(height: 14),
          Container(height: 1, color: rowTextColor.withOpacity(0.08)),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _FocusChip extends StatelessWidget {
  const _FocusChip({required this.icon, required this.label, required this.value, required this.theme});

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: _elevatedCard(radius: 22, borderOpacity: 0.12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.primary.withOpacity(0.65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black.withOpacity(0.55)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.black.withOpacity(0.84)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.accent, required this.theme});

  final double progress;
  final Color accent;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final percent = (progress.clamp(0, 1) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.12), width: 1),
      ),
      child: SizedBox(
        height: 14,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$percent%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryStat {
  const _PrimaryStat({
    required this.label,
    required this.value,
    required this.helper,
    required this.helperColor,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final String helper;
  final Color helperColor;
  final Color accent;
  final IconData icon;
}

class _DrawerEntry {
  const _DrawerEntry({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final void Function(BuildContext context)? onTap;
}

class _ShowcaseData {
  const _ShowcaseData({
    required this.title,
    required this.description,
    required this.owner,
    required this.status,
    required this.progress,
    required this.investment,
    required this.milestone,
    required this.tags,
    required this.accent,
    this.projectId,
  });

  final String title;
  final String description;
  final String owner;
  final String status;
  final double progress;
  final double investment;
  final String milestone;
  final List<String> tags;
  final Color accent;
  final String? projectId;

  bool matches(String query) {
    return title.toLowerCase().contains(query) ||
        description.toLowerCase().contains(query) ||
        owner.toLowerCase().contains(query) ||
        status.toLowerCase().contains(query) ||
        milestone.toLowerCase().contains(query) ||
        tags.any((tag) => tag.toLowerCase().contains(query));
  }
}

extension _ColorRamp on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }
}