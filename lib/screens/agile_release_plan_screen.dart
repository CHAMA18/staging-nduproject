import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ndu_project/models/agile_release_plan.dart';
import 'package:ndu_project/models/epic_model.dart';
import 'package:ndu_project/providers/project_data_provider.dart';
import 'package:ndu_project/services/agile_wireframe_service.dart';
import 'package:ndu_project/services/epic_feature_service.dart';
import 'package:ndu_project/utils/planning_phase_navigation.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/widgets/planning_phase_header.dart';
import 'package:ndu_project/widgets/responsive.dart';

const Color _kBackground = Color(0xFFF9FAFC);
const Color _kBorder = Color(0xFFE5E7EB);
const Color _kMuted = Color(0xFF6B7280);
const Color _kAccent = Color(0xFFD97706);

class AgileReleasePlanScreen extends StatefulWidget {
  const AgileReleasePlanScreen({super.key});

  @override
  State<AgileReleasePlanScreen> createState() =>
      _AgileReleasePlanScreenState();
}

class _AgileReleasePlanScreenState extends State<AgileReleasePlanScreen> {
  List<AgileReleasePlan> _plans = [];
  bool _isLoading = true;
  final DateFormat _df = DateFormat('MMM dd, yyyy');

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

  Future<void> _loadData() async {
    final pid = _projectId;
    if (pid == null) return;
    setState(() => _isLoading = true);
    try {
      final plans = await AgileWireframeService.loadReleasePlans(pid);
      if (mounted) setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addPlan() {
    final plan = AgileReleasePlan(
      releaseLabel: 'Release ${_plans.length + 1}',
    );
    final pid = _projectId;
    showDialog(
      context: context,
      builder: (ctx) => _ReleasePlanEditDialog(
        plan: plan,
        projectId: pid ?? '',
        onSave: (updated) {
          if (pid == null) return;
          AgileWireframeService.saveReleasePlan(
              projectId: pid, plan: updated);
          setState(() => _plans.add(updated));
        },
      ),
    );
  }

  void _editPlan(int index) {
    final plan = _plans[index];
    final pid = _projectId;
    showDialog(
      context: context,
      builder: (ctx) => _ReleasePlanEditDialog(
        plan: plan,
        projectId: pid ?? '',
        onSave: (updated) {
          if (pid == null) return;
          AgileWireframeService.saveReleasePlan(
              projectId: pid, plan: updated);
          setState(() => _plans[index] = updated);
        },
      ),
    );
  }

  void _deletePlan(int index) {
    final pid = _projectId;
    final plan = _plans[index];
    if (pid == null) return;
    AgileWireframeService.deleteReleasePlan(
        projectId: pid, planId: plan.id);
    setState(() => _plans.removeAt(index));
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
                  activeItemLabel: 'Agile Wireframe - Release Plan'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hp, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlanningPhaseHeader(
                      title: 'Release Plan',
                      onBack: () => PlanningPhaseNavigation.goToPrevious(
                          context, 'agile_release_plan'),
                      onForward: () => PlanningPhaseNavigation.goToNext(
                          context, 'agile_release_plan'),
                    ),
                    const SizedBox(height: 32),
                    Text('Plan releases, PI increments, and versioned deployments.',
                        style: TextStyle(fontSize: 15, color: _kMuted)),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      if (_plans.isEmpty)
                        _buildEmptyState('No release plans yet. Create your first release.')
                      else
                        ..._plans.asMap().entries
                            .map((e) => _buildPlanCard(e.key, e.value)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _addPlan,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Release Plan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kAccent,
                          side: const BorderSide(color: _kAccent),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    LaunchPhaseNavigation(
                      backLabel: PlanningPhaseNavigation.backLabel('agile_release_plan'),
                      nextLabel: PlanningPhaseNavigation.nextLabel('agile_release_plan'),
                      onBack: () => PlanningPhaseNavigation.goToPrevious(context, 'agile_release_plan'),
                      onNext: () => PlanningPhaseNavigation.goToNext(context, 'agile_release_plan'),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              const Positioned(
                right: 24,
                bottom: 24,
                child: KazAiChatBubble(positioned: false),
              ),
            ],
          ),
        ),
      ],
    ),
      ),
    );
  }

