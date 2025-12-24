import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/responsive.dart';

class TransitionToProdTeamScreen extends StatefulWidget {
  const TransitionToProdTeamScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransitionToProdTeamScreen()),
    );
  }

  @override
  State<TransitionToProdTeamScreen> createState() => _TransitionToProdTeamScreenState();
}

class _TransitionToProdTeamScreenState extends State<TransitionToProdTeamScreen> {
  final List<LaunchEntry> _transitionSteps = [];
  final List<LaunchEntry> _handoverArtifacts = [];
  final List<LaunchEntry> _signOffs = [];

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
              child: const InitiationLikeSidebar(activeItemLabel: 'Transition To Production Team'),
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
                          title: 'Guided transition steps',
                          description: 'Add the steps you plan to follow to hand over to production.',
                          entries: _transitionSteps,
                          onAdd: () => _addEntry(_transitionSteps, titleLabel: 'Step', includeStatus: true),
                          onRemove: (index) => setState(() => _transitionSteps.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Handover artifacts & tools',
                          description: 'List runbooks, dashboards, or other artifacts needed by Ops/Client.',
                          entries: _handoverArtifacts,
                          onAdd: () => _addEntry(_handoverArtifacts, titleLabel: 'Artifact'),
                          onRemove: (index) => setState(() => _handoverArtifacts.removeAt(index)),
                          showStatusChip: false,
                        ),
                        LaunchEditableSection(
                          title: 'Ops & client sign-offs',
                          description: 'Capture who needs to approve the handover and their status.',
                          entries: _signOffs,
                          onAdd: () => _addEntry(_signOffs, titleLabel: 'Approver', includeStatus: true),
                          onRemove: (index) => setState(() => _signOffs.removeAt(index)),
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
          'Transition to Prod Team · Guided flow',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Launch-phase data is now empty by default. Use the pop-ups to add the steps, artifacts, and approvals you need.',
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
