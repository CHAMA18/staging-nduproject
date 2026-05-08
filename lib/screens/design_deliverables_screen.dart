import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/responsive_scaffold.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/screens/project_activities_log_screen.dart';
import 'package:ndu_project/screens/specialized_design_screen.dart';
import 'package:ndu_project/screens/staff_team_screen.dart';
import 'package:ndu_project/services/activity_log_service.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/design_phase_service.dart';

const Color _kPageBackground = Color(0xFFF4F7FF);
const Color _kSurface = Colors.white;
const Color _kPanelSoft = Color(0xFFF8FAFF);
const Color _kBorder = Color(0xFFDDE5F3);
const Color _kPrimary = Color(0xFF0B4DBB);
const Color _kPrimaryDeep = Color(0xFF082A63);
const Color _kSecondary = Color(0xFF5B6F95);
const Color _kTeal = Color(0xFF0B7D68);
const Color _kSubtext = Color(0xFF667085);

class DesignDeliverablesScreen extends StatefulWidget {
  const DesignDeliverablesScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DesignDeliverablesScreen()),
    );
  }

  @override
  State<DesignDeliverablesScreen> createState() =>
      _DesignDeliverablesScreenState();
}

class _DesignDeliverablesScreenState extends State<DesignDeliverablesScreen> {
  DesignDeliverablesData _data = DesignDeliverablesData();
  bool _loading = false;
  String? _error;
  final _saveDebouncer = _Debouncer();
  bool _saving = false;
  DateTime? _lastSavedAt;

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _dedupeTextList(Iterable<String> values) {
    final seen = <String>{};
    final deduped = <String>[];
    for (final value in values) {
      final normalized = _normalize(value);
      if (normalized.isEmpty) continue;
      if (seen.add(normalized)) deduped.add(value.trim());
    }
    return deduped;
  }

  List<DesignDeliverablePipelineItem> _dedupePipeline(
      Iterable<DesignDeliverablePipelineItem> items) {
    final seen = <String>{};
    final deduped = <DesignDeliverablePipelineItem>[];
    for (final item in items) {
      final key = '${_normalize(item.label)}|${_normalize(item.status)}';
      if (key == '|') continue;
      if (seen.add(key)) deduped.add(item);
    }
    return deduped;
  }

  List<DesignDeliverableRegisterItem> _dedupeRegister(
      Iterable<DesignDeliverableRegisterItem> items) {
    final seen = <String>{};
    final deduped = <DesignDeliverableRegisterItem>[];
    for (final item in items) {
      final key =
          '${_normalize(item.name)}|${_normalize(item.owner)}|${_normalize(item.status)}|${_normalize(item.due)}|${_normalize(item.risk)}';
      if (key == '||||') continue;
      if (seen.add(key)) deduped.add(item);
    }
    return deduped;
  }