Widget _buildPlanCard(int index, AgileReleasePlan plan) {
    final dateStr = plan.releaseDate != null
        ? _df.format(plan.releaseDate!)
        : 'Date TBD';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.rocket_launch_outlined,
                      size: 18, color: _kAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.releaseLabel.isNotEmpty
                          ? plan.releaseLabel
                          : 'Untitled Release',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(dateStr,
                          style: TextStyle(fontSize: 12, color: _kMuted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusBgColor(plan.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(plan.status,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _statusFgColor(plan.status))),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _editPlan(index);
                    if (v == 'delete') _deletePlan(index);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            if (plan.releaseGoal.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(plan.releaseGoal,
                  style: TextStyle(fontSize: 13, color: _kMuted)),
            ],
            if (plan.version.isNotEmpty || plan.piNumber != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (plan.version.isNotEmpty)
                    _buildTag('v${plan.version}'),
                  if (plan.version.isNotEmpty && plan.piNumber != null)
                    const SizedBox(width: 6),
                  if (plan.piNumber != null)
                    _buildTag('PI ${plan.piNumber}'),
                  if (plan.trainName.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _buildTag(plan.trainName),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: Colors.blue[700])),
    );
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.withOpacity(0.1);
      case 'Ready':
        return Colors.blue.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _statusFgColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green[700]!;
      case 'Ready':
        return Colors.blue[700]!;
      default:
        return Colors.grey[700]!;
    }
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

class _ReleasePlanEditDialog extends StatefulWidget {
  final AgileReleasePlan plan;
  final String projectId;
  final ValueChanged<AgileReleasePlan> onSave;

  const _ReleasePlanEditDialog({
    required this.plan,
    required this.projectId,
    required this.onSave,
  });

  @override
  State<_ReleasePlanEditDialog> createState() =>
      _ReleasePlanEditDialogState();
}

class _ReleasePlanEditDialogState extends State<_ReleasePlanEditDialog> {
  late TextEditingController _labelCtrl;
  late TextEditingController _goalCtrl;
  late TextEditingController _scopeCtrl;
  late TextEditingController _versionCtrl;
  late TextEditingController _piCtrl;
  late TextEditingController _trainCtrl;
  DateTime? _releaseDate;
  String _status = 'Draft';
  List<Epic> _epics = [];
  Set<String> _selectedEpicIds = {};

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _labelCtrl = TextEditingController(text: p.releaseLabel);
    _goalCtrl = TextEditingController(text: p.releaseGoal);
    _scopeCtrl = TextEditingController(text: p.scope);
    _versionCtrl = TextEditingController(text: p.version);
    _piCtrl = TextEditingController(text: p.piNumber?.toString() ?? '');
    _trainCtrl = TextEditingController(text: p.trainName);
    _releaseDate = p.releaseDate;
    _status = p.status;
    _selectedEpicIds = Set.from(p.epicIds);
    _loadEpics();
  }

  Future<void> _loadEpics() async {
    if (widget.projectId.isEmpty) return;
    try {
      final epics = await EpicFeatureService.loadEpics(widget.projectId);
      if (mounted) setState(() => _epics = epics);
    } catch (_) {}
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _goalCtrl.dispose();
    _scopeCtrl.dispose();
    _versionCtrl.dispose();
    _piCtrl.dispose();
    _trainCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat df = DateFormat('MMM dd, yyyy');
    return AlertDialog(
      title: const Text('Release Plan Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                  labelText: 'Release Label', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _versionCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Version', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _piCtrl,
                    decoration: const InputDecoration(
                        labelText: 'PI Number', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _trainCtrl,
              decoration: const InputDecoration(
                  labelText: 'Release Train / ART Name',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _releaseDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _releaseDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Release Date', border: OutlineInputBorder()),
                child: Text(_releaseDate != null
                    ? df.format(_releaseDate!)
                    : 'Select date'),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                  labelText: 'Status', border: OutlineInputBorder()),
              items: ['Draft', 'Ready', 'Approved']
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _goalCtrl,
              decoration: const InputDecoration(
                  labelText: 'Release Goal', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Linked Epics',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (_epics.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No epics defined yet.',
                          style: TextStyle(
                              fontSize: 13, color: Color(0xFF9CA3AF))),
                    )
                  else
                    ..._epics.map((epic) => CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          title: Text(epic.title,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: epic.theme.isNotEmpty
                              ? Text(epic.theme,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280)))
                              : null,
                          value: _selectedEpicIds.contains(epic.id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedEpicIds.add(epic.id);
                              } else {
                                _selectedEpicIds.remove(epic.id);
                              }
                            });
                          },
                        )),
                ],
              ),
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
            final updated = AgileReleasePlan(
              id: widget.plan.id,
              releaseLabel: _labelCtrl.text,
              releaseDate: _releaseDate,
              releaseGoal: _goalCtrl.text,
              scope: _scopeCtrl.text,
              status: _status,
              version: _versionCtrl.text,
              piNumber: int.tryParse(_piCtrl.text),
              trainName: _trainCtrl.text,
              epicIds: _selectedEpicIds.toList(),
            );
            widget.onSave(updated);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
