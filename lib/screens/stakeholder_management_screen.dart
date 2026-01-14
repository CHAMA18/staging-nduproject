import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';

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

  final List<_EngagementPlan> _plans = const [];

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
                        const SizedBox(height: 24),
                        const _ParagraphBlock(
                          title: 'Stakeholder Management Plan',
                          body:
                              'Interface management plan: how interfaces with above stakeholders would be stewarded, Communication Plan: Standard communication method for all stakeholders and frequency by level of improvement.',
                        ),
                        const SizedBox(height: 20),
                        const _ParagraphBlock(
                          title: 'Stakeholder Management Plan',
                          body:
                              'Communication frequency depends on project duration. Should be tailored for stakeholder groups. Meetings integrate with google meet, zoom, Skype or account or any other one. can use name/emails from the personnel and send the invite.',
                        ),
                        const SizedBox(height: 28),
                        _StatsRow(
                          isMobile: isMobile,
                          totalStakeholders: _plans.length,
                        ),
                        const SizedBox(height: 24),
                        _InfoCardsRow(isMobile: isMobile),
                        const SizedBox(height: 24),
                        _InfluenceInterestMatrix(hasData: _plans.isNotEmpty),
                        const SizedBox(height: 28),
                        _EngagementSection(
                          activeTabIndex: _activeTabIndex,
                          onTabChanged: (index) => setState(() => _activeTabIndex = index),
                          plans: _plans,
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
          _circleButton(icon: Icons.arrow_forward_ios_rounded),
          const Spacer(),
          _UserChip(
            name: 'Samuel kamanga',
            role: 'Product manager',
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
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE5E7EB),
            child: Icon(Icons.person, size: 18, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              Text(role, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF9CA3AF)),
        ],
      ),
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
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _outlineButton(label: 'Export', icon: Icons.ios_share_outlined, onPressed: onExport),
        const SizedBox(width: 12),
        _yellowButton(label: 'Add New Project', icon: Icons.add, onPressed: onAddProject),
      ],
    );

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

  static Widget _outlineButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: const Color(0xFF111827)),
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static Widget _yellowButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: const Color(0xFF1F2937)),
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD84D),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ParagraphBlock extends StatelessWidget {
  const _ParagraphBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 10),
        Text(body, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF4B5563))),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.isMobile,
    required this.totalStakeholders,
  });

  final bool isMobile;
  final int totalStakeholders;

  @override
  Widget build(BuildContext context) {
    final String totalLabel = totalStakeholders == 0 ? '0' : totalStakeholders.toString();
    final String highInfluenceLabel = totalStakeholders == 0 ? '—' : '—';
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
  const _InfluenceInterestMatrix({required this.hasData});

  final bool hasData;

  @override
  Widget build(BuildContext context) {
    if (!hasData) {
      return const _SectionEmptyState(
        title: 'No matrix data yet',
        message: 'Add stakeholders to populate the influence-interest matrix.',
        icon: Icons.grid_view_outlined,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: Text('Low Influence', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                ),
                Expanded(
                  child: Text('High Influence', textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                ),
              ],
            ),
          ),
          _matrixRow(
            header: 'High Interest',
            leftLabel: 'Manage Closely',
            rightLabel: 'Manage Closely',
            leftName: 'Sarah Johnson',
            rightName: 'Sarah Johnson',
            leftColor: const Color(0xFFE8F5E9),
            rightColor: const Color(0xFFFDECEA),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _matrixRow(
            header: 'Low interest',
            leftLabel: 'Manage Closely',
            rightLabel: 'Manage Closely',
            leftName: 'Sarah Johnson',
            rightName: 'Sarah Johnson',
            leftColor: const Color(0xFFFDF8E7),
            rightColor: const Color(0xFFFFF7ED),
          ),
        ],
      ),
    );
  }

  static Widget _matrixRow({
    required String header,
    required String leftLabel,
    required String rightLabel,
    required String leftName,
    required String rightName,
    required Color leftColor,
    required Color rightColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              header,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _matrixCell(label: leftLabel, name: leftName, background: leftColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _matrixCell(label: rightLabel, name: rightName, background: rightColor),
          ),
        ],
      ),
    );
  }

  static Widget _matrixCell({required String label, required String name, required Color background}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
        ],
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
    required this.plans,
  });

  final int activeTabIndex;
  final ValueChanged<int> onTabChanged;
  final List<_EngagementPlan> plans;

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
                        enabled: activeTabIndex == 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _FilterButton(label: 'Filter', icon: Icons.filter_list, enabled: activeTabIndex == 1),
                    const SizedBox(width: 12),
                    _FilterButton(label: 'Export', icon: Icons.download_outlined, enabled: activeTabIndex == 1),
                  ],
                ),
                const SizedBox(height: 24),
                if (activeTabIndex == 1)
                  _EngagementTable(plans: plans)
                else
                  const _PlaceholderStakeholders(),
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
  const _SearchField({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: enabled,
      decoration: InputDecoration(
        hintText: 'Search...',
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
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.2),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.icon, required this.enabled});

  final String label;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: enabled ? () {} : null,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        foregroundColor: const Color(0xFF111827),
        backgroundColor: Colors.white,
        disabledForegroundColor: const Color(0xFFBFC5D3),
      ),
    );
  }
}

class _PlaceholderStakeholders extends StatelessWidget {
  const _PlaceholderStakeholders();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: const [
          Icon(Icons.group_outlined, size: 36, color: Color(0xFF9CA3AF)),
          SizedBox(height: 12),
          Text('Stakeholder list view coming soon', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _EngagementTable extends StatelessWidget {
  const _EngagementTable({required this.plans});

  final List<_EngagementPlan> plans;

  @override
  Widget build(BuildContext context) {
    const headers = ['STAKEHOLDER', 'METHOD', 'FREQUENCY', 'OWNER', 'STATUS', 'DESCRIPTION'];

    if (plans.isEmpty) {
      return const _SectionEmptyState(
        title: 'No engagement plans yet',
        message: 'Add engagement plans to define stakeholder touchpoints.',
        icon: Icons.playlist_add_check_outlined,
      );
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Row(
              children: headers
                  .map((header) => Expanded(
                        child: Text(
                          header,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: Color(0xFF6B7280)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          for (int i = 0; i < plans.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : const Color(0xFFF9FAFB),
                border: Border(
                  top: BorderSide(color: const Color(0xFFE5E7EB), width: i == 0 ? 1 : 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(plans[i].stakeholder, style: const TextStyle(fontSize: 13, color: Color(0xFF111827)))),
                  Expanded(child: Text(plans[i].method, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)))),
                  Expanded(child: Text(plans[i].frequency, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)))),
                  Expanded(child: Text(plans[i].owner, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)))),
                  Expanded(child: _statusPill(plans[i].status)),
                  Expanded(
                    child: Text(
                      plans[i].description,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F7EE),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
      ),
    );
  }
}

class _EngagementPlan {
  const _EngagementPlan({
    required this.stakeholder,
    required this.method,
    required this.frequency,
    required this.owner,
    required this.status,
    required this.description,
  });

  final String stakeholder;
  final String method;
  final String frequency;
  final String owner;
  final String status;
  final String description;
}
