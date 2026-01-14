import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';

class LessonsLearnedScreen extends StatefulWidget {
  const LessonsLearnedScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LessonsLearnedScreen()),
    );
  }

  @override
  State<LessonsLearnedScreen> createState() => _LessonsLearnedScreenState();
}

class _LessonsLearnedScreenState extends State<LessonsLearnedScreen> {

  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  Future<void> _openAddLessonDialog() async {
    final newEntry = await showDialog<_LessonEntry>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _AddLessonDialog(),
    );

    if (newEntry == null || !mounted) return;

    // Convert to LessonRecord and persist
    final lesson = LessonRecord(
      lesson: newEntry.lesson,
      category: newEntry.category,
      type: newEntry.type,
      phase: newEntry.phase,
      status: newEntry.status,
      submittedBy: newEntry.submittedBy,
      notes: '',
      dateSubmitted: DateTime.now(),
    );

    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'lessons_learned',
      dataUpdater: (current) => current.copyWith(
        lessonsLearned: [lesson, ...current.lessonsLearned],
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson added to Project Tasks.')));
  }

  List<_LessonEntry> get _filteredEntries {
    final query = _searchController.text.trim().toLowerCase();

    final data = ProjectDataHelper.getData(context);
    final lessons = data.lessonsLearned;

    final mapped = lessons.map((l) => _LessonEntry(
          id: l.id,
          lesson: l.lesson,
          type: l.type,
          category: l.category,
          phase: l.phase,
          impact: '',
          status: l.status,
          submittedBy: l.submittedBy,
          date: l.dateSubmitted != null ? '${l.dateSubmitted!.year.toString().padLeft(4,'0')}-${l.dateSubmitted!.month.toString().padLeft(2,'0')}-${l.dateSubmitted!.day.toString().padLeft(2,'0')}' : '',
          highlight: false,
        ))
        .toList();

    if (query.isEmpty) return mapped;

    return mapped
        .where((entry) => entry.id.toLowerCase().contains(query) ||
            entry.lesson.toLowerCase().contains(query) ||
            entry.type.toLowerCase().contains(query) ||
            entry.category.toLowerCase().contains(query) ||
            entry.phase.toLowerCase().contains(query) ||
            entry.status.toLowerCase().contains(query) ||
            entry.submittedBy.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = AppBreakpoints.sidebarWidth(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Stack(
        children: [
          SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DraggableSidebar(
                  openWidth: sidebarWidth,
                  child: const InitiationLikeSidebar(activeItemLabel: 'Lessons Learned'),
                ),
                Expanded(child: _buildMainContent(context)),
              ],
            ),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppBreakpoints.pagePadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 24),
          const PlanningAiNotesCard(
            title: 'Notes',
            sectionLabel: 'Lessons Learned',
            noteKey: 'planning_lessons_learned_notes',
            checkpoint: 'lessons_learned',
            description: 'Summarize key lessons, adoption steps, and follow-up actions.',
          ),
          const SizedBox(height: 24),
          _buildSummaryCard(isMobile),
          const SizedBox(height: 24),
          _buildProjectTasksCard(isMobile),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _circularIconButton(Icons.arrow_back_ios_new_outlined),
            const SizedBox(width: 12),
            _circularIconButton(Icons.arrow_forward_ios),
            const SizedBox(width: 16),
            const Expanded(
              child: Center(
                child: Text(
                  'Lessons Learned',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            _profileChip(),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: isMobile ? 0 : 8),
                child: const Text(
                  'Capture and implement knowledge from project experiences',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            if (!isMobile) ...[
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export coming soon.')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Export'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New project action coming soon.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('New Project'),
              ),
            ],
          ],
        ),
        if (isMobile)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export coming soon.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[800],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Export'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New project action coming soon.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('New Project'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lessons Learned',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Capture and implement knowledge from project experiences',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1),
          const SizedBox(height: 20),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _summaryLeftColumn(),
                    const SizedBox(height: 20),
                    _summaryRightColumn(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _summaryLeftColumn()),
                    Container(
                      width: 1,
                      height: 220,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    Expanded(child: _summaryRightColumn()),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _summaryLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are Lessons Learned?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          'Lessons Learned is the knowledge gained from the process of conducting a project. They may be identified at any point during the project\'s life cycle and should capture both positive experiences to repeat and negative experiences to avoid.',
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
        const SizedBox(height: 20),
        _bulletRow(Icons.emoji_events_outlined, 'Successes', 'Positive outcomes and practices to continue'),
        const SizedBox(height: 12),
        _bulletRow(Icons.report_problem_outlined, 'Challenges', 'Issues encountered and how they were addressed'),
        const SizedBox(height: 12),
        _bulletRow(Icons.lightbulb_outline, 'Insights', 'New knowledge or observations that can benefit future projects'),
      ],
    );
  }

