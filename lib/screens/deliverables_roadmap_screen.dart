import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/initiation_like_sidebar.dart';
import '../widgets/draggable_sidebar.dart';
import '../widgets/kaz_ai_chat_bubble.dart';
import '../widgets/responsive.dart';
import '../widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'front_end_planning_personnel_screen.dart';

const Color _kBackground = Color(0xFFF7F8FC);
const Color _kAccent = Color(0xFFFFC812);
const Color _kHeadline = Color(0xFF1A1D1F);
const Color _kMuted = Color(0xFF6B7280);
const Color _kCardBorder = Color(0xFFE4E7EC);
const double _kColumnGap = 22;

class DeliverablesRoadmapScreen extends StatelessWidget {
  const DeliverablesRoadmapScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DeliverablesRoadmapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: Stack(
        children: [
          SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: AppBreakpoints.sidebarWidth(context),
                  child: const InitiationLikeSidebar(activeItemLabel: 'Deliverable Roadmap'),
                ),
                const Expanded(child: _DeliverablesRoadmapBody()),
              ],
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }
}

class _DeliverablesRoadmapBody extends StatefulWidget {
  const _DeliverablesRoadmapBody();

  @override
  State<_DeliverablesRoadmapBody> createState() => _DeliverablesRoadmapBodyState();
}

enum _DeliverableStatus { completed, inProgress, planned, notStarted }

class _DeliverableItem {
  const _DeliverableItem({
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.dueDate,
    required this.status,
  });

  final String title;
  final String description;
  final String assignedTo;
  final String dueDate;
  final _DeliverableStatus status;
}

class _SprintConfig {
  const _SprintConfig({
    required this.heading,
    required this.summaryLabel,
    required this.summaryColor,
  }) : allowAdd = false;

  final String heading;
  final String summaryLabel;
  final Color summaryColor;
  final bool allowAdd;
}

class _DeliverablesRoadmapBodyState extends State<_DeliverablesRoadmapBody> {
  late final Map<int, List<_DeliverableItem>> _sprintItems = {};

  final List<_SprintConfig> _sprints = const [];

  Color _statusColor(_DeliverableStatus status) {
    switch (status) {
      case _DeliverableStatus.completed:
        return const Color(0xFF34D399);
      case _DeliverableStatus.inProgress:
        return const Color(0xFFF97316);
      case _DeliverableStatus.planned:
        return const Color(0xFF6B7280);
      case _DeliverableStatus.notStarted:
        return const Color(0xFFEF4444);
    }
  }

  String _statusLabel(_DeliverableStatus status) {
    switch (status) {
      case _DeliverableStatus.completed:
        return 'Completed';
      case _DeliverableStatus.inProgress:
        return 'In Progress';
      case _DeliverableStatus.planned:
        return 'Planned';
      case _DeliverableStatus.notStarted:
        return 'Not Started';
    }
  }

