import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/responsive.dart';

class ContractCloseOutScreen extends StatefulWidget {
  const ContractCloseOutScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContractCloseOutScreen()),
    );
  }

  @override
  State<ContractCloseOutScreen> createState() => _ContractCloseOutScreenState();
}

class _ContractCloseOutScreenState extends State<ContractCloseOutScreen> {
  final List<LaunchEntry> _summary = [];
  final List<LaunchEntry> _steps = [];
  final List<LaunchEntry> _contracts = [];
  final List<LaunchEntry> _signoffs = [];

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
              child: const InitiationLikeSidebar(activeItemLabel: 'Contract Close Out'),
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
                          title: 'Close-out summary',
                          description: 'Add the headline status and metrics you want to track—no defaults are pre-filled.',
                          entries: _summary,
                          onAdd: () => _addEntry(_summary, titleLabel: 'Summary item', includeStatus: true),
                          onRemove: (index) => setState(() => _summary.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Guided close-out steps',
                          description: 'Capture the steps you will follow to close contracts.',
                          entries: _steps,
                          onAdd: () => _addEntry(_steps, titleLabel: 'Step', includeStatus: true),
                          onRemove: (index) => setState(() => _steps.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Contracts needing attention',
                          description: 'List contracts or vendors with notes and status.',
                          entries: _contracts,
                          onAdd: () => _addEntry(_contracts, titleLabel: 'Contract or vendor', includeStatus: true),
                          onRemove: (index) => setState(() => _contracts.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Financial & compliance sign-off',
                          description: 'Track who needs to sign and the state of finance/compliance items.',
                          entries: _signoffs,
                          onAdd: () => _addEntry(_signoffs, titleLabel: 'Approver', includeStatus: true),
                          onRemove: (index) => setState(() => _signoffs.removeAt(index)),
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
          'Contract Close Out · Guided flow',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Launch-phase pages are now empty by default. Use the add buttons to populate each section through pop-ups.',
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
