import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/responsive.dart';

class DeliverProjectClosureScreen extends StatefulWidget {
  const DeliverProjectClosureScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DeliverProjectClosureScreen()),
    );
  }

  @override
  State<DeliverProjectClosureScreen> createState() => _DeliverProjectClosureScreenState();
}

class _DeliverProjectClosureScreenState extends State<DeliverProjectClosureScreen> {
  final List<LaunchEntry> _summary = [];
  final List<LaunchEntry> _scopeOutcomes = [];
  final List<LaunchEntry> _risks = [];
  final List<LaunchEntry> _checklist = [];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 18 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Deliver Project'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageHeader(context),
                        const SizedBox(height: 20),
                        LaunchEditableSection(
                          title: 'Closure summary & metrics',
                          description: 'Start from a clean slate. Add the delivery metrics or highlights you want to track.',
                          entries: _summary,
                          onAdd: () => _addEntry(_summary, titleLabel: 'Metric or highlight', includeStatus: true),
                          onRemove: (index) => setState(() => _summary.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Scope outcomes & acceptance',
                          description: 'Record acceptance notes, outcomes, or pending items.',
                          entries: _scopeOutcomes,
                          onAdd: () => _addEntry(_scopeOutcomes, titleLabel: 'Outcome', includeStatus: true),
                          onRemove: (index) => setState(() => _scopeOutcomes.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Risks, gaps, and follow-ups',
                          description: 'Document anything that must be monitored post-delivery.',
                          entries: _risks,
                          onAdd: () => _addEntry(_risks, titleLabel: 'Risk or gap', includeStatus: true),
                          onRemove: (index) => setState(() => _risks.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Final checklist',
                          description: 'Add the tasks required to confirm the project is fully delivered.',
                          entries: _checklist,
                          onAdd: () => _addEntry(_checklist, titleLabel: 'Checklist item', includeStatus: true),
                          onRemove: (index) => setState(() => _checklist.removeAt(index)),
                        ),
                        const SizedBox(height: 48),
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

  Widget _buildPageHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deliver Project · Closure Summary',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'All launch-phase data is now blank by default. Use the add buttons to populate each section from the pop-ups.',
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
