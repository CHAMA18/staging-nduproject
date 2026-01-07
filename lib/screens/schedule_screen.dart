import 'dart:async';
import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/services/openai_service_secure.dart';

/// Schedule screen recreated to match the provided mockup with
/// notes input, schedule management overview, and project timeline.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
    );
  }

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TextEditingController _notesController = TextEditingController();
  String _selectedMethodology = 'Waterfall';
  int _timelineTabIndex = 0;
  Timer? _saveDebounce;
  DateTime? _lastSavedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ProjectDataHelper.getData(context);
      _notesController.text = data.planningNotes['planning_schedule_notes'] ?? '';
      if (_notesController.text.trim().isEmpty) {
        _generateInitialNotes();
      }
      _notesController.addListener(_handleNotesChanged);
    });
  }

  Future<void> _generateInitialNotes() async {
    final data = ProjectDataHelper.getData(context);
    final contextText = ProjectDataHelper.buildFepContext(data, sectionLabel: 'Schedule');
    if (contextText.trim().isEmpty) return;
    final ai = OpenAiServiceSecure();
    final suggestion = await ai.generateFepSectionText(
      section: 'Schedule',
      context: contextText,
      maxTokens: 700,
      temperature: 0.45,
    );
    if (!mounted) return;
    if (_notesController.text.trim().isEmpty && suggestion.trim().isNotEmpty) {
      _notesController.text = suggestion.trim();
    }
  }

  void _handleNotesChanged() {
    final value = _notesController.text.trim();
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () async {
      final success = await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'planning_schedule',
        dataUpdater: (data) => data.copyWith(
          planningNotes: {
            ...data.planningNotes,
            'planning_schedule_notes': value,
          },
        ),
        showSnackbar: false,
      );
      if (mounted && success) {
        setState(() => _lastSavedAt = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _notesController.removeListener(_handleNotesChanged);
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Schedule'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 20 : 32,
                      28,
                      isMobile ? 20 : 32,
                      120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PlanningPhaseHeader(
                          title: 'Schedule',
                          onBack: () => Navigator.maybePop(context),
                          showImportButton: false,
                          showContentButton: false,
                        ),
                        const SizedBox(height: 24),
                        _NotesInputField(
                          controller: _notesController,
                          savedAt: _lastSavedAt,
                        ),
                        const SizedBox(height: 24),
                        _ScheduleManagementCard(
                          methodology: _selectedMethodology,
                          onMethodologyChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedMethodology = value);
                            }
                          },
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 24),
                        _ProjectTimelineCard(
                          selectedTab: _timelineTabIndex,
                          onTabChanged: (index) => setState(() => _timelineTabIndex = index),
                        ),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                  const AdminEditToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesInputField extends StatelessWidget {
  const _NotesInputField({required this.controller, this.savedAt});

  final TextEditingController controller;
  final DateTime? savedAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(color: Color(0x11000000), blurRadius: 14, offset: Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Input your notes here...',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
        if (savedAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Saved ${TimeOfDay.fromDateTime(savedAt!).format(context)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ],
    );
  }
}

class _ScheduleManagementCard extends StatelessWidget {
  const _ScheduleManagementCard({
    required this.methodology,
    required this.onMethodologyChanged,
    required this.isMobile,
  });

  final String methodology;
  final ValueChanged<String?> onMethodologyChanged;
  final bool isMobile;

  static const List<String> _methodologies = ['Waterfall', 'Agile', 'Hybrid'];

  static const List<_ScheduleMetric> _metrics = [];
  static const List<_TeamUtilization> _teamUtilization = [];
  static const List<_WbsNode> _wbsNodes = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompact = constraints.maxWidth < 720;
              final Widget dropdown = _MethodologyDropdown(
                value: methodology,
                onChanged: onMethodologyChanged,
              );
              final Widget actions = _ScheduleActions(isCompact: isCompact);

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule Management',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 8),
                    dropdown,
                    const SizedBox(height: 16),
                    actions,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      'Schedule Management',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  dropdown,
                  const SizedBox(width: 20),
                  Flexible(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: actions,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 24),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryPanel(metrics: _metrics, utilization: _teamUtilization),
                const SizedBox(height: 24),
                _WbsSection(nodes: _wbsNodes),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 260,
                  child: _SummaryPanel(metrics: _metrics, utilization: _teamUtilization),
                ),
                const SizedBox(width: 28),
                Expanded(child: _WbsSection(nodes: _wbsNodes)),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScheduleActions extends StatelessWidget {
  const _ScheduleActions({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: isCompact ? WrapAlignment.start : WrapAlignment.end,
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.diversity_3_outlined, size: 18, color: Color(0xFF4B5563)),
          label: const Text('Team', style: TextStyle(color: Color(0xFF111827))),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.trending_up_outlined, size: 18, color: Color(0xFF4B5563)),
          label: const Text('Estimates', style: TextStyle(color: Color(0xFF111827))),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: const Text('Import'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('New Task'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB020),
            foregroundColor: const Color(0xFF111827),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ],
    );
  }
}

