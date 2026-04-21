import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/models/staffing_row.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/screens/design_deliverables_screen.dart';
import 'package:ndu_project/screens/team_meetings_screen.dart';
import 'package:ndu_project/services/execution_phase_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/phase_transition_helper.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/staff_team_resource_grid.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart' as launch;
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';

class StaffTeamScreen extends StatefulWidget {
  const StaffTeamScreen({super.key});

  static void open(BuildContext context) {
    PhaseTransitionHelper.pushPhaseAware(
      context: context,
      builder: (_) => const StaffTeamScreen(),
      destinationCheckpoint: 'staff_team',
    );
  }

  @override
  State<StaffTeamScreen> createState() => _StaffTeamScreenState();
}

class _StaffTeamScreenState extends State<StaffTeamScreen> {
  List<StaffingRow> _staffingRows = [];
  List<launch.LaunchEntry> _onboardingActions = [];
  List<launch.LaunchEntry> _coverageRisks = [];
  bool _loading = true;
  bool _autoGenerationTriggered = false;
  bool _isAutoGenerating = false;
  Timer? _autoSaveDebounce;

  String? get _projectId {
    try {
      final provider = ProjectDataInherited.maybeOf(context);
      return provider?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final rows =
          await ExecutionPhaseService.loadStaffingRows(projectId: projectId);

      final data = await ExecutionPhaseService.loadPageData(
        projectId: projectId,
        pageKey: 'staff_team',
      );

      if (mounted) {
        setState(() {
          _staffingRows = rows;
          _onboardingActions = data?['onboardingActions']
                  ?.map((e) => launch.LaunchEntry(
                        title: e.title,
                        details: e.details,
                        status: e.status,
                      ))
                  .toList() ??
              [];
          _coverageRisks = data?['coverageRisks']
                  ?.map((e) => launch.LaunchEntry(
                        title: e.title,
                        details: e.details,
                        status: e.status,
                      ))
                  .toList() ??
              [];
          _loading = false;
        });
      }
      await _autoGenerateIfNeeded();
    } catch (e) {
      debugPrint('Error loading staff team data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _autoGenerateIfNeeded() async {
    if (!mounted || _autoGenerationTriggered || _isAutoGenerating) return;
    if (_staffingRows.isNotEmpty ||
        _onboardingActions.isNotEmpty ||
        _coverageRisks.isNotEmpty) {
      return;
    }

    _autoGenerationTriggered = true;
    _isAutoGenerating = true;

    try {
      final data = ProjectDataHelper.getData(context);
      var contextText = ProjectDataHelper.buildExecutivePlanContext(
        data,
        sectionLabel: 'Staff Team Orchestration',
      );
      if (contextText.trim().isEmpty) {
        contextText = ProjectDataHelper.buildProjectContextScan(
          data,
          sectionLabel: 'Staff Team Orchestration',
        );
      }
      final safeContext =
          contextText.trim().isEmpty ? 'Project context unavailable.' : contextText;

      final ai = OpenAiServiceSecure();
      final staffingRows = await ai.generateStaffingRows(
        context: safeContext,
        maxRows: 4,
      );
      Map<String, List<Map<String, dynamic>>> sections = {};
      if (contextText.trim().isNotEmpty) {
        sections = await ai.generateLaunchPhaseEntries(
          context: contextText,
          sections: const {
            'onboardingActions': 'Onboarding actions and ownership assignments',
            'coverageRisks': 'Coverage gaps and staffing risks',
          },
          itemsPerSection: 3,
        );
      }

      List<launch.LaunchEntry> onboarding = (sections['onboardingActions'] ?? [])
          .map(
            (e) => launch.LaunchEntry(
              title: e['title']?.toString() ?? '',
              details: e['details']?.toString() ?? '',
              status: e['status']?.toString(),
            ),
          )
          .where((entry) => entry.title.trim().isNotEmpty)
          .toList();
      List<launch.LaunchEntry> coverage = (sections['coverageRisks'] ?? [])
          .map(
            (e) => launch.LaunchEntry(
              title: e['title']?.toString() ?? '',
              details: e['details']?.toString() ?? '',
              status: e['status']?.toString(),
            ),
          )
          .where((entry) => entry.title.trim().isNotEmpty)
          .toList();

      if (onboarding.isEmpty) {
        onboarding = const [
          launch.LaunchEntry(
            title: 'Confirm onboarding timeline',
            details: 'Assign owners and due dates for new team members.',
            status: 'Planned',
          ),
          launch.LaunchEntry(
            title: 'Access and tooling setup',
            details: 'Provision credentials and tools before start date.',
            status: 'Planned',
          ),
        ];
      }
      if (coverage.isEmpty) {
        coverage = const [
          launch.LaunchEntry(
            title: 'Coverage gap in critical role',
            details: 'Identify backfill or interim owner for key workstream.',
            status: 'Open',
          ),
          launch.LaunchEntry(
            title: 'Skill overlap risk',
            details: 'Ensure cross-training for high-dependency roles.',
            status: 'Open',
          ),
        ];
      }

      if (!mounted) return;
      setState(() {
        if (staffingRows.isNotEmpty) {
          _staffingRows = staffingRows;
        }
        if (onboarding.isNotEmpty) {
          _onboardingActions = onboarding;
        }
        if (coverage.isNotEmpty) {
          _coverageRisks = coverage;
        }
      });

      await _persistChanges();
    } catch (e) {
      debugPrint('Error auto-generating staff team data: $e');
    } finally {
      _isAutoGenerating = false;
    }
  }

  void _onStaffingRowsChanged(List<StaffingRow> rows) {
    setState(() => _staffingRows = rows);
    _autoSave();
  }

  void _autoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 1500), () {
      _persistChanges();
    });
  }

  Future<void> _persistChanges() async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) return;

    try {
      await ExecutionPhaseService.saveStaffingRows(
        projectId: projectId,
        rows: _staffingRows,
        userId: FirebaseAuth.instance.currentUser?.uid,
      );

      await ExecutionPhaseService.savePageData(
        projectId: projectId,
        pageKey: 'staff_team',
        sections: {
          'onboardingActions': _onboardingActions,
          'coverageRisks': _coverageRisks,
        },
        userId: FirebaseAuth.instance.currentUser?.uid,
      );
    } catch (e) {
      debugPrint('Error persisting staff team data: $e');
    }
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: isMobile
            ? _buildMobileLayout(horizontalPadding)
            : _buildDesktopLayout(horizontalPadding),
      ),
    );
  }

  Widget _buildDesktopLayout(double hPad) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DraggableSidebar(
          openWidth: AppBreakpoints.sidebarWidth(context),
          child: const InitiationLikeSidebar(
              activeItemLabel: 'Staff Team'),
        ),
        Expanded(child: _buildScrollContent(hPad)),
      ],
    );
  }

  Widget _buildMobileLayout(double hPad) {
    return _buildScrollContent(hPad);
  }

  Widget _buildScrollContent(double hPad) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumHeader(context),
          const SizedBox(height: 32),
          _buildSectionIntro(),
          const SizedBox(height: 28),
          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ))
          else ...[
            StaffTeamResourceGrid(
              rows: _staffingRows,
              onRowsChanged: _onStaffingRowsChanged,
            ),
            const SizedBox(height: 28),
            launch.LaunchEditableSection(
              title: 'Onboarding actions',
              description:
                  'List onboarding steps and owners to get people productive.',
              entries: _onboardingActions,
              onAdd: () => _addOnboardingAction(),
              onRemove: (i) {
                setState(() => _onboardingActions.removeAt(i));
                _autoSave();
              },
              onEdit: (i, entry) => _editOnboardingAction(i, entry),
            ),
            const SizedBox(height: 20),
            launch.LaunchEditableSection(
              title: 'Coverage risks',
              description: 'Document gaps or risks in team coverage.',
              entries: _coverageRisks,
              onAdd: () => _addCoverageRisk(),
              onRemove: (i) {
                setState(() => _coverageRisks.removeAt(i));
                _autoSave();
              },
              onEdit: (i, entry) => _editCoverageRisk(i, entry),
            ),
          ],
          const SizedBox(height: 36),
          _buildBottomActionBar(context),
          const SizedBox(height: 56),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => DesignDeliverablesScreen.open(context)),
              const SizedBox(width: 12),
              _CircleIconButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onTap: () => TeamMeetingsScreen.open(context)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Staff Team Orchestration',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const _CurrentUserProfileChip(),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.rocket_launch_outlined,
                      size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  _loading ? 'Execution Phase · Loading...' : 'Execution Phase',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded,
                  size: 22, color: Color(0xFF4338CA)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Staff Plan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Strategize your project's human capital requirements. Identify core roles, determine resource allocation, and align staffing costs with your project's execution timeline.",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: LaunchPhaseNavigation(
        backLabel: 'Back: Design Deliverables',
        nextLabel: 'Next: Team Meetings',
        onBack: () => DesignDeliverablesScreen.open(context),
        onNext: () => TeamMeetingsScreen.open(context),
      ),
    );
  }

  Future<void> _addOnboardingAction() async {
    final entry = await launch.showLaunchEntryDialog(
      context,
      titleLabel: 'Action / owner',
      detailsLabel: 'Details',
      includeStatus: true,
    );
    if (entry != null && mounted) {
      setState(() => _onboardingActions.add(entry));
      _autoSave();
    }
  }

  Future<void> _editOnboardingAction(
      int index, launch.LaunchEntry currentEntry) async {
    final entry = await launch.showLaunchEntryDialog(
      context,
      titleLabel: 'Action / owner',
      detailsLabel: 'Details',
      includeStatus: true,
      initialEntry: currentEntry,
    );
    if (entry != null && mounted) {
      setState(() => _onboardingActions[index] = entry);
      _autoSave();
    }
  }

  Future<void> _addCoverageRisk() async {
    final entry = await launch.showLaunchEntryDialog(
      context,
      titleLabel: 'Risk',
      detailsLabel: 'Details',
      includeStatus: true,
    );
    if (entry != null && mounted) {
      setState(() => _coverageRisks.add(entry));
      _autoSave();
    }
  }

  Future<void> _editCoverageRisk(
      int index, launch.LaunchEntry currentEntry) async {
    final entry = await launch.showLaunchEntryDialog(
      context,
      titleLabel: 'Risk',
      detailsLabel: 'Details',
      includeStatus: true,
      initialEntry: currentEntry,
    );
    if (entry != null && mounted) {
      setState(() => _coverageRisks[index] = entry);
      _autoSave();
    }
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _CurrentUserProfileChip extends StatelessWidget {
  const _CurrentUserProfileChip();

  String _initials(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r"\s+"));
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final photoUrl = user?.photoURL;
    final email = user?.email ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        _initials(displayName),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563)),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                  ),
                  Text(
                    role,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
