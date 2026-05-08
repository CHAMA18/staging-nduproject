import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final double horizontalPadding = AppBreakpoints.isMobile(context) ? 20 : 40;

    return Scaffold(
      backgroundColor: Colors.white,
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
                  Column(
                    children: [
                      _buildWorldClassHeader(context),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildOverviewCards(),
                              const SizedBox(height: 24),
                              if (_isLoading)
                                const Center(
                                    child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: CircularProgressIndicator(),
                                ))
                              else ...[
                                _buildSnapshotSection(context),
                                const SizedBox(height: 24),
                                _buildFinalizeChecklist(),
                                const SizedBox(height: 24),
                                _buildSignOffPanel(),
                                const SizedBox(height: 24),
                                _buildClosureInsights(context),
                                const SizedBox(height: 24),
                                _buildPremiumActionBar(context),
                              ],
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildWorldClassHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Finalize Project',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lock scope, validate handoffs, and close out the project with confidence.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _finalizationStatus,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const _CurrentUserProfileChip(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            title: 'Finalization Status',
            value: _finalizationStatus,
            icon: Icons.check_circle_outline,
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildOverviewCard(
            title: 'Snapshot Metrics',
            value: '${_snapshotMetrics.length}',
            icon: Icons.dashboard_outlined,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildOverviewCard(
            title: 'Pending Checklists',
            value: '${_checklist.where((c) => c.status != 'Done').length}',
            icon: Icons.task_outlined,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildOverviewCard(
            title: 'Sign-offs',
            value: '${_signOffs.where((s) => s.status == 'Approved').length}/${_signOffs.length}',
            icon: Icons.verified_outlined,
            color: const Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
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
      trailing: null, // Permanently read-only - no edit button
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_snapshotMetrics.isEmpty)
            const _InlineEmptyState(
              title: 'No snapshot metrics',
              message: 'Add the metrics that summarize project closeout.',
            )
          else
            ..._snapshotMetrics.map((metric) => _buildSnapshotReadOnlyRow(metric)),
        ],
      ),
    );
  }

  Widget _buildSnapshotReadOnlyRow(_SnapshotMetric metric) {
    final valueColor = _getValueColor(metric.value);
    final valueIcon = _getValueIcon(metric.value);
    final hasData = metric.title.isNotEmpty ||
        metric.subtitle.isNotEmpty ||
        metric.value.isNotEmpty;

    // Safely get the accent color with fallback for invalid colors
    Color getSafeAccent() {
      try {
        return metric.accent;
      } catch (_) {
        return const Color(0xFF0EA5E9);
      }
    }

    if (!hasData) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No data entered',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Click Edit to add this metric',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Empty',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final safeAccent = getSafeAccent();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: safeAccent.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        metric.title.isEmpty ? 'Untitled Metric' : metric.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    _buildStatusBadge(metric.value, valueColor, valueIcon),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.signal_cellular_alt,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          metric.subtitle.isEmpty ? 'No signal' : metric.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF16A34A).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 11,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Saved',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16A34A),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value.isEmpty ? 'Not set' : value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getValueIcon(String value) {
    switch (value.toLowerCase()) {
      case 'complete':
        return Icons.check_circle_rounded;
      case 'on track':
        return Icons.trending_up_rounded;
      case 'at risk':
        return Icons.warning_rounded;
      case 'blocked':
        return Icons.block_rounded;
      case 'in progress':
        return Icons.autorenew_rounded;
      case 'not started':
        return Icons.radio_button_unchecked_rounded;
      case 'under review':
        return Icons.visibility_rounded;
      case 'pending sign-off':
        return Icons.pending_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  Color _getValueColor(String value) {
    switch (value.toLowerCase()) {
      case 'complete':
        return const Color(0xFF16A34A);
      case 'on track':
        return const Color(0xFF0EA5E9);
      case 'at risk':
        return const Color(0xFFF59E0B);
      case 'blocked':
        return const Color(0xFFEF4444);
      case 'in progress':
        return const Color(0xFF8B5CF6);
      case 'under review':
        return const Color(0xFF06B6D4);
      case 'pending sign-off':
        return const Color(0xFFF97316);
      case 'not started':
        return const Color(0xFF94A3B8);
      default:
        return const Color(0xFF6B7280);
    }
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
          FilledButton.icon(
            onPressed: _addChecklistItem,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add checklist item'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
          FilledButton.icon(
            onPressed: _addSignOffItem,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add sign-off'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
          FilledButton.icon(
            onPressed: _addInsight,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add insight'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Finalize decision log',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: Color(0xFF6B7280)),
                    SizedBox(width: 4),
                    Text(
                      'Read-only',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Capture the final decision summary and next-step actions.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),
          _buildStaticLabeledField(
            label: 'Finalization notes',
            text: _finalNotesController.text.isEmpty
                ? 'No finalization notes recorded'
                : _finalNotesController.text,
            hintText: 'Summarize final checks, approvals, and open items.',
          ),
          const SizedBox(height: 12),
          _buildStaticLabeledField(
            label: 'Next steps after closeout',
            text: _nextStepsController.text.isEmpty
                ? 'No next steps recorded'
                : _nextStepsController.text,
            hintText: 'List post-launch actions and support transitions.',
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

  Widget _buildStaticLabeledField({
    required String label,
    required String text,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151)),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.lock_rounded,
              size: 10,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: text == hintText ||
                      text == 'No finalization notes recorded' ||
                      text == 'No next steps recorded'
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF111827),
              fontStyle: text == hintText ||
                      text == 'No finalization notes recorded' ||
                      text == 'No next steps recorded'
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
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

class _CurrentUserProfileChip extends StatelessWidget {
  const _CurrentUserProfileChip();

  String _initials(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r"\s+"));
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase();
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final photoUrl = user?.photoURL;
    final email = user?.email ?? '';

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        _initials(displayName),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563)),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827)),
                  ),
                  Text(
                    role,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      size: 18, color: const Color(0xFF059669)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              letterSpacing: -0.3)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
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

      // Safely deserialize accent color with validation
      Color safeAccent(int defaultArgb) {
        if (map['accent'] is int && map['accent'] != null) {
          try {
            return Color(map['accent'] as int);
          } catch (_) {
            // Invalid color value, use default
          }
        }
        return Color(defaultArgb);
      }

      return _SnapshotMetric(
        id: map['id']?.toString() ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString() ?? '',
        value: map['value']?.toString() ?? '',
        accent: safeAccent(0xFF0EA5E9),
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
