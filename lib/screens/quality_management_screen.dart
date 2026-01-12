import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';

enum _QualityTab { plan, targets, qaTracking, qcTracking, metrics }

class QualityManagementScreen extends StatefulWidget {
  const QualityManagementScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QualityManagementScreen()),
    );
  }

  @override
  State<QualityManagementScreen> createState() => _QualityManagementScreenState();
}

class _QualityManagementScreenState extends State<QualityManagementScreen> {
  _QualityTab _selectedTab = _QualityTab.plan;
  ProjectDataProvider? _provider;
  bool _isGenerating = false;
  bool _aiSeeded = false;
  final TextEditingController _planController = TextEditingController();
  List<QualityTargetData> _targets = [];
  List<QaTechniqueData> _qaTechniques = [];
  List<QcTechniqueData> _qcTechniques = [];
  List<QualityMetricSummaryData> _metricSummaries = [];
  QualityTrendSeriesData _defectTrend = QualityTrendSeriesData();
  QualityTrendSeriesData _satisfactionTrend = QualityTrendSeriesData();
  Timer? _planSaveDebounce;

  void _handleTabSelected(_QualityTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ProjectDataHelper.getData(context);
      _loadQualityData(data.qualityManagementData);
      final hasContent = _planController.text.trim().isNotEmpty ||
          _targets.isNotEmpty ||
          _qaTechniques.isNotEmpty ||
          _qcTechniques.isNotEmpty ||
          _metricSummaries.isNotEmpty;
      if (!hasContent && !_aiSeeded) {
        _generateQualityFromContext();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider ??= ProjectDataInherited.maybeOf(context);
  }

  @override
  void dispose() {
    _planSaveDebounce?.cancel();
    _planController.dispose();
    super.dispose();
  }

  void _loadQualityData(QualityManagementData data) {
    _aiSeeded = data.aiSeeded;
    _planController.text = data.plan;
    _targets = List<QualityTargetData>.from(data.targets);
    _qaTechniques = List<QaTechniqueData>.from(data.qaTechniques);
    _qcTechniques = List<QcTechniqueData>.from(data.qcTechniques);
    _metricSummaries = List<QualityMetricSummaryData>.from(data.metricSummaries);
    _defectTrend = data.defectTrend;
    _satisfactionTrend = data.satisfactionTrend;
  }

  QualityManagementData _buildQualityData() {
    return QualityManagementData(
      plan: _planController.text.trim(),
      targets: _targets,
      qaTechniques: _qaTechniques,
      qcTechniques: _qcTechniques,
      metricSummaries: _metricSummaries,
      defectTrend: _defectTrend,
      satisfactionTrend: _satisfactionTrend,
      aiSeeded: _aiSeeded,
    );
  }

  Future<void> _saveQualityData({bool showSnack = false}) async {
    final provider = _provider;
    if (provider == null) return;
    provider.updateField((data) => data.copyWith(qualityManagementData: _buildQualityData()));
    final success = await provider.saveToFirebase(checkpoint: 'quality_management');
    if (!mounted || !showSnack) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Quality management saved' : 'Unable to save quality management'),
        backgroundColor: success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
      ),
    );
  }

  void _queuePlanSave() {
    _planSaveDebounce?.cancel();
    _planSaveDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _saveQualityData();
      }
    });
  }

  Future<void> _generateQualityFromContext() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final data = ProjectDataHelper.getData(context);
      final contextText = ProjectDataHelper.buildExecutivePlanContext(data, sectionLabel: 'Quality Management');
      final fallbackContext = ProjectDataHelper.buildFepContext(data, sectionLabel: 'Quality Management');
      final ai = OpenAiServiceSecure();
      final generated = await ai.generateQualityManagementFromContext(
        contextText.trim().isEmpty ? fallbackContext : contextText,
      );
      if (!mounted) return;
      setState(() {
        _aiSeeded = true;
        _planController.text = generated.plan;
        _targets = List<QualityTargetData>.from(generated.targets);
        _qaTechniques = List<QaTechniqueData>.from(generated.qaTechniques);
        _qcTechniques = List<QcTechniqueData>.from(generated.qcTechniques);
        _metricSummaries = List<QualityMetricSummaryData>.from(generated.metricSummaries);
        _defectTrend = generated.defectTrend;
        _satisfactionTrend = generated.satisfactionTrend;
      });
      await _saveQualityData();
    } catch (e) {
      debugPrint('AI quality management generation failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

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
              child: const InitiationLikeSidebar(activeItemLabel: 'Quality Management'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _PageHeader(),
                        const SizedBox(height: 24),
                        const PlanningAiNotesCard(
                          title: 'AI Notes',
                          sectionLabel: 'Quality Management',
                          noteKey: 'planning_quality_management_notes',
                          checkpoint: 'quality_management',
                          description: 'Summarize quality targets, assurance cadence, and control measures.',
                        ),
                        const SizedBox(height: 24),
                        _TabStrip(selectedTab: _selectedTab, onSelected: _handleTabSelected),
                        const SizedBox(height: 28),
                        _TabContent(
                          selectedTab: _selectedTab,
                          planController: _planController,
                          targets: _targets,
                          qaTechniques: _qaTechniques,
                          qcTechniques: _qcTechniques,
                          metricSummaries: _metricSummaries,
                          defectTrend: _defectTrend,
                          satisfactionTrend: _satisfactionTrend,
                          onPlanChanged: _queuePlanSave,
                          onSavePlan: () => _saveQualityData(showSnack: true),
                          onAddTarget: (target) {
                            setState(() => _targets.add(target));
                            _saveQualityData();
                          },
                          onUpdateTarget: (index, target) {
                            setState(() => _targets[index] = target);
                            _saveQualityData();
                          },
                          onRemoveTarget: (index) {
                            setState(() => _targets.removeAt(index));
                            _saveQualityData();
                          },
                          onAddQaTechnique: (technique) {
                            setState(() => _qaTechniques.add(technique));
                            _saveQualityData();
                          },
                          onUpdateQaTechnique: (index, technique) {
                            setState(() => _qaTechniques[index] = technique);
                            _saveQualityData();
                          },
                          onRemoveQaTechnique: (index) {
                            setState(() => _qaTechniques.removeAt(index));
                            _saveQualityData();
                          },
                          onAddQcTechnique: (technique) {
                            setState(() => _qcTechniques.add(technique));
                            _saveQualityData();
                          },
                          onUpdateQcTechnique: (index, technique) {
                            setState(() => _qcTechniques[index] = technique);
                            _saveQualityData();
                          },
                          onRemoveQcTechnique: (index) {
                            setState(() => _qcTechniques.removeAt(index));
                            _saveQualityData();
                          },
                        ),
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
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Quality Management',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
        ),
        SizedBox(height: 8),
        Text(
          'Manage quality targets, assurance processes, and control measures for your project',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.selectedTab, required this.onSelected});

  final _QualityTab selectedTab;
  final ValueChanged<_QualityTab> onSelected;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      _TabData(label: 'Quality Plan', icon: Icons.description_outlined, tab: _QualityTab.plan),
      _TabData(label: 'Targets', icon: Icons.flag_outlined, tab: _QualityTab.targets),
      _TabData(label: 'QA Tracking', icon: Icons.verified_outlined, tab: _QualityTab.qaTracking),
      _TabData(label: 'QC Tracking', icon: Icons.fact_check_outlined, tab: _QualityTab.qcTracking),
      _TabData(label: 'Metrics', icon: Icons.analytics_outlined, tab: _QualityTab.metrics),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 14)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < tabs.length; i++) ...[
              _TabChip(
                data: tabs[i],
                selected: tabs[i].tab == selectedTab,
                onTap: () => onSelected(tabs[i].tab),
              ),
              if (i != tabs.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabData {
  const _TabData({required this.label, required this.icon, required this.tab});

  final String label;
  final IconData icon;
  final _QualityTab tab;
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.data, required this.selected, required this.onTap});

  final _TabData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor = selected ? const Color(0xFF1A1D1F) : const Color(0xFF4B5563);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFFFFD166), Color(0xFFFFB020)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? const Color(0xFFFDE68A) : Colors.transparent),
            boxShadow: selected
                ? [
                    BoxShadow(color: const Color(0xFFFFB020).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(data.icon, color: textColor, size: 18),
              const SizedBox(width: 10),
              Text(
                data.label,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.selectedTab,
    required this.planController,
    required this.targets,
    required this.qaTechniques,
    required this.qcTechniques,
    required this.metricSummaries,
    required this.defectTrend,
    required this.satisfactionTrend,
    required this.onPlanChanged,
    required this.onSavePlan,
    required this.onAddTarget,
    required this.onUpdateTarget,
    required this.onRemoveTarget,
    required this.onAddQaTechnique,
    required this.onUpdateQaTechnique,
    required this.onRemoveQaTechnique,
    required this.onAddQcTechnique,
    required this.onUpdateQcTechnique,
    required this.onRemoveQcTechnique,
  });

  final _QualityTab selectedTab;
  final TextEditingController planController;
  final List<QualityTargetData> targets;
  final List<QaTechniqueData> qaTechniques;
  final List<QcTechniqueData> qcTechniques;
  final List<QualityMetricSummaryData> metricSummaries;
  final QualityTrendSeriesData defectTrend;
  final QualityTrendSeriesData satisfactionTrend;
  final VoidCallback onPlanChanged;
  final VoidCallback onSavePlan;
  final ValueChanged<QualityTargetData> onAddTarget;
  final void Function(int, QualityTargetData) onUpdateTarget;
  final ValueChanged<int> onRemoveTarget;
  final ValueChanged<QaTechniqueData> onAddQaTechnique;
  final void Function(int, QaTechniqueData) onUpdateQaTechnique;
  final ValueChanged<int> onRemoveQaTechnique;
  final ValueChanged<QcTechniqueData> onAddQcTechnique;
  final void Function(int, QcTechniqueData) onUpdateQcTechnique;
  final ValueChanged<int> onRemoveQcTechnique;

  @override
  Widget build(BuildContext context) {
    switch (selectedTab) {
      case _QualityTab.plan:
        return _QualityPlanView(
          controller: planController,
          onChanged: onPlanChanged,
          onSave: onSavePlan,
        );
      case _QualityTab.targets:
        return _TargetsView(
          targets: targets,
          onAdd: onAddTarget,
          onUpdate: onUpdateTarget,
          onRemove: onRemoveTarget,
        );
      case _QualityTab.qaTracking:
        return _QaTrackingView(
          techniques: qaTechniques,
          onAdd: onAddQaTechnique,
          onUpdate: onUpdateQaTechnique,
          onRemove: onRemoveQaTechnique,
        );
      case _QualityTab.qcTracking:
        return _QcTrackingView(
          techniques: qcTechniques,
          onAdd: onAddQcTechnique,
          onUpdate: onUpdateQcTechnique,
          onRemove: onRemoveQcTechnique,
        );
      case _QualityTab.metrics:
        return _MetricsView(
          summaries: metricSummaries,
          defectTrend: defectTrend,
          satisfactionTrend: satisfactionTrend,
        );
    }
  }
}