  Widget _summaryRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Benefits of Lessons Learned',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _benefitRow('Prevents repeating the same mistakes'),
        const SizedBox(height: 10),
        _benefitRow('Improves future project performance'),
        const SizedBox(height: 10),
        _benefitRow('Enhances organizational knowledge'),
        const SizedBox(height: 10),
        _benefitRow('Promotes continuous improvement culture'),
        const SizedBox(height: 10),
        _benefitRow('Reduces risk in similar future projects'),
        const SizedBox(height: 24),
        Row(
          children: const [
            _SummaryStat(label: 'Successes', value: '4', color: Color(0xFF36C275)),
            SizedBox(width: 16),
            _SummaryStat(label: 'Challenges', value: '4', color: Color(0xFFFFB74D)),
            SizedBox(width: 16),
            _SummaryStat(label: 'Insights', value: '4', color: Color(0xFF5C6BC0)),
          ],
        ),
      ],
    );
  }

  Widget _bulletRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _benefitRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF36C275), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectTasksCard(bool isMobile) {
    final entries = _filteredEntries;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Project Tasks',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (!isMobile)
                Row(
                  children: [
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search...',
                          filled: true,
                          fillColor: Colors.grey.withValues(alpha: 0.1),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Filter options coming soon.')),
                        );
                      },
                      icon: const Icon(Icons.filter_alt_outlined, size: 18),
                      label: const Text('Filter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _openAddLessonDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Lesson'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search...',
                      filled: true,
                      fillColor: Colors.grey.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Filter options coming soon.')),
                            );
                          },
                          icon: const Icon(Icons.filter_alt_outlined, size: 18),
                          label: const Text('Filter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[800],
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openAddLessonDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Lesson'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (entries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.search_off, color: Colors.grey[500], size: 36),
                  const SizedBox(height: 12),
                  Text(
                    'No lessons match your search yet.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            _buildTasksTable(entries),
        ],
      ),
    );
  }

  Widget _buildTasksTable(List<_LessonEntry> entries) {
    const headerStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87);
    const cellStyle = TextStyle(fontSize: 13, color: Colors.black87);
    const subStyle = TextStyle(fontSize: 12, color: Colors.black54);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final tableWidth = math.max(960.0, availableWidth);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: tableWidth, maxWidth: tableWidth),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex: 8, child: Text('#', style: headerStyle)),
                      Expanded(flex: 10, child: Text('ID', style: headerStyle)),
                      Expanded(flex: 30, child: Text('Lesson', style: headerStyle)),
                      Expanded(flex: 16, child: Text('Type', style: headerStyle)),
                      Expanded(flex: 16, child: Text('Category', style: headerStyle)),
                      Expanded(flex: 18, child: Text('Phase', style: headerStyle)),
                      Expanded(flex: 14, child: Text('Impact', style: headerStyle)),
                      Expanded(flex: 18, child: Text('Status', style: headerStyle)),
                      Expanded(flex: 24, child: Text('Submitted By', style: headerStyle)),
                      Expanded(flex: 16, child: Text('Date', style: headerStyle)),
                      Expanded(flex: 10, child: Text('Actions', style: headerStyle, textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < entries.length; i++)
                        Container(
                          decoration: BoxDecoration(
                            color: entries[i].highlight
                                ? Colors.white
                                : Colors.grey.withValues(alpha: 0.05 * ((i % 2) + 1)),
                            borderRadius: i == 0
                                ? const BorderRadius.vertical(top: Radius.circular(16))
                                : i == entries.length - 1
                                    ? const BorderRadius.vertical(bottom: Radius.circular(16))
                                    : BorderRadius.zero,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 8, child: Text('${i + 1}', style: cellStyle)),
                              Expanded(flex: 10, child: Text(entries[i].id, style: cellStyle)),
                              Expanded(
                                flex: 30,
                                child: Text(
                                  entries[i].lesson,
                                  style: cellStyle.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(flex: 16, child: _statusPill(entries[i].type)),
                              Expanded(flex: 16, child: Text(entries[i].category, style: cellStyle)),
                              Expanded(flex: 18, child: Text(entries[i].phase, style: cellStyle)),
                              Expanded(
                                flex: 14,
                                child: Text(
                                  entries[i].impact,
                                  style: entries[i].impact == 'High'
                                      ? cellStyle.copyWith(color: Colors.redAccent)
                                      : cellStyle,
                                ),
                              ),
                              Expanded(flex: 18, child: Text(entries[i].status, style: cellStyle)),
                              Expanded(
                                flex: 24,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(entries[i].submittedBy, style: cellStyle),
                                    Text('Product manager', style: subStyle),
                                  ],
                                ),
                              ),
                              Expanded(flex: 16, child: Text(entries[i].date, style: cellStyle)),
                              Expanded(
                                flex: 10,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                      child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Edit ${entries[i].id} coming soon.')),
                                          );
                                        },
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                                        tooltip: 'Edit lesson',
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          // Delete the lesson from persisted store
                                          final id = entries[i].id;
                                          await ProjectDataHelper.updateAndSave(
                                            context: context,
                                            checkpoint: 'lessons_learned',
                                            dataUpdater: (current) => current.copyWith(
                                              lessonsLearned: current.lessonsLearned.where((l) => l.id != id).toList(),
                                            ),
                                          );
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson deleted.')));
                                        },
                                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                        tooltip: 'Delete lesson',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusPill(String value) {
    Color background;
    Color foreground;
    switch (value.toLowerCase()) {
      case 'success':
        background = const Color(0xFFE8F5E9);
        foreground = const Color(0xFF2E7D32);
        break;
      case 'challenge':
        background = const Color(0xFFFFF3E0);
        foreground = const Color(0xFFF57C00);
        break;
      default:
        background = const Color(0xFFE8EAF6);
        foreground = const Color(0xFF3949AB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _circularIconButton(IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: icon == Icons.arrow_forward_ios ? const Color(0xFFFFD700) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: icon == Icons.arrow_forward_ios ? Colors.black : Colors.grey[800],
        ),
      ),
    );
  }

  Widget _profileChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Samuel kamanga',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                'Product manager',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down, color: Colors.grey[700], size: 18),
        ],
      ),
    );
  }
}