  DesignDeliverablesData _dedupeData(DesignDeliverablesData data) {
    return data.copyWith(
      pipeline: _dedupePipeline(data.pipeline),
      approvals: _dedupeTextList(data.approvals),
      register: _dedupeRegister(data.register),
      dependencies: _dedupeTextList(data.dependencies),
      handoffChecklist: _dedupeTextList(data.handoffChecklist),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    // Read from context before any awaits to avoid use_build_context_synchronously.
    final projectData = ProjectDataHelper.getData(context);
    final projectId = projectData.projectId;
    if (projectId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Try generic service load
      var loaded =
          await DesignPhaseService.instance.loadDesignDeliverables(projectId);

      if (!mounted) return;

      // 2. Fallback to legacy structure in ProjectDataModel
      if (loaded == null) {
        final existing = projectData.designDeliverablesData;
        if (!existing.isEmpty) {
          loaded = existing;
          // Note: We don't auto-save immediately to new service unless user changes something or we want migration on read.
          // Let's migrate on read:
          _updateData(loaded, saveImmediate: true);
        }
      }

      // 3. AI Generation if absolutely nothing exists
      if (loaded == null || loaded.isEmpty) {
        await _generateFromAi();
      } else {
        _applyData(loaded);
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load data: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }

  Future<void> _generateFromAi() async {
    // If we are already loading from _loadData, don't set loading=true again if it confuses logic,
    // but here we are called sequentially.
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = ProjectDataHelper.getData(context);
      final contextText = ProjectDataHelper.buildFepContext(data,
          sectionLabel: 'Design Deliverables');
      final generated = await OpenAiServiceSecure()
          .generateDesignDeliverables(context: contextText);

      if (!mounted) return;

      // Save to new service
      _updateData(generated, saveImmediate: true);

      // Also update provider for legacy read compatibility if needed (optional)
      ProjectDataHelper.getProvider(context).updateField(
        (current) => current.copyWith(designDeliverablesData: generated),
      );

      await _logActivity(
        'Generated Design Deliverables with AI',
        details: {
          'pipelineCount': generated.pipeline.length,
          'registerCount': generated.register.length,
          'approvalCount': generated.approvals.length,
        },
      );

      setState(() {
        _applyData(generated);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to generate content. Please try again later.';
        _data = DesignDeliverablesData(); // Fallback to empty
      });
    }
  }

  void _updateData(DesignDeliverablesData data, {bool saveImmediate = false}) {
    final deduped = _dedupeData(data);
    final computed = _computeMetrics(deduped.register);
    final nextData = deduped.copyWith(metrics: computed);
    setState(() => _data = nextData);

    // We update generic provider too, to keep UI consistent if other widgets rely on it,
    // although we are moving away from it.
    ProjectDataHelper.getProvider(context).updateField(
      (current) => current.copyWith(designDeliverablesData: nextData),
    );

    if (saveImmediate) {
      _saveNow();
    } else {
      _scheduleSave();
    }
  }

  void _applyData(DesignDeliverablesData data) {
    final deduped = _dedupeData(data);
    final computed = _computeMetrics(deduped.register);
    setState(() => _data = deduped.copyWith(metrics: computed));
  }

  DesignDeliverablesMetrics _computeMetrics(
      List<DesignDeliverableRegisterItem> rows) {
    int active = 0;
    int inReview = 0;
    int approved = 0;
    int atRisk = 0;
    for (final row in rows) {
      final status = row.status.trim().toLowerCase();
      final risk = row.risk.trim().toLowerCase();
      if (status == 'in review') {
        inReview++;
      } else if (status == 'approved') {
        approved++;
      } else if (status == 'in progress' || status == 'pending') {
        active++;
      }
      if (risk == 'high') {
        atRisk++;
      }
    }
    return DesignDeliverablesMetrics(
      active: active,
      inReview: inReview,
      approved: approved,
      atRisk: atRisk,
    );
  }

  void _scheduleSave() {
    _saveDebouncer.run(() async {
      if (!mounted) return;
      await _saveNow();
    });
  }

  Future<void> _saveNow() async {
    if (_saving) return;
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null) return;

    setState(() => _saving = true);

    try {
      await DesignPhaseService.instance
          .saveDesignDeliverables(projectId, _data);
      await _logActivity(
        'Updated Design Deliverables data',
        details: {
          'pipelineCount': _data.pipeline.length,
          'registerCount': _data.register.length,
          'dependencyCount': _data.dependencies.length,
        },
      );

      if (!mounted) return;
      setState(() {
        _saving = false;
        _lastSavedAt = DateTime.now();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save Design Deliverables right now.'),
          ),
        );
      }
    }
  }

