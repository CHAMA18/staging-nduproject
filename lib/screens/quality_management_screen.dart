import 'package:flutter/material.dart';

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

  void _handleTabSelected(_QualityTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
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
                          title: 'Notes',
                          sectionLabel: 'Quality Management',
                          noteKey: 'planning_quality_management_notes',
                          checkpoint: 'quality_management',
                          description: 'Summarize quality targets, assurance cadence, and control measures.',
                        ),
                        const SizedBox(height: 24),
                        _TabStrip(selectedTab: _selectedTab, onSelected: _handleTabSelected),
                        const SizedBox(height: 28),
                        _TabContent(selectedTab: _selectedTab),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 12)),
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
    final Color background = selected ? const Color(0xFFFFC044) : Colors.transparent;
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
            color: background,
            borderRadius: BorderRadius.circular(14),
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
  const _TabContent({required this.selectedTab});

  final _QualityTab selectedTab;

  @override
  Widget build(BuildContext context) {
    switch (selectedTab) {
      case _QualityTab.plan:
        return const _QualityPlanView();
      case _QualityTab.targets:
        return const _TargetsView();
      case _QualityTab.qaTracking:
        return const _QaTrackingView();
      case _QualityTab.qcTracking:
        return const _QcTrackingView();
      case _QualityTab.metrics:
        return const _MetricsView();
    }
  }
}

class _QualityPlanView extends StatefulWidget {
  const _QualityPlanView();

  @override
  State<_QualityPlanView> createState() => _QualityPlanViewState();
}

class _QualityPlanViewState extends State<_QualityPlanView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quality plan saved'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

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
            controller: _controller,
            minLines: 8,
            maxLines: 12,
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
              onPressed: _handleSave,
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
  const _TargetsView();

  @override
  State<_TargetsView> createState() => _TargetsViewState();
}

class _TargetsViewState extends State<_TargetsView> {
  final List<_QualityTarget> _targets = [];