class _MethodologyDropdown extends StatelessWidget {
  const _MethodologyDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4B5563)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w600),
          onChanged: onChanged,
          items: _ScheduleManagementCard._methodologies
              .map((option) => DropdownMenuItem<String>(value: option, child: Text(option)))
              .toList(),
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.metrics, required this.utilization});

  final List<_ScheduleMetric> metrics;
  final List<_TeamUtilization> utilization;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E9FF)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...metrics.map((metric) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _MetricTile(metric: metric),
              )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCD9BD)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Critical Path Identified',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF9A3412)),
                ),
                SizedBox(height: 6),
                Text(
                  '4 dependencies impact project delivery. Review overlaps with integration tasks.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('Manage Dependencies'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Team Utilization',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 12),
          ...utilization.map((data) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _UtilizationBar(data: data),
              )),
        ],
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({required this.title, required this.message, required this.icon});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _ScheduleMetric metric;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(metric.icon, color: const Color(0xFF1D4ED8)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                metric.value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 4),
              Text(
                metric.caption,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UtilizationBar extends StatelessWidget {
  const _UtilizationBar({required this.data});

  final _TeamUtilization data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(data.label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            Text('${(data.percent * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: data.percent,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(data.color),
          ),
        ),
      ],
    );
  }
}

class _WbsSection extends StatelessWidget {
  const _WbsSection({required this.nodes});

  final List<_WbsNode> nodes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Work Breakdown Structure',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'All Disciplines',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFBFCFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: nodes.map((node) => _WbsTreeTile(node: node)).toList(),
          ),
        ),
      ],
    );
  }
}

class _WbsTreeTile extends StatelessWidget {
  const _WbsTreeTile({required this.node, this.level = 0});

  final _WbsNode node;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: level * 22.0, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: node.highlight ? const Color(0xFFFFFBEB) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              if (node.children.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B7280)),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFCBD5F5), shape: BoxShape.circle),
                  ),
                ),
              Expanded(
                child: Text(
                  node.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
              ),
              if (node.badges.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: node.badges
                      .map((badge) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: badge.backgroundColor,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: badge.borderColor ?? Colors.transparent),
                            ),
                            child: Text(
                              badge.label,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badge.textColor),
                            ),
                          ))
                      .toList(),
                ),
              if (node.duration != null) ...[
                const SizedBox(width: 12),
                Text(
                  node.duration!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                ),
              ],
            ],
          ),
        ),
        if (node.children.isNotEmpty)
          ...node.children.map((child) => _WbsTreeTile(node: child, level: level + 1)),
      ],
    );
  }
}

class _ProjectTimelineCard extends StatelessWidget {
  const _ProjectTimelineCard({required this.selectedTab, required this.onTabChanged});

  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  static const List<String> _tabs = ['Gantt Chart', 'List', 'Board'];

  static const List<_TimelineItem> _timelineItems = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ProjectTimeline',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _tabs.length; i++)
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                        child: ChoiceChip(
                          label: Text(_tabs[i]),
                          selected: selectedTab == i,
                          onSelected: (_) => onTabChanged(i),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selectedTab == i ? Colors.white : const Color(0xFF4B5563),
                          ),
                          selectedColor: const Color(0xFF111827),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('View:', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: 'Days',
                    items: const [
                      DropdownMenuItem(value: 'Days', child: Text('Days')),
                      DropdownMenuItem(value: 'Weeks', child: Text('Weeks')),
                      DropdownMenuItem(value: 'Months', child: Text('Months')),
                    ],
                    onChanged: (_) {},
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF2563EB)),
                label: const Text('Validate', style: TextStyle(color: Color(0xFF2563EB))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.file_upload_outlined, color: Color(0xFF4B5563)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_timelineItems.isEmpty)
            const _SectionEmptyState(
              title: 'No timeline data yet',
              message: 'Add schedule items to view Gantt, list, or board timelines.',
              icon: Icons.timeline_outlined,
            )
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selectedTab == 0
                  ? _TimelineGanttView(items: _timelineItems)
                  : selectedTab == 1
                      ? _TimelineListView(items: _timelineItems)
                      : _TimelineBoardView(items: _timelineItems),
            ),
        ],
      ),
    );
  }
}

class _TimelineGanttView extends StatelessWidget {
  const _TimelineGanttView({required this.items});

  final List<_TimelineItem> items;

  static const int _totalWeeks = 52;
  static const double _weekWidth = 28;
  static const double _rowHeight = 46;
  static const double _chartPaddingTop = 32;

