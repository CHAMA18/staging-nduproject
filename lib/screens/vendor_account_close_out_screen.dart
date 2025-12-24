import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/responsive.dart';

class VendorAccountCloseOutScreen extends StatefulWidget {
  const VendorAccountCloseOutScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VendorAccountCloseOutScreen()),
    );
  }

  @override
  State<VendorAccountCloseOutScreen> createState() => _VendorAccountCloseOutScreenState();
}

class _VendorAccountCloseOutScreenState extends State<VendorAccountCloseOutScreen> {
  final List<LaunchEntry> _snapshot = [];
  final List<LaunchEntry> _steps = [];
  final List<LaunchEntry> _vendors = [];
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
              child: const InitiationLikeSidebar(activeItemLabel: 'Vendor Account Close Out'),
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
                          title: 'Vendor close-out snapshot',
                          description: 'Add counts, notes, or status items that matter to your vendor close-out.',
                          entries: _snapshot,
                          onAdd: () => _addEntry(_snapshot, titleLabel: 'Snapshot item', includeStatus: true),
                          onRemove: (index) => setState(() => _snapshot.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Guided steps',
                          description: 'Capture the sequence you will run to close vendor accounts.',
                          entries: _steps,
                          onAdd: () => _addEntry(_steps, titleLabel: 'Step', includeStatus: true),
                          onRemove: (index) => setState(() => _steps.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Vendors requiring attention',
                          description: 'List vendors with outstanding actions or risks.',
                          entries: _vendors,
                          onAdd: () => _addEntry(_vendors, titleLabel: 'Vendor', includeStatus: true),
                          onRemove: (index) => setState(() => _vendors.removeAt(index)),
                        ),
                        LaunchEditableSection(
                          title: 'Access & sign-off',
                          description: 'Track access removals, ownership, and required approvals.',
                          entries: _signOffs,
                          onAdd: () => _addEntry(_signOffs, titleLabel: 'Approver or action', includeStatus: true),
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
          'Vendor Account Close Out · Guided flow',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'The sections below now start empty. Use the pop-ups to add vendors, steps, and approvals as you work.',
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