  Future<void> _showAddTargetDialog() async {
    final nameController = TextEditingController();
    final metricController = TextEditingController();
    final targetValueController = TextEditingController();
    final currentValueController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    _QualityTargetStatus selectedStatus = _QualityTargetStatus.onTrack;

    final result = await showDialog<_QualityTarget>(
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
                        _QualityTarget(
                          name: nameController.text.trim(),
                          metric: metricController.text.trim(),
                          target: targetValueController.text.trim(),
                          current: currentValueController.text.trim(),
                          status: selectedStatus,
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
      setState(() => _targets.add(result));
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
    final removed = _targets.removeAt(index);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed target "${removed.name}"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleEditTarget(int index) {
    final original = _targets[index];
    final nameController = TextEditingController(text: original.name);
    final metricController = TextEditingController(text: original.metric);
    final targetValueController = TextEditingController(text: original.target);
    final currentValueController = TextEditingController(text: original.current);
    final formKey = GlobalKey<FormState>();
    _QualityTargetStatus selectedStatus = original.status;

    showDialog<_QualityTarget>(
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
                        _QualityTarget(
                          name: nameController.text.trim(),
                          metric: metricController.text.trim(),
                          target: targetValueController.text.trim(),
                          current: currentValueController.text.trim(),
                          status: selectedStatus,
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
        setState(() => _targets[index] = updated);
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
        targets: _targets,
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

  final List<_QualityTarget> targets;
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

  final _QualityTarget data;
  final int index;
  final bool isLast;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _TargetsViewState._statusColor(data.status);

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
                  _TargetsViewState._statusLabel(data.status),
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

class _QualityTarget {
  const _QualityTarget({
    required this.name,
    required this.metric,
    required this.target,
    required this.current,
    required this.status,
  });

  final String name;
  final String metric;
  final String target;
  final String current;
  final _QualityTargetStatus status;
}

enum _QualityTargetStatus { onTrack, monitoring, offTrack }

class _QaTrackingView extends StatefulWidget {
  const _QaTrackingView();

  @override
  State<_QaTrackingView> createState() => _QaTrackingViewState();
}

class _QaTrackingViewState extends State<_QaTrackingView> {
  final List<_QaTechnique> _techniques = [];

  Future<void> _showAddTechniqueDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final frequencyController = TextEditingController();
    final standardsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<_QaTechnique>(
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
                    _QaTechnique(
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
      setState(() => _techniques.add(result));
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
    final removed = _techniques.removeAt(index);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed technique "${removed.name}"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleEditTechnique(int index) {
    final original = _techniques[index];
    final nameController = TextEditingController(text: original.name);
    final descriptionController = TextEditingController(text: original.description);
    final frequencyController = TextEditingController(text: original.frequency);
    final standardsController = TextEditingController(text: original.standards);
    final formKey = GlobalKey<FormState>();

    showDialog<_QaTechnique>(
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
                    _QaTechnique(
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
        setState(() => _techniques[index] = result);
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
        techniques: _techniques,
        onRemove: _handleRemoveTechnique,
        onEdit: _handleEditTechnique,
      ),
    );
  }
}

class _QcTrackingView extends StatefulWidget {
  const _QcTrackingView();

  @override
  State<_QcTrackingView> createState() => _QcTrackingViewState();
}

class _QcTrackingViewState extends State<_QcTrackingView> {
  final List<_QcTechnique> _techniques = [];

  Future<void> _showAddTechniqueDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final frequencyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<_QcTechnique>(
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
                    _QcTechnique(
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
      setState(() => _techniques.add(result));
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
    final removed = _techniques.removeAt(index);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed technique "${removed.name}"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleEditTechnique(int index) {
    final original = _techniques[index];
    final nameController = TextEditingController(text: original.name);
    final descriptionController = TextEditingController(text: original.description);
    final frequencyController = TextEditingController(text: original.frequency);
    final formKey = GlobalKey<FormState>();

    showDialog<_QcTechnique>(
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
                    _QcTechnique(
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
        setState(() => _techniques[index] = result);
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
        techniques: _techniques,
        onRemove: _handleRemoveTechnique,
        onEdit: _handleEditTechnique,
      ),
    );
  }
}

class _QcTechniquesTable extends StatelessWidget {
  const _QcTechniquesTable({required this.techniques, required this.onRemove, required this.onEdit});

  final List<_QcTechnique> techniques;
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

  final _QcTechnique data;
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

class _QcTechnique {
  const _QcTechnique({required this.name, required this.description, required this.frequency});

  final String name;
  final String description;
  final String frequency;
}

class _MetricsView extends StatelessWidget {
  const _MetricsView();

  @override
  Widget build(BuildContext context) {
    const summaries = [
      _MetricSummaryData(
        title: 'Defect Density',
        value: 'N/A',
        changeLabel: '-15%',
        changeContext: 'per 1000 LOC',
        trend: _MetricTrend.down,
      ),
      _MetricSummaryData(
        title: 'Customer Satisfaction',
        value: 'N/A',
        changeLabel: '+5%',
        changeContext: 'from surveys',
        trend: _MetricTrend.up,
      ),
      _MetricSummaryData(
        title: 'On-Time Delivery',
        value: 'N/A',
        changeLabel: '+3%',
        changeContext: 'last quarter',
        trend: _MetricTrend.up,
      ),
      _MetricSummaryData(
        title: 'Test Coverage',
        value: 'N/A',
        changeLabel: '0%',
        changeContext: 'code coverage',
        trend: _MetricTrend.neutral,
      ),
    ];

    const defectTrendPoints = [12.0, 9.0, 15.0, 8.0, 6.0, 7.0];
    const defectLabels = ['Week 1', 'Week 2', 'Week 3', 'Week 4', 'Week 5', 'Week 6'];

    const satisfactionTrendPoints = [4.0, 4.2, 4.3, 4.5, 4.6, 4.6];
    const satisfactionLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

    return _PrimaryCard(
      icon: Icons.analytics_outlined,
      iconBackground: const Color(0xFFF0F9F9),
      iconColor: const Color(0xFF0F766E),
      title: 'Metrics',
      subtitle: 'Review quantitative indicators that describe overall quality performance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              if (showSideBySide) {
                return Row(
                  children: const [
                    Expanded(
                      child: _TrendCard(
                        title: 'Defect Trend',
                        subtitle: 'Number of defects found over time',
                        lineColor: Color(0xFF7C3AED),
                        areaColor: Color(0xFFDAD5FF),
                        dataPoints: defectTrendPoints,
                        labels: defectLabels,
                        maxYBuffer: 4,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: _TrendCard(
                        title: 'Customer Satisfaction Trend',
                        subtitle: 'Customer satisfaction scores by month',
                        lineColor: Color(0xFF16A34A),
                        areaColor: Color(0xFFCDEFD6),
                        dataPoints: satisfactionTrendPoints,
                        labels: satisfactionLabels,
                        maxYBuffer: 1,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: const [
                  _TrendCard(
                    title: 'Defect Trend',
                    subtitle: 'Number of defects found over time',
                    lineColor: Color(0xFF7C3AED),
                    areaColor: Color(0xFFDAD5FF),
                    dataPoints: defectTrendPoints,
                    labels: defectLabels,
                    maxYBuffer: 4,
                  ),
                  SizedBox(height: 20),
                  _TrendCard(
                    title: 'Customer Satisfaction Trend',
                    subtitle: 'Customer satisfaction scores by month',
                    lineColor: Color(0xFF16A34A),
                    areaColor: Color(0xFFCDEFD6),
                    dataPoints: satisfactionTrendPoints,
                    labels: satisfactionLabels,
                    maxYBuffer: 1,
                  ),
                ],
              );
            },
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 14)),
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

  final List<_QaTechnique> techniques;
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

  final _QaTechnique data;
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

class _QaTechnique {
  const _QaTechnique({
    required this.name,
    required this.description,
    required this.frequency,
    required this.standards,
  });

  final String name;
  final String description;
  final String frequency;
  final String standards;
}

class _MetricSummaryData {
  const _MetricSummaryData({
    required this.title,
    required this.value,
    required this.changeLabel,
    required this.changeContext,
    required this.trend,
  });

  final String title;
  final String value;
  final String changeLabel;
  final String changeContext;
  final _MetricTrend trend;
}

class _MetricSummaryCard extends StatelessWidget {
  const _MetricSummaryCard({required this.data});

  final _MetricSummaryData data;

  Color _trendColor() {
    switch (data.trend) {
      case _MetricTrend.up:
        return const Color(0xFF16A34A);
      case _MetricTrend.down:
        return const Color(0xFFEF4444);
      case _MetricTrend.neutral:
        return const Color(0xFF6B7280);
    }
  }

  IconData _trendIcon() {
    switch (data.trend) {
      case _MetricTrend.up:
        return Icons.trending_up;
      case _MetricTrend.down:
        return Icons.trending_down;
      case _MetricTrend.neutral:
        return Icons.horizontal_rule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color trendColor = _trendColor();
    final bool isNeutral = data.trend == _MetricTrend.neutral;

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
                data.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
              ),
              Icon(_trendIcon(), color: trendColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${data.changeLabel} ',
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
