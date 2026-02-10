import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/models/project_data_model.dart';

class StakeholderManagementScreen extends StatefulWidget {
  const StakeholderManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StakeholderManagementScreen()),
    );
  }

  @override
  State<StakeholderManagementScreen> createState() =>
      _StakeholderManagementScreenState();
}

class _StakeholderManagementScreenState
    extends State<StakeholderManagementScreen> {
  int _activeTabIndex = 1; // 0 = Stakeholders, 1 = Engagement Plans

  final _stakeholderSaveDebounce = _Debouncer();
  final _planSaveDebounce = _Debouncer();
  final bool _loadingStakeholders = false;
  final bool _loadingPlans = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Data is managed by ProjectDataHelper and Provider
  }

  @override
  void dispose() {
    _stakeholderSaveDebounce.dispose();
    _planSaveDebounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 36;
    final projectData = ProjectDataHelper.getData(context);

    // Filter stakeholders and plans based on search
    final filteredStakeholders = projectData.stakeholderEntries.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.organization.toLowerCase().contains(q) ||
          s.role.toLowerCase().contains(q);
    }).toList();

    final filteredPlans = projectData.engagementPlanEntries.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.stakeholder.toLowerCase().contains(q) ||
          p.objective.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Row(
        children: [
          DraggableSidebar(
            openWidth: AppBreakpoints.sidebarWidth(context),
            child: const InitiationLikeSidebar(
                activeItemLabel: 'Stakeholder Management'),
          ),
          Expanded(
            child: Column(
              children: [
                const _TopUtilityBar(),
                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding, vertical: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _TitleSection(
                                showButtonsBelow: isMobile,
                                onExport: () {},
                                onAddProject: () {},
                                onAutoPopulate: _autoPopulateFromInitiation,
                              ),
                              const SizedBox(height: 24),
                              const PlanningAiNotesCard(
                                title: 'Stakeholder Notes',
                                sectionLabel: 'Stakeholder Management',
                                noteKey: 'planning_stakeholder_notes',
                                checkpoint: 'stakeholder_management',
                                description:
                                    'Capture overall stakeholder strategy, risks, and communication protocols.',
                              ),
                              const SizedBox(height: 32),
                              _StatsRow(
                                totalStakeholders:
                                    projectData.stakeholderEntries.length,
                                externalCount: projectData.stakeholderEntries
                                    .where((s) =>
                                        s.organization.toLowerCase() !=
                                        'internal')
                                    .length,
                              ),
                              const SizedBox(height: 32),
                              _InfluenceInterestMatrix(
                                  stakeholders: projectData.stakeholderEntries),
                              const SizedBox(height: 32),
                              _EngagementSection(
                                activeTabIndex: _activeTabIndex,
                                onTabChanged: (idx) =>
                                    setState(() => _activeTabIndex = idx),
                                stakeholderTable: _StakeholdersTable(
                                  entries: filteredStakeholders,
                                  isLoading: false,
                                  onChanged: _updateStakeholder,
                                  onDelete: _deleteStakeholder,
                                ),
                                planTable: _EngagementPlansTable(
                                  entries: filteredPlans,
                                  isLoading: false,
                                  onChanged: _updateEngagementPlan,
                                  onDelete: _deleteEngagementPlan,
                                ),
                                onAdd: _activeTabIndex == 0
                                    ? _addStakeholder
                                    : _addEngagementPlan,
                                onSearch: (v) =>
                                    setState(() => _searchQuery = v),
                              ),
                              const SizedBox(height: 60),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                          right: 24, bottom: 24, child: KazAiChatBubble()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _projectId() => ProjectDataHelper.getData(context).projectId;

  // Manual persistence methods removed as we now use ProjectDataHelper.updateAndSave

  void _addStakeholder() async {
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'stakeholder_management',
      dataUpdater: (d) => d.copyWith(
        stakeholderEntries: [...d.stakeholderEntries, StakeholderEntry.empty()],
      ),
    );
  }

  void _updateStakeholder(StakeholderEntry updated) async {
    final provider = ProjectDataHelper.getProvider(context);
    final entries =
        List<StakeholderEntry>.from(provider.projectData.stakeholderEntries);
    final index = entries.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    entries[index] = updated.copyWith(updatedAt: DateTime.now());

    // Update local state immediately for responsive UI (matrix updates),
    // then debounce the remote save to reduce write volume.
    provider.updateField((d) => d.copyWith(stakeholderEntries: entries));
    _stakeholderSaveDebounce.run(() async {
      await provider.saveToFirebase(checkpoint: 'stakeholder_management');
    });
  }

  void _deleteStakeholder(String id) async {
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'stakeholder_management',
      dataUpdater: (d) => d.copyWith(
        stakeholderEntries:
            d.stakeholderEntries.where((e) => e.id != id).toList(),
      ),
    );
  }

  void _addEngagementPlan() async {
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'stakeholder_management',
      dataUpdater: (d) => d.copyWith(
        engagementPlanEntries: [
          ...d.engagementPlanEntries,
          EngagementPlanEntry.empty()
        ],
      ),
    );
  }

  void _updateEngagementPlan(EngagementPlanEntry updated) async {
    final projectData = ProjectDataHelper.getData(context);
    final entries =
        List<EngagementPlanEntry>.from(projectData.engagementPlanEntries);
    final index = entries.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    entries[index] = updated.copyWith(updatedAt: DateTime.now());

    _planSaveDebounce.run(() async {
      await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'stakeholder_management',
        showSnackbar: false,
        dataUpdater: (d) => d.copyWith(engagementPlanEntries: entries),
      );
    });
  }

  void _deleteEngagementPlan(String id) async {
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'stakeholder_management',
      dataUpdater: (d) => d.copyWith(
        engagementPlanEntries:
            d.engagementPlanEntries.where((e) => e.id != id).toList(),
      ),
    );
  }

  Future<void> _autoPopulateFromInitiation() async {
    final projectData = ProjectDataHelper.getProvider(context).projectData;
    final coreStakeholders = projectData.coreStakeholdersData;
    if (coreStakeholders == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No stakeholder data found in Initiation Phase.')));
      return;
    }

    final selectedSolutionId = projectData.preferredSolutionId;
    final solutionData = coreStakeholders.solutionStakeholderData.firstWhere(
      (s) => s.solutionTitle == projectData.preferredSolution?.title,
      orElse: () => coreStakeholders.solutionStakeholderData.isNotEmpty
          ? coreStakeholders.solutionStakeholderData.first
          : SolutionStakeholderData(),
    );

    if (solutionData.solutionTitle.isEmpty &&
        coreStakeholders.solutionStakeholderData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No stakeholder data found in Initiation Phase.')));
      return;
    }

    final List<StakeholderEntry> newEntries = [];

    void parseAndAdd(String text, String org) {
      final lines = text.split('\n');
      for (var line in lines) {
        final cleaned = line.replaceAll(RegExp(r'^[-*•]\s*'), '').trim();
        if (cleaned.isNotEmpty) {
          newEntries.add(StakeholderEntry(
            id: DateTime.now().microsecondsSinceEpoch.toString() +
                cleaned.hashCode.toString(),
            name: cleaned,
            organization: org,
            role: 'TBD',
            contactInfo: '',
            influence: 'Medium',
            interest: 'Medium',
            channel: 'Email',
            owner: 'Project Manager',
            notes: 'Added from Initiation Phase',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }
    }

    parseAndAdd(solutionData.internalStakeholders, 'Internal');
    parseAndAdd(solutionData.externalStakeholders, 'External');

    if (newEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No stakeholders found in Initiation Phase.')));
      return;
    }

    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'stakeholder_management',
      dataUpdater: (d) => d.copyWith(
        stakeholderEntries: newEntries,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Loaded ${newEntries.length} stakeholders from Initiation Phase.')));
  }
}

class _TopUtilityBar extends StatelessWidget {
  const _TopUtilityBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _circleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.maybePop(context)),
          const SizedBox(width: 12),
          _circleButton(
              icon: Icons.arrow_forward_ios_rounded,
              onTap: () async {
                final navIndex = PlanningPhaseNavigation.getPageIndex(
                    'stakeholder_management');
                if (navIndex != -1 &&
                    navIndex < PlanningPhaseNavigation.pages.length - 1) {
                  final nextPage = PlanningPhaseNavigation.pages[navIndex + 1];
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: nextPage.builder));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('No next screen available')));
                }
              }),
          const Spacer(),
          const _UserChip(
            name: '',
            role: '',
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = FirebaseAuthService.displayNameOrEmail(
        fallback: name.isNotEmpty ? name : 'User');
    final email = user?.email ?? '';
    final primary = displayName.isNotEmpty
        ? displayName
        : (email.isNotEmpty ? email : name);
    final photoUrl = user?.photoURL ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final resolvedRole = isAdmin ? 'Admin' : 'Member';
        final roleText = role.isNotEmpty ? role : resolvedRole;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage:
                    photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(
                        primary.isNotEmpty ? primary[0].toUpperCase() : 'U',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151)),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(primary,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827))),
                  Text(roleText,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: Color(0xFF9CA3AF)),
            ],
          ),
        );
      },
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection(
      {required this.showButtonsBelow,
      required this.onExport,
      required this.onAddProject,
      this.onAutoPopulate});

  final bool showButtonsBelow;
  final VoidCallback onExport;
  final VoidCallback onAddProject;
  final VoidCallback? onAutoPopulate;

  @override
  Widget build(BuildContext context) {
    const buttons = SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Stakeholder Management',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Manage stakeholders, communication plans, and engagement strategies',
                    style: TextStyle(
                        fontSize: 15, color: Color(0xFF6B7280), height: 1.5),
                  ),
                ],
              ),
            ),
            if (!showButtonsBelow) ...[
              if (onAutoPopulate != null)
                _topButton(
                    label: 'Auto-populate',
                    icon: Icons.auto_awesome,
                    color: const Color(0xFFFFC107),
                    textColor: Colors.black,
                    onPressed: onAutoPopulate!),
              const SizedBox(width: 12),
              buttons,
            ],
          ],
        ),
        if (showButtonsBelow) ...[
          const SizedBox(height: 16),
          if (onAutoPopulate != null) ...[
            _topButton(
                label: 'Auto-populate from Initiation',
                icon: Icons.auto_awesome,
                color: const Color(0xFFFFC107),
                textColor: Colors.black,
                onPressed: onAutoPopulate!),
            const SizedBox(height: 12),
          ],
          buttons,
        ],
      ],
    );
  }

  Widget _topButton(
      {required String label,
      required IconData icon,
      required Color color,
      required Color textColor,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: textColor),
      label: Text(label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.totalStakeholders,
    required this.externalCount,
  });

  final int totalStakeholders;
  final int externalCount;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    final children = [
      _MetricCard(
        title: 'Total Stakeholders',
        value: totalStakeholders.toString(),
        icon: Icons.people_alt_outlined,
        accentColor: const Color(0xFF60A5FA),
      ),
      _MetricCard(
        title: 'External Partners',
        value: externalCount.toString(),
        icon: Icons.public_rounded,
        accentColor: const Color(0xFF10B981),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i != 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i != 0) const SizedBox(width: 16),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.accentColor});

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x08000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827))),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCardsRow extends StatelessWidget {
  const _InfoCardsRow({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cards = [
      const _CommunicationFrequencyCard(),
      const _LevelDistributionCard(),
    ];

    if (isMobile) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 16),
          cards[1],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
      ],
    );
  }
}