  @override
  Widget build(BuildContext context) {
    final double timelineWidth = _totalWeeks * _weekWidth;
    final double chartHeight = _chartPaddingTop + (items.length * _rowHeight) + 32;
    final DateTime start = DateTime(2024, 1, 1);
    final DateTime end = DateTime(2024, 12, 31);
    final List<_TimelineSegment> months = _generateMonthSegments(start, end);
    final List<_TimelineSegment> weeks = _generateWeekSegments(start, end);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: timelineWidth + 140,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('2024', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                        SizedBox(height: 6),
                        Text('Week', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: timelineWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: months
                              .map((segment) => Container(
                                    width: segment.dayCount / 7 * _weekWidth,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(segment.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: weeks
                              .map((segment) => Container(
                                    width: segment.dayCount / 7 * _weekWidth,
                                    alignment: Alignment.center,
                                    child: Text(segment.label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            SizedBox(
              height: chartHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TimelineGridPainter(
                        totalWeeks: _totalWeeks,
                        weekWidth: _weekWidth,
                        rowHeight: _rowHeight,
                        itemCount: items.length,
                      ),
                    ),
                  ),
                  for (int index = 0; index < items.length; index++)
                    _TimelineRow(
                      item: items[index],
                      index: index,
                      weekWidth: _weekWidth,
                      timelineWidth: timelineWidth,
                      rowHeight: _rowHeight,
                      topOffset: _chartPaddingTop,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineListView extends StatelessWidget {
  const _TimelineListView({required this.items});

  final List<_TimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('timeline_list_view'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const _TimelineListHeader(),
          const SizedBox(height: 8),
          ...items.map((item) => _TimelineListRow(item: item)),
        ],
      ),
    );
  }
}

class _TimelineListHeader extends StatelessWidget {
  const _TimelineListHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: Text(
            'Item',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
        ),
        SizedBox(
          width: 110,
          child: Text(
            'Start',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
        ),
        SizedBox(
          width: 100,
          child: Text(
            'Duration',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
        ),
        SizedBox(
          width: 120,
          child: Text(
            'Status',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }
}

class _TimelineListRow extends StatelessWidget {
  const _TimelineListRow({required this.item});

  final _TimelineItem item;

  String _statusLabel() {
    if (item.isMilestone) return 'Milestone';
    if (item.progress >= 1) return 'Done';
    if (item.progress > 0) return 'In Progress';
    return 'Not Started';
  }

  Color _statusColor() {
    if (item.isMilestone) return const Color(0xFF2563EB);
    if (item.progress >= 1) return const Color(0xFF10B981);
    if (item.progress > 0) return const Color(0xFFF59E0B);
    return const Color(0xFF9CA3AF);
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel();
    final color = _statusColor();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  ),
                ),
                if (item.isCritical)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Critical',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              'Week ${item.startWeek}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              '${item.durationWeeks}w',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          SizedBox(
            width: 120,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineBoardView extends StatelessWidget {
  const _TimelineBoardView({required this.items});

  final List<_TimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final todo = items.where((item) => item.progress == 0).toList();
    final inProgress = items.where((item) => item.progress > 0 && item.progress < 1).toList();
    final done = items.where((item) => item.progress >= 1).toList();

    return Container(
      key: const ValueKey<String>('timeline_board_view'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _TimelineBoardColumn(title: 'To Do', items: todo, background: const Color(0xFFF5F7FE)),
            const SizedBox(width: 16),
            _TimelineBoardColumn(title: 'In Progress', items: inProgress, background: const Color(0xFFEAF4FF)),
            const SizedBox(width: 16),
            _TimelineBoardColumn(title: 'Done', items: done, background: const Color(0xFFE9F9F2)),
          ],
        ),
      ),
    );
  }
}

class _TimelineBoardColumn extends StatelessWidget {
  const _TimelineBoardColumn({required this.title, required this.items, required this.background});

  final String title;
  final List<_TimelineItem> items;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  items.length.toString(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('No items', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))
          else
            ...items.map((item) => _TimelineBoardCard(item: item)),
        ],
      ),
    );
  }
}

class _TimelineBoardCard extends StatelessWidget {
  const _TimelineBoardCard({required this.item});

  final _TimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              if (item.isCritical)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Critical',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Start Week ${item.startWeek} • ${item.durationWeeks}w',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: item.isMilestone ? 0 : item.progress,
            minHeight: 6,
            color: item.color,
            backgroundColor: const Color(0xFFE5E7EB),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.item,
    required this.index,
    required this.weekWidth,
    required this.timelineWidth,
    required this.rowHeight,
    required this.topOffset,
  });

  final _TimelineItem item;
  final int index;
  final double weekWidth;
  final double timelineWidth;
  final double rowHeight;
  final double topOffset;

  @override
  Widget build(BuildContext context) {
    final double top = topOffset + (index * rowHeight);
    final double left = (item.startWeek - 1) * weekWidth;
    final double width = item.durationWeeks * weekWidth;

    if (item.isMilestone) {
      return Positioned(
        top: top + (rowHeight / 2) - 4,
        left: left.clamp(0.0, timelineWidth - 12),
        child: Column(
          children: [
            Transform.rotate(
              angle: 0.785398, // 45 degrees in radians
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6)),
                ],
              ),
              child: Text(
                item.label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              ),
            ),
          ],
        ),
      );
    }

    return Positioned(
      top: top + 8,
      left: left.clamp(0.0, timelineWidth - 40),
      child: Container(
        width: width.clamp(60.0, timelineWidth),
        height: rowHeight - 16,
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
          border: item.isCritical
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.18),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.progressLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: item.progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineGridPainter extends CustomPainter {
  const _TimelineGridPainter({
    required this.totalWeeks,
    required this.weekWidth,
    required this.rowHeight,
    required this.itemCount,
  });

  final int totalWeeks;
  final double weekWidth;
  final double rowHeight;
  final int itemCount;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint verticalPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (int week = 0; week <= totalWeeks; week++) {
      final double x = 80 + (week * weekWidth);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), verticalPaint);
    }

    final Paint horizontalPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..strokeWidth = 1;
    for (int row = 0; row <= itemCount; row++) {
      final double y = _TimelineGanttView._chartPaddingTop + (row * rowHeight);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), horizontalPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScheduleMetric {
  const _ScheduleMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
}