  Future<void> _logActivity(
    String action, {
    Map<String, dynamic>? details,
  }) async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null || projectId.isEmpty) return;
    await ActivityLogService.instance.logActivity(
      projectId: projectId,
      phase: 'Design Phase',
      page: 'Design Deliverables',
      action: action,
      details: details,
    );
  }

  Future<void> _showAddPipelineItemDialog() async {
    final labelController = TextEditingController();
    String status = 'In progress';

    final item = await showDialog<DesignDeliverablePipelineItem>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Add Pipeline Item'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Stage or deliverable',
                        hintText: 'e.g. Final signage package',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      items: const [
                        DropdownMenuItem(
                            value: 'In progress', child: Text('In progress')),
                        DropdownMenuItem(
                            value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(
                            value: 'In review', child: Text('In review')),
                        DropdownMenuItem(
                            value: 'Approved', child: Text('Approved')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => status = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Status',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final label = labelController.text.trim();
                    if (label.isEmpty) return;
                    Navigator.of(context).pop(
                      DesignDeliverablePipelineItem(
                        label: label,
                        status: status,
                      ),
                    );
                  },
                  child: const Text('Add Item'),
                ),
              ],
            );
          },
        );
      },
    );

    labelController.dispose();
    if (item == null) return;
    _updateData(_data.copyWith(pipeline: [..._data.pipeline, item]));
  }

  Future<void> _showAddApprovalDialog() async {
    final approvalController = TextEditingController();

    final approval = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Approval'),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: approvalController,
              decoration: const InputDecoration(
                labelText: 'Approval item',
                hintText: 'e.g. Sponsor sign-off for production pack',
              ),
              minLines: 2,
              maxLines: 3,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = approvalController.text.trim();
                if (value.isEmpty) return;
                Navigator.of(context).pop(value);
              },
              child: const Text('Add Approval'),
            ),
          ],
        );
      },
    );

    approvalController.dispose();
    if (approval == null) return;
    _updateData(_data.copyWith(approvals: [..._data.approvals, approval]));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 20.0 : 32.0;
    final data = _data;

    return ResponsiveScaffold(
      activeItemLabel: 'Design Deliverables',
      backgroundColor: _kPageBackground,
      floatingActionButton: const KazAiChatBubble(positioned: false),
      body: SingleChildScrollView(
        padding:
            EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlanningPhaseHeader(
                  title: 'Design Deliverables',
                  onBack: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const SpecializedDesignScreen(),
                    ),
                  ),
                  onForward: () => StaffTeamScreen.open(context),
                  showImportButton: false,
                  showContentButton: false,
                ),
                const SizedBox(height: 20),
                _ExecutiveIntroBanner(
                  isSaving: _saving,
                  savedAt: _lastSavedAt,
                  isLoading: _loading,
                  error: _error,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _generateFromAi,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry AI Generation'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _MetricsPanel(metrics: data.metrics),
                const SizedBox(height: 24),
                _DeliverablePipelineCard(
                  items: data.pipeline,
                  onAddRequested: _showAddPipelineItemDialog,
                  onChanged: (items) =>
                      _updateData(data.copyWith(pipeline: items)),
                ),
                const SizedBox(height: 20),
                _ApprovalStatusCard(
                  items: data.approvals,
                  onAddRequested: _showAddApprovalDialog,
                  onChanged: (items) => _updateData(
                    data.copyWith(approvals: items),
                  ),
                ),
                const SizedBox(height: 24),
                _DesignDeliverablesTable(
                  rows: data.register,
                  onChanged: (rows) =>
                      _updateData(data.copyWith(register: rows)),
                ),
                const SizedBox(height: 20),
                _DesignDependenciesCard(
                  items: data.dependencies,
                  onChanged: (items) => _updateData(
                    data.copyWith(dependencies: items),
                  ),
                ),
                const SizedBox(height: 24),
                _DesignHandoffCard(
                  items: data.handoffChecklist,
                  onChanged: (items) => _updateData(
                    data.copyWith(handoffChecklist: items),
                  ),
                ),
                const SizedBox(height: 24),
                const _IntegrityPanel(),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => StaffTeamScreen.open(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF111827),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExecutiveIntroBanner extends StatelessWidget {
  const _ExecutiveIntroBanner({
    required this.isSaving,
    required this.savedAt,
    required this.isLoading,
    required this.error,
  });

  final bool isSaving;
  final DateTime? savedAt;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const _BannerPill(
          label: 'Phase: Design Deliverables',
          background: Color(0xFFE5EEFF),
          foreground: _kPrimary,
          icon: Icons.dashboard_customize_outlined,
        ),
        const _BannerPill(
          label: 'Executive tracking mode',
          background: Color(0xFFEAF8F3),
          foreground: _kTeal,
          icon: Icons.verified_outlined,
        ),
        _SaveStatusChip(isSaving: isSaving, savedAt: savedAt),
        _StatusBanner(isLoading: isLoading, error: error),
      ],
    );
  }
}

