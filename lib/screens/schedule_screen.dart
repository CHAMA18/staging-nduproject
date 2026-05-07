import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/api_key_manager.dart';
import 'package:ndu_project/services/integrated_work_package_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/schedule_cpm_service.dart';
import 'package:ndu_project/theme.dart';
import 'package:ndu_project/utils/design_planning_document.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/admin_edit_toggle.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/s_curve_chart.dart';
import 'package:ndu_project/widgets/schedule_master_view.dart';
import 'package:ndu_project/widgets/schedule_gantt_enhanced.dart';
import 'package:ndu_project/widgets/work_package_dialog.dart';
import 'package:ndu_project/widgets/work_package_detail.dart';

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
  final List<_ScheduleRow> _activityRows = [];

  String _selectedMethodology = 'Waterfall';
  DateTime? _scheduleStartDate;
  DateTime? _baselineDate;
  DateTime? _lastSavedAt;
  Timer? _saveDebounce;

  bool _isGeneratingSchedule = false;
  bool _autoImportAttempted = false;
  bool _notesExpanded = false;

  static const String _kScheduleInitializedNoteKey =
      'planning_schedule_initialized';
  static const String _kScheduleUserTouchedNoteKey =
      'planning_schedule_user_touched';

  bool _asPlanningFlag(Map<String, String> notes, String key) {
    return (notes[key] ?? '').trim().toLowerCase() == 'true';
  }

  String _timelineView = 'Months';
  String? _selectedTaskId;
  String? _hoveredTaskId;
  int _selectedMainTab =
      0; // 0: Master Schedule, 1: Gantt Chart, 2: List View, 3: Board View, 4: Work Packages, 5: Procurement Timeline, 6: Cost vs Schedule

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ApiKeyManager.initializeApiKey();
      final data = ProjectDataHelper.getData(context);
      _notesController.text =
          data.planningNotes['planning_schedule_notes']?.trim() ?? '';
      _selectedMethodology = data.planningNotes['planning_schedule_methodology']
                  ?.trim()
                  .isNotEmpty ==
              true
          ? data.planningNotes['planning_schedule_methodology']!
          : _selectedMethodology;
      final storedStart =
          data.planningNotes['planning_schedule_start_date']?.trim() ?? '';
      _scheduleStartDate = DateTime.tryParse(storedStart) ?? DateTime.now();
      final baselineValue = data.scheduleBaselineDate.trim();
      _baselineDate =
          baselineValue.isEmpty ? null : DateTime.tryParse(baselineValue);
      _loadScheduleActivities(data);
      _notesController.addListener(_handleNotesChanged);
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _notesController.removeListener(_handleNotesChanged);
    _notesController.dispose();
    for (final row in _activityRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _handleNotesChanged() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 650), () async {
      await _persistSchedule();
    });
  }

  void _handleActivityChanged() {
    if (mounted) setState(() {});
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 650), () async {
      await _persistSchedule();
    });
  }

  Future<void> _persistSchedule({bool markTouched = true}) async {
    final success = await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'planning_schedule',
      dataUpdater: (data) {
        final nextNotes = Map<String, String>.from(data.planningNotes)
          ..['planning_schedule_notes'] = _notesController.text.trim()
          ..['planning_schedule_methodology'] = _selectedMethodology
          ..['planning_schedule_start_date'] =
              _scheduleStartDate?.toIso8601String() ?? ''
          ..[_kScheduleInitializedNoteKey] = 'true';
        if (markTouched) {
          nextNotes[_kScheduleUserTouchedNoteKey] = 'true';
        }
        return data.copyWith(
          planningNotes: nextNotes,
          scheduleActivities: _buildScheduleActivities(),
        );
      },
      showSnackbar: false,
    );
    if (mounted && success) {
      setState(() => _lastSavedAt = DateTime.now());
    }
  }

  Future<void> _setBaseline() async {
    if (_activityRows.isEmpty) {
      _showInfo('Add schedule activities first.');
      return;
    }

    final now = DateTime.now().toIso8601String();
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'planning_schedule',
      dataUpdater: (data) => data.copyWith(
        scheduleBaselineActivities: _buildScheduleActivities(),
        scheduleBaselineDate: now,
      ),
      showSnackbar: false,
    );

    if (mounted) {
      setState(() => _baselineDate = DateTime.tryParse(now));
      _showInfo('Schedule baseline saved.');
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduleStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _scheduleStartDate = picked);
      _handleActivityChanged();
    }
  }

  Future<void> _pickRowDate(_ScheduleRow row, {required bool isDueDate}) async {
    final current = isDueDate
        ? _parseDate(row.dueDateController.text)
        : _parseDate(row.startDateController.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? _scheduleStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      if (isDueDate) {
        row.dueDateController.text = _formatDate(picked);
      } else {
        row.startDateController.text = _formatDate(picked);
      }
      _handleActivityChanged();
    }
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _loadScheduleActivities(ProjectDataModel data) {
    final usedIds = <String>{};
    _activityRows
      ..clear()
      ..addAll(data.scheduleActivities.map((activity) {
        var id = activity.wbsId.isNotEmpty ? activity.wbsId : activity.id;
        if (id.trim().isEmpty || usedIds.contains(id)) {
          id = DateTime.now().microsecondsSinceEpoch.toString();
        }
        usedIds.add(id);
        return _ScheduleRow.fromActivity(
          activity,
          idOverride: id,
          onChanged: _handleActivityChanged,
        );
      }));

    final scheduleInitialized =
        _asPlanningFlag(data.planningNotes, _kScheduleInitializedNoteKey);
    final scheduleUserTouched =
        _asPlanningFlag(data.planningNotes, _kScheduleUserTouchedNoteKey);
    if (_activityRows.isEmpty &&
        data.wbsTree.isNotEmpty &&
        !scheduleInitialized &&
        !scheduleUserTouched) {
      _autoImportAttempted = true;
      _importFromWbs(showConfirm: false, markTouched: false);
    }
  }

  List<ScheduleActivity> _buildScheduleActivities() {
    final data = ProjectDataHelper.getData(context, listen: false);
    final existingById = {
      for (final activity in data.scheduleActivities) activity.id: activity,
    };
    final workPackageById = {
      for (final package in data.workPackages) package.id: package,
    };
    final preferredPackageByWbs = <String, WorkPackage>{};
    for (final package in data.workPackages) {
      final keys = {
        package.sourceWbsLevel3Id,
        package.wbsItemId,
      }.where((key) => key.trim().isNotEmpty);
      for (final key in keys) {
        final existing = preferredPackageByWbs[key];
        if (existing == null ||
            _workPackageLinkRank(package) > _workPackageLinkRank(existing)) {
          preferredPackageByWbs[key] = package;
        }
      }
    }

    final computed =
        _computeSchedule(_activityRows, _scheduleStartDate ?? DateTime.now());
    final computedById = {
      for (final item in computed.items) item.id: item,
    };

    final rawActivities = _activityRows.map((row) {
      final previous = existingById[row.id];
      final linkedPackage = row.workPackageId.isNotEmpty
          ? workPackageById[row.workPackageId]
          : previous != null && previous.workPackageId.isNotEmpty
              ? workPackageById[previous.workPackageId]
              : preferredPackageByWbs[row.wbsId];
      final fallback = computedById[row.id];
      final startDateText = row.startDateController.text.trim().isNotEmpty
          ? row.startDateController.text.trim()
          : (fallback != null ? _formatDate(fallback.startDate) : '');
      final dueDateText = row.dueDateController.text.trim().isNotEmpty
          ? row.dueDateController.text.trim()
          : (fallback != null ? _formatDate(fallback.endDate) : '');

      return ScheduleActivity(
        id: row.id,
        wbsId: row.wbsId,
        title: row.titleController.text.trim(),
        durationDays: int.tryParse(row.durationController.text.trim()) ?? 5,
        predecessorIds: row.normalizedDependencyIds,
        dependencyIds: row.normalizedDependencyIds,
        isMilestone: row.isMilestone,
        status: row.status,
        priority: row.priority,
        assignee: row.assigneeController.text.trim(),
        discipline: row.disciplineController.text.trim(),
        progress: (double.tryParse(row.progressController.text.trim()) ?? 0)
                .clamp(0, 100) /
            100,
        startDate: startDateText,
        dueDate: dueDateText,
        estimatedHours: double.tryParse(row.hoursController.text.trim()) ?? 0,
        milestone: row.milestoneController.text.trim(),
        workPackageId: linkedPackage?.id ??
            (row.workPackageId.isNotEmpty
                ? row.workPackageId
                : previous?.workPackageId ?? ''),
        workPackageTitle: linkedPackage?.title ??
            (row.workPackageTitle.isNotEmpty
                ? row.workPackageTitle
                : previous?.workPackageTitle ?? ''),
        workPackageType: linkedPackage?.type ??
            (row.workPackageType.isNotEmpty
                ? row.workPackageType
                : previous?.workPackageType ?? ''),
        phase: linkedPackage?.phase ??
            (row.phase.isNotEmpty ? row.phase : previous?.phase ?? ''),
        wbsLevel2Id: linkedPackage?.wbsLevel2Id ??
            (row.wbsLevel2Id.isNotEmpty
                ? row.wbsLevel2Id
                : previous?.wbsLevel2Id ?? ''),
        wbsLevel2Title: linkedPackage?.wbsLevel2Title ??
            (row.wbsLevel2Title.isNotEmpty
                ? row.wbsLevel2Title
                : previous?.wbsLevel2Title ?? ''),
        contractId: row.contractId.isNotEmpty
            ? row.contractId
            : previous?.contractId ?? '',
        vendorId: linkedPackage != null && linkedPackage.vendorIds.isNotEmpty
            ? linkedPackage.vendorIds.first
            : previous?.vendorId ?? '',
        procurementStatus: previous?.procurementStatus ?? 'not_started',
        procurementRfqDate: previous?.procurementRfqDate,
        procurementAwardDate: previous?.procurementAwardDate,
        contractStartDate: previous?.contractStartDate,
        contractEndDate: previous?.contractEndDate,
        budgetedCost:
            linkedPackage?.budgetedCost ?? previous?.budgetedCost ?? 0,
        actualCost: linkedPackage?.actualCost ?? previous?.actualCost ?? 0,
        estimatingBasis: row.estimatingBasisController.text.trim(),
      );
    }).toList();

    return ScheduleCpmService.applyToActivities(
      activities: rawActivities,
      projectStart: _scheduleStartDate ?? DateTime.now(),
    );
  }

  int _workPackageLinkRank(WorkPackage package) {
    switch (package.packageClassification) {
      case IntegratedWorkPackageService.constructionCwp:
      case IntegratedWorkPackageService.implementationWorkPackage:
      case IntegratedWorkPackageService.agileIterationPackage:
        return 3;
      case IntegratedWorkPackageService.procurementPackage:
        return 2;
      case IntegratedWorkPackageService.engineeringEwp:
        return 1;
      default:
        return package.type == 'construction' || package.type == 'execution'
            ? 3
            : 0;
    }
  }

  List<Map<String, String>> _flattenWbsItems(List<WorkItem> items) {
    final result = <Map<String, String>>[];

    void visit(List<WorkItem> nodes) {
      for (final node in nodes) {
        if (node.children.isEmpty) {
          result.add({
            'id': node.id,
            'title': node.title,
            'dependencies': node.dependencies.join(', '),
            'discipline': node.framework,
          });
        } else {
          visit(node.children);
        }
      }
    }

    visit(items);
    return result;
  }

  Future<void> _importFromWbs({
    bool showConfirm = true,
    bool markTouched = true,
  }) async {
    final data = ProjectDataHelper.getData(context);
    if (data.wbsTree.isEmpty) {
      _showInfo('No WBS items found.');
      return;
    }

    if (showConfirm && _activityRows.isNotEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace schedule activities?'),
          content: const Text(
            'Importing from WBS will replace your current schedule list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (shouldContinue != true) return;
    }

    final flattened = _flattenWbsItems(data.wbsTree);
    final usedIds = <String>{};
    final titleToId = <String, String>{};
    final rawIdToId = <String, String>{};

    String ensureId(String? raw) {
      final cleaned = raw?.trim() ?? '';
      var candidate = cleaned.isNotEmpty
          ? cleaned
          : DateTime.now().microsecondsSinceEpoch.toString();
      if (!usedIds.contains(candidate)) {
        usedIds.add(candidate);
        return candidate;
      }
      var i = 2;
      while (usedIds.contains('$candidate-$i')) {
        i++;
      }
      candidate = '$candidate-$i';
      usedIds.add(candidate);
      return candidate;
    }

    final normalized = <Map<String, String>>[];
    for (final item in flattened) {
      final rawId = (item['id'] ?? '').trim();
      final title = (item['title'] ?? '').trim();
      final generated = ensureId(rawId);
      normalized.add({
        'rawId': rawId,
        'id': generated,
        'title': title,
        'dependencies': (item['dependencies'] ?? '').trim(),
        'discipline': (item['discipline'] ?? '').trim(),
      });
      if (rawId.isNotEmpty && !rawIdToId.containsKey(rawId)) {
        rawIdToId[rawId] = generated;
      }
      if (title.isNotEmpty && !titleToId.containsKey(title)) {
        titleToId[title] = generated;
      }
    }

    setState(() {
      for (final row in _activityRows) {
        row.dispose();
      }
      _activityRows
        ..clear()
        ..addAll(normalized.map((item) {
          final deps = (item['dependencies'] ?? '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          String? predecessor;
          if (deps.isNotEmpty) {
            predecessor = rawIdToId[deps.first] ?? titleToId[deps.first];
          }

          return _ScheduleRow(
            id: item['id'] ?? '',
            wbsId: item['rawId'] ?? '',
            title: item['title'] ?? '',
            durationDays: 5,
            predecessorId: predecessor,
            isMilestone: false,
            discipline: item['discipline'] ?? '',
            onChanged: _handleActivityChanged,
          );
        }));
    });

    if (markTouched) {
      _handleActivityChanged();
    } else {
      await _persistSchedule(markTouched: false);
      if (mounted) setState(() {});
    }
    _showInfo('Imported ${_activityRows.length} activities from WBS.');
  }

  Future<void> _generateScheduleFromAi() async {
    if (_isGeneratingSchedule) return;
    final data = ProjectDataHelper.getData(context);
    if (data.wbsTree.isEmpty) {
      _showInfo('Add WBS items first.');
      return;
    }

    setState(() => _isGeneratingSchedule = true);
    try {
      final wbsItems = _flattenWbsItems(data.wbsTree);
      final ctx = ProjectDataHelper.buildFepContext(
        data,
        sectionLabel: 'Schedule Plan',
      );
      final ai = OpenAiServiceSecure();
      final activities = await ai.generateScheduleActivities(
        context: ctx,
        wbsItems: wbsItems,
      );
      if (!mounted) return;

      setState(() {
        for (final row in _activityRows) {
          row.dispose();
        }
        _activityRows
          ..clear()
          ..addAll(activities.map(
            (activity) => _ScheduleRow.fromActivity(
              activity,
              onChanged: _handleActivityChanged,
            ),
          ));
      });

      _handleActivityChanged();
    } catch (error) {
      _showInfo('Failed to generate schedule: $error');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingSchedule = false);
      }
    }
  }

  void _addTask() {
    unawaited(_openCreateTaskDialog());
  }

  Future<void> _openCreateTaskDialog() async {
    final draft = await _showTaskDialog();
    if (draft == null || !mounted) return;

    setState(() {
      _activityRows.add(_ScheduleRow(
        id: _nextTaskId(),
        wbsId: draft.wbsId,
        title: draft.title,
        durationDays: draft.durationDays,
        predecessorId: draft.predecessorId,
        dependencyIds: draft.dependencyIds,
        isMilestone: draft.isMilestone,
        status: draft.status,
        priority: draft.priority,
        assignee: draft.assignee,
        discipline: draft.discipline,
        progressPercent: draft.progressPercent,
        startDate: draft.startDate,
        dueDate: draft.dueDate,
        estimatedHours: draft.estimatedHours,
        estimatingBasis: draft.estimatingBasis,
        milestone: draft.milestone,
        onChanged: _handleActivityChanged,
      ));
    });
    _handleActivityChanged();
  }

  Future<void> _editTask(String taskId) async {
    final index = _activityRows.indexWhere((row) => row.id == taskId);
    if (index == -1) return;
    final row = _activityRows[index];
    final draft = await _showTaskDialog(row: row);
    if (draft == null || !mounted) return;

    setState(() {
      row.wbsId = draft.wbsId;
      row.titleController.text = draft.title;
      row.durationController.text = draft.durationDays.toString();
      row.predecessorId = draft.predecessorId;
      row.dependencyIds = draft.dependencyIds;
      row.isMilestone = draft.isMilestone;
      row.status = draft.status;
      row.priority = draft.priority;
      row.assigneeController.text = draft.assignee;
      row.disciplineController.text = draft.discipline;
      row.progressController.text =
          (draft.progressPercent * 100).round().toString();
      row.startDateController.text = draft.startDate;
      row.dueDateController.text = draft.dueDate;
      row.hoursController.text =
          draft.estimatedHours <= 0 ? '' : draft.estimatedHours.toString();
      row.estimatingBasisController.text = draft.estimatingBasis;
      row.milestoneController.text = draft.milestone;
    });
    _handleActivityChanged();
  }

  String _nextTaskId() => DateTime.now().microsecondsSinceEpoch.toString();

  String _generateWbsId({String? preferred}) {
    final preferredValue = (preferred ?? '').trim();
    if (preferredValue.isNotEmpty) return preferredValue;
    final used = _activityRows.map((row) => row.wbsId.trim()).toSet();
    var idx = 1;
    while (used.contains('TASK-$idx')) {
      idx++;
    }
    return 'TASK-$idx';
  }

  String? _resolvePredecessorFromDependencyToken(String token) {
    final dep = token.trim();
    if (dep.isEmpty) return null;
    for (final row in _activityRows) {
      if (row.wbsId.trim() == dep) return row.id;
      if (row.titleController.text.trim() == dep) return row.id;
    }
    return null;
  }

  Future<_TaskDraft?> _showTaskDialog({_ScheduleRow? row}) async {
    final data = ProjectDataHelper.getData(context);
    final wbsItems = _flattenWbsItems(data.wbsTree);
    final predecessorOptions = _activityRows
        .where((candidate) => row == null || candidate.id != row.id)
        .toList();
    String? selectedWbsRawId =
        row != null && row.wbsId.trim().isNotEmpty ? row.wbsId.trim() : null;
    final availableWbsIds = wbsItems
        .map((item) => (item['id'] ?? '').trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (selectedWbsRawId != null &&
        !availableWbsIds.contains(selectedWbsRawId)) {
      selectedWbsRawId = null;
    }
    String? predecessorId = row?.predecessorId;
    bool isMilestone = row?.isMilestone ?? false;
    String status = row?.status ?? 'pending';
    String priority = row?.priority ?? 'medium';

    final titleController = TextEditingController(
      text: row?.titleController.text.trim() ?? '',
    );
    final durationController = TextEditingController(
      text: row?.durationController.text.trim().isNotEmpty == true
          ? row!.durationController.text.trim()
          : '5',
    );
    final assigneeController = TextEditingController(
      text: row?.assigneeController.text.trim() ?? '',
    );
    final disciplineController = TextEditingController(
      text: row?.disciplineController.text.trim() ?? '',
    );
    final progressController = TextEditingController(
      text: row?.progressController.text.trim().isNotEmpty == true
          ? row!.progressController.text.trim()
          : '0',
    );
    final startDateController = TextEditingController(
      text: row?.startDateController.text.trim() ?? '',
    );
    final dueDateController = TextEditingController(
      text: row?.dueDateController.text.trim() ?? '',
    );
    final hoursController = TextEditingController(
      text: row?.hoursController.text.trim() ?? '',
    );
    final estimatingBasisController = TextEditingController(
      text: row?.estimatingBasisController.text.trim() ?? '',
    );
    final milestoneController = TextEditingController(
      text: row?.milestoneController.text.trim() ?? '',
    );
    final dependencyIdsController = TextEditingController(
      text: row?.normalizedDependencyIds.join(', ') ?? '',
    );

    final result = await showDialog<_TaskDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isCreate = row == null;
            return AlertDialog(
              title: Text(isCreate ? 'Create Task' : 'Edit Task'),
              content: SizedBox(
                width: 640,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (wbsItems.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: selectedWbsRawId,
                          decoration: const InputDecoration(
                            labelText: 'WBS Item (optional)',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('None'),
                            ),
                            ...wbsItems.map(
                              (item) => DropdownMenuItem<String>(
                                value: (item['id'] ?? '').trim(),
                                child: Text(
                                  (item['title'] ?? '').trim().isEmpty
                                      ? 'Untitled'
                                      : (item['title'] ?? '').trim(),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            final raw = (value ?? '').trim();
                            setDialogState(() {
                              selectedWbsRawId = raw.isEmpty ? null : raw;
                              if (raw.isNotEmpty) {
                                Map<String, String>? selected;
                                for (final item in wbsItems) {
                                  if ((item['id'] ?? '').trim() == raw) {
                                    selected = item;
                                    break;
                                  }
                                }
                                final title = (selected?['title'] ?? '').trim();
                                final discipline =
                                    (selected?['discipline'] ?? '').trim();
                                final deps = (selected?['dependencies'] ?? '')
                                    .split(',')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty);

                                if (title.isNotEmpty) {
                                  titleController.text = title;
                                }
                                if (discipline.isNotEmpty &&
                                    disciplineController.text.trim().isEmpty) {
                                  disciplineController.text = discipline;
                                }
                                predecessorId = null;
                                final matchedDependencyIds = <String>[];
                                for (final dep in deps) {
                                  final match =
                                      _resolvePredecessorFromDependencyToken(
                                          dep);
                                  if (match != null) {
                                    matchedDependencyIds.add(match);
                                    predecessorId ??= match;
                                  }
                                }
                                dependencyIdsController.text =
                                    matchedDependencyIds.join(', ');
                              }
                            });
                          },
                        ),
                      TextField(
                        controller: titleController,
                        decoration:
                            const InputDecoration(labelText: 'Task Name'),
                      ),
                      TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Duration (days)'),
                      ),
                      DropdownButtonFormField<String?>(
                        initialValue: predecessorId,
                        decoration:
                            const InputDecoration(labelText: 'Predecessor'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...predecessorOptions.map(
                            (candidate) => DropdownMenuItem<String?>(
                              value: candidate.id,
                              child: Text(
                                candidate.titleController.text.trim().isEmpty
                                    ? 'Untitled task'
                                    : candidate.titleController.text.trim(),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            predecessorId = value;
                            final parsed = _parseDependencyIds(
                                dependencyIdsController.text);
                            if (value != null && !parsed.contains(value)) {
                              parsed.insert(0, value);
                            }
                            dependencyIdsController.text = parsed.join(', ');
                          });
                        },
                      ),
                      TextField(
                        controller: dependencyIdsController,
                        decoration: const InputDecoration(
                          labelText: 'Dependency IDs',
                          helperText:
                              'Comma-separated activity IDs. The predecessor dropdown is included automatically.',
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: status,
                              decoration:
                                  const InputDecoration(labelText: 'Status'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'pending', child: Text('Pending')),
                                DropdownMenuItem(
                                    value: 'in_progress',
                                    child: Text('In Progress')),
                                DropdownMenuItem(
                                    value: 'completed',
                                    child: Text('Completed')),
                                DropdownMenuItem(
                                    value: 'overdue', child: Text('Overdue')),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => status = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: priority,
                              decoration:
                                  const InputDecoration(labelText: 'Priority'),
                              items: const [
                                DropdownMenuItem(
                                    value: 'low', child: Text('Low')),
                                DropdownMenuItem(
                                    value: 'medium', child: Text('Medium')),
                                DropdownMenuItem(
                                    value: 'high', child: Text('High')),
                                DropdownMenuItem(
                                    value: 'critical', child: Text('Critical')),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => priority = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: assigneeController,
                        decoration:
                            const InputDecoration(labelText: 'Assignee'),
                      ),
                      TextField(
                        controller: disciplineController,
                        decoration:
                            const InputDecoration(labelText: 'Discipline'),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: progressController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Progress %'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: hoursController,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Hours'),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startDateController,
                              decoration: const InputDecoration(
                                  labelText: 'Start Date (YYYY-MM-DD)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: dueDateController,
                              decoration: const InputDecoration(
                                  labelText: 'Due Date (YYYY-MM-DD)'),
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: estimatingBasisController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Estimate Basis',
                          helperText:
                              'Assumptions, method, source data, or duration basis for this activity.',
                        ),
                      ),
                      TextField(
                        controller: milestoneController,
                        decoration:
                            const InputDecoration(labelText: 'Milestone'),
                      ),
                      SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Milestone Task'),
                        value: isMilestone,
                        onChanged: (value) {
                          setDialogState(() => isMilestone = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      _showInfo('Task name is required.');
                      return;
                    }

                    final duration =
                        int.tryParse(durationController.text.trim()) ?? 5;
                    final progress =
                        (double.tryParse(progressController.text.trim()) ?? 0)
                                .clamp(0, 100) /
                            100;
                    final startDate = startDateController.text.trim();
                    final dueDate = dueDateController.text.trim();
                    final dependencyIds =
                        _parseDependencyIds(dependencyIdsController.text);
                    if (predecessorId != null &&
                        !dependencyIds.contains(predecessorId)) {
                      dependencyIds.insert(0, predecessorId!);
                    }

                    if (startDate.isNotEmpty && _parseDate(startDate) == null) {
                      _showInfo('Start date must be YYYY-MM-DD.');
                      return;
                    }
                    if (dueDate.isNotEmpty && _parseDate(dueDate) == null) {
                      _showInfo('Due date must be YYYY-MM-DD.');
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      _TaskDraft(
                        title: title,
                        wbsId: _generateWbsId(
                          preferred: selectedWbsRawId ??
                              (row?.wbsId.trim().isNotEmpty == true
                                  ? row!.wbsId.trim()
                                  : null),
                        ),
                        durationDays: duration < 0 ? 0 : duration,
                        predecessorId: predecessorId,
                        dependencyIds: dependencyIds,
                        isMilestone: isMilestone,
                        status: _normalizeScheduleStatus(status),
                        priority: _normalizeSchedulePriority(priority),
                        assignee: assigneeController.text.trim(),
                        discipline: disciplineController.text.trim(),
                        progressPercent: progress,
                        startDate: startDate,
                        dueDate: dueDate,
                        estimatedHours:
                            double.tryParse(hoursController.text.trim()) ?? 0,
                        estimatingBasis: estimatingBasisController.text.trim(),
                        milestone: milestoneController.text.trim(),
                      ),
                    );
                  },
                  child: Text(isCreate ? 'Create Task' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    durationController.dispose();
    assigneeController.dispose();
    disciplineController.dispose();
    progressController.dispose();
    startDateController.dispose();
    dueDateController.dispose();
    hoursController.dispose();
    estimatingBasisController.dispose();
    milestoneController.dispose();
    dependencyIdsController.dispose();
    return result;
  }

  List<String> _parseDependencyIds(String value) {
    return value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .toList();
  }

  void _deleteTask(String id) {
    setState(() {
      final index = _activityRows.indexWhere((row) => row.id == id);
      if (index != -1) {
        _activityRows[index].dispose();
        _activityRows.removeAt(index);
      }
    });
    _handleActivityChanged();
  }

  Future<void> _validateSchedule() async {
    final report = _buildValidationReport();
    await showDialog<void>(
      context: context,
      builder: (context) => _ScheduleValidationDialog(report: report),
    );
  }

  _ScheduleValidationReport _buildValidationReport() {
    final activities = _buildScheduleActivities();
    final cpm = ScheduleCpmService.calculate(
      activities: activities,
      projectStart: _scheduleStartDate ?? DateTime.now(),
    );
    final data = ProjectDataHelper.getData(context, listen: false);

    final packageWarnings = <_PackageWarning>[];
    for (final package in data.workPackages) {
      final warnings = IntegratedWorkPackageService.validateReadiness(package);
      if (warnings.isNotEmpty) {
        packageWarnings
            .add(_PackageWarning(package: package, warnings: warnings));
      }
    }

    final packageCandidateIds = data.workPackages
        .map((package) => package.sourceWbsLevel3Id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final unlinkedWbsCandidates = <WorkItem>[];
    void visitLevel3(List<WorkItem> nodes, int depth) {
      for (final node in nodes) {
        if (depth == 3 && !packageCandidateIds.contains(node.id)) {
          unlinkedWbsCandidates.add(node);
        }
        if (depth < 3) {
          visitLevel3(node.children, depth + 1);
        }
      }
    }

    visitLevel3(data.wbsTree, 1);

    final missingEstimateBasis = activities.where((activity) {
      final isCritical = cpm.activitiesById[activity.id]?.isCritical ?? false;
      return (isCritical || activity.durationDays >= 5) &&
          activity.estimatingBasis.trim().isEmpty;
    }).toList();
    final resourceWarnings = _buildResourceWarnings(activities);
    final contractAlignmentWarnings =
        _buildContractAlignmentWarnings(data.workPackages);
    final baselineVarianceWarnings = _buildBaselineVarianceWarnings(
      activities: activities,
      baselineActivities: data.scheduleBaselineActivities,
    );
    final milestoneWarnings = _buildMilestoneWarnings(
      milestones: data.keyMilestones,
      activities: activities,
    );

    return _ScheduleValidationReport(
      taskCount: _activityRows.length,
      unassignedTaskCount: _activityRows
          .where((row) => row.assigneeController.text.trim().isEmpty)
          .length,
      noPredecessorCount: _activityRows
          .where((row) => !row.isMilestone && row.predecessorId == null)
          .length,
      cpm: cpm,
      packageWarnings: packageWarnings,
      unlinkedWbsCandidates: unlinkedWbsCandidates,
      missingEstimateBasis: missingEstimateBasis,
      resourceWarnings: resourceWarnings,
      contractAlignmentWarnings: contractAlignmentWarnings,
      baselineVarianceWarnings: baselineVarianceWarnings,
      milestoneWarnings: milestoneWarnings,
    );
  }

  List<_ResourceWarning> _buildResourceWarnings(
    List<ScheduleActivity> activities,
  ) {
    final dailyHoursByAssignee = <String, Map<String, double>>{};
    final unassignedExecution = <ScheduleActivity>[];

    for (final activity in activities) {
      final assignee = activity.assignee.trim();
      final workPackageType = activity.workPackageType.trim().toLowerCase();
      final isExecution = workPackageType == 'construction' ||
          workPackageType == 'execution' ||
          activity.phase.trim().toLowerCase() == 'execution';

      if (assignee.isEmpty) {
        if (isExecution) {
          unassignedExecution.add(activity);
        }
        continue;
      }

      final start = _parseDate(activity.startDate);
      final end = _parseDate(activity.dueDate);
      if (start == null || end == null || end.isBefore(start)) continue;

      final durationDays = end.difference(start).inDays + 1;
      final dailyHours = activity.estimatedHours > 0
          ? activity.estimatedHours / durationDays
          : (activity.durationDays <= 0 ? 0.0 : 8.0);
      for (var i = 0; i < durationDays; i++) {
        final dateKey = _formatDate(start.add(Duration(days: i)));
        dailyHoursByAssignee.putIfAbsent(assignee, () => {}).update(
            dateKey, (value) => value + dailyHours,
            ifAbsent: () => dailyHours);
      }
    }

    final warnings = <_ResourceWarning>[];
    for (final entry in dailyHoursByAssignee.entries) {
      final overloadedDays = entry.value.entries
          .where((day) => day.value > 8)
          .map((day) => '${day.key}: ${day.value.toStringAsFixed(1)}h')
          .toList();
      if (overloadedDays.isNotEmpty) {
        warnings.add(
          _ResourceWarning(
            title: '${entry.key} exceeds 8h/day capacity',
            detail: overloadedDays.take(5).join('\n'),
          ),
        );
      }
    }

    for (final activity in unassignedExecution) {
      warnings.add(
        _ResourceWarning(
          title: activity.title.isNotEmpty ? activity.title : activity.id,
          detail: 'Execution activity has no assigned owner/resource.',
        ),
      );
    }

    return warnings;
  }

  List<_ContractAlignmentWarning> _buildContractAlignmentWarnings(
    List<WorkPackage> packages,
  ) {
    final warnings = <_ContractAlignmentWarning>[];
    final packagesByContract = <String, List<WorkPackage>>{};

    for (final package in packages) {
      final classification = package.packageClassification.trim();
      final isProcurement =
          classification == IntegratedWorkPackageService.procurementPackage;
      final isExecution = classification ==
              IntegratedWorkPackageService.constructionCwp ||
          classification ==
              IntegratedWorkPackageService.implementationWorkPackage ||
          classification == IntegratedWorkPackageService.agileIterationPackage;

      if (isProcurement &&
          package.contractIds.isEmpty &&
          package.vendorIds.isEmpty) {
        warnings.add(
          _ContractAlignmentWarning(
            title: package.title.isNotEmpty ? package.title : package.id,
            detail: 'Procurement package has no contract or vendor reference.',
          ),
        );
      }

      if (isExecution &&
          package.contractIds.isEmpty &&
          package.contractorOrCrew.trim().isEmpty &&
          package.owner.trim().isEmpty) {
        warnings.add(
          _ContractAlignmentWarning(
            title: package.title.isNotEmpty ? package.title : package.id,
            detail:
                'Execution package has no contract, contractor/crew, or owner assignment.',
          ),
        );
      }

      for (final contractId in package.contractIds) {
        final trimmed = contractId.trim();
        if (trimmed.isNotEmpty) {
          packagesByContract.putIfAbsent(trimmed, () => []).add(package);
        }
      }
    }

    for (final entry in packagesByContract.entries) {
      final level3Ids = entry.value
          .map((package) => package.sourceWbsLevel3Id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      if (level3Ids.length > 1) {
        warnings.add(
          _ContractAlignmentWarning(
            title: 'Contract ${entry.key}',
            detail:
                'Mapped across multiple WBS Level 3 package candidates: ${entry.value.map((package) => package.title.isNotEmpty ? package.title : package.id).join(', ')}.',
          ),
        );
      }
    }

    return warnings;
  }

  List<_BaselineVarianceWarning> _buildBaselineVarianceWarnings({
    required List<ScheduleActivity> activities,
    required List<ScheduleActivity> baselineActivities,
  }) {
    if (baselineActivities.isEmpty) {
      return const [
        _BaselineVarianceWarning(
          title: 'No schedule baseline',
          detail: 'Baseline the schedule to track slippage and variance.',
        ),
      ];
    }

    final warnings = <_BaselineVarianceWarning>[];
    final baselineById = {
      for (final baseline in baselineActivities) baseline.id: baseline,
    };

    for (final activity in activities) {
      final baseline = baselineById[activity.id];
      if (baseline == null) {
        warnings.add(
          _BaselineVarianceWarning(
            title: activity.title.isNotEmpty ? activity.title : activity.id,
            detail: 'Activity is not present in the saved baseline.',
          ),
        );
        continue;
      }

      final baselineStart = _parseDate(baseline.startDate);
      final baselineEnd = _parseDate(baseline.dueDate);
      final currentStart = _parseDate(activity.startDate);
      final currentEnd = _parseDate(activity.dueDate);

      if (baselineStart != null && currentStart != null) {
        final startSlip = currentStart.difference(baselineStart).inDays;
        if (startSlip > 0) {
          warnings.add(
            _BaselineVarianceWarning(
              title: activity.title.isNotEmpty ? activity.title : activity.id,
              detail:
                  'Start slipped by $startSlip day${startSlip == 1 ? '' : 's'} from baseline.',
            ),
          );
        }
      }

      if (baselineEnd != null && currentEnd != null) {
        final finishSlip = currentEnd.difference(baselineEnd).inDays;
        if (finishSlip > 0) {
          warnings.add(
            _BaselineVarianceWarning(
              title: activity.title.isNotEmpty ? activity.title : activity.id,
              detail:
                  'Finish slipped by $finishSlip day${finishSlip == 1 ? '' : 's'} from baseline.',
            ),
          );
        }
      }

      final durationVariance = activity.durationDays - baseline.durationDays;
      if (durationVariance > 0) {
        warnings.add(
          _BaselineVarianceWarning(
            title: activity.title.isNotEmpty ? activity.title : activity.id,
            detail:
                'Duration increased by $durationVariance day${durationVariance == 1 ? '' : 's'} versus baseline.',
          ),
        );
      }
    }

    return warnings;
  }

  List<_MilestoneWarning> _buildMilestoneWarnings({
    required List<Milestone> milestones,
    required List<ScheduleActivity> activities,
  }) {
    final warnings = <_MilestoneWarning>[];
    final activityTitles = activities
        .map((activity) => activity.title.trim().toLowerCase())
        .where((title) => title.isNotEmpty)
        .toSet();
    final activityMilestones = activities
        .map((activity) => activity.milestone.trim().toLowerCase())
        .where((milestone) => milestone.isNotEmpty)
        .toSet();
    final milestoneActivities =
        activities.where((activity) => activity.isMilestone);

    for (final milestone in milestones) {
      final name = milestone.name.trim();
      if (name.isEmpty) continue;
      final normalized = name.toLowerCase();
      if (milestone.dueDate.trim().isEmpty) {
        warnings.add(
          _MilestoneWarning(
            title: name,
            detail: 'Milestone has no due date.',
          ),
        );
      }
      if (!activityTitles.contains(normalized) &&
          !activityMilestones.contains(normalized)) {
        warnings.add(
          _MilestoneWarning(
            title: name,
            detail: 'Milestone is not represented in the schedule network.',
          ),
        );
      }
    }

    for (final activity in milestoneActivities) {
      final dueDate = activity.dueDate.trim();
      if (dueDate.isEmpty) {
        warnings.add(
          _MilestoneWarning(
            title: activity.title.isNotEmpty ? activity.title : activity.id,
            detail: 'Milestone activity has no due date.',
          ),
        );
      }
    }

    return warnings;
  }

  void _moveTaskToStatus(String taskId, String targetStatus) {
    final rowIndex = _activityRows.indexWhere((row) => row.id == taskId);
    if (rowIndex == -1) return;
    final row = _activityRows[rowIndex];
    if (row.status == targetStatus) return;
    setState(() {
      row.status = targetStatus;
    });
    _handleActivityChanged();
  }

  Future<void> _createWorkPackage() async {
    final data = ProjectDataHelper.getData(context);
    final wbsLevel2Ids = <Map<String, String>>[];
    for (final item in data.wbsTree) {
      for (final child in item.children) {
        wbsLevel2Ids.add({'id': child.id, 'title': child.title});
      }
    }

    final result = await showDialog<WorkPackage>(
      context: context,
      builder: (context) => WorkPackageDialog(
        wbsLevel2Options: wbsLevel2Ids,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        data.workPackages.add(result);
      });
      _saveWorkPackages(data.workPackages);
      _showInfo('Work package created.');
    }
  }

  Future<void> _editWorkPackage(WorkPackage wp) async {
    final data = ProjectDataHelper.getData(context);
    final wbsLevel2Ids = <Map<String, String>>[];
    for (final item in data.wbsTree) {
      for (final child in item.children) {
        wbsLevel2Ids.add({'id': child.id, 'title': child.title});
      }
    }

    final result = await showDialog<WorkPackage>(
      context: context,
      builder: (context) => WorkPackageDialog(
        initialWorkPackage: wp,
        wbsLevel2Options: wbsLevel2Ids,
      ),
    );

    if (result != null && mounted) {
      final index = data.workPackages.indexWhere((item) => item.id == wp.id);
      if (index != -1) {
        setState(() {
          data.workPackages[index] = result;
        });
        _saveWorkPackages(data.workPackages);
        _showInfo('Work package updated.');
      }
    }
  }

  Future<void> _deleteWorkPackage(String wpId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Work Package'),
        content:
            const Text('Are you sure you want to delete this work package?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final data = ProjectDataHelper.getData(context);
      setState(() {
        data.workPackages.removeWhere((wp) => wp.id == wpId);
      });
      _saveWorkPackages(data.workPackages);
      _showInfo('Work package deleted.');
    }
  }

  Future<void> _showWorkPackageDetail(WorkPackage wp) async {
    final data = ProjectDataHelper.getData(context);
    final activities =
        data.scheduleActivities.where((a) => a.workPackageId == wp.id).toList();

    await showDialog(
      context: context,
      builder: (context) => WorkPackageDetailView(
        workPackage: wp,
        activities: activities,
        onEdit: () {
          Navigator.of(context).pop();
          _editWorkPackage(wp);
        },
      ),
    );
  }

  Future<void> _saveWorkPackages(List<WorkPackage> workPackages) async {
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'planning_schedule',
      dataUpdater: (data) => data.copyWith(
        workPackages: workPackages,
      ),
      showSnackbar: false,
    );
  }

  Future<void> _importWorkPackagesFromDesignAndExecution() async {
    final data = ProjectDataHelper.getData(context);
    final newPackages = <WorkPackage>[];

    // Import from Design Planning Document
    try {
      final doc = DesignPlanningDocument.fromProjectData(data);
      for (final item in [
        ...doc.modules,
        ...doc.journeys,
        ...doc.interfaces,
        ...doc.integrations
      ]) {
        if (item.name.trim().isEmpty) continue;
        newPackages.add(WorkPackage(
          title: item.name,
          description: item.purpose,
          type: 'design',
          phase: 'design',
          status: 'planned',
          owner: item.owner,
          wbsLevel2Title: item.name,
        ));
      }
    } catch (e) {
      debugPrint('Failed to load design planning document: $e');
    }

    // Import from Execution Plan
    if (data.executionPhaseData != null && !data.executionPhaseData!.isEmpty) {
      final execData = data.executionPhaseData!;
      execData.sectionData.forEach((section, entries) {
        for (final entry in entries) {
          if (entry.title.trim().isEmpty) continue;
          String type = 'execution';
          if (section.toLowerCase().contains('construction')) {
            type = 'construction';
          } else if (section.toLowerCase().contains('agile')) {
            type = 'agile';
          }
          newPackages.add(WorkPackage(
            title: entry.title,
            description: entry.details,
            type: type,
            phase: 'execution',
            status: entry.status.toLowerCase() == 'complete'
                ? 'complete'
                : 'planned',
            wbsLevel2Title: entry.title,
          ));
        }
      });
    }

    if (newPackages.isEmpty) {
      _showInfo('No items found in Design or Execution plans.');
      return;
    }

    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Work Packages'),
        content: Text(
          'Found ${newPackages.length} work items from Design and Execution plans. '
          'Import them as Work Packages?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (shouldImport != true || !mounted) return;

    final updatedPackages = [...data.workPackages, ...newPackages];
    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'planning_schedule',
      dataUpdater: (data) => data.copyWith(workPackages: updatedPackages),
      showSnackbar: false,
    );

    setState(() {});
    _showInfo('Imported ${newPackages.length} Work Packages.');
  }

  Future<void> _generateIntegratedPackageChainsFromWbs() async {
    final data = ProjectDataHelper.getData(context);
    if (data.wbsTree.isEmpty) {
      _showInfo('No WBS items found.');
      return;
    }

    final generated = IntegratedWorkPackageService.generatePackageChainsFromWbs(
      wbsTree: data.wbsTree,
      methodology: _selectedMethodology,
    );
    if (generated.isEmpty) {
      _showInfo('No WBS Level 3 package candidates found.');
      return;
    }

    final existingIds = data.workPackages.map((wp) => wp.id).toSet();
    final newPackages =
        generated.where((wp) => !existingIds.contains(wp.id)).toList();
    if (newPackages.isEmpty) {
      _showInfo('Integrated package chains are already generated.');
      return;
    }

    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Integrated Package Chains'),
        content: Text(
          'Found ${newPackages.length} new EWP, procurement, and execution '
          'packages from WBS Level 3 candidates. Generate them now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (shouldImport != true) return;
    if (!mounted) return;

    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'planning_schedule',
      dataUpdater: (data) =>
          data.copyWith(workPackages: [...data.workPackages, ...newPackages]),
      showSnackbar: false,
    );

    setState(() {});
    _showInfo('Generated ${newPackages.length} integrated work packages.');
  }

  Future<void> _generateScheduleNetworkFromPackages() async {
    final data = ProjectDataHelper.getData(context);
    if (data.workPackages.isEmpty) {
      _showInfo('No work packages found.');
      return;
    }

    final generated =
        IntegratedWorkPackageService.generateScheduleActivitiesFromPackages(
      packages: data.workPackages,
      existingActivities: _buildScheduleActivities(),
    );

    if (generated.isEmpty) {
      _showInfo('Integrated schedule network is already generated.');
      return;
    }

    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Integrated Schedule Network'),
        content: Text(
          'Found ${generated.length} work package activities not yet in the '
          'schedule. Add them with engineering, procurement, and execution '
          'logic links?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create Network'),
          ),
        ],
      ),
    );
    if (shouldImport != true || !mounted) return;

    setState(() {
      _activityRows.addAll(
        generated.map(
          (activity) => _ScheduleRow.fromActivity(
            activity,
            onChanged: _handleActivityChanged,
          ),
        ),
      );
    });

    _handleActivityChanged();
    _showInfo('Added ${generated.length} integrated schedule activities.');
  }

  Future<void> _syncMilestonesFromSchedule() async {
    final provider = ProjectDataHelper.getProvider(context);
    final data = provider.projectData;
    final activities = _buildScheduleActivities();
    final generated = _generateIntegratedMilestones(
      activities: activities,
      packages: data.workPackages,
    );

    if (generated.isEmpty) {
      _showInfo('No integrated milestones could be derived yet.');
      return;
    }

    final merged = _mergeMilestones(
      existing: data.keyMilestones,
      generated: generated,
    );
    provider.updateField((data) => data.copyWith(keyMilestones: merged));

    final success =
        await provider.saveToFirebase(checkpoint: 'planning_schedule');
    if (!mounted) return;
    if (success) {
      _showInfo('Synced ${generated.length} schedule milestones.');
    } else {
      _showInfo(
        'Milestones synced locally. Save warning: ${provider.lastError ?? 'Could not save data'}.',
      );
    }
  }

  List<Milestone> _generateIntegratedMilestones({
    required List<ScheduleActivity> activities,
    required List<WorkPackage> packages,
  }) {
    final milestones = <Milestone>[];
    final hasConstruction = packages.any((package) =>
        package.packageClassification ==
        IntegratedWorkPackageService.constructionCwp);
    final hasExecutionScope = activities.any((activity) =>
            activity.phase.trim().toLowerCase() == 'execution' ||
            activity.workPackageType.trim().toLowerCase() == 'construction' ||
            activity.workPackageType.trim().toLowerCase() == 'execution') ||
        packages.any((package) =>
            package.phase.trim().toLowerCase() == 'execution' ||
            package.type.trim().toLowerCase() == 'construction' ||
            package.type.trim().toLowerCase() == 'execution');

    void addMilestone({
      required String name,
      required String discipline,
      required String dueDate,
      required String comments,
    }) {
      milestones.add(
        Milestone(
          name: name,
          discipline: discipline,
          dueDate: dueDate,
          references: 'Generated from integrated schedule',
          comments: comments,
        ),
      );
    }

    final designComplete = _latestDate([
      ...activities
          .where((activity) =>
              activity.phase.trim().toLowerCase() == 'design' ||
              activity.workPackageType.trim().toLowerCase() == 'design')
          .map((activity) => activity.dueDate),
      ...packages
          .where((package) =>
              package.packageClassification ==
                  IntegratedWorkPackageService.engineeringEwp ||
              package.phase.trim().toLowerCase() == 'design')
          .map((package) => package.plannedEnd ?? ''),
    ]);
    if (designComplete.isNotEmpty) {
      addMilestone(
        name: 'Design Complete',
        discipline: 'Engineering',
        dueDate: designComplete,
        comments: 'Latest engineering package completion date.',
      );
    }

    final contractAwarded = _latestDate([
      ...activities.map((activity) => activity.procurementAwardDate ?? ''),
      ...packages
          .map((package) => package.procurementBreakdown.awardDate)
          .where((date) => date.trim().isNotEmpty),
    ]);
    if (contractAwarded.isNotEmpty ||
        packages.any((package) =>
            package.packageClassification ==
            IntegratedWorkPackageService.procurementPackage)) {
      addMilestone(
        name: 'Contract Awarded',
        discipline: 'Procurement',
        dueDate: contractAwarded,
        comments: 'Derived from procurement award checkpoints.',
      );
    }

    final equipmentDelivered = _latestDate([
      ...packages
          .map((package) => package.procurementBreakdown.deliveryDate)
          .where((date) => date.trim().isNotEmpty),
      ...activities
          .where((activity) =>
              activity.workPackageType.trim().toLowerCase() == 'procurement')
          .map((activity) => activity.dueDate),
    ]);
    if (equipmentDelivered.isNotEmpty ||
        packages.any((package) =>
            package.packageClassification ==
            IntegratedWorkPackageService.procurementPackage)) {
      addMilestone(
        name: 'Equipment Delivered',
        discipline: 'Procurement',
        dueDate: equipmentDelivered,
        comments: 'Derived from procurement delivery checkpoints.',
      );
    }

    final executionComplete = _latestDate([
      ...activities
          .where((activity) =>
              activity.phase.trim().toLowerCase() == 'execution' &&
              activity.workPackageType.trim().toLowerCase() != 'procurement')
          .map((activity) => activity.dueDate),
      ...packages
          .where((package) =>
              package.phase.trim().toLowerCase() == 'execution' &&
              package.type.trim().toLowerCase() != 'procurement')
          .map((package) => package.plannedEnd ?? ''),
    ]);
    if (executionComplete.isNotEmpty || hasExecutionScope) {
      addMilestone(
        name: hasConstruction
            ? 'Construction Complete'
            : 'Implementation Complete',
        discipline: hasConstruction ? 'Construction' : 'Execution',
        dueDate: executionComplete,
        comments: 'Latest execution package completion date.',
      );
    }

    final commissioningStart = _earliestDate([
      ...activities
          .where((activity) =>
              _looksLikeCommissioning(activity.title) ||
              _looksLikeCommissioning(activity.milestone) ||
              activity.phase.trim().toLowerCase() == 'launch')
          .map((activity) => activity.startDate),
      ...packages
          .where((package) =>
              _looksLikeCommissioning(package.title) ||
              _looksLikeCommissioning(package.description) ||
              package.phase.trim().toLowerCase() == 'launch')
          .map((package) => package.plannedStart ?? ''),
    ]);
    if (commissioningStart.isNotEmpty || hasExecutionScope) {
      addMilestone(
        name: 'Commissioning Start',
        discipline: 'Commissioning',
        dueDate: commissioningStart,
        comments: 'Earliest commissioning or launch-start checkpoint.',
      );
    }

    final projectLaunch = _latestDate([
      ...activities
          .where((activity) =>
              activity.phase.trim().toLowerCase() == 'launch' ||
              _looksLikeLaunch(activity.title))
          .map((activity) => activity.dueDate),
      ...packages
          .where((package) =>
              package.phase.trim().toLowerCase() == 'launch' ||
              _looksLikeLaunch(package.title))
          .map((package) => package.plannedEnd ?? ''),
    ]);
    if (projectLaunch.isNotEmpty) {
      addMilestone(
        name: 'Project Launch',
        discipline: 'Launch',
        dueDate: projectLaunch,
        comments: 'Latest launch or go-live checkpoint.',
      );
    }

    return milestones;
  }

  List<Milestone> _mergeMilestones({
    required List<Milestone> existing,
    required List<Milestone> generated,
  }) {
    final merged = [...existing];
    final indexByName = <String, int>{};
    for (var i = 0; i < merged.length; i++) {
      final key = merged[i].name.trim().toLowerCase();
      if (key.isNotEmpty) {
        indexByName[key] = i;
      }
    }

    for (final milestone in generated) {
      final key = milestone.name.trim().toLowerCase();
      final index = indexByName[key];
      if (index == null) {
        merged.add(milestone);
        indexByName[key] = merged.length - 1;
      } else {
        merged[index] = Milestone(
          name: milestone.name,
          discipline: milestone.discipline,
          dueDate: milestone.dueDate,
          references: milestone.references,
          comments: milestone.comments,
        );
      }
    }

    return merged;
  }

  String _latestDate(Iterable<String> rawDates) {
    final parsed = rawDates.map(_parseDate).whereType<DateTime>().toList()
      ..sort();
    return parsed.isEmpty ? '' : _formatDate(parsed.last);
  }

  String _earliestDate(Iterable<String> rawDates) {
    final parsed = rawDates.map(_parseDate).whereType<DateTime>().toList()
      ..sort();
    return parsed.isEmpty ? '' : _formatDate(parsed.first);
  }

  bool _looksLikeCommissioning(String value) {
    final text = value.trim().toLowerCase();
    return text.contains('commission') ||
        text.contains('handover') ||
        text.contains('startup');
  }

  bool _looksLikeLaunch(String value) {
    final text = value.trim().toLowerCase();
    return text.contains('launch') ||
        text.contains('go-live') ||
        text.contains('golive');
  }

  Future<void> _calculateScheduleCostImpact() async {
    final data = ProjectDataHelper.getData(context);
    if (data.scheduleActivities.isEmpty) {
      _showInfo('No schedule activities to analyze.');
      return;
    }

    int delayedCount = 0;
    double totalImpact = 0;
    final now = DateTime.now();

    final updatedActivities = <ScheduleActivity>[];

    for (final activity in data.scheduleActivities) {
      final dueDate = _parseDate(activity.dueDate) ?? now;
      // Calculate delay
      final baseline = data.scheduleBaselineActivities.firstWhere(
        (baseline) => baseline.id == activity.id,
        orElse: () => activity,
      );

      final baselineEnd = _parseDate(baseline.dueDate);
      if (baselineEnd == null) continue;

      final delayDays = dueDate.difference(baselineEnd).inDays;
      if (delayDays <= 0) {
        updatedActivities.add(activity);
        continue;
      }

      delayedCount++;
      final dailyRate = activity.budgetedCost /
          (activity.durationDays > 0 ? activity.durationDays : 1);
      final delayPenalty =
          dailyRate * delayDays * 1.2; // 1.2x multiplier for penalties
      totalImpact += delayPenalty;

      // Update activity with cost impact info
      updatedActivities.add(activity);
    }

    // Update work packages with actual costs
    final updatedPackages = <WorkPackage>[];
    for (final wp in data.workPackages) {
      double wpActualCost = 0;
      for (final activityId in wp.scheduleActivityIds) {
        final activity = data.scheduleActivities.firstWhere(
          (a) => a.id == activityId,
          orElse: () => ScheduleActivity(id: activityId),
        );
        wpActualCost += activity.budgetedCost;
      }
      updatedPackages.add(wp.copyWith(actualCost: wpActualCost));
    }

    await ProjectDataHelper.updateAndSave(
      context: context,
      checkpoint: 'planning_schedule',
      dataUpdater: (data) => data.copyWith(
        scheduleActivities: updatedActivities,
        workPackages:
            updatedPackages.isNotEmpty ? updatedPackages : data.workPackages,
      ),
      showSnackbar: false,
    );

    setState(() {});
    _showInfo(
      'Analysis complete: $delayedCount delayed activities, '
      'estimated cost impact: \$${totalImpact.toStringAsFixed(0)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < AppBreakpoints.tablet;
    final showSidebar = screenWidth >= 1024;
    final data = ProjectDataHelper.getData(context);

    if (!_autoImportAttempted &&
        _activityRows.isEmpty &&
        data.wbsTree.isNotEmpty &&
        !_asPlanningFlag(data.planningNotes, _kScheduleInitializedNoteKey) &&
        !_asPlanningFlag(data.planningNotes, _kScheduleUserTouchedNoteKey)) {
      _autoImportAttempted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _importFromWbs(showConfirm: false, markTouched: false);
        }
      });
    }

    final computed = _computeSchedule(
      _activityRows,
      _scheduleStartDate ?? DateTime.now(),
    );

    const mainTabs = [
      'Master Schedule',
      'Gantt Chart',
      'List View',
      'Board View',
      'Work Packages',
      'Procurement',
      'Cost vs Schedule',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSidebar)
              DraggableSidebar(
                openWidth: AppBreakpoints.sidebarWidth(context),
                child: const InitiationLikeSidebar(activeItemLabel: 'Schedule'),
              ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 20 : 28,
                      24,
                      isMobile ? 20 : 28,
                      28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PlanningPhaseHeader(
                          title: 'Schedule',
                          onBack: () => PlanningPhaseNavigation.goToPrevious(
                            context,
                            'schedule',
                          ),
                          onForward: () => PlanningPhaseNavigation.goToNext(
                            context,
                            'schedule',
                          ),
                          showImportButton: false,
                          showContentButton: false,
                        ),
                        const SizedBox(height: 16),
                        _NotesCard(
                          controller: _notesController,
                          savedAt: _lastSavedAt,
                          expanded: _notesExpanded,
                          onToggleExpanded: () {
                            setState(() => _notesExpanded = !_notesExpanded);
                          },
                        ),
                        const SizedBox(height: 16),
                        _ScheduleTopBar(
                          methodology: _selectedMethodology,
                          onMethodologyChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedMethodology = value);
                            _handleActivityChanged();
                          },
                          isGeneratingAi: _isGeneratingSchedule,
                          baselineDate: _baselineDate,
                          onImportFromWbs: () => _importFromWbs(),
                          onGenerateAi: _generateScheduleFromAi,
                          onAddTask: _addTask,
                          onSyncMilestones: _syncMilestonesFromSchedule,
                          onValidate: _validateSchedule,
                          onApproveBaseline: _setBaseline,
                          onCalculateCostImpact: _calculateScheduleCostImpact,
                        ),
                        const SizedBox(height: 16),
                        _MainTabs(
                          tabs: mainTabs,
                          selectedIndex: _selectedMainTab,
                          onChanged: (index) {
                            setState(() => _selectedMainTab = index);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildMainContent(
                          context,
                          data,
                          computed,
                        ),
                      ],
                    ),
                  ),
                  const KazAiChatBubble(),
                  const AdminEditToggle(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    ProjectDataModel data,
    _ComputedSchedule computed,
  ) {
    switch (_selectedMainTab) {
      case 0:
        return ScheduleMasterView(
          workPackages: data.workPackages,
          scheduleActivities: data.scheduleActivities,
          onWorkPackageTap: (wp) {
            // Navigate to work package detail
          },
          onActivityTap: (activity) {
            _editTask(activity.id);
          },
        );
      case 1:
        return ScheduleGanttEnhanced(
          scheduleActivities: data.scheduleActivities,
          workPackages: data.workPackages,
          onActivityTap: (activity) {
            _editTask(activity.id);
          },
          selectedActivityId: _selectedTaskId,
          hoveredActivityId: _hoveredTaskId,
        );
      case 2:
        return _TimelineWorkspaceCard(
          selectedTab: 0, // Force List view
          onTabChanged: (_) {},
          timelineView: _timelineView,
          onTimelineViewChanged: (value) {
            if (value != null) {
              setState(() => _timelineView = value);
            }
          },
          onPickStartDate: _pickStartDate,
          startDate: _scheduleStartDate,
          onValidate: _validateSchedule,
          child: _TimelineList(
            rows: _activityRows,
            computed: computed,
            onChanged: _handleActivityChanged,
            onDelete: _deleteTask,
            onPickDate: _pickRowDate,
          ),
        );
      case 3:
        return _TimelineWorkspaceCard(
          selectedTab: 1, // Force Board view
          onTabChanged: (_) {},
          timelineView: _timelineView,
          onTimelineViewChanged: (value) {
            if (value != null) {
              setState(() => _timelineView = value);
            }
          },
          onPickStartDate: _pickStartDate,
          startDate: _scheduleStartDate,
          onValidate: _validateSchedule,
          child: _TimelineBoard(
            rows: _activityRows,
            computed: computed,
            onMoveTaskToStatus: _moveTaskToStatus,
            onEditTask: _editTask,
            onDeleteTask: _deleteTask,
          ),
        );
      case 4:
        return _WorkPackagesTab(
          workPackages: data.workPackages,
          scheduleActivities: data.scheduleActivities,
          onWorkPackageTap: (wp) => _showWorkPackageDetail(wp),
          onImportFromPlans: _importWorkPackagesFromDesignAndExecution,
          onGeneratePackageChains: _generateIntegratedPackageChainsFromWbs,
          onGenerateScheduleNetwork: _generateScheduleNetworkFromPackages,
          onAddWorkPackage: _createWorkPackage,
          onEditWorkPackage: _editWorkPackage,
          onDeleteWorkPackage: _deleteWorkPackage,
        );
      case 5:
        return _ProcurementTimelineTab(
          workPackages: data.workPackages,
          scheduleActivities: data.scheduleActivities,
        );
      case 6:
        return _CostVsScheduleTab(
          workPackages: data.workPackages,
          scheduleActivities: data.scheduleActivities,
          costEstimateItems: data.costEstimateItems,
          startDate: _scheduleStartDate ?? DateTime.now(),
          endDate: (_scheduleStartDate ?? DateTime.now())
              .add(const Duration(days: 365)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ignore: unused_element
class _WbsAndSummaryCard extends StatelessWidget {
  const _WbsAndSummaryCard({required this.rows, required this.wbsTree});

  final List<_ScheduleRow> rows;
  final List<WorkItem> wbsTree;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 1000;
    final unassigned =
        rows.where((row) => row.assigneeController.text.trim().isEmpty).length;
    final critical =
        rows.where((row) => row.priority.toLowerCase() == 'critical').length;
    final totalHours = rows.fold<double>(
      0,
      (sum, row) =>
          sum + (double.tryParse(row.hoursController.text.trim()) ?? 0),
    );
    final done =
        rows.where((row) => row.status.toLowerCase() == 'completed').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryColumn(
                  rows: rows,
                  unassigned: unassigned,
                  critical: critical,
                  totalHours: totalHours,
                  done: done,
                ),
                const SizedBox(height: 12),
                _buildWbsPane(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 240,
                  child: _buildSummaryColumn(
                    rows: rows,
                    unassigned: unassigned,
                    critical: critical,
                    totalHours: totalHours,
                    done: done,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildWbsPane()),
              ],
            ),
    );
  }

  Widget _buildSummaryColumn({
    required List<_ScheduleRow> rows,
    required int unassigned,
    required int critical,
    required double totalHours,
    required int done,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Work Breakdown Structure',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 10),
        _SummaryStat(label: 'Tasks', value: rows.length.toString()),
        _SummaryStat(label: 'Unassigned', value: unassigned.toString()),
        _SummaryStat(label: 'Critical', value: critical.toString()),
        _SummaryStat(
          label: 'Estimated Hours',
          value: totalHours.toStringAsFixed(1),
        ),
        _SummaryStat(label: 'Completed', value: done.toString()),
      ],
    );
  }

  Widget _buildWbsPane() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: wbsTree.isEmpty
          ? const Text(
              'No WBS entries yet.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            )
          : Column(
              children: wbsTree
                  .map((node) => _WbsNodeTile(node: node, level: 0))
                  .toList(),
            ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _WbsNodeTile extends StatelessWidget {
  const _WbsNodeTile({required this.node, required this.level});

  final WorkItem node;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: level * 18, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                node.children.isEmpty
                    ? Icons.subdirectory_arrow_right
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: const Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  node.title.trim().isEmpty ? 'Untitled WBS Node' : node.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (node.framework.trim().isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    node.framework,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
            ],
          ),
          if (node.children.isNotEmpty)
            ...node.children
                .map((child) => _WbsNodeTile(node: child, level: level + 1)),
        ],
      ),
    );
  }
}

