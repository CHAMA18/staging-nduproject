import 'package:flutter/material.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/theme.dart';

class WorkPackageDialog extends StatefulWidget {
  const WorkPackageDialog({
    super.key,
    this.initialWorkPackage,
    this.wbsLevel2Options = const [],
  });

  final WorkPackage? initialWorkPackage;
  final List<Map<String, String>> wbsLevel2Options;

  @override
  State<WorkPackageDialog> createState() => _WorkPackageDialogState();
}

class _WorkPackageDialogState extends State<WorkPackageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _ownerController;
  late final TextEditingController _disciplineController;
  late final TextEditingController _budgetController;
  late final TextEditingController _acceptingCriteriaController;
  late final TextEditingController _notesController;

  String _type = 'design';
  String _phase = 'design';
  String _status = 'planned';
  String? _wbsLevel2Id;
  String? _plannedStart;
  String? _plannedEnd;

  @override
  void initState() {
    super.initState();
    final wp = widget.initialWorkPackage;
    _titleController = TextEditingController(text: wp?.title ?? '');
    _descriptionController = TextEditingController(text: wp?.description ?? '');
    _ownerController = TextEditingController(text: wp?.owner ?? '');
    _disciplineController = TextEditingController(text: wp?.discipline ?? '');
    _budgetController = TextEditingController(
        text: wp != null && wp.budgetedCost > 0 ? wp.budgetedCost.toString() : '');
    _acceptingCriteriaController =
        TextEditingController(text: wp?.acceptingCriteria ?? '');
    _notesController = TextEditingController(text: wp?.notes ?? '');

    if (wp != null) {
      _type = wp.type;
      _phase = wp.phase;
      _status = wp.status;
      _wbsLevel2Id = wp.wbsLevel2Id.isNotEmpty ? wp.wbsLevel2Id : null;
      _plannedStart = wp.plannedStart;
      _plannedEnd = wp.plannedEnd;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ownerController.dispose();
    _disciplineController.dispose();
    _budgetController.dispose();
    _acceptingCriteriaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final current = isStart ? _plannedStart : _plannedEnd;
    final initialDate = DateTime.tryParse(current ?? '') ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _plannedStart = picked.toIso8601String().split('T').first;
        } else {
          _plannedEnd = picked.toIso8601String().split('T').first;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final wp = widget.initialWorkPackage;
    final result = WorkPackage(
      id: wp?.id,
      wbsLevel2Id: _wbsLevel2Id ?? '',
      wbsLevel2Title: widget.wbsLevel2Options
              .firstWhere(
                (opt) => opt['id'] == _wbsLevel2Id,
                orElse: () => {'title': ''},
              )['title'] ??
          '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _type,
      phase: _phase,
      status: _status,
      owner: _ownerController.text.trim(),
      discipline: _disciplineController.text.trim(),
      plannedStart: _plannedStart,
      plannedEnd: _plannedEnd,
      budgetedCost: double.tryParse(_budgetController.text.trim()) ?? 0,
      acceptingCriteria: _acceptingCriteriaController.text.trim(),
      notes: _notesController.text.trim(),
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialWorkPackage != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Work Package' : 'Create Work Package'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                if (widget.wbsLevel2Options.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _wbsLevel2Id,
                    decoration:
                        const InputDecoration(labelText: 'WBS Level 2'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('None'),
                      ),
                      ...widget.wbsLevel2Options.map((opt) =>
                          DropdownMenuItem<String>(
                            value: opt['id'] ?? '',
                            child: Text(opt['title'] ?? ''),
                          )),
                    ],
                    onChanged: (v) => setState(() => _wbsLevel2Id = v),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(
                              value: 'design', child: Text('Design')),
                          DropdownMenuItem(
                              value: 'construction',
                              child: Text('Construction')),
                          DropdownMenuItem(
                              value: 'execution', child: Text('Execution')),
                          DropdownMenuItem(
                              value: 'agile', child: Text('Agile')),
                          DropdownMenuItem(
                              value: 'procurement',
                              child: Text('Procurement')),
                          DropdownMenuItem(
                              value: 'delivery', child: Text('Delivery')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _type = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _phase,
                        decoration: const InputDecoration(labelText: 'Phase'),
                        items: const [
                          DropdownMenuItem(
                              value: 'design', child: Text('Design')),
                          DropdownMenuItem(
                              value: 'execution', child: Text('Execution')),
                          DropdownMenuItem(
                              value: 'launch', child: Text('Launch')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _phase = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(
                              value: 'planned', child: Text('Planned')),
                          DropdownMenuItem(
                              value: 'in_progress',
                              child: Text('In Progress')),
                          DropdownMenuItem(
                              value: 'complete', child: Text('Complete')),
                          DropdownMenuItem(
                              value: 'blocked', child: Text('Blocked')),
                          DropdownMenuItem(
                              value: 'on_hold', child: Text('On Hold')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ownerController,
                        decoration: const InputDecoration(labelText: 'Owner'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _disciplineController,
                        decoration:
                            const InputDecoration(labelText: 'Discipline'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Planned Start',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            onPressed: () => _pickDate(true),
                          ),
                        ),
                        controller: TextEditingController(
                          text: _plannedStart ?? 'Select date',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Planned End',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            onPressed: () => _pickDate(false),
                          ),
                        ),
                        controller: TextEditingController(
                          text: _plannedEnd ?? 'Select date',
                        ),
                      ),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _budgetController,
                  decoration:
                      const InputDecoration(labelText: 'Budgeted Cost (\$)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                TextFormField(
                  controller: _acceptingCriteriaController,
                  decoration:
                      const InputDecoration(labelText: 'Accepting Criteria'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEdit ? 'Save Changes' : 'Create'),
        ),
      ],
    );
  }
}
