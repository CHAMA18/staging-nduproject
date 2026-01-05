import 'package:flutter/material.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/ui_ux_design_screen.dart';
import 'package:ndu_project/services/project_navigation_service.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class DevelopmentSetUpScreen extends StatefulWidget {
  const DevelopmentSetUpScreen({super.key});

  @override
  State<DevelopmentSetUpScreen> createState() => _DevelopmentSetUpScreenState();
}

class _DevelopmentSetUpScreenState extends State<DevelopmentSetUpScreen> {
  final List<_SetupCardData> _cards = [
    _SetupCardData(
      icon: Icons.storage_outlined,
      title: 'Environments & Access',
      subtitle: 'Confirm where the system runs and who can access what.',
      status: _SetupStatus.ready,
      items: const [
        _ChecklistItem('Environments: Dev, Staging, Prod defined', done: true),
        _ChecklistItem('Access: GitHub, AWS, Jira provisioned', done: true),
        _ChecklistItem('Data: Seeded test data available', done: true),
      ],
      footerLabel: 'Environment Details',
    ),
    _SetupCardData(
      icon: Icons.alt_route_outlined,
      title: 'Build & Deployment Flow',
      subtitle: 'Show how code moves safely to an environment.',
      status: _SetupStatus.inProgress,
      items: const [
        _ChecklistItem('Source Control: Trunk-based dev', done: true),
        _ChecklistItem('CI Status: Lint & Unit tests pending', done: false),
        _ChecklistItem('Deployment: Manual trigger (Draft)', done: false),
      ],
      footerLabel: 'CI/CD Configuration',
    ),
    _SetupCardData(
      icon: Icons.construction_outlined,
      title: 'Tooling & Ownership',
      subtitle: 'Avoid confusion about tools and responsibility.',
      status: _SetupStatus.ready,
      items: const [
        _ChecklistItem('Core Tools: VS Code, Linear, Figma', done: true),
        _ChecklistItem('Ownership: DevOps team assigned', done: true),
        _ChecklistItem('Onboarding: 1-day commit ready', done: true),
      ],
      footerLabel: 'Onboarding & Standards',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = ProjectDataInherited.maybeOf(context);
      final projectId = provider?.projectData.projectId;
      if (projectId != null && projectId.isNotEmpty) {
        await ProjectNavigationService.instance.saveLastPage(projectId, 'development-set-up');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final padding = AppBreakpoints.pagePadding(context);

    return ResponsiveScaffold(
      activeItemLabel: 'Development Set Up',
      body: Column(
        children: [
          const PlanningPhaseHeader(title: 'Design Phase'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  const SizedBox(height: 28),
                  ResponsiveGrid(
                    desktopColumns: 1,
                    tabletColumns: 1,
                    mobileColumns: 1,
                    spacing: 20,
                    runSpacing: 20,
                    children: _cards.map(_buildSetupCard).toList(),
                  ),
                  const SizedBox(height: 32),
                  _buildFooterActions(isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Development Set Up',
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            _buildTag(
              label: 'Readiness checkpoint',
              background: AppSemanticColors.warningSurface,
              foreground: const Color(0xFFB45309),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Prepare environments, access, and workflows so development can start without blockers. Document only what is required for day-one readiness.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildTag({required String label, required Color background, required Color foreground}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
  }

  Widget _buildSetupCard(_SetupCardData card) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 6),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(card.icon, color: const Color(0xFF111827), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _buildStatusPill(card.status),
            ],
          ),
          const SizedBox(height: 16),
          ...card.items.map(_buildChecklistItem),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppSemanticColors.border),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  card.footerLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF111827)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(_SetupStatus status) {
    final isReady = status == _SetupStatus.ready;
    final background = isReady ? AppSemanticColors.successSurface : AppSemanticColors.warningSurface;
    final foreground = isReady ? AppSemanticColors.success : const Color(0xFFB45309);
    final label = isReady ? 'READY' : 'IN PROGRESS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: foreground, letterSpacing: 0.4),
      ),
    );
  }

  Widget _buildChecklistItem(_ChecklistItem item) {
    final iconColor = item.done ? AppSemanticColors.success : Colors.grey[400];
    final icon = item.done ? Icons.check_circle_rounded : Icons.remove_circle_outline;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(bool isMobile) {
    final exportButton = ElevatedButton.icon(
      onPressed: _handleExport,
      style: ElevatedButton.styleFrom(
        backgroundColor: LightModeColors.lightPrimary,
        foregroundColor: LightModeColors.lightOnPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
      icon: const Icon(Icons.download_outlined, size: 18),
      label: const Text('Export Setup Summary', style: TextStyle(fontWeight: FontWeight.w600)),
    );

    final nextButton = ElevatedButton(
      onPressed: _handleNext,
      style: ElevatedButton.styleFrom(
        backgroundColor: LightModeColors.lightPrimary,
        foregroundColor: LightModeColors.lightOnPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Next', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(width: 6),
          Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          exportButton,
          const SizedBox(height: 12),
          nextButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        exportButton,
        const SizedBox(width: 12),
        nextButton,
      ],
    );
  }

  void _handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Setup summary export is coming soon.')),
    );
  }

  void _handleNext() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UiUxDesignScreen()),
    );
  }
}

enum _SetupStatus { ready, inProgress }

class _ChecklistItem {
  const _ChecklistItem(this.label, {required this.done});

  final String label;
  final bool done;
}

class _SetupCardData {
  const _SetupCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.items,
    required this.footerLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _SetupStatus status;
  final List<_ChecklistItem> items;
  final String footerLabel;
}