class _TimelineWorkspaceCard extends StatelessWidget {
  const _TimelineWorkspaceCard({
    required this.selectedTab,
    required this.onTabChanged,
    required this.timelineView,
    required this.onTimelineViewChanged,
    required this.onPickStartDate,
    required this.startDate,
    required this.onValidate,
    required this.child,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final String timelineView;
  final ValueChanged<String?> onTimelineViewChanged;
  final VoidCallback onPickStartDate;
  final DateTime? startDate;
  final VoidCallback onValidate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Gantt', 'List', 'Board'];
    final isCompact = MediaQuery.sizeOf(context).width < 980;

    final tabChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < tabs.length; i++)
          ChoiceChip(
            label: Text(tabs[i]),
            selected: selectedTab == i,
            onSelected: (_) => onTabChanged(i),
            selectedColor: const Color(0xFFF59E0B),
            labelStyle: TextStyle(
              color: selectedTab == i
                  ? const Color(0xFF111827)
                  : const Color(0xFF4B5563),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
      ],
    );

    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton.icon(
          onPressed: onPickStartDate,
          icon: const Icon(Icons.event_outlined, size: 16),
          label: Text(
            startDate == null
                ? 'Start Date'
                : 'Start: ${_formatDate(startDate!)}',
          ),
        ),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppSemanticColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: timelineView == 'Months' ? timelineView : 'Months',
              onChanged: onTimelineViewChanged,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 'Months', child: Text('Months')),
              ],
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onValidate,
          icon: const Icon(Icons.verified_outlined, size: 16),
          label: const Text('Validate'),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Timeline',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          if (isCompact) ...[
            tabChips,
            const SizedBox(height: 8),
            controls,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: tabChips),
                const SizedBox(width: 12),
                controls,
              ],
            ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ignore: unused_element
