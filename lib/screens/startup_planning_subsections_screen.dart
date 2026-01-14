import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/widgets/draggable_sidebar.dart';
import 'package:ndu_project/widgets/initiation_like_sidebar.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'package:ndu_project/widgets/planning_ai_notes_card.dart';

class StartUpPlanningOperationsScreen extends StatelessWidget {
  const StartUpPlanningOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'Operations Plan & Manual',
        subtitle: 'Define runbooks, ownership, and operating procedures for launch readiness.',
        noteKey: 'planning_startup_operations_notes',
        checkpoint: 'startup_planning_operations',
        activeItemLabel: 'Start-Up Planning - Operations Plan and Manual',
        metrics: const [],
        sections: const [],
      ),
    );
  }
}

/// World-class Operations Plan editor used when the section is empty.
class _WorldClassOpsEditor extends StatefulWidget {
  const _WorldClassOpsEditor({this.sectionTitle});

  final String? sectionTitle;

  @override
  State<_WorldClassOpsEditor> createState() => _WorldClassOpsEditorState();
}

class _WorldClassOpsEditorState extends State<_WorldClassOpsEditor> {
  final TextEditingController _editorCtrl = TextEditingController();
  final TextEditingController _titleCtrl = TextEditingController();
  late final List<String> _roles;
  final Set<String> _selectedRoles = {'Ops Lead'};
  late final List<String> _templates;
  String? _selectedTemplate;

  @override
  void dispose() {
    _editorCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final title = widget.sectionTitle ?? '';
    if (title.toLowerCase().contains('hypercare')) {
      _templates = ['Hypercare checklist', 'Monitoring rota', 'Incident response', 'Handover notes'];
      _roles = ['Hypercare Lead', 'Support', 'Monitoring', 'QA', 'Product'];
    } else {
      _templates = ['Runbook', 'On-call rota', 'Escalation steps', 'Monitoring checklist'];
      _roles = ['Ops Lead', 'SRE', 'Support', 'QA', 'Product'];
    }
  }

  void _applyTemplate(String template) {
    setState(() {
      _selectedTemplate = template;
      // lightweight template content - expand as needed
      _editorCtrl.text = switch (template) {
        'Runbook' => 'Objective:\n\nScope:\n\nStep 1: ...\nStep 2: ...\n\nContact: Ops Lead',
        'On-call rota' => 'Week 1: Alice\nWeek 2: Bob\n\nEscalation: ...',
        'Escalation steps' => '1. Triage\n2. Notify\n3. Escalate to vendor',
        'Monitoring checklist' => '1. Metrics to watch\n2. Alert thresholds\n3. Runbook link',
        _ => _editorCtrl.text,
      };
    });
  }

  Future<void> _attachFile() async {
    // placeholder - integrate file picker where required
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attach file feature coming soon.')));
  }

  Future<void> _saveDraft() async {
    // lightweight save feedback
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: InputDecoration(hintText: 'Title (e.g. Operations Plan & Manual)', border: InputBorder.none),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _attachFile,
            icon: const Icon(Icons.attach_file, size: 18),
            label: const Text('Attach'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF3F4F6), foregroundColor: Colors.black),
          ),
        ]),
        const SizedBox(height: 12),

        // Template chips
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in _templates)
            ChoiceChip(
              label: Text(t),
              selected: _selectedTemplate == t,
              onSelected: (_) => _applyTemplate(t),
              selectedColor: const Color(0xFFFFF8DC),
              backgroundColor: const Color(0xFFF8FAFC),
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
        ]),
        const SizedBox(height: 12),

        // Role selectors
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(10)),
          child: Wrap(spacing: 8, children: [
            const Text('Assign roles: ', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final r in _roles)
              FilterChip(
                label: Text(r),
                selected: _selectedRoles.contains(r),
                onSelected: (v) => setState(() => v ? _selectedRoles.add(r) : _selectedRoles.remove(r)),
              ),
          ]),
        ),
        const SizedBox(height: 12),

        // Rich editor area (simple multiline TextField styled)
        Container(
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: TextField(
            controller: _editorCtrl,
            maxLines: null,
            style: const TextStyle(fontSize: 14, height: 1.6),
            decoration: const InputDecoration(border: InputBorder.none, hintText: 'Start writing your operations plan — use templates above to get started.'),
          ),
        ),
        const SizedBox(height: 14),

        // Action bar
        Row(children: [
          ElevatedButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save draft'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEFF6FF), foregroundColor: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _editorCtrl.clear()),
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Clear'),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              // lightweight publish flow
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operations Plan published.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
            child: const Text('Publish', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ])
      ]),
    );
  }
}

