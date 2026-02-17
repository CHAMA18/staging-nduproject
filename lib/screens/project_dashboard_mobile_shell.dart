import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/portfolio_model.dart';
import '../models/program_model.dart';
import '../providers/project_data_provider.dart';
import '../routing/app_router.dart';
import '../services/portfolio_service.dart';
import '../services/program_service.dart';
import '../services/project_navigation_service.dart';
import '../services/project_service.dart';
import '../utils/navigation_route_resolver.dart';
import 'initiation_phase_screen.dart';

class ProjectDashboardMobileShell extends StatefulWidget {
  const ProjectDashboardMobileShell({
    super.key,
    required this.isBasicPlan,
    required this.onAddProject,
  });

  final bool isBasicPlan;
  final Future<void> Function() onAddProject;

  @override
  State<ProjectDashboardMobileShell> createState() =>
      _ProjectDashboardMobileShellState();
}

class _ProjectDashboardMobileShellState
    extends State<ProjectDashboardMobileShell> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _owner(ProjectRecord p) {
    final name = p.ownerName.trim();
    if (name.isNotEmpty && !name.contains('@')) return name;
    final email = p.ownerEmail.trim();
    return email.isEmpty ? 'Unknown' : email.split('@').first;
  }

  Future<void> _openProject(ProjectRecord project) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final provider = ProjectDataInherited.read(context);
      final success = await provider
          .loadFromFirebase(project.id)
          .timeout(const Duration(seconds: 35));
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.lastError ?? 'Unable to open project'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final checkpoint = project.checkpointRoute.isNotEmpty
          ? project.checkpointRoute
          : await ProjectNavigationService.instance.getLastPage(project.id);
      if (!mounted) return;
      final screen = NavigationRouteResolver.resolveCheckpointToScreen(
        checkpoint.isEmpty ? 'initiation' : checkpoint,
        context,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => screen ?? const InitiationPhaseScreen()),
      );
    } on TimeoutException {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project load timed out. Please retry.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening project: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final projects$ = user == null
        ? Stream.value(const <ProjectRecord>[])
        : ProjectService.streamProjects(ownerId: user.uid, filterByOwner: true);
    final programs$ = user == null
        ? Stream.value(const <ProgramModel>[])
        : ProgramService.streamPrograms(ownerId: user.uid);
    final portfolios$ = user == null
        ? Stream.value(const <PortfolioModel>[])
        : PortfolioService.streamPortfolios(ownerId: user.uid);

    return StreamBuilder<List<ProjectRecord>>(
      stream: projects$,
      builder: (context, projectSnap) {
        final all = projectSnap.data ?? const <ProjectRecord>[];
        final singles = widget.isBasicPlan
            ? all.where((e) => e.isBasicPlanProject).toList()
            : all.where((e) => !e.isBasicPlanProject).toList();
        singles.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final list = _query.trim().isEmpty
            ? singles
            : singles.where((e) {
                final q = _query.toLowerCase();
                return e.name.toLowerCase().contains(q) ||
                    e.status.toLowerCase().contains(q) ||
                    _owner(e).toLowerCase().contains(q);
              }).toList();

        return StreamBuilder<List<ProgramModel>>(
          stream: programs$,
          builder: (context, programSnap) {
            return StreamBuilder<List<PortfolioModel>>(
              stream: portfolios$,
              builder: (context, portfolioSnap) {
                final programs = programSnap.data?.length ?? 0;
                final portfolios = portfolioSnap.data?.length ?? 0;
                final focus = singles.isEmpty ? null : singles.first;
                return Scaffold(
                  backgroundColor: const Color(0xFFF3F5F9),
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.centerDocked,
                  floatingActionButton: FloatingActionButton(
                    onPressed: widget.onAddProject,
                    backgroundColor: const Color(0xFFFBBF24),
                    child: const Icon(Icons.add, color: Color(0xFF111827)),
                  ),
                  bottomNavigationBar: BottomAppBar(
                    shape: const CircularNotchedRectangle(),
                    notchMargin: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Nav(
                            icon: Icons.home,
                            label: 'Home',
                            active: true,
                            onTap: () {}),
                        _Nav(
                            icon: Icons.folder_outlined,
                            label: 'Projects',
                            active: false,
                            onTap: () {}),
                        const SizedBox(width: 28),
                        _Nav(
                            icon: Icons.show_chart_rounded,
                            label: 'Reports',
                            active: false,
                            onTap: () {}),
                        _Nav(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            active: false,
                            onTap: () {
                              context.go(
                                  '/${AppRoutes.settings}?from=${AppRoutes.dashboard}');
                            }),
                      ],
                    ),
                  ),
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 120),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Project dashboard',
                                style: TextStyle(
                                    fontSize: 28, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                  child: ElevatedButton.icon(
                                onPressed: widget.onAddProject,
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 16),
                                label: const Text('Create Project'),
                              )),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: OutlinedButton(
                                onPressed: () => context
                                    .go('/${AppRoutes.programDashboard}'),
                                child: const Text('Create Program'),
                              )),
                            ]),
                            const SizedBox(height: 12),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.3,
                              children: [
                                _tile(
                                    'Single Projects',
                                    '${singles.length}',
                                    Icons.folder_outlined,
                                    const Color(0xFF3B82F6)),
                                _tile(
                                    'Basic Projects',
                                    '${all.where((e) => e.isBasicPlanProject).length}',
                                    Icons.folder_special_outlined,
                                    const Color(0xFF14B8A6)),
                                _tile(
                                    'Programs',
                                    '$programs',
                                    Icons.layers_outlined,
                                    const Color(0xFFA855F7)),
                                _tile(
                                    'Portfolios',
                                    '$portfolios',
                                    Icons.pie_chart_outline_rounded,
                                    const Color(0xFF16A34A)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Text('Current Focus',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCCB1F),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                  focus?.name ?? 'No project selected yet.',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20)),
                            ),
                            const SizedBox(height: 14),
                            const Text('Single Projects',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _search,
                              onChanged: (v) => setState(() => _query = v),
                              decoration: const InputDecoration(
                                hintText: 'Search projects...',
                                prefixIcon: Icon(Icons.search),
                                filled: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...list.take(5).map((p) {
                              final snapshot = p.progressSnapshot;
                              final pct = snapshot.completionPercent;
                              final phase = snapshot.currentPhase.trim().isEmpty
                                  ? (p.status.trim().isEmpty
                                      ? 'Initiation'
                                      : p.status.trim())
                                  : snapshot.currentPhase.trim();
                              String healthLabel;
                              Color healthColor;
                              switch (snapshot.health) {
                                case ProjectProgressHealth.completed:
                                  healthLabel = 'Completed';
                                  healthColor = const Color(0xFF1D4ED8);
                                  break;
                                case ProjectProgressHealth.onTrack:
                                  healthLabel = 'On Track';
                                  healthColor = const Color(0xFF166534);
                                  break;
                                case ProjectProgressHealth.behind:
                                  healthLabel = 'Behind';
                                  healthColor = const Color(0xFFB91C1C);
                                  break;
                                case ProjectProgressHealth.inProgress:
                                  healthLabel = 'In Progress';
                                  healthColor = const Color(0xFF92400E);
                                  break;
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => _openProject(p),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              p.name.isEmpty
                                                  ? 'Untitled Project'
                                                  : p.name,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 2),
                                          Text('$phase - ${_owner(p)}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF6B7280))),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                '$pct%',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                healthLabel,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: healthColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                              value: pct / 100, minHeight: 6),
                                        ]),
                                  ),
                                ),
                              );
                            }),
                          ]),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _tile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 24)),
        const SizedBox(height: 2),
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ]),
      ),
    );
  }
}
