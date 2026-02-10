import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';

class FinalizeProjectScreen extends StatefulWidget {
  const FinalizeProjectScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FinalizeProjectScreen()),
    );
  }

  @override
  State<FinalizeProjectScreen> createState() => _FinalizeProjectScreenState();
}

class _FinalizeProjectScreenState extends State<FinalizeProjectScreen> {
  final TextEditingController _summaryTitleController =
      TextEditingController();
  final TextEditingController _summaryDescriptionController =
      TextEditingController();
  final TextEditingController _readinessPercentController =
      TextEditingController();
  final TextEditingController _closeoutWindowController =
      TextEditingController();
  final TextEditingController _finalNotesController = TextEditingController();
  final TextEditingController _nextStepsController = TextEditingController();

  final List<_HeroStatItem> _heroStats = [];
  final List<_SnapshotMetric> _snapshotMetrics = [];
  final List<_ChecklistItem> _checklist = [];
  final List<_SignOffItem> _signOffs = [];
  final List<_InsightItem> _insights = [];

  String _finalizationStatus = 'In progress';
  bool _isLoading = false;
  bool _suspendSave = false;

  final _Debouncer _saveDebouncer = _Debouncer();

  static const List<String> _finalizationStatuses = [
    'Not started',
    'In progress',
    'At risk',
    'Ready to finalize'
  ];
  static const List<String> _checklistStatuses = [
    'Not started',
    'In progress',
    'Blocked',
    'Done'
  ];
  static const List<String> _signOffStatuses = [
    'Pending',
    'Approved',
    'Rejected',
    'Deferred'
  ];