class _TeamUtilization {
  const _TeamUtilization({required this.label, required this.percent, required this.color});

  final String label;
  final double percent;
  final Color color;
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color? borderColor;
}

class _WbsNode {
  const _WbsNode({
    required this.title,
    this.duration,
    this.badges = const [],
    this.children = const [],
    this.highlight = false,
  });

  final String title;
  final String? duration;
  final List<_BadgeStyle> badges;
  final List<_WbsNode> children;
  final bool highlight;
}

class _TimelineItem {
  const _TimelineItem({
    required this.label,
    required this.progressLabel,
    required this.startWeek,
    required this.durationWeeks,
    required this.color,
    this.progress = 0,
    this.isCritical = false,
    this.isMilestone = false,
  });

  const _TimelineItem.milestone({
    required this.label,
    required this.startWeek,
    required this.color,
  })  : progressLabel = label,
        durationWeeks = 1,
        progress = 0,
        isCritical = false,
        isMilestone = true;

  final String label;
  final String progressLabel;
  final int startWeek;
  final int durationWeeks;
  final Color color;
  final double progress;
  final bool isCritical;
  final bool isMilestone;
}

class _TimelineSegment {
  const _TimelineSegment({required this.label, required this.dayCount});

  final String label;
  final int dayCount;
}

List<_TimelineSegment> _generateMonthSegments(DateTime start, DateTime end) {
  final List<_TimelineSegment> segments = <_TimelineSegment>[];
  final DateTime inclusiveEnd = DateTime(end.year, end.month, end.day);
  DateTime cursor = DateTime(start.year, start.month, 1);

  while (!cursor.isAfter(inclusiveEnd)) {
    final DateTime bucketStart = cursor.isBefore(start) ? start : cursor;
    final DateTime nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
    final DateTime bucketEnd = nextMonth.subtract(const Duration(days: 1));
    final DateTime actualEnd = bucketEnd.isAfter(inclusiveEnd) ? inclusiveEnd : bucketEnd;
    final int dayCount = actualEnd.difference(bucketStart).inDays + 1;
    segments.add(_TimelineSegment(label: _formatMonth(cursor), dayCount: dayCount));
    cursor = nextMonth;
  }

  return segments;
}

List<_TimelineSegment> _generateWeekSegments(DateTime start, DateTime end) {
  final List<_TimelineSegment> segments = <_TimelineSegment>[];
  final DateTime inclusiveEnd = DateTime(end.year, end.month, end.day);
  DateTime cursor = start;

  int weekNumber = 1;
  while (!cursor.isAfter(inclusiveEnd)) {
    final DateTime potentialEnd = cursor.add(const Duration(days: 6));
    final DateTime actualEnd = potentialEnd.isAfter(inclusiveEnd) ? inclusiveEnd : potentialEnd;
    final int dayCount = actualEnd.difference(cursor).inDays + 1;
    segments.add(_TimelineSegment(label: '$weekNumber', dayCount: dayCount));
    weekNumber++;
    cursor = actualEnd.add(const Duration(days: 1));
  }

  return segments;
}

String _formatMonth(DateTime date) {
  const List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[date.month - 1];
}