class _CommunicationFrequencyCard extends StatelessWidget {
  const _CommunicationFrequencyCard();

  static const List<String> _items = [];

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const _SectionEmptyState(
        title: 'No cadence defined',
        message: 'Add communication frequency to align stakeholders.',
        icon: Icons.forum_outlined,
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Communication Frequency',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 16),
          for (var item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child:
                        Icon(Icons.circle, size: 8, color: Color(0xFF111827)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF374151))),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelDistributionCard extends StatelessWidget {
  const _LevelDistributionCard();

  @override
  Widget build(BuildContext context) {
    return const _SectionEmptyState(
      title: 'No influence distribution yet',
      message: 'Map stakeholder influence to visualize engagement tiers.',
      icon: Icons.pie_chart_outline,
    );
  }
}

class _InfluenceInterestMatrix extends StatelessWidget {
  const _InfluenceInterestMatrix({required this.stakeholders});

  final List<StakeholderEntry> stakeholders;

  @override
  Widget build(BuildContext context) {
    final hHighILow = stakeholders
        .where((s) => s.influence == 'High' && s.interest == 'Low')
        .toList();
    final hHighIHigh = stakeholders
        .where((s) => s.influence == 'High' && s.interest == 'High')
        .toList();
    final hLowILow = stakeholders
        .where((s) => s.influence == 'Low' && s.interest == 'Low')
        .toList();
    final hLowIHigh = stakeholders
        .where((s) => s.influence == 'Low' && s.interest == 'High')
        .toList();
    final hMid = stakeholders
        .where((s) => s.influence == 'Medium' || s.interest == 'Medium')
        .toList();
    // 3. Keep Informed (Low/Med Influence, High Interest)
    final keepInformed = stakeholders
        .where((s) =>
            (s.influence == 'Low' || s.influence == 'Medium') &&
            s.interest == 'High')
        .toList();
    // 4. Monitor (Low/Med Influence, Low/Med Interest)
    final monitor = stakeholders
        .where((s) =>
            (s.influence == 'Low' || s.influence == 'Medium') &&
            (s.interest == 'Low' || s.interest == 'Medium'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Influence / Interest Matrix',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x05000000),
                  blurRadius: 10,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              // Column Headers (Interest)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 40), // Spacing for Y-axis label
                    Expanded(child: _axisHeader('LOW INTEREST')),
                    Expanded(child: _axisHeader('HIGH INTEREST')),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Y-axis label (Influence)
                  _verticalAxisLabel('HIGH INFLUENCE'),
                  Expanded(
                    child: _matrixQuadrant(
                      label: 'Keep Satisfied',
                      color: const Color(0xFFEFF6FF), // Blue
                      accentColor: const Color(0xFF3B82F6),
                      stakeholders: hHighILow,
                    ),
                  ),
                  Expanded(
                    child: _matrixQuadrant(
                      label: 'Manage Closely (Key Players)',
                      color: const Color(0xFFFEF2F2), // Red
                      accentColor: const Color(0xFFEF4444),
                      stakeholders: hHighIHigh,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _verticalAxisLabel('LOW INFLUENCE'),
                  Expanded(
                    child: _matrixQuadrant(
                      label: 'Monitor (Minimal Effort)',
                      color: const Color(0xFFF9FAFB), // Grey
                      accentColor: const Color(0xFF6B7280),
                      stakeholders: hLowILow,
                    ),
                  ),
                  Expanded(
                    child: _matrixQuadrant(
                      label: 'Keep Informed',
                      color: const Color(0xFFECFDF5), // Green
                      accentColor: const Color(0xFF10B981),
                      stakeholders: hLowIHigh,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _axisHeader(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Color(0xFF9CA3AF)),
      ),
    );
  }

  Widget _verticalAxisLabel(String text) {
    return Container(
      width: 40,
      height: 140,
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF9CA3AF)),
        ),
      ),
    );
  }