  @override
  void initState() {
    super.initState();
    _registerListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromFirestore());
  }

  @override
  void dispose() {
    _summaryTitleController.dispose();
    _summaryDescriptionController.dispose();
    _readinessPercentController.dispose();
    _closeoutWindowController.dispose();
    _finalNotesController.dispose();
    _nextStepsController.dispose();
    _saveDebouncer.dispose();
    super.dispose();
  }

  String? _projectId() => ProjectDataHelper.getData(context).projectId;

  void _registerListeners() {
    final controllers = [
      _summaryTitleController,
      _summaryDescriptionController,
      _readinessPercentController,
      _closeoutWindowController,
      _finalNotesController,
      _nextStepsController,
    ];
    for (final controller in controllers) {
      controller.addListener(_scheduleSave);
    }
  }

  void _scheduleSave() {
    if (_suspendSave) return;
    _saveDebouncer.run(_saveToFirestore);
  }

  Future<void> _loadFromFirestore() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('finalize_project')
          .get();
      final data = doc.data() ?? {};
      final summary = Map<String, dynamic>.from(data['summary'] ?? {});
      final actions = Map<String, dynamic>.from(data['actions'] ?? {});

      _suspendSave = true;
      _summaryTitleController.text = summary['title']?.toString() ?? '';
      _summaryDescriptionController.text =
          summary['description']?.toString() ?? '';
      _readinessPercentController.text =
          summary['readinessPercent']?.toString() ?? '';
      _closeoutWindowController.text =
          summary['closeoutWindow']?.toString() ?? '';
      _finalizationStatus =
          _normalizeStatus(summary['status']?.toString(), _finalizationStatuses);
      _finalNotesController.text = actions['finalNotes']?.toString() ?? '';
      _nextStepsController.text = actions['nextSteps']?.toString() ?? '';
      _suspendSave = false;

      final heroStats = _HeroStatItem.fromList(data['heroStats']);
      final snapshotMetrics =
          _SnapshotMetric.fromList(data['snapshotMetrics']);
      final checklist = _ChecklistItem.fromList(data['checklist']);
      final signOffs = _SignOffItem.fromList(data['signOffs']);
      final insights = _InsightItem.fromList(data['insights']);

      if (!mounted) return;
      setState(() {
        _heroStats
          ..clear()
          ..addAll(heroStats.isEmpty ? _defaultHeroStats() : heroStats);
        _snapshotMetrics
          ..clear()
          ..addAll(snapshotMetrics.isEmpty
              ? _defaultSnapshotMetrics()
              : snapshotMetrics);
        _checklist
          ..clear()
          ..addAll(checklist);
        _signOffs
          ..clear()
          ..addAll(signOffs);
        _insights
          ..clear()
          ..addAll(insights);
      });
    } catch (error) {
      debugPrint('Finalize Project load error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveToFirestore() async {
    final projectId = _projectId();
    if (projectId == null || projectId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .collection('execution_phase_sections')
          .doc('finalize_project')
          .set({
        'summary': {
          'title': _summaryTitleController.text.trim(),
          'description': _summaryDescriptionController.text.trim(),
          'readinessPercent': _readinessPercentController.text.trim(),
          'closeoutWindow': _closeoutWindowController.text.trim(),
          'status': _finalizationStatus,
        },
        'heroStats': _heroStats.map((e) => e.toMap()).toList(),
        'snapshotMetrics': _snapshotMetrics.map((e) => e.toMap()).toList(),
        'checklist': _checklist.map((e) => e.toMap()).toList(),
        'signOffs': _signOffs.map((e) => e.toMap()).toList(),
        'insights': _insights.map((e) => e.toMap()).toList(),
        'actions': {
          'finalNotes': _finalNotesController.text.trim(),
          'nextSteps': _nextStepsController.text.trim(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Finalize Project save error: $error');
    }
  }

  List<_HeroStatItem> _defaultHeroStats() {
    return [
      _HeroStatItem(id: _newId(), label: 'Open approvals', value: ''),
      _HeroStatItem(id: _newId(), label: 'Final docs', value: ''),
      _HeroStatItem(id: _newId(), label: 'Risks to watch', value: ''),
      _HeroStatItem(id: _newId(), label: 'Ops readiness', value: ''),
    ];
  }

  List<_SnapshotMetric> _defaultSnapshotMetrics() {
    return [
      _SnapshotMetric(
        id: _newId(),
        title: 'Delivery Package',
        subtitle: 'Final artifacts and deployment notes',
        value: '',
        accent: const Color(0xFF16A34A),
      ),
      _SnapshotMetric(
        id: _newId(),
        title: 'Stakeholder Sign-off',
        subtitle: 'Pending approvals',
        value: '',
        accent: const Color(0xFF2563EB),
      ),
      _SnapshotMetric(
        id: _newId(),
        title: 'Budget Closure',
        subtitle: 'Variance vs. forecast',
        value: '',
        accent: const Color(0xFFF59E0B),
      ),
      _SnapshotMetric(
        id: _newId(),
        title: 'Ops Readiness',
        subtitle: 'Handover confidence',
        value: '',
        accent: const Color(0xFF7C3AED),
      ),
    ];
  }

  String _normalizeStatus(String? value, List<String> options) {
    if (value == null || value.isEmpty) return options.first;
    for (final option in options) {
      if (option.toLowerCase() == value.toLowerCase()) return option;
    }
    return options.first;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = AppBreakpoints.isMobile(context) ? 20 : 32;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child:
                  const InitiationLikeSidebar(activeItemLabel: 'Finalize Project'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const LinearProgressIndicator(minHeight: 2),
                        if (_isLoading) const SizedBox(height: 16),
                        _buildFinalizeHero(context),
                        const SizedBox(height: 24),
                        _buildSnapshotSection(context),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isWide = constraints.maxWidth >= 980;
                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildFinalizeChecklist()),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildSignOffPanel()),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _buildFinalizeChecklist(),
                                const SizedBox(height: 20),
                                _buildSignOffPanel(),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildClosureInsights(context),
                        const SizedBox(height: 28),
                        _buildActionBar(context),
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

  Widget _buildFinalizeHero(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 30,
              offset: const Offset(0, 18)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB020),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Finalization',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D1F)),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  initialValue: _finalizationStatus,
                  decoration:
                      _heroInputDecoration('Status', filledColor: Colors.white),
                  items: _finalizationStatuses
                      .map((status) =>
                          DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _finalizationStatus = value);
                    _scheduleSave();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _summaryTitleController,
            style: TextStyle(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w700,
                color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Finalize Project',
              hintStyle: TextStyle(color: Color(0xFFE5E7EB)),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _summaryDescriptionController,
            maxLines: 2,
            style: const TextStyle(fontSize: 15, color: Color(0xFFE5E7EB)),
            decoration: const InputDecoration(
              hintText:
                  'Lock scope, validate handoffs, and close out the project.',
              hintStyle: TextStyle(color: Color(0xFFE5E7EB)),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroStatField(
                label: 'Readiness %',
                controller: _readinessPercentController,
              ),
              _HeroStatField(
                label: 'Closeout window',
                controller: _closeoutWindowController,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final stat in _heroStats)
                _HeroStatCard(
                  item: stat,
                  onChanged: (updated) => _updateHeroStat(updated),
                  onDelete: () => _deleteHeroStat(stat.id),
                ),
              _HeroStatAddButton(onAdd: _addHeroStat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotSection(BuildContext context) {
    return _SectionCard(
      title: 'Finalization Snapshot',
      subtitle: 'Summarize readiness signals for leadership review.',
      icon: Icons.dashboard_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader(
            const ['Metric', 'Signal', 'Value', ''],
            columnWidths: const [3, 4, 2, 1],
          ),
          const SizedBox(height: 12),
          if (_snapshotMetrics.isEmpty)
            const _InlineEmptyState(
              title: 'No snapshot metrics',
              message: 'Add the metrics that summarize project closeout.',
            )
          else
            ..._snapshotMetrics.map(_buildSnapshotRow),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addSnapshotMetric,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add snapshot metric'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: const Color(0xFFFFF3C4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotRow(_SnapshotMetric metric) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('snapshot-title-${metric.id}'),
              initialValue: metric.title,
              decoration: _inputDecoration('Metric'),
              onChanged: (value) =>
                  _updateSnapshotMetric(metric.copyWith(title: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: TextFormField(
              key: ValueKey('snapshot-sub-${metric.id}'),
              initialValue: metric.subtitle,
              decoration: _inputDecoration('Signal'),
              onChanged: (value) =>
                  _updateSnapshotMetric(metric.copyWith(subtitle: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('snapshot-value-${metric.id}'),
              initialValue: metric.value,
              decoration: _inputDecoration('Value'),
              onChanged: (value) =>
                  _updateSnapshotMetric(metric.copyWith(value: value)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteSnapshotMetric(metric.id),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalizeChecklist() {
    return _SectionCard(
      title: 'Finalization Checklist',
      subtitle: 'Lock down every last dependency before sign-off.',
      icon: Icons.check_circle_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader(
            const ['Checklist item', 'Owner', 'Due date', 'Status', ''],
            columnWidths: const [4, 2, 2, 2, 1],
          ),
          const SizedBox(height: 12),
          if (_checklist.isEmpty)
            const _InlineEmptyState(
              title: 'No checklist items',
              message: 'Add the remaining actions required to close out.',
            )
          else
            ..._checklist.map(_buildChecklistRow),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addChecklistItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add checklist item'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: const Color(0xFFFFF3C4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(_ChecklistItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextFormField(
              key: ValueKey('checklist-title-${item.id}'),
              initialValue: item.title,
              decoration: _inputDecoration('Checklist item'),
              maxLines: 2,
              onChanged: (value) =>
                  _updateChecklistItem(item.copyWith(title: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('checklist-owner-${item.id}'),
              initialValue: item.owner,
              decoration: _inputDecoration('Owner'),
              onChanged: (value) =>
                  _updateChecklistItem(item.copyWith(owner: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('checklist-date-${item.id}'),
              initialValue: item.dueDate,
              decoration: _inputDecoration('Due date'),
              onChanged: (value) =>
                  _updateChecklistItem(item.copyWith(dueDate: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: item.status,
              decoration: _inputDecoration('Status', dense: true),
              items: _checklistStatuses
                  .map((status) =>
                      DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateChecklistItem(item.copyWith(status: value),
                    notify: true);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteChecklistItem(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOffPanel() {
    return _SectionCard(
      title: 'Executive Sign-off',
      subtitle: 'Confirm ownership and approval before closing.',
      icon: Icons.verified_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader(
            const ['Stakeholder', 'Role', 'Status', 'Decision date', ''],
            columnWidths: const [3, 3, 2, 2, 1],
          ),
          const SizedBox(height: 12),
          if (_signOffs.isEmpty)
            const _InlineEmptyState(
              title: 'No sign-offs yet',
              message: 'Track each required stakeholder approval here.',
            )
          else
            ..._signOffs.map(_buildSignOffRow),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addSignOffItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add sign-off'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: const Color(0xFFFFF3C4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOffRow(_SignOffItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('signoff-name-${item.id}'),
              initialValue: item.name,
              decoration: _inputDecoration('Stakeholder'),
              onChanged: (value) =>
                  _updateSignOffItem(item.copyWith(name: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextFormField(
              key: ValueKey('signoff-role-${item.id}'),
              initialValue: item.role,
              decoration: _inputDecoration('Role'),
              onChanged: (value) =>
                  _updateSignOffItem(item.copyWith(role: value)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: item.status,
              decoration: _inputDecoration('Status', dense: true),
              items: _signOffStatuses
                  .map((status) =>
                      DropdownMenuItem(value: status, child: Text(status)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateSignOffItem(item.copyWith(status: value), notify: true);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('signoff-date-${item.id}'),
              initialValue: item.decisionDate,
              decoration: _inputDecoration('Decision date'),
              onChanged: (value) =>
                  _updateSignOffItem(item.copyWith(decisionDate: value)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
            onPressed: () => _deleteSignOffItem(item.id),
          ),
        ],
      ),
    );
  }

  Widget _buildClosureInsights(BuildContext context) {
    return _SectionCard(
      title: 'Closure Insights',
      subtitle: 'Capture final risks, coverage, and warranty commitments.',
      icon: Icons.lightbulb_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_insights.isEmpty)
            const _InlineEmptyState(
              title: 'No closure insights yet',
              message: 'Add risks, coverage, and warranty notes to close out.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 900;
                if (isWide) {
                  return Row(
                    children: [
                      for (int i = 0; i < _insights.length; i++) ...[
                        Expanded(
                          child: _InsightCard(
                            item: _insights[i],
                            onChanged: _updateInsight,
                            onDelete: () => _deleteInsight(_insights[i].id),
                          ),
                        ),
                        if (i != _insights.length - 1)
                          const SizedBox(width: 16),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    for (int i = 0; i < _insights.length; i++) ...[
                      _InsightCard(
                        item: _insights[i],
                        onChanged: _updateInsight,
                        onDelete: () => _deleteInsight(_insights[i].id),
                      ),
                      if (i != _insights.length - 1)
                        const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _addInsight,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add insight'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              backgroundColor: const Color(0xFFFFF3C4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Finalize decision log',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Capture the final decision summary and next-step actions.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),
          _buildLabeledField(
            label: 'Finalization notes',
            controller: _finalNotesController,
            hintText: 'Summarize final checks, approvals, and open items.',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildLabeledField(
            label: 'Next steps after closeout',
            controller: _nextStepsController,
            hintText: 'List post-launch actions and support transitions.',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText, {bool dense = false}) {
    return InputDecoration(
      hintText: hintText,
      isDense: dense,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: dense ? 8 : 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF93C5FD)),
      ),
    );
  }

  InputDecoration _heroInputDecoration(String hintText,
      {Color filledColor = Colors.white}) {
    return InputDecoration(
      hintText: hintText,
      isDense: true,
      filled: true,
      fillColor: filledColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: _inputDecoration(hintText),
        ),
      ],
    );
  }

  Widget _buildTableHeader(List<String> labels,
      {List<int>? columnWidths}) {
    final widths =
        columnWidths ?? List<int>.filled(labels.length, 1, growable: false);
    return Row(
      children: List.generate(labels.length, (index) {
        return Expanded(
          flex: widths[index],
          child: Text(
            labels[index],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        );
      }),
    );
  }

  void _addHeroStat() {
    setState(() {
      _heroStats.add(_HeroStatItem(id: _newId(), label: '', value: ''));
    });
    _scheduleSave();
  }

  void _updateHeroStat(_HeroStatItem item) {
    final index = _heroStats.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _heroStats[index] = item;
    _scheduleSave();
  }

  void _deleteHeroStat(String id) {
    setState(() => _heroStats.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addSnapshotMetric() {
    setState(() {
      _snapshotMetrics.add(_SnapshotMetric(
        id: _newId(),
        title: '',
        subtitle: '',
        value: '',
        accent: const Color(0xFF0EA5E9),
      ));
    });
    _scheduleSave();
  }

  void _updateSnapshotMetric(_SnapshotMetric metric) {
    final index =
        _snapshotMetrics.indexWhere((entry) => entry.id == metric.id);
    if (index == -1) return;
    _snapshotMetrics[index] = metric;
    _scheduleSave();
  }

  void _deleteSnapshotMetric(String id) {
    setState(() => _snapshotMetrics.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addChecklistItem() {
    setState(() {
      _checklist.add(_ChecklistItem(
        id: _newId(),
        title: '',
        owner: '',
        dueDate: '',
        status: _checklistStatuses.first,
      ));
    });
    _scheduleSave();
  }

  void _updateChecklistItem(_ChecklistItem item, {bool notify = false}) {
    final index = _checklist.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _checklist[index] = item;
    if (notify && mounted) {
      setState(() {});
    }
    _scheduleSave();
  }

  void _deleteChecklistItem(String id) {
    setState(() => _checklist.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addSignOffItem() {
    setState(() {
      _signOffs.add(_SignOffItem(
        id: _newId(),
        name: '',
        role: '',
        status: _signOffStatuses.first,
        decisionDate: '',
      ));
    });
    _scheduleSave();
  }

  void _updateSignOffItem(_SignOffItem item, {bool notify = false}) {
    final index = _signOffs.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _signOffs[index] = item;
    if (notify && mounted) {
      setState(() {});
    }
    _scheduleSave();
  }

  void _deleteSignOffItem(String id) {
    setState(() => _signOffs.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }

  void _addInsight() {
    setState(() {
      _insights.add(_InsightItem(id: _newId(), title: '', detail: ''));
    });
    _scheduleSave();
  }

  void _updateInsight(_InsightItem item) {
    final index = _insights.indexWhere((entry) => entry.id == item.id);
    if (index == -1) return;
    _insights[index] = item;
    _scheduleSave();
  }

  void _deleteInsight(String id) {
    setState(() => _insights.removeWhere((entry) => entry.id == id));
    _scheduleSave();
  }
}

class _HeroStatField extends StatelessWidget {
  const _HeroStatField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: SizedBox(
        width: 180,
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final _HeroStatItem item;
  final ValueChanged<_HeroStatItem> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: ValueKey('hero-label-${item.id}'),
              initialValue: item.label,
              style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Label',
                hintStyle: TextStyle(color: Color(0xFFD1D5DB)),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) => onChanged(item.copyWith(label: value)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              key: ValueKey('hero-value-${item.id}'),
              initialValue: item.value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Value',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) => onChanged(item.copyWith(value: value)),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.white70),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatAddButton extends StatelessWidget {
  const _HeroStatAddButton({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const SizedBox(
          width: 140,
          child: Row(
            children: [
              Icon(Icons.add, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('Add stat',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.item,
    required this.onChanged,
    required this.onDelete,
  });

  final _InsightItem item;
  final ValueChanged<_InsightItem> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: ValueKey('insight-title-${item.id}'),
            initialValue: item.title,
            decoration: const InputDecoration(
              hintText: 'Insight title',
              border: InputBorder.none,
            ),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827)),
            onChanged: (value) =>
                onChanged(item.copyWith(title: value)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('insight-detail-${item.id}'),
            initialValue: item.detail,
            decoration: const InputDecoration(
              hintText: 'Detail',
              border: InputBorder.none,
            ),
            maxLines: 3,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
            onChanged: (value) =>
                onChanged(item.copyWith(detail: value)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827))),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827))),
                const SizedBox(height: 2),
                Text(message,
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatItem {
  _HeroStatItem({required this.id, required this.label, required this.value});

  final String id;
  final String label;
  final String value;

  _HeroStatItem copyWith({String? label, String? value}) {
    return _HeroStatItem(
      id: id,
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'value': value,
      };

  static List<_HeroStatItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _HeroStatItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        label: map['label']?.toString() ?? '',
        value: map['value']?.toString() ?? '',
      );
    }).toList();
  }
}

class _SnapshotMetric {
  _SnapshotMetric({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
  });

  final String id;
  final String title;
  final String subtitle;
  final String value;
  final Color accent;

  _SnapshotMetric copyWith({
    String? title,
    String? subtitle,
    String? value,
    Color? accent,
  }) {
    return _SnapshotMetric(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      value: value ?? this.value,
      accent: accent ?? this.accent,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'value': value,
        'accent': accent.toARGB32(),
      };

  static List<_SnapshotMetric> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _SnapshotMetric(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
        value: map['value']?.toString() ?? '',
        accent: Color(map['accent'] is int
            ? map['accent'] as int
            : const Color(0xFF0EA5E9).toARGB32()),
      );
    }).toList();
  }
}

class _ChecklistItem {
  _ChecklistItem({
    required this.id,
    required this.title,
    required this.owner,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final String title;
  final String owner;
  final String dueDate;
  final String status;

  _ChecklistItem copyWith({
    String? title,
    String? owner,
    String? dueDate,
    String? status,
  }) {
    return _ChecklistItem(
      id: id,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'owner': owner,
        'dueDate': dueDate,
        'status': status,
      };

  static List<_ChecklistItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _ChecklistItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        owner: map['owner']?.toString() ?? '',
        dueDate: map['dueDate']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Not started',
      );
    }).toList();
  }
}

class _SignOffItem {
  _SignOffItem({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.decisionDate,
  });

  final String id;
  final String name;
  final String role;
  final String status;
  final String decisionDate;

  _SignOffItem copyWith({
    String? name,
    String? role,
    String? status,
    String? decisionDate,
  }) {
    return _SignOffItem(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      decisionDate: decisionDate ?? this.decisionDate,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'role': role,
        'status': status,
        'decisionDate': decisionDate,
      };

  static List<_SignOffItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _SignOffItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: map['name']?.toString() ?? '',
        role: map['role']?.toString() ?? '',
        status: map['status']?.toString() ?? 'Pending',
        decisionDate: map['decisionDate']?.toString() ?? '',
      );
    }).toList();
  }
}

class _InsightItem {
  _InsightItem({
    required this.id,
    required this.title,
    required this.detail,
  });

  final String id;
  final String title;
  final String detail;

  _InsightItem copyWith({String? title, String? detail}) {
    return _InsightItem(
      id: id,
      title: title ?? this.title,
      detail: detail ?? this.detail,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'detail': detail,
      };

  static List<_InsightItem> fromList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map? ?? {});
      return _InsightItem(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        detail: map['detail']?.toString() ?? '',
      );
    }).toList();
  }
}

class _Debouncer {
  _Debouncer({Duration? delay}) : delay = delay ?? const Duration(milliseconds: 600);

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
