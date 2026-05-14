import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/roadmap_sprint.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/roadmap_service.dart';
import 'package:ndu_project/services/agile_wireframe_service.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';

const Color _kBackground = Color(0xFFF9FAFC);
const Color _kBorder = Color(0xFFE5E7EB);
const Color _kMuted = Color(0xFF6B7280);
const Color _kHeadline = Color(0xFF111827);
const Color _kAccent = Color(0xFFD97706);

class AgileSprintCalendarScreen extends StatefulWidget {
  const AgileSprintCalendarScreen({super.key});

  @override
  State<AgileSprintCalendarScreen> createState() =>
      _AgileSprintCalendarScreenState();
}

class _AgileSprintCalendarScreenState
    extends State<AgileSprintCalendarScreen> {
  List<RoadmapSprint> _sprints = [];
  bool _isLoading = true;
  TextEditingController _ceremonyController = TextEditingController();
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  Timer? _saveDebounce;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  List<RoadmapSprint> get _filteredSprints {
    if (_searchQuery.isEmpty) return _sprints;
    final q = _searchQuery.toLowerCase();
    return _sprints.where((s) =>
      s.name.toLowerCase().contains(q) ||
      s.goal.toLowerCase().contains(q)
    ).toList();
  }

  String? get _projectId {
    try {
      return ProjectDataInherited.maybeOf(context)?.projectData.projectId;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _ceremonyController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final pid = _projectId;
    if (pid == null) return;
    setState(() => _isLoading = true);
    try {
      final sprints = await RoadmapService.loadSprints(projectId: pid);
      final calendarData =
          await AgileWireframeService.loadSprintCalendar(pid);
      if (!mounted) return;
      _ceremonyController = TextEditingController(
          text: calendarData['ceremonies'] as String? ?? '');
      setState(() {
        _sprints = sprints;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCeremonies() async {
    final pid = _projectId;
    if (pid == null) return;
    await AgileWireframeService.saveSprintCalendar(
      projectId: pid,
      data: {'ceremonies': _ceremonyController.text},
    );
  }

  void _addSprint() {
    showDialog(
      context: context,
      builder: (ctx) => _SprintEditDialog(
        onSave: (sprint) {
          final pid = _projectId;
          if (pid == null) return;
          final updatedList = [..._sprints, sprint];
          RoadmapService.saveSprints(projectId: pid, sprints: updatedList);
          setState(() => _sprints = updatedList);
        },
      ),
    );
  }

  void _editSprint(int index) {
    final sprint = _sprints[index];
    showDialog(
      context: context,
      builder: (ctx) => _SprintEditDialog(
        existing: sprint,
        onSave: (updated) {
          final pid = _projectId;
          if (pid == null) return;
          final updatedList = [..._sprints];
          updatedList[index] = updated;
          RoadmapService.saveSprints(projectId: pid, sprints: updatedList);
          setState(() => _sprints = updatedList);
        },
      ),
    );
  }

  void _deleteSprint(int index) async {
    final pid = _projectId;
    if (pid == null) return;
    final updatedList = [..._sprints];
    updatedList.removeAt(index);
    await RoadmapService.saveSprints(projectId: pid, sprints: updatedList);
    setState(() => _sprints = updatedList);
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double hp = isMobile ? 20 : 40;

    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Agile Wireframe - Sprint Calendar'),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hp, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlanningPhaseHeader(
                      title: 'Sprint Cadence & Calendar',
                      onBack: () => PlanningPhaseNavigation.goToPrevious(
                          context, 'agile_sprint_calendar'),
                      onForward: () => PlanningPhaseNavigation.goToNext(
                          context, 'agile_sprint_calendar'),
                    ),
                    const SizedBox(height: 32),
                    Text('Define sprint duration, dates, and ceremony schedule.',
                        style: TextStyle(fontSize: 15, color: _kMuted)),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search sprints...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                      const SizedBox(height: 16),
                      if (_filteredSprints.isEmpty)
                        _buildEmptyState(
                            _searchQuery.isNotEmpty
                                ? 'No sprints match "$_searchQuery".'
                                : 'No sprints defined. Create your first sprint.')
                      else
                        ..._filteredSprints.asMap().entries.map((e) =>
                            _buildSprintCard(e.key, e.value)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _addSprint,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Sprint'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kAccent,
                          side: const BorderSide(color: _kAccent),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Ceremony Schedule',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _kHeadline)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ceremonyController,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. Sprint Planning (Mon 9-11am), Daily Standup (9:15am), Review (Fri 3-4pm), Retro (Fri 4-5pm)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        onChanged: (_) {
                          _saveDebounce?.cancel();
                          _saveDebounce = Timer(
                              const Duration(milliseconds: 500),
                              _saveCeremonies);
                        },
                      ),
                    ],
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSprintCard(int index, RoadmapSprint sprint) {
    final startStr =
        sprint.startDate != null ? _dateFormat.format(sprint.startDate!) : 'TBD';
    final endStr =
        sprint.endDate != null ? _dateFormat.format(sprint.endDate!) : 'TBD';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('${sprint.order}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _kAccent)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sprint.name.isNotEmpty ? sprint.name : 'Sprint ${sprint.order}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('$startStr – $endStr',
                      style: TextStyle(fontSize: 12, color: _kMuted)),
                  if (sprint.goal.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(sprint.goal,
                          style: TextStyle(fontSize: 12, color: _kMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _editSprint(index);
                if (v == 'delete') _deleteSprint(index);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: _kMuted, fontSize: 15)),
      ),
    );
  }
}

class _SprintEditDialog extends StatefulWidget {
  final RoadmapSprint? existing;
  final ValueChanged<RoadmapSprint> onSave;

  const _SprintEditDialog({this.existing, required this.onSave});

  @override
  State<_SprintEditDialog> createState() => _SprintEditDialogState();
}

class _SprintEditDialogState extends State<_SprintEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _goalCtrl;
  late TextEditingController _orderCtrl;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _goalCtrl = TextEditingController(text: e?.goal ?? '');
    _orderCtrl =
        TextEditingController(text: (e?.order ?? _nextOrder()).toString());
    _startDate = e?.startDate;
    _endDate = e?.endDate;
  }

  int _nextOrder() {
    return (widget.existing?.order ?? 0) + 1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat df = DateFormat('MMM dd, yyyy');
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Sprint' : 'Add Sprint'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Sprint Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orderCtrl,
              decoration: const InputDecoration(
                  labelText: 'Sprint #', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Start Date', border: OutlineInputBorder()),
                child: Text(_startDate != null
                    ? df.format(_startDate!)
                    : 'Select date'),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'End Date', border: OutlineInputBorder()),
                child: Text(
                    _endDate != null ? df.format(_endDate!) : 'Select date'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalCtrl,
              decoration: const InputDecoration(
                  labelText: 'Sprint Goal', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final sprint = RoadmapSprint(
              id: widget.existing?.id,
              name: _nameCtrl.text,
              order: int.tryParse(_orderCtrl.text) ?? 0,
              startDate: _startDate,
              endDate: _endDate,
              goal: _goalCtrl.text,
            );
            widget.onSave(sprint);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