class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _TimelineGantt extends StatelessWidget {
  const _TimelineGantt({
    required this.computed,
    required this.selectedTaskId,
    required this.hoveredTaskId,
    required this.onTaskTap,
    required this.onTaskHover,
  });

  final _ComputedSchedule computed;
  final String? selectedTaskId;
  final String? hoveredTaskId;
  final ValueChanged<String?> onTaskTap;
  final ValueChanged<String?> onTaskHover;

  static const double _leftColumnWidth = 280;
  static const double _chartHeightPerRow = 44;

  @override
  Widget build(BuildContext context) {
    final start = computed.minDate ?? DateTime.now();
    final end = computed.maxDate ?? start;
    final monthSegments = _generateMonthSegments(start, end);
    final totalDays = end.difference(start).inDays + 1;
    final timelineWidth = (totalDays * 2.6).clamp(800.0, 2400.0);
    final pxPerDay = timelineWidth / totalDays;
    final chartHeight = computed.items.length * _chartHeightPerRow + 32;
    final totalChartWidth = _leftColumnWidth + timelineWidth + 2;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: totalChartWidth,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppSemanticColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppSemanticColors.border)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: _leftColumnWidth,
                    child: Text(
                      'Task',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: timelineWidth,
                    child: SizedBox(
                      height: 18,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Row(
                          children: monthSegments.map((segment) {
                            final segmentWidth = segment.dayCount * pxPerDay;
                            return SizedBox(
                              width: segmentWidth,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    segment.label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: chartHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GanttGridPainter(
                        leftColumnWidth: _leftColumnWidth,
                        rowHeight: _chartHeightPerRow,
                        rowCount: computed.items.length,
                        monthSegments: monthSegments,
                        pxPerDay: pxPerDay,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DependencyPainter(
                        items: computed.items,
                        leftColumnWidth: _leftColumnWidth,
                        rowHeight: _chartHeightPerRow,
                        startDate: start,
                        pxPerDay: pxPerDay,
                        selectedTaskId: selectedTaskId,
                        hoveredTaskId: hoveredTaskId,
                      ),
                    ),
                  ),
                  for (int index = 0; index < computed.items.length; index++)
                    _GanttRow(
                      item: computed.items[index],
                      index: index,
                      startDate: start,
                      leftColumnWidth: _leftColumnWidth,
                      rowHeight: _chartHeightPerRow,
                      pxPerDay: pxPerDay,
                      isSelected: selectedTaskId == computed.items[index].id,
                      onTap: () => onTaskTap(computed.items[index].id),
                      onEnter: () => onTaskHover(computed.items[index].id),
                      onExit: () => onTaskHover(null),
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

class _GanttRow extends StatelessWidget {
  const _GanttRow({
    required this.item,
    required this.index,
    required this.startDate,
    required this.leftColumnWidth,
    required this.rowHeight,
    required this.pxPerDay,
    required this.isSelected,
    required this.onTap,
    required this.onEnter,
    required this.onExit,
  });

  final _ComputedItem item;
  final int index;
  final DateTime startDate;
  final double leftColumnWidth;
  final double rowHeight;
  final double pxPerDay;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final top = index * rowHeight + 6;
    final leftOffset = item.startDate.difference(startDate).inDays * pxPerDay;
    final durationDays = item.durationDays == 0 ? 1 : item.durationDays;
    final width = (durationDays * pxPerDay).clamp(18.0, 600.0);

    return Positioned(
      left: 0,
      right: 0,
      top: top,
      height: rowHeight - 10,
      child: Row(
        children: [
          SizedBox(
            width: leftColumnWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (item.isCritical)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'CP',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  left: leftOffset,
                  top: 3,
                  child: MouseRegion(
                    onEnter: (_) => onEnter(),
                    onExit: (_) => onExit(),
                    child: GestureDetector(
                      onTap: onTap,
                      child: Container(
                        height: rowHeight - 16,
                        width: width,
                        decoration: BoxDecoration(
                          color: item.isCritical
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFFF59E0B), width: 2)
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${(item.progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GanttGridPainter extends CustomPainter {
  const _GanttGridPainter({
    required this.leftColumnWidth,
    required this.rowHeight,
    required this.rowCount,
    required this.monthSegments,
    required this.pxPerDay,
  });

  final double leftColumnWidth;
  final double rowHeight;
  final int rowCount;
  final List<_TimelineSegment> monthSegments;
  final double pxPerDay;

  @override
  void paint(Canvas canvas, Size size) {
    final rowPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;

    for (int row = 0; row <= rowCount; row++) {
      final y = row * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rowPaint);
    }

    final dividerPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 1;

    double x = leftColumnWidth;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), dividerPaint);
    for (final segment in monthSegments) {
      x += segment.dayCount * pxPerDay;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), dividerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GanttGridPainter oldDelegate) => false;
}

class _DependencyPainter extends CustomPainter {
  const _DependencyPainter({
    required this.items,
    required this.leftColumnWidth,
    required this.rowHeight,
    required this.startDate,
    required this.pxPerDay,
    required this.selectedTaskId,
    required this.hoveredTaskId,
  });

  final List<_ComputedItem> items;
  final double leftColumnWidth;
  final double rowHeight;
  final DateTime startDate;
  final double pxPerDay;
  final String? selectedTaskId;
  final String? hoveredTaskId;

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedTaskId == null && hoveredTaskId == null) return;

    final focusIds = <String>{};
    if (selectedTaskId != null) focusIds.add(selectedTaskId!);
    if (hoveredTaskId != null) focusIds.add(hoveredTaskId!);

    final byId = {for (final item in items) item.id: item};

    final paint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final targetId in focusIds) {
      final target = byId[targetId];
      if (target == null) continue;

      final targetRow = items.indexWhere((element) => element.id == target.id);
      final targetY = targetRow * rowHeight + (rowHeight / 2);
      final targetX = leftColumnWidth +
          target.startDate.difference(startDate).inDays * pxPerDay;

      for (final predecessorId in target.predecessorIds) {
        final predecessor = byId[predecessorId];
        if (predecessor == null) continue;

        final predecessorRow =
            items.indexWhere((element) => element.id == predecessor.id);
        final predecessorY = predecessorRow * rowHeight + (rowHeight / 2);
        final predecessorWidth =
            (predecessor.durationDays == 0 ? 1 : predecessor.durationDays) *
                pxPerDay;
        final predecessorX = leftColumnWidth +
            predecessor.startDate.difference(startDate).inDays * pxPerDay +
            predecessorWidth;

        final path = Path()
          ..moveTo(predecessorX, predecessorY)
          ..lineTo(predecessorX + 12, predecessorY)
          ..lineTo(predecessorX + 12, targetY)
          ..lineTo(targetX, targetY);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DependencyPainter oldDelegate) {
    return oldDelegate.selectedTaskId != selectedTaskId ||
        oldDelegate.hoveredTaskId != hoveredTaskId ||
        oldDelegate.items != items;
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({
    required this.rows,
    required this.computed,
    required this.onChanged,
    required this.onDelete,
    required this.onPickDate,
  });

  final List<_ScheduleRow> rows;
  final _ComputedSchedule computed;
  final VoidCallback onChanged;
  final ValueChanged<String> onDelete;
  final Future<void> Function(_ScheduleRow row, {required bool isDueDate})
      onPickDate;

  static const _statusOptions = [
    'pending',
    'in_progress',
    'completed',
    'overdue',
  ];
  static const _priorityOptions = ['low', 'medium', 'high', 'critical'];

  @override
  Widget build(BuildContext context) {
    final computedById = {
      for (final item in computed.items) item.id: item,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppSemanticColors.border),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: FixedColumnWidth(160),
            1: FixedColumnWidth(90),
            2: FixedColumnWidth(85),
            3: FixedColumnWidth(160),
            4: FixedColumnWidth(110),
            5: FixedColumnWidth(100),
            6: FixedColumnWidth(130),
            7: FixedColumnWidth(110),
            8: FixedColumnWidth(110),
            9: FixedColumnWidth(110),
            10: FixedColumnWidth(110),
            11: FixedColumnWidth(100),
            12: FixedColumnWidth(160),
            13: FixedColumnWidth(110),
            14: FixedColumnWidth(110),
            15: FixedColumnWidth(110),
            16: FixedColumnWidth(48),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: AppSemanticColors.border),
            verticalInside: BorderSide(color: AppSemanticColors.border),
          ),
          children: [
            _headerRow(),
            ...rows.map((row) {
              final computedItem = computedById[row.id];
              final computedStart = computedItem?.startDate;
              final computedEnd = computedItem?.endDate;
              final statusValue = _normalizeScheduleStatus(row.status);
              final priorityValue = _normalizeSchedulePriority(row.priority);
              final predecessorCandidates =
                  rows.where((candidate) => candidate.id != row.id).toList();
              final predecessorIds =
                  predecessorCandidates.map((item) => item.id).toSet();
              final predecessorValue =
                  predecessorIds.contains(row.predecessorId)
                      ? row.predecessorId
                      : null;

              if (row.status != statusValue) {
                row.status = statusValue;
              }
              if (row.priority != priorityValue) {
                row.priority = priorityValue;
              }

              return TableRow(
                children: [
                  _cell(
                    TextField(
                      controller: row.titleController,
                      onChanged: (_) => onChanged(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  _cell(
                    TextFormField(
                      initialValue: row.wbsId,
                      onChanged: (value) {
                        row.wbsId = value.trim();
                        onChanged();
                      },
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  _cell(
                    TextField(
                      controller: row.durationController,
                      onChanged: (_) => onChanged(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  _cell(
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        isExpanded: true,
                        value: predecessorValue,
                        hint: const Text('None'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...predecessorCandidates.map((candidate) {
                            final label =
                                candidate.titleController.text.trim().isEmpty
                                    ? 'Untitled task'
                                    : candidate.titleController.text.trim();
                            return DropdownMenuItem<String?>(
                              value: candidate.id,
                              child:
                                  Text(label, overflow: TextOverflow.ellipsis),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          final previous = row.predecessorId;
                          row.predecessorId = value;
                          final dependencies = row.normalizedDependencyIds;
                          if (previous != null && previous != value) {
                            dependencies.remove(previous);
                          }
                          if (value == null) {
                            dependencies.remove(previous);
                          } else if (!dependencies.contains(value)) {
                            dependencies.insert(0, value);
                          }
                          row.dependencyIds = dependencies;
                          onChanged();
                        },
                      ),
                    ),
                  ),
                  _cell(
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value:
                            _TimelineList._statusOptions.contains(statusValue)
                                ? statusValue
                                : null,
                        hint: const Text('Pending'),
                        items: _statusOptions
                            .map((option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(_titleCase(option)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          row.status = value;
                          onChanged();
                        },
                      ),
                    ),
                  ),
                  _cell(
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _TimelineList._priorityOptions
                                .contains(priorityValue)
                            ? priorityValue
                            : null,
                        hint: const Text('Medium'),
                        items: _priorityOptions
                            .map((option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(_titleCase(option)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          row.priority = value;
                          onChanged();
                        },
                      ),
                    ),
                  ),
                  _cell(
                    TextField(
                      controller: row.assigneeController,
                      onChanged: (_) => onChanged(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  _cell(
                    TextField(
                      controller: row.disciplineController,
                      onChanged: (_) => onChanged(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  _cell(
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: row.progressController,
                            onChanged: (_) => onChanged(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        const Text('%', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                  _cell(
                    TextButton(
                      onPressed: () => onPickDate(row, isDueDate: false),
                      child: Text(
                        row.startDateController.text.trim().isNotEmpty
                            ? row.startDateController.text.trim()
                            : (computedStart != null
                                ? _formatDate(computedStart)
                                : '-'),
                      ),
                    ),
                  ),
                  _cell(
                    TextButton(
                      onPressed: () => onPickDate(row, isDueDate: true),
                      child: Text(
                        row.dueDateController.text.trim().isNotEmpty
                            ? row.dueDateController.text.trim()
                            : (computedEnd != null
                                ? _formatDate(computedEnd)
                                : '-'),
                      ),
                    ),
                  ),
                  _cell(
                    TextField(
                      controller: row.hoursController,
                      onChanged: (_) => onChanged(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  _cell(
                    TextField(
                      controller: row.estimatingBasisController,
                      onChanged: (_) => onChanged(),
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Basis',
                      ),
                    ),
                  ),
                  _cell(
                    TextField(
                      controller: row.milestoneController,
                      onChanged: (_) => onChanged(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  _cell(
                    Text(
                      '\$${row.budgetedCost.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _cell(
                    Text(
                      '\$${row.actualCost.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _cell(
                    Builder(
                      builder: (context) {
                        final variance = row.budgetedCost - row.actualCost;
                        final varianceColor = variance >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444);
                        return Text(
                          '${variance >= 0 ? '+' : '-'}\$${variance.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: varianceColor,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
                  _cell(
                    IconButton(
                      onPressed: () => onDelete(row.id),
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  TableRow _headerRow() {
    TextStyle style = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF4B5563),
    );

    Widget label(String text) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(text, style: style),
        );

    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
      children: [
        label('Task Name'),
        label('WBS ID'),
        label('Duration'),
        label('Predecessor'),
        label('Status'),
        label('Priority'),
        label('Assignee'),
        label('Discipline'),
        label('Progress'),
        label('Start Date'),
        label('Due Date'),
        label('Est. Hours'),
        label('Estimate Basis'),
        label('Milestone'),
        label('Budgeted Cost'),
        label('Actual Cost'),
        label('Cost Variance'),
        label(''),
      ],
    );
  }

  Widget _cell(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: child,
    );
  }
}

class _TimelineBoard extends StatelessWidget {
  const _TimelineBoard({
    required this.rows,
    required this.computed,
    required this.onMoveTaskToStatus,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final List<_ScheduleRow> rows;
  final _ComputedSchedule computed;
  final void Function(String taskId, String targetStatus) onMoveTaskToStatus;
  final ValueChanged<String> onEditTask;
  final ValueChanged<String> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    final computedById = {
      for (final item in computed.items) item.id: item,
    };

    final now = DateTime.now();
    final toDo = <_ScheduleRow>[];
    final inProgress = <_ScheduleRow>[];
    final done = <_ScheduleRow>[];
    final overdue = <_ScheduleRow>[];

    for (final row in rows) {
      final normalized = row.status.toLowerCase();
      final due = _parseDate(row.dueDateController.text) ??
          computedById[row.id]?.endDate;
      final isOverdue =
          due != null && due.isBefore(now) && normalized != 'completed';

      if (normalized == 'completed') {
        done.add(row);
      } else if (isOverdue || normalized == 'overdue') {
        overdue.add(row);
      } else if (normalized == 'in_progress') {
        inProgress.add(row);
      } else {
        toDo.add(row);
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BoardColumn(
            title: 'To Do',
            color: const Color(0xFFF3F4F6),
            statusValue: 'pending',
            rows: toDo,
            computedById: computedById,
            onMoveTaskToStatus: onMoveTaskToStatus,
            onEditTask: onEditTask,
            onDeleteTask: onDeleteTask,
          ),
          const SizedBox(width: 12),
          _BoardColumn(
            title: 'In Progress',
            color: const Color(0xFFEAF4FF),
            statusValue: 'in_progress',
            rows: inProgress,
            computedById: computedById,
            onMoveTaskToStatus: onMoveTaskToStatus,
            onEditTask: onEditTask,
            onDeleteTask: onDeleteTask,
          ),
          const SizedBox(width: 12),
          _BoardColumn(
            title: 'Done',
            color: const Color(0xFFEAFBF1),
            statusValue: 'completed',
            rows: done,
            computedById: computedById,
            onMoveTaskToStatus: onMoveTaskToStatus,
            onEditTask: onEditTask,
            onDeleteTask: onDeleteTask,
          ),
          const SizedBox(width: 12),
          _BoardColumn(
            title: 'Overdue',
            color: const Color(0xFFFDECEE),
            statusValue: 'overdue',
            rows: overdue,
            computedById: computedById,
            onMoveTaskToStatus: onMoveTaskToStatus,
            onEditTask: onEditTask,
            onDeleteTask: onDeleteTask,
          ),
        ],
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.title,
    required this.color,
    required this.statusValue,
    required this.rows,
    required this.computedById,
    required this.onMoveTaskToStatus,
    required this.onEditTask,
    required this.onDeleteTask,
  });

  final String title;
  final Color color;
  final String statusValue;
  final List<_ScheduleRow> rows;
  final Map<String, _ComputedItem> computedById;
  final void Function(String taskId, String targetStatus) onMoveTaskToStatus;
  final ValueChanged<String> onEditTask;
  final ValueChanged<String> onDeleteTask;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data.trim().isNotEmpty,
      onAcceptWithDetails: (details) {
        onMoveTaskToStatus(details.data, statusValue);
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: isActive
                ? Border.all(color: const Color(0xFF3B82F6), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      rows.length.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (rows.isEmpty)
                Text(
                  isActive ? 'Drop task here' : 'No tasks',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                )
              else
                ...rows.map((row) {
                  final computed = computedById[row.id];
                  return Draggable<String>(
                    data: row.id,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: 260,
                        child: _BoardTaskCard(
                          row: row,
                          computed: computed,
                          onEdit: () => onEditTask(row.id),
                          onDelete: () => onDeleteTask(row.id),
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.45,
                      child: _BoardTaskCard(
                        row: row,
                        computed: computed,
                        onEdit: () => onEditTask(row.id),
                        onDelete: () => onDeleteTask(row.id),
                      ),
                    ),
                    child: _BoardTaskCard(
                      row: row,
                      computed: computed,
                      onEdit: () => onEditTask(row.id),
                      onDelete: () => onDeleteTask(row.id),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _BoardTaskCard extends StatelessWidget {
  const _BoardTaskCard({
    required this.row,
    required this.computed,
    required this.onEdit,
    required this.onDelete,
  });

  final _ScheduleRow row;
  final _ComputedItem? computed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = (double.tryParse(row.progressController.text.trim()) ?? 0)
        .clamp(0, 100);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.titleController.text.trim().isEmpty
                      ? 'Untitled task'
                      : row.titleController.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                iconSize: 16,
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          if (row.wbsId.trim().isNotEmpty)
            Text(
              'WBS ${row.wbsId}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
            ),
          const SizedBox(height: 6),
          Text(
            row.assigneeController.text.trim().isEmpty
                ? 'Unassigned'
                : row.assigneeController.text.trim(),
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            'Due ${row.dueDateController.text.trim().isNotEmpty ? row.dueDateController.text.trim() : (computed != null ? _formatDate(computed!.endDate) : '-')}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskDraft {
  const _TaskDraft({
    required this.title,
    required this.wbsId,
    required this.durationDays,
    required this.predecessorId,
    required this.dependencyIds,
    required this.isMilestone,
    required this.status,
    required this.priority,
    required this.assignee,
    required this.discipline,
    required this.progressPercent,
    required this.startDate,
    required this.dueDate,
    required this.estimatedHours,
    required this.estimatingBasis,
    required this.milestone,
  });

  final String title;
  final String wbsId;
  final int durationDays;
  final String? predecessorId;
  final List<String> dependencyIds;
  final bool isMilestone;
  final String status;
  final String priority;
  final String assignee;
  final String discipline;
  final double progressPercent;
  final String startDate;
  final String dueDate;
  final double estimatedHours;
  final String estimatingBasis;
  final String milestone;
}

class _ScheduleRow {
  _ScheduleRow({
    required this.id,
    this.wbsId = '',
    String title = '',
    int durationDays = 5,
    this.predecessorId,
    List<String>? dependencyIds,
    this.isMilestone = false,
    String status = 'pending',
    String priority = 'medium',
    String assignee = '',
    String discipline = '',
    double progressPercent = 0,
    String startDate = '',
    String dueDate = '',
    double estimatedHours = 0,
    String estimatingBasis = '',
    String milestone = '',
    this.workPackageId = '',
    this.workPackageTitle = '',
    this.workPackageType = '',
    this.phase = '',
    this.wbsLevel2Id = '',
    this.wbsLevel2Title = '',
    this.contractId = '',
    this.budgetedCost = 0,
    this.actualCost = 0,
    this.onChanged,
  })  : status = _normalizeScheduleStatus(status),
        priority = _normalizeSchedulePriority(priority),
        titleController = TextEditingController(text: title),
        durationController =
            TextEditingController(text: durationDays.toString()),
        assigneeController = TextEditingController(text: assignee),
        disciplineController = TextEditingController(text: discipline),
        progressController = TextEditingController(
          text: ((progressPercent * 100).clamp(0, 100)).round().toString(),
        ),
        startDateController = TextEditingController(text: startDate),
        dueDateController = TextEditingController(text: dueDate),
        hoursController = TextEditingController(
          text: estimatedHours == 0 ? '' : estimatedHours.toStringAsFixed(1),
        ),
        estimatingBasisController =
            TextEditingController(text: estimatingBasis),
        milestoneController = TextEditingController(text: milestone),
        dependencyIds = dependencyIds ??
            (predecessorId == null ? <String>[] : <String>[predecessorId]) {
    if (onChanged != null) {
      titleController.addListener(onChanged!);
      durationController.addListener(onChanged!);
      assigneeController.addListener(onChanged!);
      disciplineController.addListener(onChanged!);
      progressController.addListener(onChanged!);
      startDateController.addListener(onChanged!);
      dueDateController.addListener(onChanged!);
      hoursController.addListener(onChanged!);
      estimatingBasisController.addListener(onChanged!);
      milestoneController.addListener(onChanged!);
    }
  }

  final String id;
  String wbsId;
  final TextEditingController titleController;
  final TextEditingController durationController;
  final TextEditingController assigneeController;
  final TextEditingController disciplineController;
  final TextEditingController progressController;
  final TextEditingController startDateController;
  final TextEditingController dueDateController;
  final TextEditingController hoursController;
  final TextEditingController estimatingBasisController;
  final TextEditingController milestoneController;
  String? predecessorId;
  List<String> dependencyIds;
  bool isMilestone;
  String status;
  String priority;
  String workPackageId;
  String workPackageTitle;
  String workPackageType;
  String phase;
  String wbsLevel2Id;
  String wbsLevel2Title;
  String contractId;
  double budgetedCost;
  double actualCost;
  final VoidCallback? onChanged;

  factory _ScheduleRow.fromActivity(
    ScheduleActivity activity, {
    String? idOverride,
    VoidCallback? onChanged,
  }) {
    return _ScheduleRow(
      id: idOverride ??
          (activity.wbsId.isNotEmpty ? activity.wbsId : activity.id),
      wbsId: activity.wbsId,
      title: activity.title,
      durationDays: activity.durationDays,
      predecessorId: activity.predecessorIds.isEmpty
          ? null
          : activity.predecessorIds.first,
      dependencyIds: {
        ...activity.predecessorIds,
        ...activity.dependencyIds,
      }.where((id) => id.trim().isNotEmpty).toList(),
      isMilestone: activity.isMilestone,
      status: activity.status,
      priority: activity.priority,
      assignee: activity.assignee,
      discipline: activity.discipline,
      progressPercent: activity.progress,
      startDate: activity.startDate,
      dueDate: activity.dueDate,
      estimatedHours: activity.estimatedHours,
      estimatingBasis: activity.estimatingBasis,
      milestone: activity.milestone,
      workPackageId: activity.workPackageId,
      workPackageTitle: activity.workPackageTitle,
      workPackageType: activity.workPackageType,
      phase: activity.phase,
      wbsLevel2Id: activity.wbsLevel2Id,
      wbsLevel2Title: activity.wbsLevel2Title,
      contractId: activity.contractId,
      budgetedCost: activity.budgetedCost,
      actualCost: activity.actualCost,
      onChanged: onChanged,
    );
  }

  void dispose() {
    titleController.dispose();
    durationController.dispose();
    assigneeController.dispose();
    disciplineController.dispose();
    progressController.dispose();
    startDateController.dispose();
    dueDateController.dispose();
    hoursController.dispose();
    estimatingBasisController.dispose();
    milestoneController.dispose();
  }

  List<String> get normalizedDependencyIds {
    final values = <String>[
      if (predecessorId != null && predecessorId!.trim().isNotEmpty)
        predecessorId!.trim(),
      ...dependencyIds.map((id) => id.trim()),
    ].where((id) => id.isNotEmpty).toList();
    return values.toSet().toList();
  }
}

class _ComputedSchedule {
  const _ComputedSchedule({
    required this.items,
    required this.totalDurationDays,
    required this.minDate,
    required this.maxDate,
  });

  final List<_ComputedItem> items;
  final int totalDurationDays;
  final DateTime? minDate;
  final DateTime? maxDate;
}

class _ComputedItem {
  const _ComputedItem({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.startOffsetDays,
    required this.isCritical,
    required this.progress,
    required this.predecessorIds,
  });

  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final int startOffsetDays;
  final bool isCritical;
  final double progress;
  final List<String> predecessorIds;
}

class _ScheduleValidationReport {
  const _ScheduleValidationReport({
    required this.taskCount,
    required this.unassignedTaskCount,
    required this.noPredecessorCount,
    required this.cpm,
    required this.packageWarnings,
    required this.unlinkedWbsCandidates,
    required this.missingEstimateBasis,
    required this.resourceWarnings,
    required this.contractAlignmentWarnings,
    required this.baselineVarianceWarnings,
    required this.milestoneWarnings,
  });

  final int taskCount;
  final int unassignedTaskCount;
  final int noPredecessorCount;
  final CpmResult cpm;
  final List<_PackageWarning> packageWarnings;
  final List<WorkItem> unlinkedWbsCandidates;
  final List<ScheduleActivity> missingEstimateBasis;
  final List<_ResourceWarning> resourceWarnings;
  final List<_ContractAlignmentWarning> contractAlignmentWarnings;
  final List<_BaselineVarianceWarning> baselineVarianceWarnings;
  final List<_MilestoneWarning> milestoneWarnings;
}

class _PackageWarning {
  const _PackageWarning({required this.package, required this.warnings});

  final WorkPackage package;
  final List<String> warnings;
}

class _ResourceWarning {
  const _ResourceWarning({required this.title, required this.detail});

  final String title;
  final String detail;
}

class _ContractAlignmentWarning {
  const _ContractAlignmentWarning({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;
}

class _BaselineVarianceWarning {
  const _BaselineVarianceWarning({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;
}

class _MilestoneWarning {
  const _MilestoneWarning({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;
}

class _ScheduleValidationDialog extends StatelessWidget {
  const _ScheduleValidationDialog({required this.report});

  final _ScheduleValidationReport report;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Schedule Validation'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ValidationStat(
                    label: 'Tasks',
                    value: report.taskCount.toString(),
                    color: const Color(0xFF2563EB),
                  ),
                  _ValidationStat(
                    label: 'Unassigned',
                    value: report.unassignedTaskCount.toString(),
                    color: const Color(0xFFF59E0B),
                  ),
                  _ValidationStat(
                    label: 'No Predecessor',
                    value: report.noPredecessorCount.toString(),
                    color: const Color(0xFFF59E0B),
                  ),
                  _ValidationStat(
                    label: 'Logic Warnings',
                    value: report.cpm.diagnostics.length.toString(),
                    color: const Color(0xFFEF4444),
                  ),
                  _ValidationStat(
                    label: 'Readiness Warnings',
                    value: report.packageWarnings
                        .fold<int>(0, (sum, item) => sum + item.warnings.length)
                        .toString(),
                    color: const Color(0xFFEF4444),
                  ),
                  _ValidationStat(
                    label: 'Resource Warnings',
                    value: report.resourceWarnings.length.toString(),
                    color: const Color(0xFFEF4444),
                  ),
                  _ValidationStat(
                    label: 'Contract Warnings',
                    value: report.contractAlignmentWarnings.length.toString(),
                    color: const Color(0xFFEF4444),
                  ),
                  _ValidationStat(
                    label: 'Baseline Variance',
                    value: report.baselineVarianceWarnings.length.toString(),
                    color: const Color(0xFFF59E0B),
                  ),
                  _ValidationStat(
                    label: 'Milestone Gaps',
                    value: report.milestoneWarnings.length.toString(),
                    color: const Color(0xFFF59E0B),
                  ),
                  _ValidationStat(
                    label: 'Critical Path',
                    value: report.cpm.criticalPathIds.length.toString(),
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ValidationSection(
                title: 'CPM Logic',
                emptyText: 'No CPM logic warnings.',
                children: report.cpm.diagnostics
                    .map((diagnostic) => _ValidationLine(
                          title: diagnostic.activityId,
                          detail: diagnostic.message,
                        ))
                    .toList(),
              ),
              _ValidationSection(
                title: 'Readiness Warnings',
                emptyText: 'No package readiness warnings.',
                children: report.packageWarnings
                    .map((item) => _ValidationLine(
                          title: item.package.title.isNotEmpty
                              ? item.package.title
                              : item.package.id,
                          detail: item.warnings.join('\n'),
                        ))
                    .toList(),
              ),
              _ValidationSection(
                title: 'Unlinked WBS Level 3 Candidates',
                emptyText: 'All WBS Level 3 candidates are linked to packages.',
                children: report.unlinkedWbsCandidates
                    .map((item) => _ValidationLine(
                          title: item.title.isNotEmpty ? item.title : item.id,
                          detail: item.description.isNotEmpty
                              ? item.description
                              : 'No package chain generated for this candidate.',
                        ))
                    .toList(),
              ),
              _ValidationSection(
                title: 'Missing Estimate Basis',
                emptyText:
                    'Critical and longer-duration activities have estimate basis.',
                children: report.missingEstimateBasis
                    .map((activity) => _ValidationLine(
                          title: activity.title.isNotEmpty
                              ? activity.title
                              : activity.id,
                          detail:
                              'Duration ${activity.durationDays} days, critical path: ${activity.isCriticalPath ? 'yes' : 'no'}.',
                        ))
                    .toList(),
              ),
              _ValidationSection(
                title: 'Resource Loading',
                emptyText: 'No resource loading warnings.',
                children: report.resourceWarnings
                    .map((warning) => _ValidationLine(
                          title: warning.title,
                          detail: warning.detail,
                        ))
                    .toList(),
              ),
              _ValidationSection(
                title: 'Contract Alignment',
                emptyText: 'No contract alignment warnings.',
                children: report.contractAlignmentWarnings
                    .map((warning) => _ValidationLine(
                          title: warning.title,
                          detail: warning.detail,
                        ))
                    .toList(),
              ),
              _ValidationSection(
                title: 'Baseline Variance',
                emptyText: 'No baseline variance warnings.',
                children: report.baselineVarianceWarnings
                    .map((warning) => _ValidationLine(
                          title: warning.title,
                          detail: warning.detail,
                        ))
                    .toList(),
              ),
              _ValidationSection(
                title: 'Milestone Coverage',
                emptyText: 'No milestone coverage warnings.',
                children: report.milestoneWarnings
                    .map((warning) => _ValidationLine(
                          title: warning.title,
                          detail: warning.detail,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ValidationStat extends StatelessWidget {
  const _ValidationStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValidationSection extends StatelessWidget {
  const _ValidationSection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          if (children.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(fontSize: 12, color: Color(0xFF047857)),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

class _ValidationLine extends StatelessWidget {
  const _ValidationLine({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF78350F),
            ),
          ),
        ],
      ),
    );
  }
}

_ComputedSchedule _computeSchedule(List<_ScheduleRow> rows, DateTime start) {
  final byId = {for (final row in rows) row.id: row};
  final resolved = <String, _ComputedItem>{};
  int maxEndOffset = 0;

  int durationFor(_ScheduleRow row) {
    if (row.isMilestone) return 0;
    return int.tryParse(row.durationController.text.trim()) ?? 5;
  }

  _ComputedItem compute(String id, [Set<String>? visiting]) {
    if (resolved.containsKey(id)) return resolved[id]!;
    final row = byId[id]!;
    visiting ??= <String>{};

    if (visiting.contains(id)) {
      return _ComputedItem(
        id: id,
        title: row.titleController.text.trim(),
        startDate: start,
        endDate: start,
        durationDays: durationFor(row),
        startOffsetDays: 0,
        isCritical: false,
        progress: (double.tryParse(row.progressController.text.trim()) ?? 0)
                .clamp(0, 100) /
            100,
        predecessorIds: row.normalizedDependencyIds,
      );
    }

    visiting.add(id);

    int startOffset = 0;
    for (final dependencyId in row.normalizedDependencyIds) {
      if (!byId.containsKey(dependencyId)) continue;
      final predecessor = compute(dependencyId, visiting);
      final candidate = predecessor.startOffsetDays + predecessor.durationDays;
      if (candidate > startOffset) {
        startOffset = candidate;
      }
    }

    final duration = durationFor(row);
    final explicitStart = _parseDate(row.startDateController.text);
    final explicitDue = _parseDate(row.dueDateController.text);

    final startDate = explicitStart ?? start.add(Duration(days: startOffset));
    final fallbackEnd =
        startDate.add(Duration(days: duration == 0 ? 0 : duration - 1));
    final endDate = explicitDue ?? fallbackEnd;

    final item = _ComputedItem(
      id: id,
      title: row.titleController.text.trim().isEmpty
          ? 'Untitled task'
          : row.titleController.text.trim(),
      startDate: startDate,
      endDate: endDate,
      durationDays: duration,
      startOffsetDays: startOffset,
      isCritical: false,
      progress: (double.tryParse(row.progressController.text.trim()) ?? 0)
              .clamp(0, 100) /
          100,
      predecessorIds: row.normalizedDependencyIds,
    );

    resolved[id] = item;

    final endOffset = item.startDate.difference(start).inDays +
        (item.durationDays == 0 ? 1 : item.durationDays);
    if (endOffset > maxEndOffset) {
      maxEndOffset = endOffset;
    }

    visiting.remove(id);
    return item;
  }

  for (final row in rows) {
    compute(row.id);
  }

  final longest = maxEndOffset;
  final criticalIds = <String>{};

  for (final item in resolved.values) {
    final end = item.startDate.difference(start).inDays + item.durationDays;
    if (end == longest) {
      criticalIds.add(item.id);
    }
  }

  final items = resolved.values
      .map(
        (item) => _ComputedItem(
          id: item.id,
          title: item.title,
          startDate: item.startDate,
          endDate: item.endDate,
          durationDays: item.durationDays,
          startOffsetDays: item.startOffsetDays,
          isCritical: criticalIds.contains(item.id),
          progress: item.progress,
          predecessorIds: item.predecessorIds,
        ),
      )
      .toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));

  DateTime? minDate;
  DateTime? maxDate;
  for (final item in items) {
    if (minDate == null || item.startDate.isBefore(minDate)) {
      minDate = item.startDate;
    }
    if (maxDate == null || item.endDate.isAfter(maxDate)) {
      maxDate = item.endDate;
    }
  }

  return _ComputedSchedule(
    items: items,
    totalDurationDays: longest,
    minDate: minDate,
    maxDate: maxDate,
  );
}

class _TimelineSegment {
  const _TimelineSegment({required this.label, required this.dayCount});

  final String label;
  final int dayCount;
}

List<_TimelineSegment> _generateMonthSegments(DateTime start, DateTime end) {
  final segments = <_TimelineSegment>[];
  final inclusiveEnd = DateTime(end.year, end.month, end.day);
  DateTime cursor = DateTime(start.year, start.month, 1);

  while (!cursor.isAfter(inclusiveEnd)) {
    final bucketStart = cursor.isBefore(start) ? start : cursor;
    final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
    final bucketEnd = nextMonth.subtract(const Duration(days: 1));
    final actualEnd =
        bucketEnd.isAfter(inclusiveEnd) ? inclusiveEnd : bucketEnd;
    final dayCount = actualEnd.difference(bucketStart).inDays + 1;

    segments.add(
      _TimelineSegment(label: _formatMonth(cursor), dayCount: dayCount),
    );
    cursor = nextMonth;
  }

  return segments;
}

DateTime? _parseDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String _formatMonth(DateTime date) {
  const months = [
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
  return '${months[date.month - 1]} ${date.year}';
}

String _titleCase(String value) {
  final words = value.split('_');
  return words.map((word) {
    if (word.isEmpty) return word;
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }).join(' ');
}

String _normalizeScheduleStatus(String raw) {
  final value = raw.trim().toLowerCase().replaceAll(' ', '_');
  const allowed = {'pending', 'in_progress', 'completed', 'overdue'};
  return allowed.contains(value) ? value : 'pending';
}

String _normalizeSchedulePriority(String raw) {
  final value = raw.trim().toLowerCase();
  const allowed = {'low', 'medium', 'high', 'critical'};
  return allowed.contains(value) ? value : 'medium';
}

class _MainTabs extends StatelessWidget {
  const _MainTabs({
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 1100;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: isCompact
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildChips(),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildChips(),
            ),
    );
  }

  List<Widget> _buildChips() {
    return List.generate(tabs.length, (index) {
      return ChoiceChip(
        label: Text(tabs[index]),
        selected: selectedIndex == index,
        onSelected: (_) => onChanged(index),
        selectedColor: const Color(0xFFF59E0B),
        labelStyle: TextStyle(
          color: selectedIndex == index
              ? const Color(0xFF111827)
              : const Color(0xFF4B5563),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      );
    });
  }
}

class _WorkPackagesTab extends StatelessWidget {
  const _WorkPackagesTab({
    required this.workPackages,
    required this.scheduleActivities,
    this.onWorkPackageTap,
    this.onImportFromPlans,
    this.onGeneratePackageChains,
    this.onGenerateScheduleNetwork,
    this.onAddWorkPackage,
    this.onEditWorkPackage,
    this.onDeleteWorkPackage,
  });

  final List<WorkPackage> workPackages;
  final List<ScheduleActivity> scheduleActivities;
  final ValueChanged<WorkPackage>? onWorkPackageTap;
  final VoidCallback? onImportFromPlans;
  final VoidCallback? onGeneratePackageChains;
  final VoidCallback? onGenerateScheduleNetwork;
  final VoidCallback? onAddWorkPackage;
  final ValueChanged<WorkPackage>? onEditWorkPackage;
  final ValueChanged<String>? onDeleteWorkPackage;

  @override
  Widget build(BuildContext context) {
    if (workPackages.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppSemanticColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.work_outline,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Work Packages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create work packages to organize schedule activities.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            if (onImportFromPlans != null) ...[
              const SizedBox(height: 16),
              if (onGeneratePackageChains != null) ...[
                FilledButton.icon(
                  onPressed: onGeneratePackageChains,
                  icon: const Icon(Icons.account_tree_outlined, size: 16),
                  label: const Text('Generate Package Chains'),
                ),
                const SizedBox(height: 8),
              ],
              if (onGenerateScheduleNetwork != null) ...[
                OutlinedButton.icon(
                  onPressed: onGenerateScheduleNetwork,
                  icon: const Icon(Icons.timeline_outlined, size: 16),
                  label: const Text('Create Schedule Network'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: onImportFromPlans,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Import from Plans'),
              ),
            ],
          ],
        ),
      );
    }

    final activitiesByWp = <String, List<ScheduleActivity>>{};
    for (final activity in scheduleActivities) {
      if (activity.workPackageId.isNotEmpty) {
        activitiesByWp
            .putIfAbsent(activity.workPackageId, () => [])
            .add(activity);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Work Packages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              if (onGeneratePackageChains != null)
                FilledButton.icon(
                  onPressed: onGeneratePackageChains,
                  icon: const Icon(Icons.account_tree_outlined, size: 16),
                  label: const Text('Generate Package Chains'),
                ),
              const SizedBox(width: 8),
              if (onGenerateScheduleNetwork != null)
                OutlinedButton.icon(
                  onPressed: onGenerateScheduleNetwork,
                  icon: const Icon(Icons.timeline_outlined, size: 16),
                  label: const Text('Create Schedule Network'),
                ),
              const SizedBox(width: 8),
              if (onImportFromPlans != null)
                OutlinedButton.icon(
                  onPressed: onImportFromPlans,
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Import from Plans'),
                ),
              const SizedBox(width: 8),
              if (onAddWorkPackage != null)
                FilledButton.icon(
                  onPressed: onAddWorkPackage,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Work Package'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...workPackages.map((wp) {
            final activities = activitiesByWp[wp.id] ?? [];
            return _WorkPackageCard(
              workPackage: wp,
              activities: activities,
              onTap: () => onWorkPackageTap?.call(wp),
              onEdit: onEditWorkPackage != null
                  ? () => onEditWorkPackage!(wp)
                  : null,
              onDelete: onDeleteWorkPackage != null
                  ? () => onDeleteWorkPackage!(wp.id)
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

class _WorkPackageCard extends StatelessWidget {
  const _WorkPackageCard({
    required this.workPackage,
    required this.activities,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final WorkPackage workPackage;
  final List<ScheduleActivity> activities;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = workPackage.budgetedCost > 0
        ? (workPackage.actualCost / workPackage.budgetedCost).clamp(0.0, 1.0)
        : 0.0;
    final readinessWarnings =
        IntegratedWorkPackageService.validateReadiness(workPackage);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppSemanticColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    workPackage.title.isNotEmpty
                        ? workPackage.title
                        : 'Untitled Work Package',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(workPackage.status),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    workPackage.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (readinessWarnings.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: readinessWarnings.take(5).join('\n'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFF97316)),
                      ),
                      child: Text(
                        '${readinessWarnings.length} WARN',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ),
                ],
                if (onEdit != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                ],
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Color(0xFFEF4444)),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (workPackage.description.isNotEmpty) ...[
              Text(
                workPackage.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  workPackage.owner.isNotEmpty
                      ? workPackage.owner
                      : 'Unassigned',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.category_outlined,
                    size: 14, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(
                  workPackage.type.isNotEmpty
                      ? workPackage.type.toUpperCase()
                      : 'N/A',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${workPackage.budgetedCost.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            if (activities.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Activities (${activities.length}):',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 6),
              ...activities.take(3).map((activity) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppSemanticColors.border),
                  ),
                  child: Row(
                    children: [
                      if (activity.isCriticalPath)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CP',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          activity.title.isNotEmpty
                              ? activity.title
                              : 'Untitled Activity',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF374151),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(activity.progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (activities.length > 3)
                Text(
                  '+ ${activities.length - 3} more...',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'complete':
        return const Color(0xFF10B981);
      case 'blocked':
      case 'on_hold':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}

class _ProcurementTimelineTab extends StatelessWidget {
  const _ProcurementTimelineTab({
    required this.workPackages,
    required this.scheduleActivities,
  });

  final List<WorkPackage> workPackages;
  final List<ScheduleActivity> scheduleActivities;

  @override
  Widget build(BuildContext context) {
    final procurementActivities = scheduleActivities
        .where((a) => a.workPackageType == 'procurement')
        .toList();

    if (procurementActivities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppSemanticColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Procurement Activities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Procurement timeline will show here when activities are linked to procurement work packages.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Procurement Timeline',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          ...procurementActivities.map((activity) {
            return _ProcurementActivityCard(activity: activity);
          }),
        ],
      ),
    );
  }
}

class _ProcurementActivityCard extends StatelessWidget {
  const _ProcurementActivityCard({required this.activity});

  final ScheduleActivity activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  activity.title.isNotEmpty
                      ? activity.title
                      : 'Untitled Procurement Activity',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _procurementStatusColor(activity.procurementStatus),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  activity.procurementStatus.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (activity.startDate.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.event_outlined,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      activity.startDate,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              if (activity.dueDate.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.event_available_outlined,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      activity.dueDate,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              const Spacer(),
              if (activity.vendorId.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.business_outlined,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      'Vendor: ${activity.vendorId}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: activity.progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            ),
          ),
        ],
      ),
    );
  }

  Color _procurementStatusColor(String status) {
    switch (status) {
      case 'rfq':
        return const Color(0xFFF59E0B);
      case 'evaluating':
        return const Color(0xFF3B82F6);
      case 'awarded':
        return const Color(0xFF8B5CF6);
      case 'contracted':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}

class _EVMData {
  const _EVMData({
    required this.plannedValue,
    required this.earnedValue,
    required this.actualCost,
    required this.scheduleVariance,
    required this.costVariance,
    required this.schedulePerformanceIndex,
    required this.costPerformanceIndex,
    required this.budgetAtCompletion,
    required this.estimateAtCompletion,
    required this.estimateToComplete,
    required this.varianceAtCompletion,
  });

  final double plannedValue; // PV
  final double earnedValue; // EV
  final double actualCost; // AC
  final double scheduleVariance; // SV = EV - PV
  final double costVariance; // CV = EV - AC
  final double schedulePerformanceIndex; // SPI = EV / PV
  final double costPerformanceIndex; // CPI = EV / AC
  final double budgetAtCompletion; // BAC
  final double estimateAtCompletion; // EAC
  final double estimateToComplete; // ETC
  final double varianceAtCompletion; // VAC = BAC - EAC
}

class _CostVsScheduleTab extends StatelessWidget {
  const _CostVsScheduleTab({
    required this.workPackages,
    required this.scheduleActivities,
    required this.costEstimateItems,
    this.startDate,
    this.endDate,
  });

  final List<WorkPackage> workPackages;
  final List<ScheduleActivity> scheduleActivities;
  final List<CostEstimateItem> costEstimateItems;
  final DateTime? startDate;
  final DateTime? endDate;

  List<SCurveDataPoint> _generatePlannedCurve() {
    if (workPackages.isEmpty || startDate == null || endDate == null) return [];

    final points = <SCurveDataPoint>[];
    double cumulative = 0;
    final sorted = [...workPackages]..sort((a, b) {
        final aDate =
            a.plannedStart != null ? DateTime.tryParse(a.plannedStart!) : null;
        final bDate =
            b.plannedStart != null ? DateTime.tryParse(b.plannedStart!) : null;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });

    for (final wp in sorted) {
      final date =
          wp.plannedStart != null ? DateTime.tryParse(wp.plannedStart!) : null;
      if (date != null) {
        cumulative += wp.budgetedCost;
        points.add(SCurveDataPoint(date: date, cumulativeCost: cumulative));
      }
    }

    return points;
  }

  List<SCurveDataPoint> _generateActualCurve() {
    if (workPackages.isEmpty || startDate == null || endDate == null) return [];

    final points = <SCurveDataPoint>[];
    double cumulative = 0;
    final sorted = [...workPackages]..sort((a, b) {
        final aDate =
            a.actualStart != null ? DateTime.tryParse(a.actualStart!) : null;
        final bDate =
            b.actualStart != null ? DateTime.tryParse(b.actualStart!) : null;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });

    for (final wp in sorted) {
      final date =
          wp.actualStart != null ? DateTime.tryParse(wp.actualStart!) : null;
      if (date != null) {
        cumulative += wp.actualCost > 0 ? wp.actualCost : wp.budgetedCost;
        points.add(SCurveDataPoint(date: date, cumulativeCost: cumulative));
      }
    }

    return points;
  }

  /// Calculate progress percentage for a work package based on linked activities
  double _getWorkPackageProgress(WorkPackage wp) {
    if (wp.scheduleActivityIds.isEmpty) {
      // Fallback to status-based progress
      switch (wp.status) {
        case 'complete':
          return 1.0;
        case 'in_progress':
          return 0.5;
        default:
          return 0.0;
      }
    }

    final linkedActivities = scheduleActivities
        .where((a) => wp.scheduleActivityIds.contains(a.id))
        .toList();

    if (linkedActivities.isEmpty) return 0.0;

    final totalProgress = linkedActivities.fold<double>(
      0,
      (sum, act) => sum + act.progress.clamp(0.0, 1.0),
    );

    return totalProgress / linkedActivities.length;
  }

  /// Calculate Earned Value Management (EVM) metrics
  _EVMData _calculateEVM() {
    final now = DateTime.now();

    // Planned Value (PV): Sum of budgeted costs for work scheduled to be completed by now
    double plannedValue = 0;
    for (final wp in workPackages) {
      if (wp.plannedEnd != null) {
        final endDate = DateTime.tryParse(wp.plannedEnd!);
        if (endDate != null && !endDate.isAfter(now)) {
          plannedValue += wp.budgetedCost;
        }
      }
    }

    // Earned Value (EV): Sum of budgeted costs for work actually completed
    double earnedValue = 0;
    for (final wp in workPackages) {
      final progress = _getWorkPackageProgress(wp);
      earnedValue += wp.budgetedCost * progress;
    }

    // Actual Cost (AC): Sum of actual costs incurred
    double actualCost = workPackages.fold<double>(
      0,
      (sum, wp) => sum + wp.actualCost,
    );

    // Schedule Variance (SV) = EV - PV
    final scheduleVariance = earnedValue - plannedValue;

    // Cost Variance (CV) = EV - AC
    final costVariance = earnedValue - actualCost;

    // Schedule Performance Index (SPI) = EV / PV
    final schedulePerformanceIndex =
        plannedValue > 0 ? earnedValue / plannedValue : 0.0;

    // Cost Performance Index (CPI) = EV / AC
    final costPerformanceIndex =
        actualCost > 0 ? earnedValue / actualCost : 0.0;

    // Estimate at Completion (EAC) = BAC / CPI
    final budgetAtCompletion = workPackages.fold<double>(
      0,
      (sum, wp) => sum + wp.budgetedCost,
    );
    final estimateAtCompletion = costPerformanceIndex > 0
        ? budgetAtCompletion / costPerformanceIndex
        : budgetAtCompletion;

    // Estimate to Complete (ETC) = EAC - AC
    final estimateToComplete = estimateAtCompletion - actualCost;

    // Variance at Completion (VAC) = BAC - EAC
    final varianceAtCompletion = budgetAtCompletion - estimateAtCompletion;

    return _EVMData(
      plannedValue: plannedValue,
      earnedValue: earnedValue,
      actualCost: actualCost,
      scheduleVariance: scheduleVariance,
      costVariance: costVariance,
      schedulePerformanceIndex: schedulePerformanceIndex,
      costPerformanceIndex: costPerformanceIndex,
      budgetAtCompletion: budgetAtCompletion,
      estimateAtCompletion: estimateAtCompletion,
      estimateToComplete: estimateToComplete,
      varianceAtCompletion: varianceAtCompletion,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = workPackages.fold<double>(
      0,
      (sum, wp) => sum + wp.budgetedCost,
    );
    final totalActual = workPackages.fold<double>(
      0,
      (sum, wp) => sum + wp.actualCost,
    );
    final totalEstimate = costEstimateItems
        .where(
          (item) => item.costState == 'forecast' && !item.isBaseline,
        )
        .fold<double>(0, (sum, item) => sum + item.amount);

    final variance = totalBudget - totalActual;
    final variancePercent =
        totalBudget > 0 ? (variance / totalBudget * 100).abs() : 0.0;

    final evmData = _calculateEVM();
    final plannedCurve = _generatePlannedCurve();
    final actualCurve = _generateActualCurve();

    final chartStart = startDate ?? DateTime.now();
    final chartEnd = endDate ?? DateTime.now().add(const Duration(days: 365));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost vs Schedule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _CostStatCard(
                title: 'Total Budget',
                amount: totalBudget,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 12),
              _CostStatCard(
                title: 'Total Actual',
                amount: totalActual,
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 12),
              _CostStatCard(
                title: 'Cost Estimates',
                amount: totalEstimate,
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 12),
              _CostStatCard(
                title: 'Variance',
                amount: variance,
                color: variance >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                subtitle: '${variancePercent.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // EVM Metrics Section
          const Text(
            'Earned Value Management (EVM) Metrics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _EVMStatCard(
                title: 'Planned Value (PV)',
                value: '\$${evmData.plannedValue.toStringAsFixed(0)}',
                color: const Color(0xFF3B82F6),
              ),
              _EVMStatCard(
                title: 'Earned Value (EV)',
                value: '\$${evmData.earnedValue.toStringAsFixed(0)}',
                color: const Color(0xFF10B981),
              ),
              _EVMStatCard(
                title: 'Actual Cost (AC)',
                value: '\$${evmData.actualCost.toStringAsFixed(0)}',
                color: const Color(0xFFF59E0B),
              ),
              _EVMStatCard(
                title: 'Schedule Variance (SV)',
                value: '\$${evmData.scheduleVariance.toStringAsFixed(0)}',
                color: evmData.scheduleVariance >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
              _EVMStatCard(
                title: 'Cost Variance (CV)',
                value: '\$${evmData.costVariance.toStringAsFixed(0)}',
                color: evmData.costVariance >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
              _EVMStatCard(
                title: 'SPI',
                value: evmData.schedulePerformanceIndex.toStringAsFixed(2),
                color: evmData.schedulePerformanceIndex >= 1.0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                subtitle: 'Schedule Performance',
              ),
              _EVMStatCard(
                title: 'CPI',
                value: evmData.costPerformanceIndex.toStringAsFixed(2),
                color: evmData.costPerformanceIndex >= 1.0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF59E0B),
                subtitle: 'Cost Performance',
              ),
              _EVMStatCard(
                title: 'Estimate at Completion (EAC)',
                value: '\$${evmData.estimateAtCompletion.toStringAsFixed(0)}',
                color: const Color(0xFF8B5CF6),
              ),
              _EVMStatCard(
                title: 'Estimate to Complete (ETC)',
                value: '\$${evmData.estimateToComplete.toStringAsFixed(0)}',
                color: const Color(0xFF6366F1),
              ),
              _EVMStatCard(
                title: 'Variance at Completion (VAC)',
                value: '\$${evmData.varianceAtCompletion.toStringAsFixed(0)}',
                color: evmData.varianceAtCompletion >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'S-Curve: Cumulative Cost Over Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          SCurveChart(
            plannedData: plannedCurve,
            actualData: actualCurve,
            startDate: chartStart,
            endDate: chartEnd,
            height: 300,
          ),
          const SizedBox(height: 24),
          const Text(
            'Work Packages by Cost',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          if (workPackages.isEmpty)
            const Text(
              'No work packages to display.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            )
          else
            ...workPackages.map((wp) {
              final wpActual = wp.actualCost;
              final wpBudget = wp.budgetedCost;
              final utilization =
                  wpBudget > 0 ? (wpActual / wpBudget).clamp(0.0, 1.0) : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppSemanticColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            wp.title.isNotEmpty
                                ? wp.title
                                : 'Untitled Work Package',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        Text(
                          '\$${wpActual.toStringAsFixed(0)} / \$${wpBudget.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: utilization,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          utilization > 1.0
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CostStatCard extends StatelessWidget {
  const _CostStatCard({
    required this.title,
    required this.amount,
    required this.color,
    this.subtitle,
  });

  final String title;
  final double amount;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppSemanticColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '\$${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EVMStatCard extends StatelessWidget {
  const _EVMStatCard({
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.controller,
    required this.savedAt,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final TextEditingController controller;
  final DateTime? savedAt;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: (_) => onToggleExpanded(),
        title: const Text(
          'Schedule Notes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        trailing: savedAt != null
            ? Text(
                'Saved ${_formatTime(savedAt!)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Add notes about the project schedule...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTopBar extends StatelessWidget {
  const _ScheduleTopBar({
    required this.methodology,
    required this.onMethodologyChanged,
    required this.isGeneratingAi,
    required this.baselineDate,
    required this.onImportFromWbs,
    required this.onGenerateAi,
    required this.onAddTask,
    required this.onSyncMilestones,
    required this.onValidate,
    required this.onApproveBaseline,
    this.onCalculateCostImpact,
  });

  final String methodology;
  final ValueChanged<String?> onMethodologyChanged;
  final bool isGeneratingAi;
  final DateTime? baselineDate;
  final VoidCallback onImportFromWbs;
  final VoidCallback onGenerateAi;
  final VoidCallback onAddTask;
  final VoidCallback onSyncMilestones;
  final VoidCallback onValidate;
  final VoidCallback onApproveBaseline;
  final VoidCallback? onCalculateCostImpact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppSemanticColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'Methodology:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: methodology,
                        onChanged: onMethodologyChanged,
                        items: const [
                          DropdownMenuItem(
                              value: 'Waterfall', child: Text('Waterfall')),
                          DropdownMenuItem(
                              value: 'Agile', child: Text('Agile')),
                          DropdownMenuItem(
                              value: 'Hybrid', child: Text('Hybrid')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (baselineDate != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Baseline Set',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onImportFromWbs,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Import from WBS'),
              ),
              FilledButton.icon(
                onPressed: isGeneratingAi ? null : onGenerateAi,
                icon: isGeneratingAi
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 16),
                label: Text(isGeneratingAi ? 'Generating...' : 'AI Generate'),
              ),
              FilledButton.icon(
                onPressed: onAddTask,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Task'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF111827),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onSyncMilestones,
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Sync Milestones'),
              ),
              OutlinedButton.icon(
                onPressed: onValidate,
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Validate'),
              ),
              OutlinedButton.icon(
                onPressed: onApproveBaseline,
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text('Set Baseline'),
              ),
              if (onCalculateCostImpact != null)
                OutlinedButton.icon(
                  onPressed: onCalculateCostImpact,
                  icon: const Icon(Icons.calculate_outlined, size: 16),
                  label: const Text('Calculate Cost Impact'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