  Widget _buildArrowButton({required IconData icon, required Color background, required Color borderColor, Color? iconColor}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        boxShadow: [
          if (background == Colors.white)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Icon(icon, size: 20, color: iconColor ?? _kHeadline),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _displayName(user);
    final subtitle = _displaySubtitle(user);
    final initials = _initialsFor(displayName);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildArrowButton(
          icon: Icons.arrow_back_ios_new,
          background: Colors.white,
          borderColor: _kCardBorder,
        ),
        const SizedBox(width: 10),
        _buildArrowButton(
          icon: Icons.autorenew,
          background: _kAccent.withOpacity(0.2),
          borderColor: _kAccent,
          iconColor: const Color(0xFFD97706),
        ),
        const SizedBox(width: 24),
        const Expanded(
          child: Center(
            child: Text(
              'Deliverables Roadmap',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _kHeadline),
            ),
          ),
        ),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kCardBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _kAccent,
                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w800, color: _kHeadline)),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kHeadline)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kMuted)),
                ],
              ),
              const SizedBox(width: 12),
              const Icon(Icons.keyboard_arrow_down_rounded, color: _kMuted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusLabel(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildStatusChip(_DeliverableStatus status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDeliverableCard(_DeliverableItem item) {
    final assignedLabel = item.assignedTo.isNotEmpty ? 'Tasked: ${item.assignedTo}' : 'Tasked: -';
    final dueLabel = item.dueDate.isNotEmpty ? item.dueDate : 'No due date';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 240;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 10,
                      decoration: BoxDecoration(
                        color: _statusColor(item.status),
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCompact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _kHeadline),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          _buildStatusChip(item.status),
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _kHeadline),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusChip(item.status),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Text(
                      item.description,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kMuted),
                    ),
                    const SizedBox(height: 20),
                    if (isCompact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignedLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            dueLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              assignedLabel,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            dueLabel,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _displayName(User? user) {
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return 'Guest';
  }

  String _displaySubtitle(User? user) {
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return 'Signed in';
  }

  String _initialsFor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\\s+'));
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    final first = parts.first.characters.first.toUpperCase();
    final last = parts.last.characters.first.toUpperCase();
    return '$first$last';
  }

  Widget _buildHeading(String heading) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kHeadline),
        children: [
          TextSpan(text: heading.split('(').first),
          if (heading.contains('('))
            TextSpan(
              text: heading.substring(heading.indexOf('(')),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildColumn(int index) {
    final config = _sprints[index];
    final items = _sprintItems[index] ?? <_DeliverableItem>[];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4FA),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _buildHeading(config.heading)),
              if (config.allowAdd)
                GestureDetector(
                  onTap: () => _handleAddDeliverable(index),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kCardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, size: 18, color: _kHeadline),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatusLabel(config.summaryLabel, config.summaryColor),
          const SizedBox(height: 20),
          for (final item in items) _buildDeliverableCard(item),
        ],
      ),
    );
  }

  Widget _buildColumns(double maxWidth) {
    final columnCount = _sprints.length;
    final totalGap = _kColumnGap * (columnCount - 1);
    final computedWidth = (maxWidth - totalGap) / columnCount;
    final needsHorizontalScroll = computedWidth < 230;
    final resolvedWidth = needsHorizontalScroll ? 230.0 : computedWidth;

    List<Widget> buildRowChildren() {
      return [
        for (var i = 0; i < columnCount; i++) ...[
          SizedBox(width: resolvedWidth, child: _buildColumn(i)),
          if (i != columnCount - 1) const SizedBox(width: _kColumnGap),
        ],
      ];
    }

    if (needsHorizontalScroll) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: buildRowChildren(),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: buildRowChildren(),
    );
  }

  Future<void> _handleAddDeliverable(int index) async {
    final newItem = await _openAddDeliverableDialog(context);
    if (newItem == null) {
      return;
    }

    setState(() {
      _sprintItems[index]?.add(newItem);
    });
  }

  Future<_DeliverableItem?> _openAddDeliverableDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final assignedController = TextEditingController();
    final dueDateController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var selectedStatus = _DeliverableStatus.inProgress;

    _DeliverableItem? result;

    await showDialog<_DeliverableItem>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Text(
            'Create Deliverable',
            style: TextStyle(fontWeight: FontWeight.w800, color: _kHeadline),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Deliverable Title'),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        minLines: 2,
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: assignedController,
                        decoration: const InputDecoration(labelText: 'Assigned To'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please specify who is assigned';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dueDateController,
                        decoration: const InputDecoration(labelText: 'Due Date'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please set a due date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_DeliverableStatus>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: _DeliverableStatus.values
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(_statusLabel(status)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setStateDialog(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }
                result = _DeliverableItem(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  assignedTo: assignedController.text.trim(),
                  dueDate: dueDateController.text.trim(),
                  status: selectedStatus,
                );
                Navigator.of(dialogContext).pop(result);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: _kHeadline,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      color: _kBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          const PlanningAiNotesCard(
            title: 'Notes',
            sectionLabel: 'Deliverable Roadmap',
            noteKey: 'planning_deliverable_roadmap_notes',
            checkpoint: 'deliverable_roadmap',
            description: 'Summarize roadmap milestones, delivery pacing, and risk flags.',
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: _sprints.isEmpty
                      ? const _EmptyStateCard(
                          title: 'No sprint roadmap yet',
                          message: 'Add roadmap deliverables to visualize sprint pacing.',
                          icon: Icons.view_week_outlined,
                        )
                      : _buildColumns(constraints.maxWidth),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          LaunchPhaseNavigation(
            backLabel: 'Back: Start-Up Planning',
            nextLabel: 'Next: Personnel',
            onBack: () => Navigator.of(context).maybePop(),
            onNext: () => FrontEndPlanningPersonnelScreen.open(context),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.title, required this.message, required this.icon});

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
        border: Border.all(color: _kCardBorder),
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
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kHeadline)),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(fontSize: 12, color: _kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