class _QualityPlanView extends StatelessWidget {
  const _QualityPlanView({
    required this.controller,
    required this.onChanged,
    required this.onSave,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _PrimaryCard(
      icon: Icons.description_outlined,
      iconBackground: const Color(0xFFEFF6FF),
      iconColor: const Color(0xFF2563EB),
      title: 'Quality Plan',
      subtitle: 'Describe the quality plan including quality targets, quality assurance, and quality control aspects',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            minLines: 8,
            maxLines: 12,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              hintText:
                  'Enter your quality plan details here...\n\nQuality Targets: Identify key aspects that need quality assurance and control\nQuality Assurance: Define systematic processes to prevent defects\nQuality Control: Outline inspections, checks, and testing methods\nMonitor and Measure: Track progress against quality metrics',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, height: 1.45),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            ),
            style: const TextStyle(fontSize: 15, color: Color(0xFF1F2937), height: 1.5),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();
                onSave();
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetsView extends StatefulWidget {
  const _TargetsView({
    required this.targets,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
  });

  final List<QualityTargetData> targets;
  final ValueChanged<QualityTargetData> onAdd;
  final void Function(int, QualityTargetData) onUpdate;
  final ValueChanged<int> onRemove;

  @override
  State<_TargetsView> createState() => _TargetsViewState();
}

class _TargetsViewState extends State<_TargetsView> {
  Future<void> _showAddTargetDialog() async {
    final nameController = TextEditingController();
    final metricController = TextEditingController();
    final targetValueController = TextEditingController();
    final currentValueController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    _QualityTargetStatus selectedStatus = _QualityTargetStatus.onTrack;

    final result = await showDialog<QualityTargetData>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text('Add Quality Target'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Target Name'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a target name' : null,
                      ),
                      TextFormField(
                        controller: metricController,
                        decoration: const InputDecoration(labelText: 'Metric'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a metric' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: targetValueController,
                              decoration: const InputDecoration(labelText: 'Target'),
                              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter target value' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: currentValueController,
                              decoration: const InputDecoration(labelText: 'Current'),
                              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter current value' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_QualityTargetStatus>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: _QualityTargetStatus.values
                            .map((status) => DropdownMenuItem<_QualityTargetStatus>(
                                  value: status,
                                  child: Text(_TargetsViewState._statusLabel(status)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setInnerState(() => selectedStatus = value);
                          }
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
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogContext).pop(
                        QualityTargetData(
                          name: nameController.text.trim(),
                          metric: metricController.text.trim(),
                          target: targetValueController.text.trim(),
                          current: currentValueController.text.trim(),
                          status: _statusLabel(selectedStatus),
                        ),
                      );
                    }
                  },
                  child: const Text('Add Target'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    metricController.dispose();
    targetValueController.dispose();
    currentValueController.dispose();

    if (result != null) {
      widget.onAdd(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Target "${result.name}" added'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleRemoveTarget(int index) {
    final removed = widget.targets[index];
    widget.onRemove(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed target "${removed.name}"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleEditTarget(int index) {
    final original = widget.targets[index];
    final nameController = TextEditingController(text: original.name);
    final metricController = TextEditingController(text: original.metric);
    final targetValueController = TextEditingController(text: original.target);
    final currentValueController = TextEditingController(text: original.current);
    final formKey = GlobalKey<FormState>();
    _QualityTargetStatus selectedStatus = _statusFromLabel(original.status);

    showDialog<QualityTargetData>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text('Edit Quality Target'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Target Name'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a target name' : null,
                      ),
                      TextFormField(
                        controller: metricController,
                        decoration: const InputDecoration(labelText: 'Metric'),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a metric' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: targetValueController,
                              decoration: const InputDecoration(labelText: 'Target'),
                              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter target value' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: currentValueController,
                              decoration: const InputDecoration(labelText: 'Current'),
                              validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter current value' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_QualityTargetStatus>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: _QualityTargetStatus.values
                            .map((status) => DropdownMenuItem<_QualityTargetStatus>(
                                  value: status,
                                  child: Text(_TargetsViewState._statusLabel(status)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setInnerState(() => selectedStatus = value);
                          }
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
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogContext).pop(
                        QualityTargetData(
                          name: nameController.text.trim(),
                          metric: metricController.text.trim(),
                          target: targetValueController.text.trim(),
                          current: currentValueController.text.trim(),
                          status: _statusLabel(selectedStatus),
                        ),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    ).then((updated) {
      nameController.dispose();
      metricController.dispose();
      targetValueController.dispose();
      currentValueController.dispose();

      if (updated != null) {
        widget.onUpdate(index, updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated target "${updated.name}"'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PrimaryCard(
      icon: Icons.flag_outlined,
      iconBackground: const Color(0xFFF3F4FF),
      iconColor: const Color(0xFF7C3AED),
      title: 'Quality Targets',
      subtitle: 'Key quality metrics and their target values',
      actions: [
        ElevatedButton.icon(
          onPressed: _showAddTargetDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Target'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
      child: _QualityTargetsTable(
        targets: widget.targets,
        onRemove: _handleRemoveTarget,
        onEdit: _handleEditTarget,
      ),
    );
  }

  static String _statusLabel(_QualityTargetStatus status) {
    switch (status) {
      case _QualityTargetStatus.onTrack:
        return 'On Track';
      case _QualityTargetStatus.monitoring:
        return 'Monitoring';
      case _QualityTargetStatus.offTrack:
        return 'Off Track';
    }
  }

  static _QualityTargetStatus _statusFromLabel(String value) {
    final v = value.toLowerCase();
    if (v.contains('off')) return _QualityTargetStatus.offTrack;
    if (v.contains('monitor')) return _QualityTargetStatus.monitoring;
    return _QualityTargetStatus.onTrack;
  }

  static Color _statusColor(_QualityTargetStatus status) {
    switch (status) {
      case _QualityTargetStatus.onTrack:
        return const Color(0xFF16A34A);
      case _QualityTargetStatus.monitoring:
        return const Color(0xFFF59E0B);
      case _QualityTargetStatus.offTrack:
        return const Color(0xFFDC2626);
    }
  }
}

class _QualityTargetsTable extends StatelessWidget {
  const _QualityTargetsTable({required this.targets, required this.onRemove, required this.onEdit});

  final List<QualityTargetData> targets;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final bool hasTargets = targets.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: const [
                _TargetsHeaderCell(label: 'Target Name', flex: 25),
                _TargetsHeaderCell(label: 'Metric', flex: 18),
                _TargetsHeaderCell(label: 'Target', flex: 12),
                _TargetsHeaderCell(label: 'Current', flex: 12),
                _TargetsHeaderCell(label: 'Status', flex: 13),
                _TargetsHeaderCell(label: 'Actions', flex: 10, alignEnd: true),
              ],
            ),
          ),
          if (hasTargets)
            for (int i = 0; i < targets.length; i++)
              _TargetDataRow(
                data: targets[i],
                index: i,
                isLast: i == targets.length - 1,
                onRemove: onRemove,
                onEdit: onEdit,
              )
          else
            Container(
              height: 120,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'No quality targets defined yet. Click "Add Target" to get started.',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _TargetsHeaderCell extends StatelessWidget {
  const _TargetsHeaderCell({required this.label, required this.flex, this.alignEnd = false});

  final String label;
  final int flex;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
        ),
      ),
    );
  }
}

class _TargetDataRow extends StatelessWidget {
  const _TargetDataRow({
    required this.data,
    required this.index,
    required this.isLast,
    required this.onRemove,
    required this.onEdit,
  });

  final QualityTargetData data;
  final int index;
  final bool isLast;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _TargetsViewState._statusColor(_TargetsViewState._statusFromLabel(data.status));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFAFF),
        border: Border(
          bottom: isLast ? BorderSide.none : const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 25,
            child: Text(
              data.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              data.metric,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              data.target,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              data.current,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            ),
          ),
          Expanded(
            flex: 13,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data.status.isEmpty ? 'On Track' : data.status,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit(index);
                      break;
                    case 'remove':
                      onRemove(index);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'remove', child: Text('Remove')),
                ],
                child: const Icon(Icons.more_horiz, color: Color(0xFF6B7280)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _QualityTargetStatus { onTrack, monitoring, offTrack }

class _QaTrackingView extends StatefulWidget {
  const _QaTrackingView({
    required this.techniques,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
  });

  final List<QaTechniqueData> techniques;
  final ValueChanged<QaTechniqueData> onAdd;
  final void Function(int, QaTechniqueData) onUpdate;
  final ValueChanged<int> onRemove;

  @override
  State<_QaTrackingView> createState() => _QaTrackingViewState();
}

class _QaTrackingViewState extends State<_QaTrackingView> {
  Future<void> _showAddTechniqueDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final frequencyController = TextEditingController();
    final standardsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<QaTechniqueData>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add QA Technique'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Technique'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a technique' : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a description' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: frequencyController,
                          decoration: const InputDecoration(labelText: 'Frequency'),
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter frequency' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: standardsController,
                          decoration: const InputDecoration(labelText: 'Standards'),
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter standards' : null,
                        ),
                      ),
                    ],
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
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(
                    QaTechniqueData(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      frequency: frequencyController.text.trim(),
                      standards: standardsController.text.trim(),
                    ),
                  );
                }
              },
              child: const Text('Add Technique'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    frequencyController.dispose();
    standardsController.dispose();

    if (result != null) {
      widget.onAdd(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Technique "${result.name}" added'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleRemoveTechnique(int index) {
    final removed = widget.techniques[index];
    widget.onRemove(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed technique "${removed.name}"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleEditTechnique(int index) {
    final original = widget.techniques[index];
    final nameController = TextEditingController(text: original.name);
    final descriptionController = TextEditingController(text: original.description);
    final frequencyController = TextEditingController(text: original.frequency);
    final standardsController = TextEditingController(text: original.standards);
    final formKey = GlobalKey<FormState>();

    showDialog<QaTechniqueData>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit QA Technique'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Technique'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a technique' : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a description' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: frequencyController,
                          decoration: const InputDecoration(labelText: 'Frequency'),
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter frequency' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: standardsController,
                          decoration: const InputDecoration(labelText: 'Standards'),
                          validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter standards' : null,
                        ),
                      ),
                    ],
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
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(
                    QaTechniqueData(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      frequency: frequencyController.text.trim(),
                      standards: standardsController.text.trim(),
                    ),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    ).then((result) {
      nameController.dispose();
      descriptionController.dispose();
      frequencyController.dispose();
      standardsController.dispose();

      if (result != null) {
        widget.onUpdate(index, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated technique "${result.name}"'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PrimaryCard(
      icon: Icons.verified_outlined,
      iconBackground: const Color(0xFFF3F4FF),
      iconColor: const Color(0xFF7C3AED),
      title: 'Quality Assurance Techniques',
      subtitle: 'Systematic processes to prevent defects and ensure quality standards',
      actions: [
        ElevatedButton.icon(
          onPressed: _showAddTechniqueDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Technique'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
      child: _QaTechniquesTable(
        techniques: widget.techniques,
        onRemove: _handleRemoveTechnique,
        onEdit: _handleEditTechnique,
      ),
    );
  }
}

class _QcTrackingView extends StatefulWidget {
  const _QcTrackingView({
    required this.techniques,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
  });

  final List<QcTechniqueData> techniques;
  final ValueChanged<QcTechniqueData> onAdd;
  final void Function(int, QcTechniqueData) onUpdate;
  final ValueChanged<int> onRemove;

  @override
  State<_QcTrackingView> createState() => _QcTrackingViewState();
}

class _QcTrackingViewState extends State<_QcTrackingView> {
  Future<void> _showAddTechniqueDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final frequencyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<QcTechniqueData>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add QC Technique'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Technique'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a technique' : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a description' : null,
                  ),
                  TextFormField(
                    controller: frequencyController,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter frequency' : null,
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
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(
                    QcTechniqueData(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      frequency: frequencyController.text.trim(),
                    ),
                  );
                }
              },
              child: const Text('Add Technique'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    frequencyController.dispose();

    if (result != null) {
      widget.onAdd(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Technique "${result.name}" added'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleRemoveTechnique(int index) {
    final removed = widget.techniques[index];
    widget.onRemove(index);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed technique "${removed.name}"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleEditTechnique(int index) {
    final original = widget.techniques[index];
    final nameController = TextEditingController(text: original.name);
    final descriptionController = TextEditingController(text: original.description);
    final frequencyController = TextEditingController(text: original.frequency);
    final formKey = GlobalKey<FormState>();

    showDialog<QcTechniqueData>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit QC Technique'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Technique'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a technique' : null,
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a description' : null,
                  ),
                  TextFormField(
                    controller: frequencyController,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter frequency' : null,
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
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(
                    QcTechniqueData(
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                      frequency: frequencyController.text.trim(),
                    ),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    ).then((result) {
      nameController.dispose();
      descriptionController.dispose();
      frequencyController.dispose();

      if (result != null) {
        widget.onUpdate(index, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated technique "${result.name}"'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PrimaryCard(
      icon: Icons.fact_check_outlined,
      iconBackground: const Color(0xFFF3F4FF),
      iconColor: const Color(0xFF7C3AED),
      title: 'Quality Control Techniques',
      subtitle: 'Inspections and tests to identify defects in deliverables',
      actions: [
        ElevatedButton.icon(
          onPressed: _showAddTechniqueDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Technique'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
      child: _QcTechniquesTable(
        techniques: widget.techniques,
        onRemove: _handleRemoveTechnique,
        onEdit: _handleEditTechnique,
      ),
    );
  }
}

class _QcTechniquesTable extends StatelessWidget {
  const _QcTechniquesTable({required this.techniques, required this.onRemove, required this.onEdit});

  final List<QcTechniqueData> techniques;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final bool hasTechniques = techniques.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: const [
                _QcHeaderCell(label: 'Technique', flex: 26),
                _QcHeaderCell(label: 'Description', flex: 44),
                _QcHeaderCell(label: 'Frequency', flex: 18),
                _QcHeaderCell(label: 'Actions', flex: 12, alignEnd: true),
              ],
            ),
          ),
          if (hasTechniques)
            for (int i = 0; i < techniques.length; i++)
              _QcDataRow(
                data: techniques[i],
                index: i,
                isLast: i == techniques.length - 1,
                onRemove: onRemove,
                onEdit: onEdit,
              )
          else
            Container(
              height: 120,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text(
                'No QC techniques defined yet. Click "Add Technique" to get started.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _QcHeaderCell extends StatelessWidget {
  const _QcHeaderCell({required this.label, required this.flex, this.alignEnd = false});

  final String label;
  final int flex;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
        ),
      ),
    );
  }
}

class _QcDataRow extends StatelessWidget {
  const _QcDataRow({
    required this.data,
    required this.index,
    required this.isLast,
    required this.onRemove,
    required this.onEdit,
  });

  final QcTechniqueData data;
  final int index;
  final bool isLast;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFAFF),
        border: Border(
          bottom: isLast ? BorderSide.none : const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 26,
            child: Text(
              data.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
            ),
          ),
          Expanded(
            flex: 44,
            child: Text(
              data.description,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.45),
            ),
          ),
          Expanded(
            flex: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  data.frequency,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    tooltip: 'Edit technique',
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6B7280)),
                    onPressed: () => onEdit(index),
                  ),
                  IconButton(
                    tooltip: 'Remove technique',
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                    onPressed: () => onRemove(index),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsView extends StatelessWidget {
  const _MetricsView({
    required this.summaries,
    required this.defectTrend,
    required this.satisfactionTrend,
  });

  final List<QualityMetricSummaryData> summaries;
  final QualityTrendSeriesData defectTrend;
  final QualityTrendSeriesData satisfactionTrend;

  @override
  Widget build(BuildContext context) {
    return _PrimaryCard(
      icon: Icons.analytics_outlined,
      iconBackground: const Color(0xFFF0F9F9),
      iconColor: const Color(0xFF0F766E),
      title: 'Metrics',
      subtitle: 'Review quantitative indicators that describe overall quality performance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summaries.isEmpty)
            const _EmptyMetricsState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth >= 900;
                final bool isTablet = constraints.maxWidth >= 640;

                if (isWide) {
                  return Row(
                    children: [
                      for (int i = 0; i < summaries.length; i++) ...[
                        Expanded(child: _MetricSummaryCard(data: summaries[i])),
                        if (i != summaries.length - 1) const SizedBox(width: 16),
                      ],
                    ],
                  );
                }

                final double itemWidth = isTablet ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final data in summaries)
                      SizedBox(width: itemWidth, child: _MetricSummaryCard(data: data)),
                  ],
                );
              },
            ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool showSideBySide = constraints.maxWidth >= 900;
              final bool hasDefect = defectTrend.dataPoints.isNotEmpty && defectTrend.labels.isNotEmpty;
              final bool hasSatisfaction = satisfactionTrend.dataPoints.isNotEmpty && satisfactionTrend.labels.isNotEmpty;
              if (showSideBySide) {
                return Row(
                  children: [
                    Expanded(
                      child: hasDefect
                          ? _TrendCard(
                              title: defectTrend.title,
                              subtitle: defectTrend.subtitle,
                              lineColor: const Color(0xFF7C3AED),
                              areaColor: const Color(0xFFDAD5FF),
                              dataPoints: defectTrend.dataPoints,
                              labels: defectTrend.labels,
                              maxYBuffer: defectTrend.maxYBuffer,
                            )
                          : const _TrendEmptyCard(),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: hasSatisfaction
                          ? _TrendCard(
                              title: satisfactionTrend.title,
                              subtitle: satisfactionTrend.subtitle,
                              lineColor: const Color(0xFF16A34A),
                              areaColor: const Color(0xFFCDEFD6),
                              dataPoints: satisfactionTrend.dataPoints,
                              labels: satisfactionTrend.labels,
                              maxYBuffer: satisfactionTrend.maxYBuffer,
                            )
                          : const _TrendEmptyCard(),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  if (hasDefect)
                    _TrendCard(
                      title: defectTrend.title,
                      subtitle: defectTrend.subtitle,
                      lineColor: const Color(0xFF7C3AED),
                      areaColor: const Color(0xFFDAD5FF),
                      dataPoints: defectTrend.dataPoints,
                      labels: defectTrend.labels,
                      maxYBuffer: defectTrend.maxYBuffer,
                    )
                  else
                    const _TrendEmptyCard(),
                  const SizedBox(height: 20),
                  if (hasSatisfaction)
                    _TrendCard(
                      title: satisfactionTrend.title,
                      subtitle: satisfactionTrend.subtitle,
                      lineColor: const Color(0xFF16A34A),
                      areaColor: const Color(0xFFCDEFD6),
                      dataPoints: satisfactionTrend.dataPoints,
                      labels: satisfactionTrend.labels,
                      maxYBuffer: satisfactionTrend.maxYBuffer,
                    )
                  else
                    const _TrendEmptyCard(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyMetricsState extends StatelessWidget {
  const _EmptyMetricsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: const [
          Icon(Icons.analytics_outlined, color: Color(0xFFF59E0B)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No quality metrics available yet. Generate metrics to populate the dashboard.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendEmptyCard extends StatelessWidget {
  const _TrendEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Trend data unavailable',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          SizedBox(height: 6),
          Text(
            'Trend charts will appear once metrics are defined.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFFFFFFF),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCard extends StatelessWidget {
  const _PrimaryCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 16)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(width: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _QaTechniquesTable extends StatelessWidget {
  const _QaTechniquesTable({required this.techniques, required this.onRemove, required this.onEdit});

  final List<QaTechniqueData> techniques;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final bool hasTechniques = techniques.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: const [
                _QaTechniqueHeaderCell(label: 'Technique', flex: 24),
                _QaTechniqueHeaderCell(label: 'Description', flex: 32),
                _QaTechniqueHeaderCell(label: 'Frequency', flex: 16),
                _QaTechniqueHeaderCell(label: 'Standards', flex: 20),
                _QaTechniqueHeaderCell(label: 'Actions', flex: 8, alignEnd: true),
              ],
            ),
          ),
          if (hasTechniques)
            for (int i = 0; i < techniques.length; i++)
              _QaTechniqueDataRow(
                data: techniques[i],
                index: i,
                isLast: i == techniques.length - 1,
                onRemove: onRemove,
                onEdit: onEdit,
              )
          else
            Container(
              height: 120,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const Text(
                'No QA techniques defined yet. Click "Add Technique" to get started.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _QaTechniqueHeaderCell extends StatelessWidget {
  const _QaTechniqueHeaderCell({required this.label, required this.flex, this.alignEnd = false});

  final String label;
  final int flex;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
        ),
      ),
    );
  }
}

class _QaTechniqueDataRow extends StatelessWidget {
  const _QaTechniqueDataRow({
    required this.data,
    required this.index,
    required this.isLast,
    required this.onRemove,
    required this.onEdit,
  });

  final QaTechniqueData data;
  final int index;
  final bool isLast;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : const Color(0xFFFAFAFF),
        border: Border(
          bottom: isLast ? BorderSide.none : const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 24,
            child: Text(
              data.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
            ),
          ),
          Expanded(
            flex: 32,
            child: Text(
              data.description,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
            ),
          ),
          Expanded(
            flex: 16,
            child: Text(
              data.frequency,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              data.standards,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            ),
          ),
          Expanded(
            flex: 8,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit(index);
                      break;
                    case 'remove':
                      onRemove(index);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'remove', child: Text('Remove')),
                ],
                child: const Icon(Icons.more_horiz, color: Color(0xFF6B7280)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricSummaryCard extends StatelessWidget {
  const _MetricSummaryCard({required this.data});

  final QualityMetricSummaryData data;

  Color _trendColor() {
    switch (_trendType()) {
      case _MetricTrend.up:
        return const Color(0xFF16A34A);
      case _MetricTrend.down:
        return const Color(0xFFEF4444);
      case _MetricTrend.neutral:
        return const Color(0xFF6B7280);
    }
  }

  IconData _trendIcon() {
    switch (_trendType()) {
      case _MetricTrend.up:
        return Icons.trending_up;
      case _MetricTrend.down:
        return Icons.trending_down;
      case _MetricTrend.neutral:
        return Icons.horizontal_rule;
    }
  }

  _MetricTrend _trendType() {
    final trend = data.trend.toLowerCase();
    if (trend.contains('down') || trend.contains('decrease')) return _MetricTrend.down;
    if (trend.contains('up') || trend.contains('increase')) return _MetricTrend.up;
    return _MetricTrend.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final Color trendColor = _trendColor();
    final bool isNeutral = _trendType() == _MetricTrend.neutral;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data.title.isEmpty ? 'Metric' : data.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
              ),
              Icon(_trendIcon(), color: trendColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.value.isEmpty ? '--' : data.value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: data.changeLabel.isEmpty ? '' : '${data.changeLabel} ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isNeutral ? const Color(0xFF6B7280) : trendColor,
                  ),
                ),
                TextSpan(
                  text: data.changeContext,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.subtitle,
    required this.lineColor,
    required this.areaColor,
    required this.dataPoints,
    required this.labels,
    this.maxYBuffer = 0,
  });

  final String title;
  final String subtitle;
  final Color lineColor;
  final Color areaColor;
  final List<double> dataPoints;
  final List<String> labels;
  final double maxYBuffer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1.7,
            child: CustomPaint(
              painter: _TrendLinePainter(
                lineColor: lineColor,
                areaColor: areaColor,
                values: dataPoints,
                maxYBuffer: maxYBuffer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _MetricTrend { up, down, neutral }

class _TrendLinePainter extends CustomPainter {
  _TrendLinePainter({
    required this.lineColor,
    required this.areaColor,
    required this.values,
    this.maxYBuffer = 0,
  });

  final Color lineColor;
  final Color areaColor;
  final List<double> values;
  final double maxYBuffer;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final double minValue = values.reduce((a, b) => a < b ? a : b);
    final double maxValue = values.reduce((a, b) => a > b ? a : b) + maxYBuffer;
    final double verticalRange = (maxValue - minValue).abs() < 0.0001 ? 1 : maxValue - minValue;

    final double horizontalStep = values.length == 1 ? 0 : size.width / (values.length - 1);

    final path = Path();
    final areaPath = Path();

    for (int i = 0; i < values.length; i++) {
      final double x = horizontalStep * i;
      final double normalizedY = (values[i] - minValue) / verticalRange;
      final double y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        areaPath.moveTo(x, size.height);
        areaPath.lineTo(x, y);
      } else {
        final double prevX = horizontalStep * (i - 1);
        final double prevNormalizedY = (values[i - 1] - minValue) / verticalRange;
        final double prevY = size.height - (prevNormalizedY * size.height);

        final double controlPointX = (prevX + x) / 2;
        path.cubicTo(controlPointX, prevY, controlPointX, y, x, y);
        areaPath.cubicTo(controlPointX, prevY, controlPointX, y, x, y);
      }
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    final Paint areaPaint = Paint()
      ..color = areaColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, areaPaint);

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    final Paint pointPaint = Paint()..color = lineColor;

    for (int i = 0; i < values.length; i++) {
      final double x = horizontalStep * i;
      final double normalizedY = (values[i] - minValue) / verticalRange;
      final double y = size.height - (normalizedY * size.height);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
