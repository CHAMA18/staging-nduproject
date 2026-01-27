import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class StakeholderManagementScreen extends StatefulWidget {
  const StakeholderManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StakeholderManagementScreen()),
    );
  }

  @override
  State<StakeholderManagementScreen> createState() => _StakeholderManagementScreenState();
}

class _StakeholderManagementScreenState extends State<StakeholderManagementScreen> {
  int _activeTabIndex = 1; // 0 = Stakeholders, 1 = Engagement Plans

  final List<_StakeholderEntry> _stakeholders = [];
  final List<_EngagementPlanEntry> _engagementPlans = [];
  final _Debouncer _stakeholderSaveDebounce = _Debouncer();
  final _Debouncer _planSaveDebounce = _Debouncer();
  bool _loadingStakeholders = false;
  bool _loadingPlans = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStakeholders();
      _loadEngagementPlans();
    });
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Stakeholder Management'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopUtilityBar(onBack: () => Navigator.maybePop(context)),
                        const SizedBox(height: 28),
                        _TitleSection(
                          showButtonsBelow: isMobile,
                          onExport: () {},
                          onAddProject: () {},
                        ),
                        const SizedBox(height: 24),
                        const PlanningAiNotesCard(
                          title: 'Notes',
                          sectionLabel: 'Stakeholder Management',
                          noteKey: 'planning_stakeholder_management_notes',
                          checkpoint: 'stakeholder_management',
                          description: 'Summarize stakeholder priorities, engagement cadence, and influence mapping.',
                        ),
                        const SizedBox(height: 28),
                        _StatsRow(
                          isMobile: isMobile,
                          totalStakeholders: _stakeholders.length,
                          highInfluenceCount: _stakeholders.where((entry) => entry.influence.toLowerCase() == 'high').length,
                        ),
                        const SizedBox(height: 24),
                        _InfoCardsRow(isMobile: isMobile),
                        const SizedBox(height: 24),
                        _InfluenceInterestMatrix(stakeholders: _stakeholders),
                        const SizedBox(height: 28),
                        _EngagementSection(
                          activeTabIndex: _activeTabIndex,
                          onTabChanged: (index) => setState(() => _activeTabIndex = index),
                          stakeholders: _stakeholders.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()) || s.organization.toLowerCase().contains(_searchQuery.toLowerCase())).toList(),
                          engagementPlans: _engagementPlans.where((p) => p.stakeholder.toLowerCase().contains(_searchQuery.toLowerCase()) || p.objective.toLowerCase().contains(_searchQuery.toLowerCase())).toList(),
                          isLoadingStakeholders: _loadingStakeholders,
                          isLoadingPlans: _loadingPlans,
                          onAddStakeholder: _addStakeholder,
                          onUpdateStakeholder: _updateStakeholder,
                          onDeleteStakeholder: _deleteStakeholder,
                          onAddPlan: _addEngagementPlan,
                          onUpdatePlan: _updateEngagementPlan,
                          onDeletePlan: _deleteEngagementPlan,
                          searchQuery: _searchQuery,
                          onSearchQueryChanged: (query) => setState(() => _searchQuery = query),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _projectId() => ProjectDataHelper.getData(context).projectId;

  Future<void> _loadStakeholders() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    setState(() => _loadingStakeholders = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('stakeholder_management')
          .doc('stakeholders')
          .get();
      final data = doc.data() ?? {};
      final items = data['items'];
      final entries = _StakeholderEntry.fromList(items);
      if (!mounted) return;
      setState(() {
        _stakeholders
          ..clear()
          ..addAll(entries);
      });
    } catch (error) {
      debugPrint('Failed to load stakeholders: $error');
    } finally {
      if (mounted) setState(() => _loadingStakeholders = false);
    }
  }

  Future<void> _loadEngagementPlans() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    setState(() => _loadingPlans = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('stakeholder_management')
          .doc('engagement_plans')
          .get();
      final data = doc.data() ?? {};
      final items = data['items'];
      final entries = _EngagementPlanEntry.fromList(items);
      if (!mounted) return;
      setState(() {
        _engagementPlans
          ..clear()
          ..addAll(entries);
      });
    } catch (error) {
      debugPrint('Failed to load engagement plans: $error');
    } finally {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  void _scheduleStakeholderSave() {
    _stakeholderSaveDebounce.run(_persistStakeholders);
  }

  void _schedulePlanSave() {
    _planSaveDebounce.run(_persistEngagementPlans);
  }

  Future<void> _persistStakeholders() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    final payload = {
      'items': _stakeholders.map((entry) => entry.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('stakeholder_management')
        .doc('stakeholders')
        .set(payload, SetOptions(merge: true));
  }

  Future<void> _persistEngagementPlans() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    final payload = {
      'items': _engagementPlans.map((entry) => entry.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await FirebaseFirestore.instance
        .collection('projects')
        .doc(projectId)
        .collection('stakeholder_management')
        .doc('engagement_plans')
        .set(payload, SetOptions(merge: true));
  }

  void _addStakeholder() {
    setState(() {
      _stakeholders.add(_StakeholderEntry.empty());
    });
    _scheduleStakeholderSave();
  }

  void _updateStakeholder(_StakeholderEntry updated) {
    final index = _stakeholders.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    setState(() => _stakeholders[index] = updated.copyWith(updatedAt: DateTime.now()));
    _scheduleStakeholderSave();
  }

  void _deleteStakeholder(String id) {
    setState(() => _stakeholders.removeWhere((entry) => entry.id == id));
    _scheduleStakeholderSave();
  }

  void _addEngagementPlan() {
    setState(() {
      _engagementPlans.add(_EngagementPlanEntry.empty());
    });
    _schedulePlanSave();
  }

  void _updateEngagementPlan(_EngagementPlanEntry updated) {
    final index = _engagementPlans.indexWhere((entry) => entry.id == updated.id);
    if (index == -1) return;
    setState(() => _engagementPlans[index] = updated.copyWith(updatedAt: DateTime.now()));
    _schedulePlanSave();
  }

  void _deleteEngagementPlan(String id) {
    setState(() => _engagementPlans.removeWhere((entry) => entry.id == id));
    _schedulePlanSave();
  }
}

class _TopUtilityBar extends StatelessWidget {
  const _TopUtilityBar({required this.onBack});

  final VoidCallback onBack;

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
          _circleButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 12),
          _circleButton(
             icon: Icons.arrow_forward_ios_rounded,
             onTap: () async {
                 final navIndex = PlanningPhaseNavigation.getPageIndex('stakeholder_management');
                 if (navIndex != -1 && navIndex < PlanningPhaseNavigation.pages.length - 1) {
                   final nextPage = PlanningPhaseNavigation.pages[navIndex + 1];
                   Navigator.pushReplacement(context, MaterialPageRoute(builder: nextPage.builder));
                 } else {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No next screen available')));
                 }
             }
          ),
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
    final displayName = FirebaseAuthService.displayNameOrEmail(fallback: name.isNotEmpty ? name : 'User');
    final email = user?.email ?? '';
    final primary = displayName.isNotEmpty ? displayName : (email.isNotEmpty ? email : name);
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
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty
                    ? Text(
                        primary.isNotEmpty ? primary[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(primary, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  Text(roleText, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF9CA3AF)),
            ],
          ),
        );
      },
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.showButtonsBelow, required this.onExport, required this.onAddProject});

  final bool showButtonsBelow;
  final VoidCallback onExport;
  final VoidCallback onAddProject;

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
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Manage stakeholders, communication plans, and engagement strategies',
                    style: TextStyle(fontSize: 15, color: Color(0xFF6B7280), height: 1.5),
                  ),
                ],
              ),
            ),
            if (!showButtonsBelow) buttons,
          ],
        ),
        if (showButtonsBelow) ...[
          const SizedBox(height: 16),
          buttons,
        ],
      ],
    );
  }


}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.isMobile,
    required this.totalStakeholders,
    required this.highInfluenceCount,
  });

  final bool isMobile;
  final int totalStakeholders;
  final int highInfluenceCount;

  @override
  Widget build(BuildContext context) {
    final String totalLabel = totalStakeholders == 0 ? '0' : totalStakeholders.toString();
    final String highInfluenceLabel = totalStakeholders == 0 ? '0' : highInfluenceCount.toString();
    final children = [
      _MetricCard(
        title: 'Total Stakeholders',
        value: totalLabel,
        icon: Icons.people_alt_outlined,
        accentColor: Color(0xFF60A5FA),
      ),
      _MetricCard(
        title: 'High Influence',
        value: highInfluenceLabel,
        icon: Icons.trending_up_rounded,
        accentColor: Color(0xFFF87171),
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
        Expanded(child: children[0]),
        const SizedBox(width: 16),
        Expanded(child: children[1]),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.icon, required this.accentColor});

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
          BoxShadow(color: Color(0x08000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
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
          const Text('Communication Frequency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 16),
          for (var item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 8, color: Color(0xFF111827)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(item, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
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

  final List<_StakeholderEntry> stakeholders;

  @override
  Widget build(BuildContext context) {
    // Quadrants mapping (Power/Influence on Y-axis, Interest on X-axis)
    // 1. Manage Closely (High/High)
    final manageClosely = stakeholders.where((s) => s.influence == 'High' && s.interest == 'High').toList();
    // 2. Keep Satisfied (High Influence, Low/Med Interest)
    final keepSatisfied = stakeholders.where((s) => s.influence == 'High' && (s.interest == 'Low' || s.interest == 'Medium')).toList();
    // 3. Keep Informed (Low/Med Influence, High Interest)
    final keepInformed = stakeholders.where((s) => (s.influence == 'Low' || s.influence == 'Medium') && s.interest == 'High').toList();
    // 4. Monitor (Low/Med Influence, Low/Med Interest)
    final monitor = stakeholders.where((s) => (s.influence == 'Low' || s.influence == 'Medium') && (s.interest == 'Low' || s.interest == 'Medium')).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Influence / Interest Matrix',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4)),
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
                      stakeholders: keepSatisfied,
                    ),
                  ),
                  Expanded(
                    child: _matrixQuadrant(
                      label: 'Manage Closely (Key Players)',
                      color: const Color(0xFFFEF2F2), // Red
                      accentColor: const Color(0xFFEF4444),
                      stakeholders: manageClosely,
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
                      stakeholders: monitor,
                    ),
                  ),
                  Expanded(
                    child: _matrixQuadrant(
                      label: 'Keep Informed',
                      color: const Color(0xFFECFDF5), // Green
                      accentColor: const Color(0xFF10B981),
                      stakeholders: keepInformed,
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
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF9CA3AF)),
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
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF9CA3AF)),
        ),
      ),
    );
  }

  Widget _matrixQuadrant({
    required String label,
    required Color color,
    required Color accentColor,
    required List<_StakeholderEntry> stakeholders,
  }) {
    return Container(
      height: 140,
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accentColor),
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
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: accentColor.withOpacity(0.5)),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: stakeholders.map((s) => _stakeholderChip(s, accentColor)).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stakeholderChip(_StakeholderEntry s, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Text(
        s.name.isEmpty ? 'Unnamed' : s.name,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color.withOpacity(0.8)),
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({required this.title, required this.message, required this.icon});

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

class _EngagementSection extends StatelessWidget {
  const _EngagementSection({
    required this.activeTabIndex,
    required this.onTabChanged,
    required this.stakeholders,
    required this.engagementPlans,
    required this.isLoadingStakeholders,
    required this.isLoadingPlans,
    required this.onAddStakeholder,
    required this.onUpdateStakeholder,
    required this.onDeleteStakeholder,
    required this.onAddPlan,
    required this.onUpdatePlan,
    required this.onDeletePlan,
    required this.searchQuery,
    required this.onSearchQueryChanged,
  });

  final int activeTabIndex;
  final ValueChanged<int> onTabChanged;
  final List<_StakeholderEntry> stakeholders;
  final List<_EngagementPlanEntry> engagementPlans;
  final bool isLoadingStakeholders;
  final bool isLoadingPlans;
  final VoidCallback onAddStakeholder;
  final ValueChanged<_StakeholderEntry> onUpdateStakeholder;
  final ValueChanged<String> onDeleteStakeholder;
  final VoidCallback onAddPlan;
  final ValueChanged<_EngagementPlanEntry> onUpdatePlan;
  final ValueChanged<String> onDeletePlan;
  final String searchQuery;
  final ValueChanged<String> onSearchQueryChanged;

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
                        value: searchQuery,
                        onChanged: onSearchQueryChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: activeTabIndex == 0 ? onAddStakeholder : onAddPlan,
                      icon: const Icon(Icons.add),
                      label: Text(activeTabIndex == 0 ? 'Add stakeholder' : 'Add plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD84D),
                        foregroundColor: const Color(0xFF1F2937),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (activeTabIndex == 0)
                  _StakeholdersTable(
                    entries: stakeholders,
                    isLoading: isLoadingStakeholders,
                    onChanged: onUpdateStakeholder,
                    onDelete: onDeleteStakeholder,
                  )
                else
                  _EngagementPlansTable(
                    entries: engagementPlans,
                    isLoading: isLoadingPlans,
                    onChanged: onUpdatePlan,
                    onDelete: onDeletePlan,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({required String title, required int index}) {
    final bool isActive = activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: index == 0
                ? const BorderRadius.only(topLeft: Radius.circular(20))
                : const BorderRadius.only(topRight: Radius.circular(20)),
            border: Border(
              bottom: BorderSide(color: isActive ? Colors.white : const Color(0xFFE5E7EB), width: 1),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.enabled, required this.value, required this.onChanged});

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
        prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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

  final List<_StakeholderEntry> entries;
  final bool isLoading;
  final ValueChanged<_StakeholderEntry> onChanged;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final columns = [
      const _TableColumnDef('Stakeholder', 200),
      const _TableColumnDef('Organization', 180),
      const _TableColumnDef('Role/Title', 160),
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
                onChanged: (value) => onChanged(entry.copyWith(organization: value)),
              ),
              _TextCell(
                value: entry.role,
                fieldKey: '${entry.id}_role',
                hintText: 'Role/Title',
                onChanged: (value) => onChanged(entry.copyWith(role: value)),
              ),
              _DropdownCell(
                value: entry.influence,
                fieldKey: '${entry.id}_influence',
                options: const ['High', 'Medium', 'Low'],
                onChanged: (value) => onChanged(entry.copyWith(influence: value)),
              ),
              _DropdownCell(
                value: entry.interest,
                fieldKey: '${entry.id}_interest',
                options: const ['High', 'Medium', 'Low'],
                onChanged: (value) => onChanged(entry.copyWith(interest: value)),
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

  final List<_EngagementPlanEntry> entries;
  final bool isLoading;
  final ValueChanged<_EngagementPlanEntry> onChanged;
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
                onChanged: (value) => onChanged(entry.copyWith(stakeholder: value)),
              ),
              _TextCell(
                value: entry.objective,
                fieldKey: '${entry.id}_objective',
                hintText: 'Objective',
                minLines: 1,
                maxLines: 2,
                onChanged: (value) => onChanged(entry.copyWith(objective: value)),
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
                onChanged: (value) => onChanged(entry.copyWith(frequency: value)),
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
                options: const ['Planned', 'In progress', 'At risk', 'Completed'],
                onChanged: (value) => onChanged(entry.copyWith(status: value)),
              ),
              _TextCell(
                value: entry.nextTouchpoint,
                fieldKey: '${entry.id}_next_touchpoint',
                hintText: 'Next touchpoint',
                onChanged: (value) => onChanged(entry.copyWith(nextTouchpoint: value)),
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
        borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
      ),
      child: Row(
        children: columns
            .map((column) => SizedBox(
                  width: column.width,
                  child: Text(
                    column.label.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Color(0xFF6B7280)),
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
          constraints: BoxConstraints(minWidth: columns.fold<double>(0, (sum, col) => sum + col.width)),
          child: Column(
            children: [
              header,
              for (int i = 0; i < rows.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: i.isEven ? Colors.white : const Color(0xFFF9FAFB),
                    border: Border(
                      top: BorderSide(color: const Color(0xFFE5E7EB), width: i == 0 ? 1 : 0.5),
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
          .map((option) => DropdownMenuItem(value: option, child: Text(option, style: const TextStyle(fontSize: 13))))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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

class _StakeholderEntry {
  const _StakeholderEntry({
    required this.id,
    required this.name,
    required this.organization,
    required this.role,
    required this.influence,
    required this.interest,
    required this.channel,
    required this.owner,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String organization;
  final String role;
  final String influence;
  final String interest;
  final String channel;
  final String owner;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory _StakeholderEntry.empty() {
    final now = DateTime.now();
    return _StakeholderEntry(
      id: now.microsecondsSinceEpoch.toString(),
      name: '',
      organization: '',
      role: '',
      influence: 'Medium',
      interest: 'Medium',
      channel: '',
      owner: '',
      notes: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  _StakeholderEntry copyWith({
    String? name,
    String? organization,
    String? role,
    String? influence,
    String? interest,
    String? channel,
    String? owner,
    String? notes,
    DateTime? updatedAt,
  }) {
    return _StakeholderEntry(
      id: id,
      name: name ?? this.name,
      organization: organization ?? this.organization,
      role: role ?? this.role,
      influence: influence ?? this.influence,
      interest: interest ?? this.interest,
      channel: channel ?? this.channel,
      owner: owner ?? this.owner,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'organization': organization,
      'role': role,
      'influence': influence,
      'interest': interest,
      'channel': channel,
      'owner': owner,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static List<_StakeholderEntry> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _StakeholderEntry(
        id: (data['id'] as String?) ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: (data['name'] as String?) ?? '',
        organization: (data['organization'] as String?) ?? '',
        role: (data['role'] as String?) ?? '',
        influence: (data['influence'] as String?) ?? 'Medium',
        interest: (data['interest'] as String?) ?? 'Medium',
        channel: (data['channel'] as String?) ?? '',
        owner: (data['owner'] as String?) ?? '',
        notes: (data['notes'] as String?) ?? '',
        createdAt: _readTimestamp(data['createdAt']) ?? DateTime.now(),
        updatedAt: _readTimestamp(data['updatedAt']) ?? DateTime.now(),
      );
    }).toList();
  }
}

class _EngagementPlanEntry {
  const _EngagementPlanEntry({
    required this.id,
    required this.stakeholder,
    required this.objective,
    required this.method,
    required this.frequency,
    required this.owner,
    required this.status,
    required this.nextTouchpoint,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String stakeholder;
  final String objective;
  final String method;
  final String frequency;
  final String owner;
  final String status;
  final String nextTouchpoint;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory _EngagementPlanEntry.empty() {
    final now = DateTime.now();
    return _EngagementPlanEntry(
      id: now.microsecondsSinceEpoch.toString(),
      stakeholder: '',
      objective: '',
      method: '',
      frequency: '',
      owner: '',
      status: 'Planned',
      nextTouchpoint: '',
      notes: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  _EngagementPlanEntry copyWith({
    String? stakeholder,
    String? objective,
    String? method,
    String? frequency,
    String? owner,
    String? status,
    String? nextTouchpoint,
    String? notes,
    DateTime? updatedAt,
  }) {
    return _EngagementPlanEntry(
      id: id,
      stakeholder: stakeholder ?? this.stakeholder,
      objective: objective ?? this.objective,
      method: method ?? this.method,
      frequency: frequency ?? this.frequency,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      nextTouchpoint: nextTouchpoint ?? this.nextTouchpoint,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stakeholder': stakeholder,
      'objective': objective,
      'method': method,
      'frequency': frequency,
      'owner': owner,
      'status': status,
      'nextTouchpoint': nextTouchpoint,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static List<_EngagementPlanEntry> fromList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) {
      final data = Map<String, dynamic>.from(item);
      return _EngagementPlanEntry(
        id: (data['id'] as String?) ?? DateTime.now().microsecondsSinceEpoch.toString(),
        stakeholder: (data['stakeholder'] as String?) ?? '',
        objective: (data['objective'] as String?) ?? '',
        method: (data['method'] as String?) ?? '',
        frequency: (data['frequency'] as String?) ?? '',
        owner: (data['owner'] as String?) ?? '',
        status: (data['status'] as String?) ?? 'Planned',
        nextTouchpoint: (data['nextTouchpoint'] as String?) ?? '',
        notes: (data['notes'] as String?) ?? '',
        createdAt: _readTimestamp(data['createdAt']) ?? DateTime.now(),
        updatedAt: _readTimestamp(data['updatedAt']) ?? DateTime.now(),
      );
    }).toList();
  }
}

DateTime? _readTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class _Debouncer {
  _Debouncer({Duration? delay}) : delay = delay ?? const Duration(milliseconds: 700);

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
