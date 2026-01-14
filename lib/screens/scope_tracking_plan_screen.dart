import 'dart:async';
import 'package:flutter/material.dart';

import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/ai_suggesting_textfield.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/widgets/launch_phase_navigation.dart';
import 'package:ndu_project/screens/change_management_screen.dart';
import 'package:ndu_project/widgets/new_change_request_dialog.dart';
import 'package:ndu_project/services/change_request_service.dart';

class ScopeTrackingPlanScreen extends StatelessWidget {
  const ScopeTrackingPlanScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScopeTrackingPlanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppBreakpoints.isMobile(context);
    final double horizontalPadding = isMobile ? 20 : 24;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(activeItemLabel: 'Scope Tracking Plan'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool twoColumns = constraints.maxWidth >= 980;
                        final double gap = 24;
                        final double cardWidth = twoColumns ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ScopeTrackingHeader(onBack: () => Navigator.maybePop(context)),
                            const SizedBox(height: 20),
                            const PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: 'Scope Tracking Plan',
                              noteKey: 'planning_scope_tracking_notes',
                              checkpoint: 'scope_tracking_plan',
                              description: 'Capture scope boundaries, governance decisions, and change thresholds.',
                            ),
                            const SizedBox(height: 24),
                            const _ScopeTrackingHero(),
                            const SizedBox(height: 20),
                            const _ScopeMetricRow(),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: const _ScopeBaselineCard(),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _ChangeIntakeCard(),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _GovernanceCadenceCard(),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: const _DriftSignalsCard(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const _ScopeControlPlaybook(),
                            const SizedBox(height: 28),
                            const _ChangeRegisterCard(),
                            const SizedBox(height: 16),
                            LaunchPhaseNavigation(
                              backLabel: 'Back: Cost Estimate',
                              nextLabel: 'Next: Change Management',
                              onBack: () => Navigator.of(context).maybePop(),
                              onNext: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangeManagementScreen())),
                            ),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
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

class _ScopeTrackingHeader extends StatelessWidget {
  const _ScopeTrackingHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          _RoundIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const SizedBox(width: 10),
          const _RoundIconButton(icon: Icons.arrow_forward_ios_rounded),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scope Tracking Plan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                SizedBox(height: 6),
                Text(
                  'Govern scope integrity, change control, and variance signals across delivery.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const _StatusPill(label: 'Active'),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: const Text('Export'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Publish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 14, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

class _ScopeTrackingHero extends StatelessWidget {
  const _ScopeTrackingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7CC), Color(0xFFFFFBEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5E7A5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF2E2A4)),
            ),
            child: const Icon(Icons.track_changes_outlined, color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scope Guardrails',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                ),
                SizedBox(height: 6),
                Text(
                  'Baseline scope, govern changes, and detect drift before impact escalates.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF7C5C1A)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF2E2A4)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scope Health', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                SizedBox(height: 4),
                Text('Stable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeMetricRow extends StatelessWidget {
  const _ScopeMetricRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: const [
        _ScopeMetricCard(label: 'Baseline Items', value: '42', accent: Color(0xFF2563EB)),
        _ScopeMetricCard(label: 'Open Changes', value: '7', accent: Color(0xFFF59E0B)),
        _ScopeMetricCard(label: 'Approved Variance', value: '+6%', accent: Color(0xFF10B981)),
        _ScopeMetricCard(label: 'Next Review', value: 'Oct 18', accent: Color(0xFF8B5CF6)),
      ],
    );
  }
}

class _ScopeMetricCard extends StatelessWidget {
  const _ScopeMetricCard({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent)),
        ],
      ),
    );
  }
}

class _ScopeBaselineCard extends StatelessWidget {
  const _ScopeBaselineCard();