  Widget _matrixQuadrant({
    required String label,
    required Color color,
    required Color accentColor,
    required List<StakeholderEntry> stakeholders,
  }) {
    return Container(
      height: 140,
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: stakeholders.isEmpty
                ? Center(
                    child: Text(
                      'None',
                      style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: accentColor.withValues(alpha: 0.5)),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: stakeholders
                          .map((s) => _stakeholderChip(s, accentColor))
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stakeholderChip(StakeholderEntry s, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Text(
        s.name.isEmpty ? 'Unnamed' : s.name,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.8)),
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState(
      {required this.title, required this.message, required this.icon});

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(message,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EngagementSection extends StatelessWidget {
  const _EngagementSection({
    required this.activeTabIndex,
    required this.onTabChanged,
    required this.stakeholderTable,
    required this.planTable,
    required this.onAdd,
    required this.onSearch,
  });

  final int activeTabIndex;
  final ValueChanged<int> onTabChanged;
  final Widget stakeholderTable;
  final Widget planTable;
  final VoidCallback onAdd;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F5FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                _tabButton(title: 'Stakeholders', index: 0),
                _tabButton(title: 'Engagement Plans', index: 1),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SearchField(
                        enabled: true,
                        value: '', // Managed externally now
                        onChanged: onSearch,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add),
                      label: Text(
                          activeTabIndex == 0 ? 'Add stakeholder' : 'Add plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD84D),
                        foregroundColor: const Color(0xFF1F2937),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                IndexedStack(
                  index: activeTabIndex,
                  children: [
                    stakeholderTable,
                    planTable,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({required String title, required int index}) {
    final active = activeTabIndex == index;
    return InkWell(
      onTap: () => onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFF1F2937) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField(
      {required this.enabled, required this.value, required this.onChanged});

  final bool enabled;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search stakeholders...',
        prefixIcon:
            const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFC812), width: 1.2),
        ),
      ),
    );
  }
}

// _FilterButton removed as per plan

class _StakeholdersTable extends StatelessWidget {
  const _StakeholdersTable({
    required this.entries,
    required this.isLoading,
    required this.onChanged,
    required this.onDelete,
  });

  final List<StakeholderEntry> entries;
  final bool isLoading;
  final ValueChanged<StakeholderEntry> onChanged;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final columns = [
      const _TableColumnDef('Stakeholder', 200),
      const _TableColumnDef('Organization', 180),
      const _TableColumnDef('Role/Title', 160),
      const _TableColumnDef('Contact Info', 200),
      const _TableColumnDef('Influence', 140),
      const _TableColumnDef('Interest', 140),
      const _TableColumnDef('Channel', 180),
      const _TableColumnDef('Owner', 160),
      const _TableColumnDef('Notes', 240),
      const _TableColumnDef('', 70),
    ];

    if (isLoading) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (entries.isEmpty) {
      return const _SectionEmptyState(
        title: 'No stakeholders yet',
        message: 'Add stakeholders to build your engagement register.',
        icon: Icons.group_outlined,
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in entries)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.name,
                fieldKey: '${entry.id}_name',
                hintText: 'Name',
                onChanged: (value) => onChanged(entry.copyWith(name: value)),
              ),
              _TextCell(
                value: entry.organization,
                fieldKey: '${entry.id}_organization',
                hintText: 'Organization',
                onChanged: (value) =>
                    onChanged(entry.copyWith(organization: value)),
              ),
              _TextCell(
                value: entry.role,
                fieldKey: '${entry.id}_role',
                hintText: 'Role/Title',
                onChanged: (value) => onChanged(entry.copyWith(role: value)),
              ),
              _TextCell(
                value: entry.contactInfo,
                fieldKey: '${entry.id}_contactInfo',
                hintText: 'Email/Phone',
                onChanged: (value) =>
                    onChanged(entry.copyWith(contactInfo: value)),
              ),
              _DropdownCell(
                value: entry.influence,
                fieldKey: '${entry.id}_influence',
                options: const ['High', 'Medium', 'Low'],
                onChanged: (value) =>
                    onChanged(entry.copyWith(influence: value)),
              ),
              _DropdownCell(
                value: entry.interest,
                fieldKey: '${entry.id}_interest',
                options: const ['High', 'Medium', 'Low'],
                onChanged: (value) =>
                    onChanged(entry.copyWith(interest: value)),
              ),
              _TextCell(
                value: entry.channel,
                fieldKey: '${entry.id}_channel',
                hintText: 'Channel',
                onChanged: (value) => onChanged(entry.copyWith(channel: value)),
              ),
              _TextCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                hintText: 'Owner',
                onChanged: (value) => onChanged(entry.copyWith(owner: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                minLines: 1,
                maxLines: 2,
                onChanged: (value) => onChanged(entry.copyWith(notes: value)),
              ),
              _DeleteCell(onPressed: () => onDelete(entry.id)),
            ],
          ),
      ],
    );
  }
}

