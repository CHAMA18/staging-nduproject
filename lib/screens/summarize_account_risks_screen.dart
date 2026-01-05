import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/responsive.dart';

class SummarizeAccountRisksScreen extends StatefulWidget {
  const SummarizeAccountRisksScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SummarizeAccountRisksScreen()),
    );
  }

  @override
  State<SummarizeAccountRisksScreen> createState() => _SummarizeAccountRisksScreenState();
}

class _SummarizeAccountRisksScreenState extends State<SummarizeAccountRisksScreen> {
  final List<LaunchEntry> _accountHealth = [];
  final List<LaunchEntry> _highlights = [];
  final List<LaunchEntry> _risks = [];
  final List<LaunchEntry> _next90Days = [];

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
              child: const InitiationLikeSidebar(activeItemLabel: 'Project Summary'),
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
                          title: 'Account health snapshot',
                          description: 'Add your own health assessment and notes—nothing is pre-filled.',
                          entries: _accountHealth,
                          onAdd: () => _addEntry(_accountHealth, titleLabel: 'Health note', includeStatus: true),
                          onRemove: (index) => setState(() => _accountHealth.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Highlights / what went well',
                          description: 'Capture strengths, wins, and positives from the account.',
                          entries: _highlights,
                          onAdd: () => _addEntry(_highlights, titleLabel: 'Highlight'),
                          onRemove: (index) => setState(() => _highlights.removeAt(index)),
                          showStatusChip: false,
                        ),
                        LaunchEditableSection(
                          title: 'Key delivery risks & issues',
                          description: 'Document risks, owners, and mitigation plans via the pop-up.',
                          entries: _risks,
                          onAdd: () => _addEntry(_risks, titleLabel: 'Risk or issue', includeStatus: true),
                          onRemove: (index) => setState(() => _risks.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Next 90 days focus',
                          description: 'List the immediate follow-ups to keep the account healthy.',
                          entries: _next90Days,
                          onAdd: () => _addEntry(_next90Days, titleLabel: 'Follow-up', includeStatus: true),
                          onRemove: (index) => setState(() => _next90Days.removeAt(index)),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC812),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'SUMMARIZE ACCOUNT & RISKS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'One-page summary of where the account stands at launch',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'All sections are intentionally clear of default data. Use the add buttons to populate the summary via pop-ups.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
                height: 1.5,
                fontSize: 14,
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
