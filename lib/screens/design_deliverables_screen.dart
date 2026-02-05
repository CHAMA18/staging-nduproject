import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';
import 'package:ndu_project/screens/design_phase_screen.dart';
import 'package:ndu_project/services/openai_service_secure.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/user_service.dart';
import 'package:ndu_project/utils/project_data_helper.dart';
import 'package:ndu_project/models/project_data_model.dart';
import 'package:ndu_project/services/design_phase_service.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final projectId = ProjectDataHelper.getData(context).projectId;
    if (projectId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Try generic service load
      var loaded =
          await DesignPhaseService.instance.loadDesignDeliverables(projectId);

      // 2. Fallback to legacy structure in ProjectDataModel
      if (loaded == null) {
        final existing =
            ProjectDataHelper.getData(context).designDeliverablesData;
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
    final computed = _computeMetrics(data.register);
    final nextData = data.copyWith(metrics: computed);
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
    final computed = _computeMetrics(data.register);
    setState(() => _data = data.copyWith(metrics: computed));
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

      if (!mounted) return;
      setState(() {
        _saving = false;
        _lastSavedAt = DateTime.now();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        debugPrint('Save error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 20.0 : 32.0;
    final data = _data;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: const InitiationLikeSidebar(
                  activeItemLabel: 'Design Deliverables'),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final cardWidth = width;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(
                                onBack: () => Navigator.maybePop(context)),
                            const SizedBox(height: 12),
                            const Text(
                              'Track design artifacts, approvals, and delivery readiness.',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            const PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: 'Design Deliverables',
                              noteKey: 'design_deliverables_notes',
                              checkpoint: 'design_deliverables',
                              description:
                                  'Summarize key deliverables, approvals, and handoff criteria.',
                            ),
                            const SizedBox(height: 24),
                            _MetricsRow(
                              metrics: data.metrics,
                            ),
                            if (_saving || _lastSavedAt != null) ...[
                              const SizedBox(height: 12),
                              _SaveStatusChip(
                                  isSaving: _saving, savedAt: _lastSavedAt),
                            ],
                            if (_loading || _error != null) ...[
                              const SizedBox(height: 12),
                              _StatusBanner(isLoading: _loading, error: _error),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: cardWidth,
                              child: _DeliverablePipelineCard(
                                items: data.pipeline,
                                onChanged: (items) =>
                                    _updateData(data.copyWith(pipeline: items)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: cardWidth,
                              child: _ApprovalStatusCard(
                                items: data.approvals,
                                onChanged: (items) => _updateData(
                                    data.copyWith(approvals: items)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _DesignDeliverablesTable(
                              rows: data.register,
                              onChanged: (rows) =>
                                  _updateData(data.copyWith(register: rows)),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: cardWidth,
                              child: _DesignDependenciesCard(
                                items: data.dependencies,
                                onChanged: (items) => _updateData(
                                    data.copyWith(dependencies: items)),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: cardWidth,
                              child: _DesignHandoffCard(
                                items: data.handoffChecklist,
                                onChanged: (items) => _updateData(
                                    data.copyWith(handoffChecklist: items)),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () =>
                                    DesignPhaseScreen.open(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD700),
                                  foregroundColor: const Color(0xFF111827),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 36, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('Next',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
                  ),
                  const Positioned(
                      right: 24, bottom: 24, child: KazAiChatBubble()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const _CircleIconButton(icon: Icons.arrow_forward_ios_rounded),
        const SizedBox(width: 16),
        const Text(
          'Design Deliverables',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
        const Spacer(),
        const _UserChip(),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        FirebaseAuthService.displayNameOrEmail(fallback: 'User');
    final email = user?.email ?? '';
    final primaryText = email.isNotEmpty ? email : displayName;

    return StreamBuilder<bool>(
      stream: UserService.watchAdminStatus(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? UserService.isAdminEmail(email);
        final role = isAdmin ? 'Admin' : 'Member';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151)),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(primaryText,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(role,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down,
                  size: 18, color: Color(0xFF9CA3AF)),
            ],
          ),
        );
      },
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.metrics,
  });

  final DesignDeliverablesMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _MetricCard(
          label: 'Active Deliverables',
          accent: const Color(0xFF2563EB),
          value: metrics.active,
        ),
        _MetricCard(
          label: 'In Review',
          accent: const Color(0xFFF59E0B),
          value: metrics.inReview,
        ),
        _MetricCard(
          label: 'Approved',
          accent: const Color(0xFF10B981),
          value: metrics.approved,
        ),
        _MetricCard(
          label: 'At Risk',
          accent: const Color(0xFFEF4444),
          value: metrics.atRisk,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.accent,
    required this.value,
  });

  final String label;
  final Color accent;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverablePipelineCard extends StatelessWidget {
  const _DeliverablePipelineCard(
      {required this.items, required this.onChanged});

  final List<DesignDeliverablePipelineItem> items;
  final ValueChanged<List<DesignDeliverablePipelineItem>> onChanged;

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
              onPressed: () => onChanged([
                ...items,
                const DesignDeliverablePipelineItem(status: 'In progress'),
              ]),
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
  const _ApprovalStatusCard({required this.items, required this.onChanged});

  final List<String> items;
  final ValueChanged<List<String>> onChanged;

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
              onPressed: () => onChanged([...items, '']),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 16),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(message,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
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
        ? const Color(0xFF2563EB)
        : (error == null ? const Color(0xFF16A34A) : const Color(0xFFDC2626));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
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
    final color = isSaving ? const Color(0xFF64748B) : const Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

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