class _EngagementPlansTable extends StatelessWidget {
  const _EngagementPlansTable({
    required this.entries,
    required this.isLoading,
    required this.onChanged,
    required this.onDelete,
  });

  final List<EngagementPlanEntry> entries;
  final bool isLoading;
  final ValueChanged<EngagementPlanEntry> onChanged;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final columns = [
      const _TableColumnDef('Stakeholder', 200),
      const _TableColumnDef('Objective', 220),
      const _TableColumnDef('Method', 160),
      const _TableColumnDef('Frequency', 140),
      const _TableColumnDef('Owner', 160),
      const _TableColumnDef('Status', 140),
      const _TableColumnDef('Next Touchpoint', 160),
      const _TableColumnDef('Notes', 240),
      const _TableColumnDef('', 70),
    ];

    if (isLoading) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (entries.isEmpty) {
      return const _SectionEmptyState(
        title: 'No engagement plans yet',
        message: 'Add engagement plans to define stakeholder touchpoints.',
        icon: Icons.playlist_add_check_outlined,
      );
    }

    return _EditableTable(
      columns: columns,
      rows: [
        for (final entry in entries)
          _EditableRow(
            key: ValueKey(entry.id),
            columns: columns,
            cells: [
              _TextCell(
                value: entry.stakeholder,
                fieldKey: '${entry.id}_stakeholder',
                hintText: 'Stakeholder',
                onChanged: (value) =>
                    onChanged(entry.copyWith(stakeholder: value)),
              ),
              _TextCell(
                value: entry.objective,
                fieldKey: '${entry.id}_objective',
                hintText: 'Objective',
                minLines: 1,
                maxLines: 2,
                onChanged: (value) =>
                    onChanged(entry.copyWith(objective: value)),
              ),
              _TextCell(
                value: entry.method,
                fieldKey: '${entry.id}_method',
                hintText: 'Method',
                onChanged: (value) => onChanged(entry.copyWith(method: value)),
              ),
              _TextCell(
                value: entry.frequency,
                fieldKey: '${entry.id}_frequency',
                hintText: 'Frequency',
                onChanged: (value) =>
                    onChanged(entry.copyWith(frequency: value)),
              ),
              _TextCell(
                value: entry.owner,
                fieldKey: '${entry.id}_owner',
                hintText: 'Owner',
                onChanged: (value) => onChanged(entry.copyWith(owner: value)),
              ),
              _DropdownCell(
                value: entry.status,
                fieldKey: '${entry.id}_status',
                options: const [
                  'Planned',
                  'In progress',
                  'At risk',
                  'Completed'
                ],
                onChanged: (value) => onChanged(entry.copyWith(status: value)),
              ),
              _TextCell(
                value: entry.nextTouchpoint,
                fieldKey: '${entry.id}_next_touchpoint',
                hintText: 'Next touchpoint',
                onChanged: (value) =>
                    onChanged(entry.copyWith(nextTouchpoint: value)),
              ),
              _TextCell(
                value: entry.notes,
                fieldKey: '${entry.id}_notes',
                hintText: 'Notes',
                minLines: 1,
                maxLines: 2,
                onChanged: (value) => onChanged(entry.copyWith(notes: value)),
              ),
              _DeleteCell(onPressed: () => onDelete(entry.id)),
            ],
          ),
      ],
    );
  }
}