  @override
  Widget build(BuildContext context) {
    return _ScopeCardShell(
      title: 'Scope Baseline',
      subtitle: 'Baseline integrity and scope freeze checkpoints.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ScopeProgressBar(label: 'Baseline completeness', value: 0.86),
          const SizedBox(height: 14),
          const _ScopeBullet(text: 'Freeze date approved by sponsor'),
          const _ScopeBullet(text: 'Change threshold set at 5% cost delta'),
          const _ScopeBullet(text: 'Critical path scope tagged'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _ScopeTag(label: 'Baseline v2.1'),
              _ScopeTag(label: 'Last audit: Sep 30'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChangeIntakeCard extends StatelessWidget {
  const _ChangeIntakeCard();

  @override
  Widget build(BuildContext context) {
    return _ScopeCardShell(
      title: 'Change Intake Workflow',
      subtitle: 'Standardize how scope changes move through governance.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _WorkflowStep(step: '1', title: 'Submit request', detail: 'Form + business case'),
          _WorkflowStep(step: '2', title: 'Triage & assign', detail: 'PMO + workstream lead'),
          _WorkflowStep(step: '3', title: 'Impact analysis', detail: 'Cost, schedule, risk'),
          _WorkflowStep(step: '4', title: 'Board review', detail: 'Weekly change control'),
          _WorkflowStep(step: '5', title: 'Approve & baseline', detail: 'Update scope logs'),
        ],
      ),
    );
  }
}

class _GovernanceCadenceCard extends StatelessWidget {
  const _GovernanceCadenceCard();

  @override
  Widget build(BuildContext context) {
    return _ScopeCardShell(
      title: 'Governance Cadence',
      subtitle: 'Oversight rhythm for scope health.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CadenceRow(label: 'Change control board', value: 'Weekly • Tue 10:00'),
          const _CadenceRow(label: 'Scope health review', value: 'Bi-weekly • Fri 14:00'),
          const _CadenceRow(label: 'Executive checkpoint', value: 'Monthly • 1st Thu'),
          const SizedBox(height: 16),
          const Text(
            'Next session agenda',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 8),
          const _ScopeBullet(text: 'Review open CRs and fast-track decisions'),
          const _ScopeBullet(text: 'Validate variance vs baseline'),
          const _ScopeBullet(text: 'Confirm mitigation owners'),
        ],
      ),
    );
  }
}

class _DriftSignalsCard extends StatelessWidget {
  const _DriftSignalsCard();