class _AddLessonDialog extends StatefulWidget {
  const _AddLessonDialog();

  @override
  State<_AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<_AddLessonDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _lessonController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _phaseController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  final TextEditingController _submittedByController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _selectedType = 'Success';
  String _selectedImpact = 'Medium';
  bool _highlightRow = false;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _idController.dispose();
    _lessonController.dispose();
    _categoryController.dispose();
    _phaseController.dispose();
    _statusController.dispose();
    _submittedByController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Add Lesson',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in the Project Task details below.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _idController,
                    decoration: _inputDecoration('ID', hintText: 'e.g. T-004'),
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Please provide an ID.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lessonController,
                    decoration: _inputDecoration('Lesson'),
                    textInputAction: TextInputAction.newline,
                    maxLines: 4,
                    minLines: 3,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Please describe the lesson.' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedType,
                          decoration: _inputDecoration('Type'),
                          items: const [
                            DropdownMenuItem(value: 'Success', child: Text('Success')),
                            DropdownMenuItem(value: 'Challenge', child: Text('Challenge')),
                            DropdownMenuItem(value: 'Insight', child: Text('Insight')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedType = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedImpact,
                          decoration: _inputDecoration('Impact'),
                          items: const [
                            DropdownMenuItem(value: 'High', child: Text('High')),
                            DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                            DropdownMenuItem(value: 'Low', child: Text('Low')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedImpact = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _categoryController,
                          decoration: _inputDecoration('Category', hintText: 'e.g. Process'),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Please add a category.' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phaseController,
                          decoration: _inputDecoration('Phase', hintText: 'e.g. Planning'),
                          textInputAction: TextInputAction.next,
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Please add a phase.' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _statusController,
                          decoration: _inputDecoration('Status', hintText: 'e.g. In Review'),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Please provide a status.' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _submittedByController,
                          decoration: _inputDecoration('Submitted By', hintText: 'e.g. Emily Johnson'),
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Please add a name.' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    decoration: _inputDecoration('Date', hintText: 'YYYY-MM-DD').copyWith(
                      suffixIcon: IconButton(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                    readOnly: true,
                    onTap: _pickDate,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Select a date.' : null,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: _highlightRow,
                    onChanged: (value) => setState(() => _highlightRow = value),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Highlight this lesson in the table'),
                    activeColor: const Color(0xFFFFD700),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Add Lesson'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey.withValues(alpha: 0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final entry = _LessonEntry(
      id: _idController.text.trim(),
      lesson: _lessonController.text.trim(),
      type: _selectedType,
      category: _categoryController.text.trim(),
      phase: _phaseController.text.trim(),
      impact: _selectedImpact,
      status: _statusController.text.trim(),
      submittedBy: _submittedByController.text.trim(),
      date: _dateController.text.trim(),
      highlight: _highlightRow,
    );

    Navigator.of(context).pop(entry);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _LessonEntry {
  final String id;
  final String lesson;
  final String type;
  final String category;
  final String phase;
  final String impact;
  final String status;
  final String submittedBy;
  final String date;
  final bool highlight;

  const _LessonEntry({
    required this.id,
    required this.lesson,
    required this.type,
    required this.category,
    required this.phase,
    required this.impact,
    required this.status,
    required this.submittedBy,
    required this.date,
    required this.highlight,
  });
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