class _BannerPill extends StatelessWidget {
  const _BannerPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: foreground,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({required this.metrics});

  final DesignDeliverablesMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCardData(
        label: 'Active Deliverables',
        accent: _kPrimary,
        value: metrics.active,
        icon: Icons.inventory_2_rounded,
        progress: metrics.active == 0 ? 0.18 : 0.70,
      ),
      _MetricCardData(
        label: 'In Review',
        accent: const Color(0xFFD58A00),
        value: metrics.inReview,
        icon: Icons.visibility_outlined,
        progress: metrics.inReview == 0 ? 0.12 : 0.30,
      ),
      _MetricCardData(
        label: 'Approved',
        accent: _kTeal,
        value: metrics.approved,
        icon: Icons.verified_rounded,
        progress: metrics.approved == 0 ? 0.12 : 0.92,
      ),
      _MetricCardData(
        label: 'At Risk',
        accent: const Color(0xFFDC2626),
        value: metrics.atRisk,
        icon: Icons.warning_amber_rounded,
        progress: metrics.atRisk == 0 ? 0.08 : 0.15,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        if (compact) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                _MetricCard(data: cards[i]),
                if (i != cards.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _MetricCard(data: cards[0])),
                const SizedBox(width: 12),
                Expanded(child: _MetricCard(data: cards[1])),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _MetricCard(data: cards[2])),
                const SizedBox(width: 12),
                Expanded(child: _MetricCard(data: cards[3])),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _IntegrityPanel extends StatelessWidget {
  const _IntegrityPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kPrimaryDeep, Color(0xFF1B3F86)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22082A63),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final iconBlock = Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.token_rounded,
              size: 40,
              color: Colors.white,
            ),
          );
          final content = const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Integrity Check',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Final approval should only happen after active deliverables are mapped to approvals, dependencies, and handoff evidence. This keeps the next phase clean and reduces rework risk.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD6E4FF),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconBlock,
                const SizedBox(height: 18),
                const Text(
                  'System Integrity Check',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Final approval should only happen after active deliverables are mapped to approvals, dependencies, and handoff evidence. This keeps the next phase clean and reduces rework risk.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD6E4FF),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 18),
                _OutlineActionButton(
                  label: 'View Logs',
                  onPressed: () => ProjectActivitiesLogScreen.open(context),
                ),
              ],
            );
          }

          return Row(
            children: [
              iconBlock,
              const SizedBox(width: 20),
              content,
              const SizedBox(width: 20),
              _OutlineActionButton(
                label: 'View Logs',
                onPressed: () => ProjectActivitiesLogScreen.open(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.label,
    required this.accent,
    required this.value,
    required this.icon,
    required this.progress,
  });

  final String label;
  final Color accent;
  final int value;
  final IconData icon;
  final double progress;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F082A63),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, color: data.accent, size: 22),
              Text(
                data.value.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: _kPrimaryDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _kSubtext,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: data.progress,
              backgroundColor: data.accent.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(data.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverablePipelineCard extends StatelessWidget {
  const _DeliverablePipelineCard(
      {required this.items,
      required this.onChanged,
      required this.onAddRequested});

  final List<DesignDeliverablePipelineItem> items;
  final ValueChanged<List<DesignDeliverablePipelineItem>> onChanged;
  final VoidCallback onAddRequested;

  List<DesignDeliverablePipelineItem> _updateItem(
    List<DesignDeliverablePipelineItem> list,
    int index,
    DesignDeliverablePipelineItem item,
  ) {
    final next = [...list];
    next[index] = item;
    return next;
  }

  List<DesignDeliverablePipelineItem> _removeItem(
      List<DesignDeliverablePipelineItem> list, int index) {
    final next = [...list];
    next.removeAt(index);
    return next;
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Deliverable Pipeline',
      subtitle: 'Progress across design stages.',
      child: Column(
        children: [
          if (items.isNotEmpty)
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _EditablePipelineRow(
                index: index,
                item: item,
                onChanged: (updated) =>
                    onChanged(_updateItem(items, index, updated)),
                onRemove: () => onChanged(_removeItem(items, index)),
              );
            }),
          if (items.isEmpty)
            const _EmptyStateRow(message: 'No pipeline updates yet.'),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddRequested,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add pipeline item'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalStatusCard extends StatelessWidget {
  const _ApprovalStatusCard(
      {required this.items,
      required this.onChanged,
      required this.onAddRequested});

  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final VoidCallback onAddRequested;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Approval Status',
      subtitle: 'Stakeholder sign-offs and gating items.',
      child: Column(
        children: [
          if (items.isNotEmpty)
            ...items.asMap().entries.map((entry) {
              return _EditableChecklistRow(
                index: entry.key,
                value: entry.value,
                onChanged: (value) {
                  final next = [...items];
                  next[entry.key] = value;
                  onChanged(next);
                },
                onRemove: () {
                  final next = [...items]..removeAt(entry.key);
                  onChanged(next);
                },
              );
            }),
          if (items.isEmpty)
            const _EmptyStateRow(message: 'No approvals tracked yet.'),
          if (items.isEmpty) const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddRequested,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add approval'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignDeliverablesTable extends StatelessWidget {
  const _DesignDeliverablesTable({required this.rows, required this.onChanged});

  final List<DesignDeliverableRegisterItem> rows;
  final ValueChanged<List<DesignDeliverableRegisterItem>> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Deliverables Register',
      subtitle: 'Track key artifacts and readiness.',
      child: Column(
        children: [
          const _RegisterHeader(),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const _EmptyStateRow(message: 'No deliverables registered yet.'),
          if (rows.isNotEmpty)
            ...rows.asMap().entries.map(
                  (entry) => _EditableRegisterRow(
                    index: entry.key,
                    row: entry.value,
                    onChanged: (updated) {
                      final next = [...rows];
                      next[entry.key] = updated;
                      onChanged(next);
                    },
                    onRemove: () {
                      final next = [...rows]..removeAt(entry.key);
                      onChanged(next);
                    },
                  ),
                ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onChanged([
                ...rows,
                const DesignDeliverableRegisterItem(),
              ]),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add deliverable'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignDependenciesCard extends StatelessWidget {
  const _DesignDependenciesCard({required this.items, required this.onChanged});

  final List<String> items;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Design Dependencies',
      subtitle: 'Items that unblock delivery.',
      child: Column(
        children: [
          if (items.isNotEmpty)
            ...items.asMap().entries.map((entry) {
              return _EditableBulletRow(
                index: entry.key,
                value: entry.value,
                onChanged: (value) {
                  final next = [...items];
                  next[entry.key] = value;
                  onChanged(next);
                },
                onRemove: () {
                  final next = [...items]..removeAt(entry.key);
                  onChanged(next);
                },
              );
            }),
          if (items.isEmpty)
            const _EmptyStateRow(message: 'No dependencies captured yet.'),
          if (items.isEmpty) const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onChanged([...items, '']),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add dependency'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignHandoffCard extends StatelessWidget {
  const _DesignHandoffCard({required this.items, required this.onChanged});

  final List<String> items;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Design Handoff Checklist',
      subtitle: 'Ensure delivery-ready assets.',
      child: Column(
        children: [
          if (items.isNotEmpty)
            ...items.asMap().entries.map((entry) {
              return _EditableChecklistRow(
                index: entry.key,
                value: entry.value,
                onChanged: (value) {
                  final next = [...items];
                  next[entry.key] = value;
                  onChanged(next);
                },
                onRemove: () {
                  final next = [...items]..removeAt(entry.key);
                  onChanged(next);
                },
              );
            }),
          if (items.isEmpty)
            const _EmptyStateRow(message: 'No handoff items listed yet.'),
          if (items.isEmpty) const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onChanged([...items, '']),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add handoff item'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F082A63),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _kPrimaryDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: _kSubtext,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _EditablePipelineRow extends StatelessWidget {
  const _EditablePipelineRow({
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final DesignDeliverablePipelineItem item;
  final ValueChanged<DesignDeliverablePipelineItem> onChanged;
  final VoidCallback onRemove;

  static const List<String> _statusOptions = [
    'In progress',
    'In review',
    'Complete',
    'Blocked',
  ];

  @override
  Widget build(BuildContext context) {
    final statusValue =
        item.status.trim().isEmpty ? _statusOptions.first : item.status;
    final options = _statusOptions.contains(statusValue)
        ? _statusOptions
        : [statusValue, ..._statusOptions];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: TextFormField(
              key: ValueKey('pipeline-label-$index'),
              initialValue: item.label,
              decoration: _inlineInputDecoration('Stage or deliverable'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              onChanged: (value) => onChanged(DesignDeliverablePipelineItem(
                label: value,
                status: item.status,
              )),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: options.first,
              decoration: _inlineInputDecoration('Status'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              items: options
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                onChanged(DesignDeliverablePipelineItem(
                  label: item.label,
                  status: value,
                ));
              },
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _PipelineRow extends StatelessWidget {
  const _PipelineRow({required this.label, required this.value});

  final String label;
  final String value;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'complete':
        return const Color(0xFF10B981);
      case 'in review':
        return const Color(0xFFF59E0B);
      case 'in progress':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(value,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}

class _EditableChecklistRow extends StatelessWidget {
  const _EditableChecklistRow({
    required this.index,
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: ValueKey('checklist-$index'),
              initialValue: value,
              decoration: _inlineInputDecoration('Add item'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              onChanged: onChanged,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF374151)))),
        ],
      ),
    );
  }
}

class _EditableBulletRow extends StatelessWidget {
  const _EditableBulletRow({
    required this.index,
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              key: ValueKey('bullet-$index'),
              initialValue: value,
              decoration: _inlineInputDecoration('Add dependency'),
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF374151), height: 1.4),
              onChanged: onChanged,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}

class _EditableRegisterRow extends StatelessWidget {
  const _EditableRegisterRow({
    required this.index,
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final DesignDeliverableRegisterItem row;
  final ValueChanged<DesignDeliverableRegisterItem> onChanged;
  final VoidCallback onRemove;

  static const List<String> _statusOptions = [
    'In progress',
    'In review',
    'Approved',
    'Pending',
  ];

  static const List<String> _riskOptions = ['Low', 'Medium', 'High'];

  List<String> _ownerOptions(BuildContext context) {
    final members = ProjectDataHelper.getData(context).teamMembers;
    final names = members
        .map((member) {
          final name = member.name.trim();
          if (name.isNotEmpty) return name;
          final email = member.email.trim();
          if (email.isNotEmpty) return email;
          return member.role.trim();
        })
        .where((value) => value.isNotEmpty)
        .toList();
    if (names.isEmpty) return const ['Owner'];
    return names.toSet().toList();
  }

  List<String> _optionsFor(String value, List<String> defaults) {
    if (value.isEmpty) return defaults;
    return defaults.contains(value) ? defaults : [value, ...defaults];
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = _optionsFor(row.status, _statusOptions);
    final riskOptions = _optionsFor(row.risk, _riskOptions);
    final ownerOptions = _optionsFor(row.owner, _ownerOptions(context));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextFormField(
              key: ValueKey('deliverable-name-$index'),
              initialValue: row.name,
              decoration: _inlineInputDecoration('Deliverable'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              onChanged: (value) => onChanged(row.copyWith(name: value)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              key: ValueKey('deliverable-owner-$index'),
              initialValue: ownerOptions.first,
              decoration: _inlineInputDecoration('Owner'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              items: ownerOptions
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                onChanged(row.copyWith(owner: value));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: statusOptions.first,
              decoration: _inlineInputDecoration('Status'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              items: statusOptions
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                onChanged(row.copyWith(status: value));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('deliverable-due-$index'),
              initialValue: row.due,
              decoration: _inlineInputDecoration('Due date'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              keyboardType: TextInputType.datetime,
              onChanged: (value) => onChanged(row.copyWith(due: value)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: riskOptions.first,
              decoration: _inlineInputDecoration('Risk'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
              items: riskOptions
                  .map((option) =>
                      DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                onChanged(row.copyWith(risk: value));
              },
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline,
                size: 18, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          flex: 4,
          child: Text('Deliverable',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        Expanded(
          flex: 3,
          child: Text('Owner',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        Expanded(
          flex: 2,
          child: Text('Status',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        Expanded(
          flex: 2,
          child: Text('Due',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
        Expanded(
          flex: 2,
          child: Text('Risk',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _RegisterRow extends StatelessWidget {
  const _RegisterRow({
    required this.name,
    required this.owner,
    required this.status,
    required this.due,
    required this.risk,
  });

  final String name;
  final String owner;
  final String status;
  final String due;
  final String risk;

  Color _riskColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'in review':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(name,
                style: const TextStyle(fontSize: 12, color: Color(0xFF111827))),
          ),
          Expanded(
            flex: 3,
            child: Text(owner,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
          Expanded(
            flex: 2,
            child: Text(status,
                style: TextStyle(fontSize: 12, color: _statusColor(status))),
          ),
          Expanded(
            flex: 2,
            child: Text(due,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
          Expanded(
            flex: 2,
            child: Text(risk,
                style: TextStyle(fontSize: 12, color: _riskColor(risk))),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateRow extends StatelessWidget {
  const _EmptyStateRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: _kPanelSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _kSubtext,
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isLoading, this.error});

  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final text = isLoading
        ? 'Generating deliverables from project context...'
        : error ?? 'Ready';
    final color = isLoading
        ? _kPrimary
        : (error == null ? _kTeal : const Color(0xFFDC2626));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(isLoading ? Icons.auto_awesome : Icons.info_outline,
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: TextStyle(fontSize: 12, color: color))),
        ],
      ),
    );
  }
}

class _SaveStatusChip extends StatelessWidget {
  const _SaveStatusChip({required this.isSaving, required this.savedAt});

  final bool isSaving;
  final DateTime? savedAt;

  @override
  Widget build(BuildContext context) {
    final label = isSaving
        ? 'Saving...'
        : savedAt == null
            ? 'Not saved'
            : 'Saved ${TimeOfDay.fromDateTime(savedAt!).format(context)}';
    final color = isSaving ? _kSecondary : _kTeal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF374151), height: 1.4))),
        ],
      ),
    );
  }
}

InputDecoration _inlineInputDecoration(String hint) {
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF2563EB)),
    ),
  );
}

class _Debouncer {
  _Debouncer({Duration? delay})
      : delay = delay ?? const Duration(milliseconds: 700);

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
