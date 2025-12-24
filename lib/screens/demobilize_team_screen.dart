import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class DemobilizeTeamScreen extends StatefulWidget {
  const DemobilizeTeamScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DemobilizeTeamScreen()),
    );
  }

  @override
  State<DemobilizeTeamScreen> createState() => _DemobilizeTeamScreenState();
}

class _DemobilizeTeamScreenState extends State<DemobilizeTeamScreen> {
  final List<LaunchEntry> _teamRampDown = [];
  final List<LaunchEntry> _knowledgeTransfer = [];
  final List<LaunchEntry> _vendorOffboarding = [];
  final List<LaunchEntry> _communications = [];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: 'Demobilize Team',
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const KazAiChatBubble(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: isMobile ? 16 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(context, isMobile),
            const SizedBox(height: 20),
            LaunchEditableSection(
              title: 'Team ramp-down plan',
              description: 'Add actions and decisions for releasing core team members.',
              entries: _teamRampDown,
              onAdd: () => _addEntry(_teamRampDown, titleLabel: 'Ramp-down item'),
              onRemove: (index) => setState(() => _teamRampDown.removeAt(index)),
            ),
            LaunchEditableSection(
              title: 'Knowledge transfer & handover',
              description: 'Capture the sessions, artifacts, and owners for knowledge capture.',
              entries: _knowledgeTransfer,
              onAdd: () => _addEntry(_knowledgeTransfer, titleLabel: 'Knowledge item'),
              onRemove: (index) => setState(() => _knowledgeTransfer.removeAt(index)),
            ),
            LaunchEditableSection(
              title: 'Vendor & access offboarding',
              description: 'Track vendor exits, tool access clean-up, and remaining obligations.',
              entries: _vendorOffboarding,
              onAdd: () => _addEntry(_vendorOffboarding, titleLabel: 'Offboarding item', includeStatus: true),
              onRemove: (index) => setState(() => _vendorOffboarding.removeAt(index)),
            ),
            LaunchEditableSection(
              title: 'Communications & people care',
              description: 'Log communications, FAQs, and support for impacted people.',
              entries: _communications,
              onAdd: () => _addEntry(_communications, titleLabel: 'Communication item'),
              onRemove: (index) => setState(() => _communications.removeAt(index)),
              showStatusChip: false,
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DEMOBILIZE TEAM',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Wind down the project team responsibly',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Everything below starts blank—use the pop-ups to capture the actions, owners, and safeguards you need.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Future<void> _addEntry(
    List<LaunchEntry> targetList, {
    String titleLabel = 'Title',
    bool includeStatus = true,
  }) async {
    final entry = await showLaunchEntryDialog(
      context,
      titleLabel: titleLabel,
      detailsLabel: 'Details',
      includeStatus: includeStatus,
    );
    if (entry != null && mounted) {
      setState(() => targetList.add(entry));
    }
  }
}