class StartUpPlanningHypercareScreen extends StatelessWidget {
  const StartUpPlanningHypercareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'Hypercare Plan',
        subtitle: 'Define post-launch monitoring, coverage, and escalation routines.',
        noteKey: 'planning_startup_hypercare_notes',
        checkpoint: 'startup_planning_hypercare',
        activeItemLabel: 'Start-Up Planning - Hypercare Plan',
        metrics: const [],
        sections: const [],
      ),
    );
  }
}

class StartUpPlanningDevOpsScreen extends StatelessWidget {
  const StartUpPlanningDevOpsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'DevOps',
        subtitle: 'Assess pipeline readiness, environments, and automation coverage.',
        noteKey: 'planning_startup_devops_notes',
        checkpoint: 'startup_planning_devops',
        activeItemLabel: 'Start-Up Planning - DevOps',
        metrics: const [],
        sections: const [],
      ),
    );
  }
}

class StartUpPlanningCloseOutPlanScreen extends StatelessWidget {
  const StartUpPlanningCloseOutPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _StartUpPlanningSectionScreen(
      config: _StartUpPlanningSectionConfig(
        title: 'Close Out Plan',
        subtitle: 'Outline post-launch closure activities and acceptance criteria.',
        noteKey: 'planning_startup_closeout_notes',
        checkpoint: 'startup_planning_closeout',
        activeItemLabel: 'Start-Up Planning - Close Out Plan',
        metrics: const [],
        sections: const [],
      ),
    );
  }
}

class _StartUpPlanningSectionScreen extends StatelessWidget {
  const _StartUpPlanningSectionScreen({required this.config});

  final _StartUpPlanningSectionConfig config;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final horizontalPadding = isMobile ? 20.0 : 32.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DraggableSidebar(
              openWidth: AppBreakpoints.sidebarWidth(context),
              child: InitiationLikeSidebar(activeItemLabel: config.activeItemLabel),
            ),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final gap = 24.0;
                        final twoCol = width >= 980;
                        final halfWidth = twoCol ? (width - gap) / 2 : width;
                        final hasContent = config.metrics.isNotEmpty || config.sections.isNotEmpty;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHeader(title: config.title, onBack: () => Navigator.maybePop(context)),
                            const SizedBox(height: 12),
                            Text(
                              config.subtitle,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 20),
                            PlanningAiNotesCard(
                              title: 'Notes',
                              sectionLabel: config.title,
                              noteKey: config.noteKey,
                              checkpoint: config.checkpoint,
                              description: 'Capture critical decisions, dependencies, and readiness updates.',
                            ),
                            const SizedBox(height: 24),
                            if (hasContent) ...[
                              _MetricsRow(metrics: config.metrics),
                              const SizedBox(height: 24),
                              Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: config.sections
                                    .map((section) => SizedBox(width: halfWidth, child: _SectionCard(data: section)))
                                    .toList(),
                              ),
                            ] else
                              _WorldClassOpsEditor(sectionTitle: config.title),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
                  ),
                  const Positioned(right: 24, bottom: 24, child: KazAiChatBubble()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartUpPlanningSectionConfig {
  const _StartUpPlanningSectionConfig({
    required this.title,
    required this.subtitle,
    required this.noteKey,
    required this.checkpoint,
    required this.activeItemLabel,
    required this.metrics,
    required this.sections,
  });

  final String title;
  final String subtitle;
  final String noteKey;
  final String checkpoint;
  final String activeItemLabel;
  final List<_MetricData> metrics;
  final List<_SectionData> sections;
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const _CircleIconButton(icon: Icons.arrow_forward_ios_rounded),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
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
    final displayName = user?.displayName ?? user?.email ?? 'User';

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
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null
                ? Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Text('Product manager', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: metrics
          .map((metric) => _MetricCard(label: metric.label, value: metric.value, accent: metric.color))
          .toList(),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.accent});

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent),
          ),
        ],
      ),
    );
  }
}

class _SectionData {
  const _SectionData({
    required this.title,
    required this.subtitle,
  })  : bullets = const [],
        statusRows = const [];

  final String title;
  final String subtitle;
  final List<_BulletData> bullets;
  final List<_StatusRowData> statusRows;
}

class _BulletData {
  const _BulletData(this.text, this.isCheck);

  final String text;
  final bool isCheck;
}

class _StatusRowData {
  const _StatusRowData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.data});

  final _SectionData data;

  @override
  Widget build(BuildContext context) {
    final showBullets = data.bullets.isNotEmpty;
    final showStatus = data.statusRows.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(data.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4)),
          const SizedBox(height: 16),
          if (showBullets)
            ...data.bullets.map((bullet) => _BulletRow(data: bullet)),
          if (showStatus)
            ...data.statusRows.map((row) => _StatusRow(data: row)),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.data});

  final _BulletData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.isCheck ? Icons.check_circle_outline : Icons.circle,
            size: data.isCheck ? 16 : 8,
            color: data.isCheck ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.data});

  final _StatusRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              data.value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: data.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({required this.title, required this.message, required this.icon});

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