  @override
  Widget build(BuildContext context) {
    return _ScopeCardShell(
      title: 'Scope Drift Signals',
      subtitle: 'Early warnings to protect delivery.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ScopeBullet(text: 'Unplanned work added in sprints'),
          const _ScopeBullet(text: 'Variance > 3% for two cycles'),
          const _ScopeBullet(text: 'Dependencies added without CR'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _ScopeTag(label: '3 Active Alerts', tone: Color(0xFFF59E0B)),
              _ScopeTag(label: '1 Escalation', tone: Color(0xFFEF4444)),
              _ScopeTag(label: 'Risk Score: Medium', tone: Color(0xFF6366F1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScopeControlPlaybook extends StatelessWidget {
  const _ScopeControlPlaybook();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Scope Control Playbook',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
          ),
          SizedBox(height: 6),
          Text(
            'Use AI to draft scope boundaries, approval criteria, and escalation triggers.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          SizedBox(height: 16),
          _ScopeTrackingTextField(
            fieldLabel: 'Scope Baseline Statement',
            noteKey: 'scope_tracking_baseline_statement',
            hintText: 'Define what is in-scope, out-of-scope, and assumptions.',
          ),
          SizedBox(height: 16),
          _ScopeTrackingTextField(
            fieldLabel: 'Change Control Criteria',
            noteKey: 'scope_tracking_change_criteria',
            hintText: 'Document thresholds and criteria for approval.',
          ),
          SizedBox(height: 16),
          _ScopeTrackingTextField(
            fieldLabel: 'Escalation Triggers',
            noteKey: 'scope_tracking_escalation_triggers',
            hintText: 'Specify conditions that require executive review.',
          ),
        ],
      ),
    );
  }
}

class _ScopeTrackingTextField extends StatefulWidget {
  const _ScopeTrackingTextField({
    required this.fieldLabel,
    required this.noteKey,
    required this.hintText,
  });

  final String fieldLabel;
  final String noteKey;
  final String hintText;

  @override
  State<_ScopeTrackingTextField> createState() => _ScopeTrackingTextFieldState();
}

class _ScopeTrackingTextFieldState extends State<_ScopeTrackingTextField> {
  String _currentText = '';
  Timer? _saveDebounce;
  DateTime? _lastSavedAt;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  void _handleChanged(String value) {
    _currentText = value;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), () async {
      final trimmed = value.trim();
      final success = await ProjectDataHelper.updateAndSave(
        context: context,
        checkpoint: 'planning_${widget.noteKey}',
        dataUpdater: (data) => data.copyWith(
          planningNotes: {
            ...data.planningNotes,
            widget.noteKey: trimmed,
          },
        ),
        showSnackbar: false,
      );
      if (mounted && success) {
        setState(() => _lastSavedAt = DateTime.now());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentText.isEmpty) {
      final saved = ProjectDataHelper.getData(context).planningNotes[widget.noteKey] ?? '';
      if (saved.trim().isNotEmpty) {
        _currentText = saved;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AiSuggestingTextField(
          fieldLabel: widget.fieldLabel,
          hintText: widget.hintText,
          sectionLabel: 'Scope Tracking Plan',
          autoGenerate: true,
          autoGenerateSection: widget.fieldLabel,
          initialText: ProjectDataHelper.getData(context).planningNotes[widget.noteKey],
          onChanged: _handleChanged,
        ),
        if (_lastSavedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Saved ${TimeOfDay.fromDateTime(_lastSavedAt!).format(context)}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ),
      ],
    );
  }
}

class _ChangeRegisterCard extends StatefulWidget {
  const _ChangeRegisterCard();

  @override
  State<_ChangeRegisterCard> createState() => _ChangeRegisterCardState();
}

class _ChangeRegisterCardState extends State<_ChangeRegisterCard> {
  Future<void> _openChangeDialog({ChangeRequest? request}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => NewChangeRequestDialog(changeRequest: request),
    );
    if (result == true && mounted) {
      final message = request == null ? 'Change request created' : 'Change request updated';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteRequest(ChangeRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete change request'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ChangeRequestService.deleteChangeRequest(request.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Change request deleted')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'in review':
        return const Color(0xFFF59E0B);
      case 'submitted':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF8D6E00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Change Request Register',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openChangeDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New change request', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Track scope change requests, impact, and approval status.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<ChangeRequest>>(
            stream: ChangeRequestService.streamChangeRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('Unable to load change requests: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                );
              }
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  alignment: Alignment.center,
                  child: const Text('No change requests have been created yet.', style: TextStyle(color: Color(0xFF6B7280))),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowHeight: 44,
                        dataRowHeight: 52,
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text('Request', style: TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text('Impact', style: TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
                        ],
                        rows: requests.map((request) {
                          return DataRow(cells: [
                            DataCell(Text(request.displayId, style: const TextStyle(fontSize: 12, color: Color(0xFF0EA5E9)))),
                            DataCell(Text(request.title, style: const TextStyle(fontSize: 13))),
                            DataCell(Text(request.impact, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                            DataCell(Text(request.requester, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
                            DataCell(_StatusChip(label: request.status, color: _statusColor(request.status))),
                            DataCell(
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit request',
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF111827)),
                                    onPressed: () => _openChangeDialog(request: request),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete request',
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                    onPressed: () => _deleteRequest(request),
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _ScopeCardShell extends StatelessWidget {
  const _ScopeCardShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ScopeProgressBar extends StatelessWidget {
  const _ScopeProgressBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }
}

class _ScopeBullet extends StatelessWidget {
  const _ScopeBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeTag extends StatelessWidget {
  const _ScopeTag({required this.label, this.tone});

  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? const Color(0xFF111827);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.step,
    required this.title,
    required this.detail,
  });

  final String step;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CadenceRow extends StatelessWidget {
  const _CadenceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }
}
