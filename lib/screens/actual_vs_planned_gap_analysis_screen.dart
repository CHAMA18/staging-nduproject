import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class ActualVsPlannedGapAnalysisScreen extends StatefulWidget {
  const ActualVsPlannedGapAnalysisScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ActualVsPlannedGapAnalysisScreen()),
    );
  }

  @override
  State<ActualVsPlannedGapAnalysisScreen> createState() => _ActualVsPlannedGapAnalysisScreenState();
}

class _ActualVsPlannedGapAnalysisScreenState extends State<ActualVsPlannedGapAnalysisScreen> {
  final List<LaunchEntry> _scheduleGaps = [];
  final List<LaunchEntry> _costGaps = [];
  final List<LaunchEntry> _scopeGaps = [];
  final List<LaunchEntry> _benefitsAndCauses = [];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: 'Project Financial Review',
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
              title: 'Schedule gap analysis',
              description: 'Document the biggest timeline variances and what drove them.',
              entries: _scheduleGaps,
              onAdd: () => _addEntry(_scheduleGaps, includeStatus: true, titleLabel: 'Milestone'),
              onRemove: (index) => setState(() => _scheduleGaps.removeAt(index)),
            ),
            LaunchEditableSection(
              title: 'Cost & budget gaps',
              description: 'Capture where spend diverged from plan and the drivers.',
              entries: _costGaps,
              onAdd: () => _addEntry(_costGaps, includeStatus: true, titleLabel: 'Cost item'),
              onRemove: (index) => setState(() => _costGaps.removeAt(index)),
            ),
            LaunchEditableSection(
              title: 'Scope & quality gaps',
              description: 'Note any descoped items, quality issues, or additions.',
              entries: _scopeGaps,
              onAdd: () => _addEntry(_scopeGaps, includeStatus: true, titleLabel: 'Scope item'),
              onRemove: (index) => setState(() => _scopeGaps.removeAt(index)),
            ),
            LaunchEditableSection(
              title: 'Benefits & root causes',
              description: 'Summarize realized benefits and the root causes behind gaps.',
              entries: _benefitsAndCauses,
              onAdd: () => _addEntry(_benefitsAndCauses, includeStatus: true, titleLabel: 'Benefit or cause'),
              onRemove: (index) => setState(() => _benefitsAndCauses.removeAt(index)),
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
          'ACTUAL VS PLANNED GAP ANALYSIS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Compare what was promised vs. what was delivered',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start with a blank slate; add schedule, budget, scope, and benefits data through the pop-ups below.',
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
