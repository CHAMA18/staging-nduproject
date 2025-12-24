import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_editable_section.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';

class ProjectCloseOutScreen extends StatefulWidget {
  const ProjectCloseOutScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProjectCloseOutScreen()),
    );
  }

  @override
  State<ProjectCloseOutScreen> createState() => _ProjectCloseOutScreenState();
}

class _ProjectCloseOutScreenState extends State<ProjectCloseOutScreen> {
  final List<LaunchEntry> _closeOutChecklist = [];
  final List<LaunchEntry> _approvals = [];
  final List<LaunchEntry> _archive = [];

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 16 : 32;

    return ResponsiveScaffold(
      activeItemLabel: 'Project Close Out',
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
              title: 'Close-out checklist',
              description: 'Add the tasks you need to finish before the project is closed.',
              entries: _closeOutChecklist,
              onAdd: () => _addEntry(_closeOutChecklist, titleLabel: 'Checklist item', includeStatus: true),
              onRemove: (index) => setState(() => _closeOutChecklist.removeAt(index)),
            ),
            LaunchEditableSection(
              title: 'Approvals & sign-off',
              description: 'Capture approvers, their roles, and confirmation status.',
              entries: _approvals,
              onAdd: () => _addEntry(_approvals, titleLabel: 'Approver', includeStatus: true),
              onRemove: (index) => setState(() => _approvals.removeAt(index)),
            ),
            LaunchEditableSection(
              title: 'Archive & access',
              description: 'List the repositories, documents, and access changes required.',
              entries: _archive,
              onAdd: () => _addEntry(_archive, titleLabel: 'Archive item'),
              onRemove: (index) => setState(() => _archive.removeAt(index)),
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
          'PROJECT CLOSE OUT',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Formally close the project and lock in the outcomes',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'No default content is pre-filled. Use the pop-ups in each section to capture the close-out data you need.',
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