class _EditableTable extends StatelessWidget {
  const _EditableTable({required this.columns, required this.rows});

  final List<_TableColumnDef> columns;
  final List<_EditableRow> rows;

  @override
  Widget build(BuildContext context) {
    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18)),
      ),
      child: Row(
        children: columns
            .map((column) => SizedBox(
                  width: column.width,
                  child: Text(
                    column.label.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Color(0xFF6B7280)),
                  ),
                ))
            .toList(),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              minWidth:
                  columns.fold<double>(0, (total, col) => total + col.width)),
          child: Column(
            children: [
              header,
              for (int i = 0; i < rows.length; i++)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: i.isEven ? Colors.white : const Color(0xFFF9FAFB),
                    border: Border(
                      top: BorderSide(
                          color: const Color(0xFFE5E7EB),
                          width: i == 0 ? 1 : 0.5),
                    ),
                  ),
                  child: rows[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  const _EditableRow({super.key, required this.columns, required this.cells});

  final List<_TableColumnDef> columns;
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        cells.length,
        (index) => SizedBox(width: columns[index].width, child: cells[index]),
      ),
    );
  }
}

class _TableColumnDef {
  const _TableColumnDef(this.label, this.width);

  final String label;
  final double width;
}

class _TextCell extends StatefulWidget {
  const _TextCell({
    required this.value,
    required this.fieldKey,
    required this.onChanged,
    this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String value;
  final String fieldKey;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final ValueChanged<String> onChanged;

  @override
  State<_TextCell> createState() => _TextCellState();
}

class _TextCellState extends State<_TextCell> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TextCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      // Only update from external source if it's actually different from what's currently being typed
      // This prevents the cursor from jumping during rapid typing but allows external sync.
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextFormField(
        controller: _controller,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          hintText: widget.hintText,
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _DropdownCell extends StatelessWidget {
  const _DropdownCell({
    required this.value,
    required this.fieldKey,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final String fieldKey;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final resolvedValue = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<String>(
      key: ValueKey(fieldKey),
      initialValue: resolvedValue,
      items: options
          .map((option) => DropdownMenuItem(
              value: option,
              child: Text(option, style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

class _DeleteCell extends StatelessWidget {
  const _DeleteCell({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: IconButton(
        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
        onPressed: onPressed,
      ),
    );
  }
}

// Private entry classes removed in favor of StakeholderEntry and EngagementPlanEntry in project_data_model.dart

class _Debouncer {
  _Debouncer({Duration? delay})
      : delay = delay ?? const Duration(milliseconds: 700);

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
