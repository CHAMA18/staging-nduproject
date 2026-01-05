import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class CommerceViabilityScreen extends StatefulWidget {
  const CommerceViabilityScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommerceViabilityScreen()),
    );
  }

  @override
  State<CommerceViabilityScreen> createState() => _CommerceViabilityScreenState();
}

class _CommerceViabilityScreenState extends State<CommerceViabilityScreen> {
  final List<LaunchEntry> _viabilityChecks = [];
  final List<LaunchEntry> _financialSignals = [];
  final List<LaunchEntry> _decisions = [];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: 'Warranties & Operations Support',
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
              title: 'Viability checkpoints',
              description: 'Add the checks you want to run to confirm the business case still holds.',
              entries: _viabilityChecks,
              onAdd: () => _addEntry(_viabilityChecks, titleLabel: 'Checkpoint'),
              onRemove: (index) => setState(() => _viabilityChecks.removeAt(index)),
            ),
            LaunchEditableSection(
              title: 'Financial signals & unit economics',
              description: 'Capture demand, margins, and cost-to-serve data as you collect it.',
              entries: _financialSignals,
              onAdd: () => _addEntry(_financialSignals, titleLabel: 'Signal', includeStatus: true),
              onRemove: (index) => setState(() => _financialSignals.removeAt(index)),
            ),
            LaunchEditableSection(
              title: 'Decisions & recommendations',
              description: 'Record the go / grow / pause call with supporting context.',
              entries: _decisions,
              onAdd: () => _addEntry(_decisions, titleLabel: 'Decision', includeStatus: true),
              onRemove: (index) => setState(() => _decisions.removeAt(index)),
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
          'COMMERCE VIABILITY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check if this solution is commercially sustainable',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'The sections below start empty—use the pop-ups to add the numbers, risks, and decisions you want to track.',
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
